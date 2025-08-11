module utils.level_loader;

import raylib;

import std.stdio;
import std.file;
import std.string;
import std.json;
import std.conv : to;
import std.array : array;
import std.algorithm : map, filter;

import utils.csv_loader;
import utils.rvw_converter;
import world.tile_collision;
import world.screen_state;
import world.screen_settings;
import world.screen_manager;

bool levelInitialized = false;

// Enhanced tile structure with properties
struct Tile {
    int tileId;
    bool isSolid = false;
    bool isPlatform = false;
    bool isHazard = false;
    int heightProfile = 0; // For slopes
    ubyte flipFlags = 0; // Horizontal/vertical/diagonal flip flags
}

// Enhanced level data with multiple layers
struct LevelData {
    string levelName;
    int width;
    int height;
    
    // Multiple tile layers
    Tile[][] groundLayer1;
    Tile[][] groundLayer2;
    Tile[][] groundLayer3;
    Tile[][] semiSolidLayer1;
    Tile[][] semiSolidLayer2;
    Tile[][] semiSolidLayer3;
    Tile[][] collisionLayer;
    Tile[][] hazardLayer;
    
    // Object data (separate from tiles)
    LevelObject[] objects;
    
    // Level metadata
    Vector2 playerSpawnPoint;
    string tilesetName;
    Color backgroundColor;
    int timeLimit; // In seconds, 0 = no limit
}

// Structure for level objects (enemies, items, etc.)
struct LevelObject {
    int objectId;
    float x, y;
    int objectType; // Enemy, item, trigger, etc.
    string[] properties; // Additional properties as strings
}

// Load a complete level with all layers and objects
LevelData loadCompleteLevel(string levelPath) {
    LevelData level;
    
    // Try to load level metadata first
    string metadataPath = levelPath ~ "/metadata.json";
    if (exists(metadataPath)) {
        level = loadLevelMetadata(metadataPath);
    } else {
        // Set defaults
        level.levelName = "Unnamed Level";
        level.backgroundColor = Color(135, 206, 235, 255); // Sky blue
        level.tilesetName = "default";
        level.playerSpawnPoint = Vector2(100, 100);
    }
    
    // Load all tile layers
    level.groundLayer1 = loadTileLayer(levelPath ~ "/LEVEL_0_Ground_1.csv");
    level.groundLayer2 = loadTileLayer(levelPath ~ "/LEVEL_0_Ground_2.csv");
    level.groundLayer3 = loadTileLayer(levelPath ~ "/Ground_3.csv"); // Fallback name
    level.semiSolidLayer1 = loadTileLayer(levelPath ~ "/LEVEL_0_SemiSolid_1.csv");
    level.semiSolidLayer2 = loadTileLayer(levelPath ~ "/LEVEL_0_SemiSolid_2.csv");
    level.semiSolidLayer3 = loadTileLayer(levelPath ~ "/SemiSolid_3.csv"); // Fallback name
    level.collisionLayer = loadTileLayer(levelPath ~ "/LEVEL_0_Collision.csv");
    level.hazardLayer = loadTileLayer(levelPath ~ "/Hazards.csv"); // Fallback name
    
    // Calculate level dimensions from largest layer
    calculateLevelDimensions(level);
    
    // Load objects
    level.objects = loadLevelObjects(levelPath ~ "/LEVEL_0_Objects_1.csv");
    
    writeln("Loaded level: ", level.levelName, " (", level.width, "x", level.height, ")");
    writeln("  Objects: ", level.objects.length);
    
    return level;
}

// Load level metadata from JSON file
LevelData loadLevelMetadata(string metadataPath) {
    LevelData level;
    
    try {
        string content = readText(metadataPath);
        JSONValue json = parseJSON(content);
        
        if ("levelName" in json) level.levelName = json["levelName"].str;
        if ("tilesetName" in json) level.tilesetName = json["tilesetName"].str;
        if ("timeLimit" in json) level.timeLimit = cast(int)json["timeLimit"].integer;
        
        if ("playerSpawn" in json) {
            auto spawn = json["playerSpawn"];
            level.playerSpawnPoint = Vector2(
                cast(float)spawn["x"].floating,
                cast(float)spawn["y"].floating
            );
        }
        
        if ("backgroundColor" in json) {
            auto bg = json["backgroundColor"];
            level.backgroundColor = Color(
                cast(ubyte)bg["r"].integer,
                cast(ubyte)bg["g"].integer,
                cast(ubyte)bg["b"].integer,
                cast(ubyte)bg["a"].integer
            );
        }
        
    } catch (Exception e) {
        writeln("Warning: Could not parse metadata: ", e.msg);
    }
    
    return level;
}

// Load a single tile layer from CSV with enhanced tile properties
Tile[][] loadTileLayer(string csvPath) {
    if (!exists(csvPath)) {
        writeln("Layer file not found: ", csvPath, " (using empty layer)");
        return [];
    }

    auto csvData = CSVLoader.loadCSVString(csvPath);
    Tile[][] tiles;

    foreach (row; csvData) {
        Tile[] tileRow;
        foreach (cellStr; row) {
            int tileId = to!int(cellStr);
            Tile tile;

            // Handle -1 and 0 as empty tiles
            if (tileId <= 0) {
                tileId = 0;
            } else {
                // Adjust tile ID offset
                tileId += 1;
            }

            tile.tileId = tileId;

            // Set tile properties based on ID ranges or specific values
            if (tileId > 0) {
                if (tileId >= 1 && tileId <= 50) {
                    tile.isSolid = true;
                } else if (tileId >= 51 && tileId <= 100) {
                    tile.isPlatform = true;
                } else if (tileId >= 200 && tileId <= 250) {
                    tile.isHazard = true;
                } else if (tileId >= 100 && tileId <= 150) {
                    tile.isSolid = true;
                    tile.heightProfile = tileId - 100;
                }
            }

            tileRow ~= tile;
        }
        tiles ~= tileRow;
    }

    return tiles;
}

// Load level objects from CSV
LevelObject[] loadLevelObjects(string csvPath) {
    if (!exists(csvPath)) {
        writeln("Objects file not found: ", csvPath);
        return [];
    }

    auto csvData = CSVLoader.loadCSVString(csvPath);
    LevelObject[] objects;

    foreach (row; csvData) {
        if (row.length >= 4) {
            LevelObject obj;
            obj.objectId = to!int(row[0]);
            obj.x = to!float(row[1]);
            obj.y = to!float(row[2]);
            obj.objectType = to!int(row[3]);

            for (int i = 4; i < row.length; i++) {
                obj.properties ~= row[i];
            }

            objects ~= obj;
        }
    }

    writeln("Loaded ", objects.length, " objects");
    return objects;
}

// Calculate level dimensions from all layers
void calculateLevelDimensions(ref LevelData level) {
    int maxWidth = 0;
    int maxHeight = 0;
    
    // Check all layers and find the largest dimensions
    Tile[][][] allLayers = [
        level.groundLayer1, level.groundLayer2, level.groundLayer3,
        level.semiSolidLayer1, level.semiSolidLayer2, level.semiSolidLayer3,
        level.collisionLayer, level.hazardLayer
    ];
    
    foreach (layer; allLayers) {
        if (layer.length > maxHeight) {
            maxHeight = cast(int)layer.length;
        }
        if (layer.length > 0 && layer[0].length > maxWidth) {
            maxWidth = cast(int)layer[0].length;
        }
    }
    
    level.width = maxWidth;
    level.height = maxHeight;
}

// Convenience function for backward compatibility
LevelData loadLevelFromCSV(string csvPath) {
    LevelData level;
    level.groundLayer1 = loadTileLayer(csvPath);
    calculateLevelDimensions(level);
    return level;
}

// Get tile at specific position in a layer
Tile getTileAtPosition(const Tile[][] layer, int x, int y) {
    if (y >= 0 && y < layer.length && x >= 0 && x < layer[y].length) {
        return layer[y][x];
    }
    return Tile(0); // Empty tile
}

// Check if position has solid collision (checks multiple layers)
bool isSolidAtPosition(const LevelData level, float worldX, float worldY, int tileSize = 16) {
    int tileX = cast(int)(worldX / tileSize);
    int tileY = cast(int)(worldY / tileSize);
    
    // Check collision layer first
    if (level.collisionLayer.length > 0) {
        Tile collisionTile = getTileAtPosition(level.collisionLayer, tileX, tileY);
        if (collisionTile.isSolid) return true;
    }
    
    // Check ground layers
    Tile groundTile1 = getTileAtPosition(level.groundLayer1, tileX, tileY);
    if (groundTile1.isSolid) return true;
    
    Tile groundTile2 = getTileAtPosition(level.groundLayer2, tileX, tileY);
    if (groundTile2.isSolid) return true;
    
    Tile groundTile3 = getTileAtPosition(level.groundLayer3, tileX, tileY);
    if (groundTile3.isSolid) return true;
    
    return false;
}

// Helper functions for tile creation

// Create an empty tile with default values
Tile createEmptyTile() {
    Tile tile;
    tile.tileId = 0;
    tile.isSolid = false;
    tile.isPlatform = false;
    tile.isHazard = false;
    tile.heightProfile = 0;
    tile.flipFlags = 0;
    return tile;
}

// Create a tile from a tile ID with appropriate properties
Tile createTileFromId(int tileId) {
    Tile tile;
    
    // Handle -1 and 0 as empty tiles
    if (tileId <= 0) {
        return createEmptyTile();
    }
    
    tile.tileId = tileId;
    
    // Set tile properties based on ID ranges (same logic as CSV loading)
    if (tileId >= 1 && tileId <= 50) {
        tile.isSolid = true;
    } else if (tileId >= 51 && tileId <= 100) {
        tile.isPlatform = true;
    } else if (tileId >= 200 && tileId <= 250) {
        tile.isHazard = true;
    } else if (tileId >= 100 && tileId <= 150) {
        tile.isSolid = true;
        tile.heightProfile = tileId - 100;
    }
    
    return tile;
}

// NEW JSON LOADING FUNCTIONS

// Load a complete level from JSON file (Tiled format)
LevelData loadLevelFromJSON(string jsonPath) {
    LevelData level;
    
    try {
        string jsonContent = readText(jsonPath);
        JSONValue json = parseJSON(jsonContent);
        
        // Get level dimensions
        level.width = cast(int)json["width"].integer;
        level.height = cast(int)json["height"].integer;
        
        writeln("Loading JSON level: ", level.width, "x", level.height);
        
        // Set default metadata
        level.levelName = "JSON Level";
        level.backgroundColor = Color(135, 206, 235, 255); // Sky blue
        level.tilesetName = "default";
        level.playerSpawnPoint = Vector2(100, 100);
        
        // Initialize all layers
        level.groundLayer1 = initializeLayer(level.width, level.height);
        level.groundLayer2 = initializeLayer(level.width, level.height);
        level.groundLayer3 = initializeLayer(level.width, level.height);
        level.semiSolidLayer1 = initializeLayer(level.width, level.height);
        level.semiSolidLayer2 = initializeLayer(level.width, level.height);
        level.semiSolidLayer3 = initializeLayer(level.width, level.height);
        level.collisionLayer = initializeLayer(level.width, level.height);
        level.hazardLayer = initializeLayer(level.width, level.height);
        
        // Process each layer from JSON
        foreach (layerJson; json["layers"].array) {
            string layerName = layerJson["name"].str;
            auto tileData = layerJson["data"].array;
            
            writeln("Processing JSON layer: ", layerName);
            
            // Map layer name to correct layer array
            Tile[][] targetLayer = getLayerByName(level, layerName);
            if (targetLayer !is null) {
                loadJSONTileData(targetLayer, tileData, level.width, level.height);
            }
        }
        
        writeln("JSON level loaded successfully!");
        
    } catch (Exception e) {
        writeln("Error loading JSON level: ", e.msg);
    }
    
    return level;
}

// Helper to get layer reference by name
Tile[][] getLayerByName(ref LevelData level, string layerName) {
    switch (layerName) {
        case "Ground_1_Collision":
            return level.groundLayer1;
        case "Ground_2_Collision":
            return level.groundLayer2;
        case "Ground_3_Collision":
            return level.groundLayer3;
        case "SemiSolids_1_Collision":
            return level.semiSolidLayer1;
        case "SemiSolids_2_Collision":
            return level.semiSolidLayer2;
        case "SemiSolids_3_Collision":
            return level.semiSolidLayer3;
        case "Collision":
            return level.collisionLayer;
        case "Hazard":
            return level.hazardLayer;
        default:
            writeln("Unknown layer name: ", layerName);
            return null;
    }
}

// Initialize empty layer
Tile[][] initializeLayer(int width, int height) {
    Tile[][] layer = new Tile[][](height, width);
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            layer[y][x] = createEmptyTile();
        }
    }
    return layer;
}

// Load tile data from JSON array into layer
void loadJSONTileData(Tile[][] layer, JSONValue[] tileData, int width, int height) {
    for (int i = 0; i < tileData.length && i < width * height; i++) {
        int tileId = cast(int)tileData[i].integer;
        int x = i % width;
        int y = i / width;
        
        if (y < height && x < width) {
            layer[y][x] = createTileFromId(tileId);
        }
    }
}

// Overloaded function to load level with JSON option
LevelData loadCompleteLevel(string levelPath, bool useJson) {

    switch(useJson){
        case false: // CSV
            return loadCompleteLevel(levelPath);
        break;
        case true: // JSON
            string jsonPath = levelPath ~ "/LEVEL_0.json";
            if (exists(jsonPath)) {
                return loadLevelFromJSON(jsonPath);
            } else {
                writeln("JSON file not found: ", jsonPath, ", falling back to CSV");
            }
        break;
        default:
            writeln("Error, Defaulting to CSV");
            // Fall back to original CSV loading
            return loadCompleteLevel(levelPath);
        break;
    }
            // Fall back to original CSV loading
            return loadCompleteLevel(levelPath);
}

// different type of loading function for RVW
LevelData loadCompleteLevel(string levelPath, int lvlID) {    
    import std.file : exists;
    writeln("[RVW] Attempting to load RVW file: ", levelPath, ", index: ", lvlID);
    if (!exists(levelPath)) {
        writeln("[RVW] ERROR: File does not exist: ", levelPath);
        throw new Exception("RVW file not found: " ~ levelPath);
    }
    auto level = LoadRVW(cast(const(char *))levelPath, lvlID); //defaults to 0
    writeln("[RVW] Finished LoadRVW call.");
    // Optionally print some properties to check for nulls or bad data
    writeln("[RVW] Loaded level name: ", level.levelName, ", size: ", level.width, "x", level.height);
    return level;
}

// different type of loading function for RVW
LevelData loadCompleteLevel(int lvlID) {    
    return LoadRVW("levels.rvw", lvlID); //defaults to 0
}