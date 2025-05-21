module tileset_manager;

import raylib;
import std.stdio;
import std.string;
import std.conv;
import std.format;
import std.algorithm;

/**
 * TilesetManager handles the loading and management of tilesets for rendering.
 * It maps tile IDs directly to their corresponding textures.
 */
class TilesetManager {
    private static TilesetManager _instance;
    
    // Tileset textures
    private Texture2D _groundTileset;
    private Texture2D _semiSolidTileset;
    
    // Tile dimensions in the tileset
    private int _tileWidth = 16;
    private int _tileHeight = 16;
    
    // Number of tiles per row in each tileset
    private int _groundTilesetColumns;
    private int _semiSolidTilesetColumns;
    
    // Tile mapping system for custom overrides (only used when a specific mapping is needed)
    private int[int] _customTileIdMap;
    
    // UI properties
    private bool _showTilesetExplorer = false;
    private int _explorerTilesetSelection = 0; // 0 = ground, 1 = semi-solid
    private int _explorerHoverTileIndex = -1;
    private int _selectedExplorerTileIndex = -1;
    private bool _showTileIDs = false;
    
    /**
     * Private constructor for singleton
     */
    private this() {
        loadTilesets();
    }
    
    /**
     * Get the singleton instance of TilesetManager
     */
    static TilesetManager getInstance() {
        if (_instance is null) {
            _instance = new TilesetManager();
        }
        return _instance;
    }
    
    /**
     * Load all tileset textures
     */
    void loadTilesets() {
        writeln("Loading tilesets...");
        
        // Load the ground tileset
        _groundTileset = LoadTexture("resources/image/tilemap/SPGSolidTileHeightCollision.png".toStringz());
        if (_groundTileset.id == 0) {
            writeln("Failed to load ground tileset!");
        } else {
            writeln("Ground tileset loaded: ", _groundTileset.width, "x", _groundTileset.height);
            _groundTilesetColumns = _groundTileset.width / _tileWidth;
        }
        
        // Load the semi-solid tileset
        _semiSolidTileset = LoadTexture("resources/image/tilemap/SPGSolidTileHeightSemiSolids.png".toStringz());
        if (_semiSolidTileset.id == 0) {
            writeln("Failed to load semi-solid tileset!");
        } else {
            writeln("Semi-solid tileset loaded: ", _semiSolidTileset.width, "x", _semiSolidTileset.height);
            _semiSolidTilesetColumns = _semiSolidTileset.width / _tileWidth;
        }
    }
    
    /**
     * Unload all tileset textures
     */
    void unloadTilesets() {
        UnloadTexture(_groundTileset);
        UnloadTexture(_semiSolidTileset);
    }
    
    /**
     * Add a custom tile mapping
     */
    void addTileMapping(int csvTileId, int tilesetIndex) {
        _customTileIdMap[csvTileId] = tilesetIndex;
        writeln("Added custom tile mapping: CSV ID ", csvTileId, " -> Tileset index ", tilesetIndex);
    }
    
    /**
     * Get the source rectangle for a tile in the tileset
     * @param tileId The tile ID to get the source rectangle for
     * @param layerName The layer name to determine which tileset to use
     * @return Rectangle representing the source region in the tileset
     */
    Rectangle getTileSourceRect(int tileId, string layerName) {
        // Determine which tileset to use based on layer name
        Texture2D* tilesetToUse = &_groundTileset;
        int columnsInTileset = _groundTilesetColumns;
        
        if (layerName.indexOf("SemiSolid") != -1) {
            tilesetToUse = &_semiSolidTileset;
            columnsInTileset = _semiSolidTilesetColumns;
        }
        
        // Skip invalid tiles
        if (tileId < 0 || tilesetToUse.id == 0 || columnsInTileset == 0) {
            return Rectangle(0, 0, 0, 0);
        }
        
        int tileIndex;
        
        // Check for custom mapping first (highest priority)
        if (tileId in _customTileIdMap) {
            tileIndex = _customTileIdMap[tileId];
            
            // Log when using custom mapping (only once per tile ID)
            static bool[int] loggedCustomMappings;
            if (!(tileId in loggedCustomMappings)) {
                writeln("Using custom mapping for tile ID ", tileId, " -> index ", tileIndex);
                loggedCustomMappings[tileId] = true;
            }
        } 
        // For tile ID 0, use a blank/empty tile
        else if (tileId == 0) {
            return Rectangle(0, 0, 0, 0);
        }
        // Otherwise, use direct modulo mapping - simplest approach
        else {
            // Use simple modulo to wrap IDs into the available tileset size
            int maxTiles = columnsInTileset * (tilesetToUse.height / _tileHeight);
            tileIndex = tileId % maxTiles;
            
            // Log when using modulo mapping (only once per tile ID)
            static bool[int] loggedModuloMappings;
            if (!(tileId in loggedModuloMappings) && tileId > 0) {
                writeln("Using modulo mapping for tile ID ", tileId, " -> index ", tileIndex);
                loggedModuloMappings[tileId] = true;
            }
        }
        
        // Calculate position in the tileset
        int col = tileIndex % columnsInTileset;
        int row = tileIndex / columnsInTileset;
        
        // Return the source rectangle
        return Rectangle(
            col * _tileWidth,
            row * _tileHeight,
            _tileWidth,
            _tileHeight
        );
    }
    
    /**
     * Draw a tile from the tileset
     */
    void drawTile(int tileId, string layerName, Rectangle destRect, Color tint, 
                  bool flippedHorizontally, bool flippedVertically, bool flippedDiagonally) {
        // Skip invalid tiles
        if (tileId <= 0) {
            return;
        }
        
        // Get the appropriate tileset
        Texture2D* tilesetToUse = &_groundTileset;
        if (layerName.indexOf("SemiSolid") != -1) {
            tilesetToUse = &_semiSolidTileset;
        }
        
        // Get source rectangle from tileset
        Rectangle sourceRect = getTileSourceRect(tileId, layerName);
        
        // Skip drawing if we couldn't find a valid source rectangle
        if (sourceRect.width == 0 || sourceRect.height == 0) {
            // Draw error indicator for unmapped tiles
            if (tileId > 0) {
                DrawRectangleRec(destRect, Color(200, 50, 50, 255)); // Red background
                
                // Draw diagonal lines as a pattern
                DrawLine(
                    cast(int)destRect.x, cast(int)destRect.y, 
                    cast(int)(destRect.x + destRect.width), cast(int)(destRect.y + destRect.height), 
                    Colors.WHITE
                );
                DrawLine(
                    cast(int)destRect.x, cast(int)(destRect.y + destRect.height), 
                    cast(int)(destRect.x + destRect.width), cast(int)destRect.y, 
                    Colors.WHITE
                );
                
                // Show tile ID for debugging
                if (_showTileIDs) {
                    string idStr = to!string(tileId);
                    int fontSize = cast(int)(min(destRect.width, destRect.height) / 3);
                    fontSize = max(8, fontSize); // Ensure minimum readable size
                    
                    Vector2 textSize = MeasureTextEx(GetFontDefault(), idStr.toStringz(), fontSize, 1);
                    float textX = destRect.x + (destRect.width - textSize.x) / 2;
                    float textY = destRect.y + (destRect.height - textSize.y) / 2;
                    
                    DrawText(idStr.toStringz(), cast(int)textX, cast(int)textY, fontSize, Colors.WHITE);
                }
            }
            return;
        }
        
        // Default origin and rotation
        Vector2 origin = Vector2(0, 0);
        float rotation = 0.0f;
        
        // Handle flipping and rotation
        if (flippedHorizontally) {
            sourceRect.width = -sourceRect.width;
        }
        
        if (flippedVertically) {
            sourceRect.height = -sourceRect.height;
        }
        
        if (flippedDiagonally) {
            // For diagonal flipping, we need to rotate the tile
            rotation = 90.0f;
            origin = Vector2(destRect.width / 2, destRect.height / 2);
            
            // Adjust flipping based on other flags
            if (flippedHorizontally && !flippedVertically) {
                sourceRect.height = -sourceRect.height;
            } else if (!flippedHorizontally && flippedVertically) {
                sourceRect.width = -sourceRect.width;
            } else if (flippedHorizontally && flippedVertically) {
                // Both flipped - keep the sourceRect as is after the rotation
            }
        }
        
        // Draw the tile
        DrawTexturePro(*tilesetToUse, sourceRect, destRect, origin, rotation, tint);
        
        // Draw tile ID if enabled
        if (_showTileIDs && tileId > 0) {
            string idStr = to!string(tileId);
            DrawText(idStr.toStringz(), 
                    cast(int)(destRect.x + 2), 
                    cast(int)(destRect.y + 2), 
                    8, Colors.RED);
        }
    }
    
    /**
     * Toggle showing of tile IDs for debugging
     */
    void toggleShowTileIDs() {
        _showTileIDs = !_showTileIDs;
        writeln("Show tile IDs: ", _showTileIDs ? "On" : "Off");
    }
    
    /**
     * Toggle the tileset explorer view
     */
    void toggleTilesetExplorer() {
        _showTilesetExplorer = !_showTilesetExplorer;
        writeln("Tileset explorer: ", _showTilesetExplorer ? "Shown" : "Hidden");
    }
    
    /**
     * Switch the active tileset in the explorer
     */
    void switchExplorerTileset() {
        _explorerTilesetSelection = (_explorerTilesetSelection + 1) % 2;
        writeln("Tileset explorer now showing: ", 
               _explorerTilesetSelection == 0 ? "Ground tileset" : "Semi-solid tileset");
    }
    
    /**
     * Get the currently selected tile index in the explorer
     */
    int getSelectedExplorerTileIndex() {
        return _selectedExplorerTileIndex;
    }
    
    /**
     * Check if the tileset explorer is currently visible
     */
    @property bool isExplorerVisible() {
        return _showTilesetExplorer;
    }
    
    /**
     * Update the tileset explorer (handle input)
     */
    void updateTilesetExplorer() {
        if (!_showTilesetExplorer) return;
        
        // Choose which tileset to display
        Texture2D tilesetToShow = _explorerTilesetSelection == 0 ? _groundTileset : _semiSolidTileset;
        int columnsInTileset = _explorerTilesetSelection == 0 ? _groundTilesetColumns : _semiSolidTilesetColumns;
        
        if (tilesetToShow.id == 0 || columnsInTileset == 0) return;
        
        // Calculate scaled size for display
        float scale = 2.0f;
        int scaledTileWidth = cast(int)(_tileWidth * scale);
        int scaledTileHeight = cast(int)(_tileHeight * scale);
        
        // Calculate layout
        int tilesPerRow = min(columnsInTileset, GetScreenWidth() / scaledTileWidth);
        int maxRows = min(tilesetToShow.height / _tileHeight, 4); // Limit to 4 rows
        
        // Handle mouse clicks to select tiles
        if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
            Vector2 mousePos = GetMousePosition();
            
            // Check if mouse is in the explorer area
            if (mousePos.y >= GetScreenHeight() - (maxRows * scaledTileHeight + 40)) {
                // Check each tile
                for (int row = 0; row < maxRows; row++) {
                    for (int col = 0; col < tilesPerRow; col++) {
                        int tileIndex = row * columnsInTileset + col;
                        
                        // Skip if beyond tileset bounds
                        if (tileIndex >= columnsInTileset * (tilesetToShow.height / _tileHeight)) {
                            continue;
                        }
                        
                        // Destination rectangle on screen
                        Rectangle destRect = Rectangle(
                            col * scaledTileWidth, 
                            GetScreenHeight() - (maxRows - row) * scaledTileHeight,
                            scaledTileWidth, 
                            scaledTileHeight
                        );
                        
                        if (CheckCollisionPointRec(mousePos, destRect)) {
                            _selectedExplorerTileIndex = tileIndex;
                            writeln("Selected tileset index: ", _selectedExplorerTileIndex,
                                   " (", _explorerTilesetSelection == 0 ? "Ground" : "SemiSolid", ")");
                            
                            // For ease of use, also print how to map to this tile
                            writeln("Tip: To map a level tile to this tileset tile, click on the level tile and then press M");
                            return; // Found the clicked tile, exit
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Draw the UI components (explorer)
     */
    void drawUI() {
        if (_showTilesetExplorer) {
            drawTilesetExplorer();
        }
    }
    
    /**
     * Draw the tileset explorer interface
     */
    void drawTilesetExplorer() {
        // Choose which tileset to display
        Texture2D tilesetToShow = _explorerTilesetSelection == 0 ? _groundTileset : _semiSolidTileset;
        int columnsInTileset = _explorerTilesetSelection == 0 ? _groundTilesetColumns : _semiSolidTilesetColumns;
        
        // Don't proceed if no valid tileset
        if (tilesetToShow.id == 0 || columnsInTileset == 0) {
            DrawText("No tileset loaded to explore.".toStringz(), 10, GetScreenHeight() - 30, 10, Colors.RED);
            return;
        }
        
        // Calculate scaled size for display
        float scale = 2.0f; // Make tiles larger for easier viewing
        int scaledTileWidth = cast(int)(_tileWidth * scale);
        int scaledTileHeight = cast(int)(_tileHeight * scale);
        
        // Draw the tileset at the bottom of the screen
        int tilesPerRow = min(columnsInTileset, GetScreenWidth() / scaledTileWidth);
        int maxRows = min(tilesetToShow.height / _tileHeight, 4); // Limit to 4 rows max
        
        // Background for the explorer
        DrawRectangle(0, GetScreenHeight() - (maxRows * scaledTileHeight + 40), 
                     GetScreenWidth(), maxRows * scaledTileHeight + 40, 
                     Color(0, 0, 0, 200));
        
        // Info text
        string tilesetName = _explorerTilesetSelection == 0 ? "Ground Tileset" : "Semi-Solid Tileset";
        string tilesetInfo = format("%s: %dx%d (%d x %dpx tiles)", 
                                  tilesetName, columnsInTileset, 
                                  tilesetToShow.height / _tileHeight,
                                  columnsInTileset * _tileWidth, 
                                  (tilesetToShow.height / _tileHeight) * _tileHeight);
        DrawText(tilesetInfo.toStringz(), 10, GetScreenHeight() - (maxRows * scaledTileHeight + 30), 
                15, Colors.WHITE);
        
        string controlsText = "Controls: E-Toggle Explorer, TAB-Switch Tileset";
        if (_selectedExplorerTileIndex >= 0) {
            controlsText ~= " | Click on level tiles to map them to selected tileset tile";
        }
        DrawText(controlsText.toStringz(), 10, GetScreenHeight() - (maxRows * scaledTileHeight + 10), 
                10, Colors.YELLOW);
        
        // Track mouse position for hover effects
        Vector2 mousePos = GetMousePosition();
        _explorerHoverTileIndex = -1; // Reset hover index
        
        // Draw each tile
        for (int row = 0; row < maxRows; row++) {
            for (int col = 0; col < tilesPerRow; col++) {
                int tileIndex = row * columnsInTileset + col;
                
                // Skip if beyond tileset bounds
                if (tileIndex >= columnsInTileset * (tilesetToShow.height / _tileHeight)) {
                    continue;
                }
                
                // Source rectangle from the tileset
                Rectangle sourceRect = Rectangle(
                    (tileIndex % columnsInTileset) * _tileWidth, 
                    (tileIndex / columnsInTileset) * _tileHeight,
                    _tileWidth, 
                    _tileHeight
                );
                
                // Destination rectangle on screen
                Rectangle destRect = Rectangle(
                    col * scaledTileWidth, 
                    GetScreenHeight() - (maxRows - row) * scaledTileHeight,
                    scaledTileWidth, 
                    scaledTileHeight
                );
                
                // Check if this tile is selected
                if (tileIndex == _selectedExplorerTileIndex && 
                    _explorerTilesetSelection == (_explorerTilesetSelection == 0 ? 0 : 1)) {
                    // Draw a highlight for the selected tile
                    DrawRectangleRec(destRect, Color(0, 255, 0, 100)); // Green highlight
                }
                // Check if mouse is hovering over this tile
                else if (CheckCollisionPointRec(mousePos, destRect)) {
                    _explorerHoverTileIndex = tileIndex;
                    DrawRectangleRec(destRect, Color(255, 255, 0, 100)); // Yellow highlight
                }
                
                // Draw the tile
                DrawTexturePro(tilesetToShow, sourceRect, destRect, Vector2(0, 0), 0, Colors.WHITE);
                
                // Draw tile index
                string indexText = format("%d", tileIndex);
                DrawText(indexText.toStringz(), 
                        cast(int)(destRect.x + 2), 
                        cast(int)(destRect.y + 2), 
                        8, Colors.RED);
            }
        }
        
        // Show more detailed info for hovered tile
        if (_explorerHoverTileIndex >= 0) {
            string hoverText = format("Tile Index: %d", _explorerHoverTileIndex);
            DrawText(hoverText.toStringz(), 
                    cast(int)(mousePos.x + 10), 
                    cast(int)(mousePos.y - 20), 
                    15, Colors.YELLOW);
        }
    }
}
