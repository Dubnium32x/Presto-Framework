module level;

import raylib;
import std.stdio;
import std.string;
import std.file;
import std.algorithm;
import std.conv;
import std.array;
import std.format;

import parser.csv_tile_loader; // Import the CSV tile loader
import screen_states;
import screen_manager;
import screen_settings;
import level_list;
import memory_manager;
import tileset_manager; // Import the tileset manager

// Define a struct to hold the level data
struct Level {
    string name;
    int tileWidth;
    int tileHeight;
    int[][] data;
    Vector2 playerStartPosition = Vector2(-1, -1); // Default if not found
}

class LevelManager : IScreen { // Implement IScreen
    Level[] levels;
    int currentLevelIndex;
    Level currentLevel;
    TilesetManager tilesetManager; // Tileset manager for texture rendering
    bool useTextures = true; // Flag to toggle between texture rendering and debug rectangles
    float scaleFactor = 1.0f; // Scale factor for rendering, adjustable with + and - keys

    // Constructor
    this() {
        currentLevelIndex = 0;
        // Initialize the tileset manager
        tilesetManager = TilesetManager.getInstance();
        loadLevels(LevelList.LEVEL_0, ActNumber.ACT_1);
    }
    
    // Destructor
    ~this() {
        // Clean up resources
        if (tilesetManager !is null) {
            tilesetManager.unloadTilesets();
        }
    }

    void loadLevels(LevelList levelList, ActNumber actNumber) {
        // Convert LevelList enum member to string for the level name
        string levelEnumString = to!string(levelList);
        int layersLoaded = 0;
        int layersAttempted = 0;
        
        writeln("=== Starting to load level: ", levelEnumString, " Act: ", to!string(actNumber), " ===");
        
        // Iterate through LayerNames
        for (int i = 0; i < LayerNames.length; i++) {
            string layerName = LayerNames[i];
            // Construct filePath based on new understanding from README
            // e.g., resources/data/levels/LEVEL_0/LEVEL_0_Ground_1.csv
            // Assuming actNumber might be part of the layerName or a subfolder if needed
            // For now, let's assume actNumber isn't directly in this basic CSV path structure yet
            // and that LayerNames already incorporate any act-specific parts if necessary,
            // or that levels are structured in folders like LEVEL_0/ACT_1/Ground_1.csv
            // Based on README: resources/data/levels/[LevelName]/
            // And CSVs are like [LevelName]_[LayerName]_[ActNumber].csv
            // However, the current loadLevels iterates LayerNames and tries to load a single CSV per layer.
            // This seems to imply each "Level" struct might actually be a "LevelLayer"
            // Or, a Level should contain multiple TileLayer structs.

            // Let's adjust to load multiple layers for the given levelList and actNumber
            // The current `Level` struct seems to hold data for one layer.
            // If `levels` is an array of these `Level` (layers), then the loop over `LayerNames` makes sense.

            string currentLevelName = to!string(levelList); // e.g., "LEVEL_0"
            // The filePath was "levels/" ~ levelName ~ ".csv";
            // Based on README, it should be more like "resources/data/levels/[LevelName]/[LayerName].csv"
            // Or, if one CSV contains all data for a level, then "resources/data/levels/[LevelName].csv"

            // Given the error was about LevelNames, and the loop structure,
            // it seems the intention was to load multiple *levels* (like LEVEL_0, LEVEL_1)
            // not multiple *layers* for a single level in this specific loop.
            // However, the constructor calls loadLevels with a specific level (LEVEL_0).

            // Let's assume `loadLevels` is meant to load all layers for THE GIVEN `levelList` and `actNumber`.
            // And `LevelNames` was a mistake, it should use `LayerNames`.

            // The `Level` struct has `name`, `tileWidth`, `tileHeight`, `data`. This looks like one layer.
            // If `levels` is an array of these `Level` (layers), then the loop over `LayerNames` makes sense.

            // Construct the file path without appending the Act number
            string filePath = "resources/data/levels/" ~ currentLevelName ~ "/" ~ currentLevelName ~ "_" ~ layerName ~ ".csv";
            writeln("Attempting to load: ", filePath);

            if (exists(filePath)) {
                writeln("Loading layer for level: ", currentLevelName, ", Layer: ", layerName, ", Act: ", to!string(actNumber));
                // loadCSVLayer expects path, name, tileWidth, tileHeight, playerStartTileID
                // Use consistent tile dimensions based on known game tile sizes
                // Typical Sonic-style games use 16x16 pixel tiles
                int tileWidth = 16;
                int tileHeight = 16;
                auto loadResult = loadCSVLayer(filePath, layerName, tileWidth, tileHeight, 0); // 0 is the player start tile ID
                
                // Assuming the Level struct is for one layer's data
                auto levelLayer = Level(
                    currentLevelName ~ "_" ~ layerName ~ "_" ~ to!string(actNumber), // Name for this specific layer
                    loadResult.layer.tileWidth, 
                    loadResult.layer.tileHeight, 
                    loadResult.layer.data,
                    loadResult.playerStartPosition
                );
                levels ~= levelLayer; // Add this layer to the list
                layersLoaded++;
            }
            else {
                writeln("Layer file not found: ", filePath);
            }
            layersAttempted++;
        }
        
        writeln("=== Finished loading level: ", layersLoaded, " layers loaded out of ", layersAttempted, " attempted ===");
        
        if (levels.length > 0) {
            // currentLevel would be the first loaded layer/level by default.
            // This might need adjustment if you expect currentLevel to be a composite of layers.
            currentLevel = levels[0]; // Or handle currentLevelIndex appropriately
            writeln("Loaded first layer as current: ", currentLevel.name);
        }
        else {
            writeln("No levels loaded.");
        }
    }

    // IScreen interface methods
    void initialize() {
        writeln("LevelManager initialized.");
        // Potentially load initial level or ensure it's loaded
        if (levels.length == 0) {
            // Default load if not already done, or handle error
            loadLevels(LevelList.LEVEL_0, ActNumber.ACT_1); // Example default
        }
    }

    // Track currently selected tile for mapping purposes
    private int selectedTileX = -1;
    private int selectedTileY = -1;
    private int selectedTileId = -1;
    
    void update() {
        // Update the tileset explorer first to handle its input
        tilesetManager.updateTilesetExplorer();
        
        // Handle input for toggling texture rendering
        if (IsKeyPressed(KeyboardKey.KEY_T)) {
            useTextures = !useTextures;
            writeln("Texture rendering: ", useTextures ? "Enabled" : "Disabled");
        }
        
        // Handle input for toggling tile ID display
        if (IsKeyPressed(KeyboardKey.KEY_I)) {
            tilesetManager.toggleShowTileIDs();
        }
        
        // Handle input for toggling tileset explorer
        if (IsKeyPressed(KeyboardKey.KEY_E)) {
            tilesetManager.toggleTilesetExplorer();
        }
        
        // Handle input for switching explorer tileset
        if (IsKeyPressed(KeyboardKey.KEY_TAB)) {
            tilesetManager.switchExplorerTileset();
        }
        
        // Handle input for adjusting scale factor
        if (IsKeyPressed(KeyboardKey.KEY_EQUAL) || IsKeyPressed(KeyboardKey.KEY_KP_ADD)) {
            // Increase scale factor
            scaleFactor += 0.1f;
            writeln("Scale factor: ", scaleFactor);
        }
        else if (IsKeyPressed(KeyboardKey.KEY_MINUS) || IsKeyPressed(KeyboardKey.KEY_KP_SUBTRACT)) {
            // Decrease scale factor, but don't go below 0.1
            scaleFactor = max(0.1f, scaleFactor - 0.1f);
            writeln("Scale factor: ", scaleFactor);
        }
        
        // Handle mouse clicks for tile inspection and mapping
        if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
            Vector2 mousePos = GetMousePosition();
            
            // Only process level tile clicks if the mouse isn't in the explorer area
            bool isInExplorerArea = false;
            if (tilesetManager.isExplorerVisible) {
                // Check if the click was in the explorer area
                int explorerHeight = GetScreenHeight() / 3; // Approximate height of explorer
                if (mousePos.y >= GetScreenHeight() - explorerHeight) {
                    isInExplorerArea = true;
                }
            }
            
            if (!isInExplorerArea) {
                // Calculate world coordinates from screen coordinates
                int screenCenterX = GetScreenWidth() / 2;
                int screenCenterY = GetScreenHeight() / 2;
                
                int levelWidthScaled = cast(int)(currentLevel.data[0].length * currentLevel.tileWidth * scaleFactor);
                int levelHeightScaled = cast(int)(currentLevel.data.length * currentLevel.tileHeight * scaleFactor);
                
                int offsetX = (screenCenterX - levelWidthScaled / 2) / 2;
                int offsetY = (screenCenterY - levelHeightScaled / 2) / 2;
                
                // Calculate which tile was clicked
                int tileX = cast(int)((mousePos.x - offsetX) / (currentLevel.tileWidth * scaleFactor));
                int tileY = cast(int)((mousePos.y - offsetY) / (currentLevel.tileHeight * scaleFactor));
                
                // Check if tile coordinates are valid
                if (tileX >= 0 && tileX < currentLevel.data[0].length && 
                    tileY >= 0 && tileY < currentLevel.data.length) {
                    
                    selectedTileX = tileX;
                    selectedTileY = tileY;
                    selectedTileId = currentLevel.data[tileY][tileX];
                    
                    writeln("Selected tile at (", tileX, ",", tileY, ") with ID: ", selectedTileId);
                    
                    // Check if a tileset index is selected in the explorer, if yes, create a mapping
                    int selectedTilesetIndex = tilesetManager.getSelectedExplorerTileIndex();
                    if (selectedTilesetIndex >= 0 && selectedTileId > 0) {
                        tilesetManager.addTileMapping(selectedTileId, selectedTilesetIndex);
                        writeln("Created mapping: Level tile ID ", selectedTileId, 
                               " -> Tileset index ", selectedTilesetIndex);
                    }
                }
            }
        }
        
        // Simpler mapping approach - press M to use the modulo approach (% maxTiles)
        // for the selected tile
        if (IsKeyPressed(KeyboardKey.KEY_M) && selectedTileId != -1) {
            // Remove any custom mapping for this tile ID, letting it fallback to the default modulo approach
            tilesetManager.addTileMapping(selectedTileId, selectedTileId % 20); // Assume modulo 20 is a good default
            writeln("Using modulo-based mapping for tile ID ", selectedTileId);
        }
        
        // Press D to show details about the selected tile
        if (IsKeyPressed(KeyboardKey.KEY_D) && selectedTileId != -1) {
            writeln("=== Selected Tile Details ===");
            writeln("Tile ID: ", selectedTileId);
            writeln("Position: (", selectedTileX, ", ", selectedTileY, ")");
            writeln("Modulo 20 would be index: ", selectedTileId % 20);
            writeln("Recommended: Select a tile in the explorer and click on this level tile to create a mapping");
            writeln("==========================");
        }
    }

    void draw() {
        // Drawing logic for the current level/screen
        // NO BeginDrawing(), EndDrawing(), or ClearBackground() here.
        // ScreenManager handles the render target.
        // All coordinates are relative to the virtual screen (e.g., 640x360).

        // Debug information
        DrawText("GAME SCREEN (LevelManager)".toStringz(), 10, 10, 20, Colors.MAROON);
        
        // Add drawing calls for the level content here
        // e.g., draw tiles from currentLevel.data
        if (currentLevel.data.length > 0) {
            string levelInfoText = format("Level: %s, Size: %dx%d, Tile Size: %dx%d", 
                          currentLevel.name, 
                          currentLevel.data[0].length, 
                          currentLevel.data.length,
                          currentLevel.tileWidth,
                          currentLevel.tileHeight);
            DrawText(levelInfoText.toStringz(), 10, 40, 12, Colors.WHITE);
                    
            int visibleTiles = 0; // Count tiles that will be drawn
            
            // Scale factor is now a class member variable that can be adjusted with + and - keys
            // This is for debugging only - normally you'd use camera controls for this
            
            // Calculate offset to center the level better on screen
            int screenCenterX = GetScreenWidth() / 2;
            int screenCenterY = GetScreenHeight() / 2;
            
            int levelWidthScaled = cast(int)(currentLevel.data[0].length * currentLevel.tileWidth * scaleFactor);
            int levelHeightScaled = cast(int)(currentLevel.data.length * currentLevel.tileHeight * scaleFactor);
            
            // Center the level
            int offsetX = (screenCenterX - levelWidthScaled / 2) / 2;  // Divide by 2 to shift it left a bit
            int offsetY = (screenCenterY - levelHeightScaled / 2) / 2;  // Divide by 2 to shift it up a bit
                    
            for (int y = 0; y < currentLevel.data.length; y++) {
                for (int x = 0; x < currentLevel.data[y].length; x++) {
                    int tileId = currentLevel.data[y][x];
                    if (tileId != -1) // Assuming -1 is an empty tile
                        {
                        // Simple culling - skip tiles that would be outside the screen bounds
                        int tileScreenX = offsetX + cast(int)(x * currentLevel.tileWidth * scaleFactor);
                        int tileScreenY = offsetY + cast(int)(y * currentLevel.tileHeight * scaleFactor);
                        int tileScreenWidth = cast(int)(currentLevel.tileWidth * scaleFactor);
                        int tileScreenHeight = cast(int)(currentLevel.tileHeight * scaleFactor);
                        
                        // Skip if the tile is completely outside the screen
                        if (tileScreenX + tileScreenWidth < 0 || 
                            tileScreenY + tileScreenHeight < 0 ||
                            tileScreenX > GetScreenWidth() || 
                            tileScreenY > GetScreenHeight()) {
                            continue;
                        }
                        
                        // Handle flipped tiles (negative numbers)
                        bool flippedHorizontally = false;
                        bool flippedVertically = false;
                        bool flippedDiagonally = false;
                        
                        // Constants for the flip bits (based on Tiled)
                        enum FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
                        enum FLIPPED_VERTICALLY_FLAG   = 0x40000000;
                        enum FLIPPED_DIAGONALLY_FLAG   = 0x20000000;
                        enum TILE_ID_MASK              = 0x1FFFFFFF;
                        
                        if (tileId < 0 || tileId > TILE_ID_MASK) {
                            // Extract flip flags if they exist
                            flippedHorizontally = (tileId & FLIPPED_HORIZONTALLY_FLAG) != 0;
                            flippedVertically = (tileId & FLIPPED_VERTICALLY_FLAG) != 0;
                            flippedDiagonally = (tileId & FLIPPED_DIAGONALLY_FLAG) != 0;
                            
                            // Clear the flip flags to get the actual tile ID
                            tileId &= TILE_ID_MASK;
                            
                            writeln("Found flipped tile: ", tileId, 
                                   " H:", flippedHorizontally, 
                                   " V:", flippedVertically, 
                                   " D:", flippedDiagonally);
                        }
                        
                        // Calculate destination rectangle for the tile
                        Rectangle destRect = Rectangle(
                            offsetX + cast(int)(x * currentLevel.tileWidth * scaleFactor), 
                            offsetY + cast(int)(y * currentLevel.tileHeight * scaleFactor), 
                            cast(int)(currentLevel.tileWidth * scaleFactor), 
                            cast(int)(currentLevel.tileHeight * scaleFactor)
                        );
                        
                        // Get layer name from the current level name (e.g., "LEVEL_0_Ground_1_ACT_1" -> "Ground_1")
                        string layerName = "";
                        auto nameParts = currentLevel.name.split("_");
                        if (nameParts.length >= 4) {
                            layerName = nameParts[2] ~ "_" ~ nameParts[3];
                        }
                        
                        // Draw either texture or debug rectangle based on the useTextures flag
                        if (useTextures) {
                            // Use white tint for normal rendering
                            Color tint = Colors.WHITE;
                            
                            // Draw the tile using the tileset manager
                            tilesetManager.drawTile(
                                tileId, 
                                layerName, 
                                destRect, 
                                tint, 
                                flippedHorizontally, 
                                flippedVertically, 
                                flippedDiagonally
                            );
                        } else {
                            // Debug rendering with colored rectangles
                            Color tileColor = Colors.BLUE;
                            if (flippedHorizontally || flippedVertically || flippedDiagonally) {
                                tileColor = Colors.PURPLE; // Use purple for flipped tiles
                            }
                            
                            // Draw a debug rectangle
                            DrawRectangleRec(destRect, tileColor);
                        }
                        
                        visibleTiles++; // Count each tile we draw
                    }
                }
            }
            
            // Draw highlight around the currently selected tile if applicable
            if (selectedTileX >= 0 && selectedTileY >= 0 && 
                selectedTileX < currentLevel.data[0].length && 
                selectedTileY < currentLevel.data.length) {
                
                Rectangle selectedRect = Rectangle(
                    offsetX + cast(int)(selectedTileX * currentLevel.tileWidth * scaleFactor), 
                    offsetY + cast(int)(selectedTileY * currentLevel.tileHeight * scaleFactor), 
                    cast(int)(currentLevel.tileWidth * scaleFactor), 
                    cast(int)(currentLevel.tileHeight * scaleFactor)
                );
                
                // Draw a highlighted rectangle around selected tile
                DrawRectangleLinesEx(selectedRect, 2, Colors.YELLOW);
            }
            
            string tilesText = format("Visible tiles: %d (Scale: %.1f%%) - %s", 
                                 visibleTiles, scaleFactor * 100, 
                                 useTextures ? "Textures On" : "Debug View");
            DrawText(tilesText.toStringz(), 10, 60, 12, Colors.WHITE);
            
            // Add controls info
            string controlsText = "Controls: T-Toggle Textures, I-Show Tile IDs, +/- Adjust Scale";
            DrawText(controlsText.toStringz(), 10, 100, 10, Colors.GREEN);
            
            // Add simple mapping instructions
            string mappingText = "E-Toggle Tileset Explorer, Select tileset tile, then click level tile to map";
            DrawText(mappingText.toStringz(), 10, 115, 10, Colors.GREEN);
            
            // Add extra controls
            string extraText = "D-Show tile details, M-Use modulo mapping for selected tile";
            DrawText(extraText.toStringz(), 10, 130, 10, Colors.GREEN);
            
            // Show currently selected tile info if applicable
            if (selectedTileId != -1) {
                string selectedText = format("Selected tile: (%d,%d) ID: %d", 
                                           selectedTileX, selectedTileY, selectedTileId);
                DrawText(selectedText.toStringz(), 10, 145, 10, Colors.YELLOW);
            }
            
            // Add player position information if available
            if(currentLevel.playerStartPosition.x != -1 && currentLevel.playerStartPosition.y != -1) {
                string playerPosText = format("Player start: %.1f, %.1f", 
                    currentLevel.playerStartPosition.x, 
                    currentLevel.playerStartPosition.y);
                DrawText(playerPosText.toStringz(), 10, 80, 12, Colors.YELLOW);
            }
            
            // Draw player start position for debugging
            if(currentLevel.playerStartPosition.x != -1 && currentLevel.playerStartPosition.y != -1) {
                // Ensure player start position is also drawn relative to virtual screen and scaled
                Vector2 scaledPos = Vector2(
                    offsetX + currentLevel.playerStartPosition.x * scaleFactor,
                    offsetY + currentLevel.playerStartPosition.y * scaleFactor
                );
                DrawCircleV(scaledPos, 5, Colors.RED);
            }
        } else {
            DrawText("No level data to draw.".toStringz(), 10, 30, 20, Colors.LIGHTGRAY); // Adjusted position
        }
        
        // Draw the tileset manager UI elements
        tilesetManager.drawUI();
        
        // NO EndDrawing();
    }
}
