module utils.rvw_loader;

import raylib;

import std.stdio;
import std.conv;
import std.string;
import std.array;
import std.algorithm;
import std.math;
import std.file;
import core.stdc.stdlib;

import utils.csv_loader;
import utils.level_loader;
import world.level;
// import world.tileset_manager;

enum RVWLoaderState {
    UNINITIALIZED,
    INITIALIZED
}

class RVWLoader {
    // Singleton Instance
    private static RVWLoader _instance;

    RVWLoaderState _state = RVWLoaderState.UNINITIALIZED;
    private LevelData levelData;
    private Texture2D[] currentTilesetTextures;
    private Texture2D groundTileset;
    private Texture2D semiSolidTileset;
    private bool tilesetsLoaded = false;

    this () {
        
    }

    // Destructor to clean up when application closes
    ~this() {
        clearState();
        // Also clean up RVW files
        cleanupRVWFiles();
    }

    static RVWLoader getInstance() {
        if (_instance is null) {
            _instance = new RVWLoader();
        }
        return _instance;
    }

    void init() {
        if (_state == RVWLoaderState.UNINITIALIZED) {
            // Clear any existing state
            clearState();
            // Load tilesets
            loadTilesets();
            _state = RVWLoaderState.INITIALIZED;
        }
    }

    void clearState() {
        // Unload any existing textures
        if (groundTileset.id != 0) {
            UnloadTexture(groundTileset);
            groundTileset = Texture2D();
        }
        if (semiSolidTileset.id != 0) {
            UnloadTexture(semiSolidTileset);
            semiSolidTileset = Texture2D();
        }
        
        // Clear tileset arrays
        foreach (texture; currentTilesetTextures) {
            if (texture.id != 0) {
                UnloadTexture(texture);
            }
        }
        currentTilesetTextures.length = 0;
        
        // COMPLETELY clear level data - this should fix leftover tile artifacts
        levelData = LevelData();
        
        tilesetsLoaded = false;
        
        writeln("RVWLoader state COMPLETELY cleared - no more leftover tiles");
    }

    void cleanupRVWFiles() {
        // Remove any RVW files when shutting down
        try {
            import std.file : dirEntries, SpanMode, remove, exists;
            
            auto rvwFiles = dirEntries(".", "*.rvw", SpanMode.shallow);
            foreach (file; rvwFiles) {
                if (exists(file.name)) {
                    remove(file.name);
                    writeln("Cleaned up RVW file on shutdown: ", file.name);
                }
            }
        } catch (Exception e) {
            writeln("Warning: Could not clean up RVW files on shutdown: ", e.msg);
        }
    }

    void loadTilesets() {
        try {
            // Load ground tileset
            groundTileset = LoadTexture("resources/image/tilemap/Ground_1.png");
            if (groundTileset.id == 0) {
                writeln("Failed to load Ground_1.png tileset");
            } else {
                writeln("Successfully loaded Ground_1.png tileset");
            }

            // Load semi-solid tileset
            semiSolidTileset = LoadTexture("resources/image/tilemap/SemiSolids_1.png");
            if (semiSolidTileset.id == 0) {
                writeln("Failed to load SemiSolids_1.png tileset");
            } else {
                writeln("Successfully loaded SemiSolids_1.png tileset");
            }

            tilesetsLoaded = (groundTileset.id != 0 || semiSolidTileset.id != 0);
            if (tilesetsLoaded) {
                writeln("Tilesets loaded successfully");
            } else {
                writeln("Failed to load any tilesets");
            }
        } catch (Exception e) {
            writeln("Error loading tilesets: ", e.msg);
            tilesetsLoaded = false;
        }
    }

    LevelData LoadRVW(const char *filename, uint position) {
        LevelData value = LevelData();
        int dataSize = 0;
        char *filedata = cast(char *)LoadFileData(filename, &dataSize);

        if (filedata != null) {
            if (dataSize >= (cast(int)(position + 1) * LevelData.sizeof)) {
                LevelData *dataPtr = cast(LevelData *)filedata;
                value = dataPtr[position];
            } else {
                writefln("Error: Failed to find level data at position %d", position);
            }

            UnloadFileData(cast(ubyte *)filedata);
        }

        return value;
    }

    // Instance method that loads and stores level data
    bool loadRVW(const char *filename, uint position) {
        levelData = LoadRVW(filename, position);
        // Return true if we successfully loaded data (assuming valid if we have at least one tile layer)
        return levelData.groundLayer1.length > 0;
    }

    bool SaveRVW(const char *filename, LevelData value, uint position) {
        bool success = false;
        int dataSize = 0;
        uint newDataSize = 0;
        char *fileData = cast(char *)LoadFileData(filename, &dataSize);
        char *newFileData = null;

        if (fileData != null) {
            if (dataSize <= (position * LevelData.sizeof)) {
                // Increase data size up to position and store value
                newDataSize = cast(uint)((position + 1) * LevelData.sizeof);
                newFileData = cast(char *)realloc(fileData, newDataSize);

                if (newFileData != null) {
                    // realloc succeeded
                    LevelData *dataPtr = cast(LevelData *)newFileData;
                    dataPtr[position] = value;
                } else {
                    // realloc failed
                    newFileData = fileData;
                    newDataSize = dataSize;
                }
            } else {
                // Store the old size of the file
                newFileData = fileData;
                newDataSize = dataSize;

                // Replace value on selected position
                LevelData *dataPtr = cast(LevelData *)newFileData;
                dataPtr[position] = value;
            }

            success = SaveFileData(filename, newFileData, newDataSize);
            free(newFileData);
        } else {
            // File does not exist, create it
            dataSize = cast(int)((position + 1) * LevelData.sizeof);
            fileData = cast(char *)malloc(dataSize);
            LevelData *dataPtr = cast(LevelData *)fileData;
            dataPtr[position] = value;

            success = SaveFileData(filename, fileData, dataSize);
            UnloadFileData(cast(ubyte *)fileData);
        }

        return success;
    }

    static Texture2D[] setCurrentTileset(string tilesetName, string basePath = "resources/data/") {
        Texture2D[] tilesetTextures;
        string tilesetPath = basePath ~ "tilesets/" ~ tilesetName;

        // Load all textures in the tileset directory
        if (exists(tilesetPath) && isDir(tilesetPath)) {
            auto files = dirEntries(tilesetPath, SpanMode.shallow);
            foreach (file; files) {
                if (file.isFile && file.name.endsWith(".png")) {
                    string fullPath = tilesetPath ~ "/" ~ file.name;
                    Texture2D texture = LoadTexture(fullPath.toStringz);
                    if (texture.id != 0) {
                        tilesetTextures ~= texture;
                    } else {
                        writeln("Failed to load texture: ", fullPath);
                    }
                }
            }
        } else {
            writeln("Tileset directory does not exist: ", tilesetPath);
        }

        return tilesetTextures;
    }

    // Check if a tileset is loaded for the current level
    bool hasTilesetLoaded() {
        return tilesetsLoaded;
    }

    // Draw a tile layer with culling based on camera position
    void drawTileLayerCulled(int[][] tileData, Camera2D camera, Vector2 offset, Color tint = Colors.WHITE) {
        if (tileData.length == 0) return;

        int tileSize = 16; // 16x16 tiles to match your level data

        // FOR DEBUGGING: Draw ALL tiles, ignore camera culling
        // This ensures we see the complete level regardless of camera position
        int startX = 0;
        int endX = cast(int)tileData[0].length;
        int startY = 0;
        int endY = cast(int)tileData.length;

        // Remove spammy debug output - just print once
        static bool printedOnce = false;
        if (!printedOnce) {
            writeln("Drawing all tiles: ", startX, ",", startY, " to ", endX, ",", endY);
            writeln("Tileset loaded: ", hasTilesetLoaded());
            
            // Sample some tile data to see what we're actually working with
            if (tileData.length > 0 && tileData[0].length > 0) {
                writeln("Sample tile data (first 10 tiles in row 0): ");
                for (int i = 0; i < min(10, cast(int)tileData[0].length); i++) {
                    write(tileData[0][i], " ");
                }
                writeln("");
                
                if (tileData.length > 20) {
                    writeln("Sample tile data (first 10 tiles in row 20): ");
                    for (int i = 0; i < min(10, cast(int)tileData[20].length); i++) {
                        write(tileData[20][i], " ");
                    }
                    writeln("");
                }
            }
            
            printedOnce = true;
        }

        // Draw ALL tiles (no culling for debugging)
        for (int y = startY; y < endY; y++) {
            for (int x = startX; x < endX; x++) {
                int tileId = tileData[y][x];
                if (tileId > 0) {
                    drawTile(tileId, x * tileSize + offset.x, y * tileSize + offset.y, tint);
                }
            }
        }
    }

    // Draw a single tile at the specified position
    void drawTile(int tileId, float x, float y, Color tint = Colors.WHITE) {
        // Skip empty tiles (-1) and invalid tiles first
        if (tileId <= 0) return;
        
        // Debug: Print tileset status on first call
        static bool printedTilesetStatus = false;
        if (!printedTilesetStatus) {
            writeln("=== TILESET DEBUG INFO ===");
            writeln("hasTilesetLoaded(): ", hasTilesetLoaded());
            writeln("tilesetsLoaded: ", tilesetsLoaded);
            writeln("groundTileset.id: ", groundTileset.id);
            writeln("semiSolidTileset.id: ", semiSolidTileset.id);
            printedTilesetStatus = true;
        }
        
        if (!hasTilesetLoaded()) {
            // Draw debug rectangle if no tileset is loaded
            DrawRectangle(cast(int)x, cast(int)y, 16, 16, Color(255, 0, 255, 128)); // Magenta debug
            return;
        }

        // Use Ground_1 tileset for most tiles (we can make this more sophisticated later)
        Texture2D tileset = groundTileset;
        if (tileset.id == 0) {
            // Fallback to debug rectangle
            DrawRectangle(cast(int)x, cast(int)y, 16, 16, Color(255, 255, 0, 128));
            return;
        }

        // Calculate tile position in the tileset
        // Tileset is 256x224 pixels with 16x16 tiles = 16 tiles wide × 14 tiles tall
        int tilesPerRow = 16;
        int maxTiles = 16 * 14; // 224 total tiles in tileset
        
        // Bounds check - make sure we don't go outside the tileset
        if (tileId >= maxTiles) {
            // Tile ID is too high for this tileset, don't draw
            import std.stdio;
            writeln("Warning: Tile ID ", tileId, " exceeds tileset bounds (max ", maxTiles, ")");
            return;
        }
        
        // You said tile ID 220 should be at position (13, 14)
        // That's row 13, column 12 (0-based) = 13 * 16 + 12 = 220
        // So tile ID matches linear position directly
        int adjustedTileId = tileId;
        int tileX = adjustedTileId % tilesPerRow; // Get column
        int tileY = adjustedTileId / tilesPerRow; // Get row
        
        // Additional bounds check for calculated position
        if (tileX < 0 || tileX >= 16 || tileY < 0 || tileY >= 14) {
            import std.stdio;
            writeln("Warning: Calculated tile position (", tileX, ", ", tileY, ") is out of bounds for tile ID ", tileId);
            return;
        }

        // Define source rectangle (where to cut from the tileset)
        Rectangle sourceRect = Rectangle(
            tileX * 16.0f,       // X position in tileset
            tileY * 16.0f,       // Y position in tileset
            16.0f,               // Width (16 pixels)
            16.0f                // Height (16 pixels)
        );

        // Define destination rectangle (where to draw on screen)
        Rectangle destRect = Rectangle(
            x,      // Screen X
            y,      // Screen Y
            16.0f,  // Width
            16.0f   // Height
        );

        // Draw the tile
        DrawTexturePro(tileset, sourceRect, destRect, Vector2(0, 0), 0.0f, tint);
    }
}

