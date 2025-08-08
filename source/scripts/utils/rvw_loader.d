module utils.rvw_loader;

import raylib;
import std.stdio;
import std.file;
import std.string;
import std.conv : to;
import std.format;

import utils.csv_converter;
import world.memory_manager;

/**
 * RVW (Really Versatile World) Loader for Presto Framework
 * 
 * Handles loading level data from RVW binary files created by csv_converter
 * and integrates with tileset rendering system.
 */

// Tileset information structure
struct TilesetInfo {
    Texture2D texture;
    int tileWidth = 16;
    int tileHeight = 16;
    int tilesPerRow;
    int totalTiles;
    string filePath;
}

/**
 * RVW Loader Class - integrates with existing csv_converter system
 */
class RVWLoader {
    private static RVWLoader _instance;
    private MemoryManager memoryManager;
    
    // Tileset management
    private TilesetInfo[string] tilesets;
    private TilesetInfo currentTileset;
    private bool hasTileset = false;
    
    // RVW binary data cache
    private int[][][string] rvwDataCache;
    
    private this() {
        memoryManager = MemoryManager.instance();
    }
    
    static RVWLoader getInstance() {
        if (_instance is null) {
            _instance = new RVWLoader();
        }
        return _instance;
    }
    
    /**
     * Initialize the RVW loader
     */
    void initialize() {
        writeln("RVWLoader initialized");
        
        // Load default Sonic Physics Guide tilesets
        loadTileset("spg_solid", "resources/image/tilemap/SPGSolidTileHeightCollision.png");
        loadTileset("spg_semisolid", "resources/image/tilemap/SPGSolidTileHeightSemiSolids.png");
        
        // Set default tileset
        if ("spg_solid" in tilesets) {
            setCurrentTileset("spg_solid");
        }
    }
    
    /**
     * Load a tileset texture
     */
    bool loadTileset(string name, string filePath) {
        if (!exists(filePath)) {
            writeln("Tileset file not found: ", filePath);
            return false;
        }
        
        TilesetInfo tileset;
        tileset.texture = memoryManager.loadTexture(filePath);
        tileset.filePath = filePath;
        tileset.tileWidth = 16;  // Standard Sonic tile size
        tileset.tileHeight = 16;
        
        if (tileset.texture.id == 0) {
            writeln("Failed to load tileset texture: ", filePath);
            return false;
        }
        
        // Calculate tiles per row and total tiles
        tileset.tilesPerRow = tileset.texture.width / tileset.tileWidth;
        int tilesPerColumn = tileset.texture.height / tileset.tileHeight;
        tileset.totalTiles = tileset.tilesPerRow * tilesPerColumn;
        
        tilesets[name] = tileset;
        
        writeln("Loaded tileset '", name, "': ", tileset.tilesPerRow, "x", tilesPerColumn, 
                " tiles (", tileset.totalTiles, " total)");
        
        return true;
    }
    
    /**
     * Set the current active tileset
     */
    bool setCurrentTileset(string name) {
        if (name in tilesets) {
            currentTileset = tilesets[name];
            hasTileset = true;
            writeln("Set current tileset to: ", name);
            return true;
        }
        
        writeln("Tileset not found: ", name);
        return false;
    }
    
    /**
     * Load level data from RVW binary file (using existing csv_converter functions)
     */
    int[][] loadLevelFromRVW(string rvwFilePath, uint position) {
        if (!exists(rvwFilePath)) {
            writeln("RVW file not found: ", rvwFilePath);
            return [];
        }
        
        // Use the existing LoadRVW function from csv_converter
        int[][] levelData = LoadRVW(rvwFilePath.toStringz, position);
        
        if (levelData.length > 0) {
            writeln("Loaded RVW level data: ", levelData.length, " rows from ", rvwFilePath);
            // Cache the data
            string cacheKey = rvwFilePath ~ "_" ~ position.to!string;
            rvwDataCache[cacheKey] = levelData;
        } else {
            writeln("No data loaded from RVW file: ", rvwFilePath, " at position ", position);
        }
        
        return levelData;
    }
    
    /**
     * Convert CSV to RVW binary format (using existing csv_converter functions)
     */
    bool convertCSVToRVW(string csvFilePath, string rvwFilePath, uint position) {
        if (!exists(csvFilePath)) {
            writeln("CSV file not found for conversion: ", csvFilePath);
            return false;
        }
        
        // Use the existing ConvertCSV2RVW function from csv_converter
        bool success = ConvertCSV2RVW(rvwFilePath.toStringz, position, csvFilePath);
        
        if (success) {
            writeln("Successfully converted ", csvFilePath, " to RVW format: ", rvwFilePath);
        } else {
            writeln("Failed to convert ", csvFilePath, " to RVW format");
        }
        
        return success;
    }
    
    /**
     * Draw a tile from the current tileset
     */
    void drawTile(int tileId, float x, float y, Color tint = Colors.WHITE) {
        if (!hasTileset || tileId <= 0 || tileId > currentTileset.totalTiles) {
            return;
        }
        
        // Calculate source rectangle in tileset
        int tileX = (tileId - 1) % currentTileset.tilesPerRow;
        int tileY = (tileId - 1) / currentTileset.tilesPerRow;
        
        Rectangle sourceRect = Rectangle(
            tileX * currentTileset.tileWidth,
            tileY * currentTileset.tileHeight,
            currentTileset.tileWidth,
            currentTileset.tileHeight
        );
        
        Rectangle destRect = Rectangle(
            x, y,
            currentTileset.tileWidth,
            currentTileset.tileHeight
        );
        
        Vector2 origin = Vector2(0, 0);
        
        DrawTexturePro(currentTileset.texture, sourceRect, destRect, origin, 0.0f, tint);
    }
    
    /**
     * Draw a layer of tiles from 2D array
     */
    void drawTileLayer(int[][] tileData, Vector2 offset = Vector2(0, 0), Color tint = Colors.WHITE) {
        if (!hasTileset || tileData.length == 0) {
            return;
        }
        
        for (int y = 0; y < tileData.length; y++) {
            for (int x = 0; x < tileData[y].length; x++) {
                int tileId = tileData[y][x];
                if (tileId > 0) {
                    float drawX = offset.x + (x * currentTileset.tileWidth);
                    float drawY = offset.y + (y * currentTileset.tileHeight);
                    drawTile(tileId, drawX, drawY, tint);
                }
            }
        }
    }
    
    /**
     * Draw a visible portion of a tile layer (for performance)
     */
    void drawTileLayerCulled(int[][] tileData, Camera2D camera, Vector2 offset = Vector2(0, 0), Color tint = Colors.WHITE) {
        if (!hasTileset || tileData.length == 0) {
            return;
        }
        
        // Calculate visible tile range
        int startX = cast(int)((camera.target.x - camera.offset.x - offset.x) / currentTileset.tileWidth) - 1;
        int endX = cast(int)((camera.target.x + camera.offset.x - offset.x) / currentTileset.tileWidth) + 2;
        int startY = cast(int)((camera.target.y - camera.offset.y - offset.y) / currentTileset.tileHeight) - 1;
        int endY = cast(int)((camera.target.y + camera.offset.y - offset.y) / currentTileset.tileHeight) + 2;
        
        // Clamp to level bounds
        if (startX < 0) startX = 0;
        if (startY < 0) startY = 0;
        if (endX >= tileData[0].length) endX = cast(int)tileData[0].length;
        if (endY >= tileData.length) endY = cast(int)tileData.length;
        
        // Draw visible tiles
        for (int y = startY; y < endY; y++) {
            for (int x = startX; x < endX; x++) {
                int tileId = tileData[y][x];
                if (tileId > 0) {
                    float drawX = offset.x + (x * currentTileset.tileWidth);
                    float drawY = offset.y + (y * currentTileset.tileHeight);
                    drawTile(tileId, drawX, drawY, tint);
                }
            }
        }
    }
    
    /**
     * Get tile size from current tileset
     */
    Vector2 getTileSize() {
        if (hasTileset) {
            return Vector2(currentTileset.tileWidth, currentTileset.tileHeight);
        }
        return Vector2(16, 16); // Default size
    }
    
    /**
     * Get tileset information
     */
    TilesetInfo getCurrentTilesetInfo() {
        return currentTileset;
    }
    
    /**
     * Check if a tileset is loaded
     */
    bool hasTilesetLoaded() {
        return hasTileset;
    }
    
    /**
     * List all loaded tilesets
     */
    string[] getLoadedTilesets() {
        return tilesets.keys;
    }
    
    /**
     * Create sample RVW files from CSV data
     */
    void createSampleRVWFiles(string csvBasePath, string rvwBasePath) {
        writeln("Creating sample RVW files from CSV data...");
        
        string[] layers = [
            "_Ground_1.csv",
            "_Ground_2.csv", 
            "_SemiSolid_1.csv",
            "_SemiSolid_2.csv",
            "_Collision.csv"
        ];
        
        foreach (i, layer; layers) {
            string csvPath = csvBasePath ~ layer;
            string rvwPath = rvwBasePath ~ ".rvw";
            
            if (exists(csvPath)) {
                convertCSVToRVW(csvPath, rvwPath, cast(uint)i);
            }
        }
        
        writeln("Sample RVW file creation completed");
    }
    
    /**
     * Debug: Draw tileset preview
     */
    void drawTilesetPreview(float x, float y, int maxTilesPerRow = 16) {
        if (!hasTileset) {
            DrawText("No tileset loaded", cast(int)x, cast(int)y, 16, Colors.RED);
            return;
        }
        
        DrawText(("Tileset: " ~ currentTileset.filePath).toStringz, cast(int)x, cast(int)y - 20, 12, Colors.WHITE);
        
        int tilesDrawn = 0;
        int maxTilesToShow = 64; // Limit for preview
        
        for (int tileId = 1; tileId <= currentTileset.totalTiles && tilesDrawn < maxTilesToShow; tileId++) {
            int row = tilesDrawn / maxTilesPerRow;
            int col = tilesDrawn % maxTilesPerRow;
            
            float drawX = x + (col * (currentTileset.tileWidth + 2));
            float drawY = y + (row * (currentTileset.tileHeight + 2));
            
            drawTile(tileId, drawX, drawY);
            
            // Draw tile ID
            string idText = tileId.to!string;
            DrawText(idText.toStringz, cast(int)drawX, cast(int)drawY + currentTileset.tileHeight + 2, 8, Colors.WHITE);
            
            tilesDrawn++;
        }
    }
    
    /**
     * Cleanup resources
     */
    void unload() {
        // Clear caches
        rvwDataCache = null;
        
        // Tilesets will be unloaded by MemoryManager
        tilesets = null;
        hasTileset = false;
        
        writeln("RVWLoader unloaded");
    }
}
