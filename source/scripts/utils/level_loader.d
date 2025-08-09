module utils.level_loader;

import raylib;
import std.stdio;
import std.file;
import std.path;
import std.string;
import std.array;
import std.conv : to;
import std.algorithm;
import std.format;

import utils.csv_loader;
import utils.csv_converter;
import world.level_list;

/**
 * Level Loader for Presto Framework
 * 
 * Handles loading and caching of level data, including tile maps,
 * collision data, object placement, and level metadata.
 */

// Tile types for different layers
enum TileType {
    EMPTY = 0,
    SOLID = 1,
    SEMI_SOLID = 2,
    WATER = 3,
    LAVA = 4,
    WIND = 5,
    ICE = 6,
    SLIPPERY = 7,
    BREAKABLE = 8,
    SPIKES = 9,
    CHECKPOINT = 10,
    GOAL = 11
}

// Object types that can be placed in levels
enum ObjectType {
    NONE = 0,
    RING = 1,
    MONITOR_SPEED = 2,
    MONITOR_JUMP = 3,
    MONITOR_SHIELD_FIRE = 4,
    MONITOR_SHIELD_LIGHTNING = 5,
    MONITOR_SHIELD_WATER = 6,
    MONITOR_INVINCIBILITY = 7,
    MONITOR_EXTRA_LIFE = 8,
    SPRING_YELLOW = 9,
    SPRING_RED = 10,
    SPRING_BLUE = 11,
    ENEMY_MOTOBUG = 12,
    ENEMY_CRABMEAT = 13,
    ENEMY_BUZZER = 14,
    ENEMY_CHOPPER = 15,
    CHECKPOINT_LAMP = 16,
    GOAL_POST = 17
}

// Structure for individual tiles
struct Tile {
    int tileId;
    TileType tileType;
    int angle; // For slopes (in hex angle format)
    bool isSolid;
    bool hasCollision;
    
    this(int id, TileType type = TileType.EMPTY, int tileAngle = 0) {
        tileId = id;
        tileType = type;
        angle = tileAngle;
        isSolid = (type == TileType.SOLID || type == TileType.SEMI_SOLID);
        hasCollision = isSolid;
    }
}

// Structure for objects placed in the level
struct LevelObject {
    ObjectType objectType;
    float x, y;
    int subType; // For variations of the same object type
    bool isActive;
    
    this(ObjectType type, float posX, float posY, int sub = 0) {
        objectType = type;
        x = posX;
        y = posY;
        subType = sub;
        isActive = true;
    }
}

// Complete level data structure
struct LevelData {
    // Level metadata
    string levelName;
    int levelNumber;
    int actNumber;
    int width, height; // In tiles
    
    // Tile layers (multiple layers for complex level geometry)
    Tile[][] groundLayer1;      // Primary solid terrain
    Tile[][] groundLayer2;      // Secondary solid terrain (overlays)
    Tile[][] semiSolidLayer1;   // Jump-through platforms
    Tile[][] semiSolidLayer2;   // Additional platforms
    Tile[][] collisionLayer;    // Pure collision data (simplified)
    
    // Object layer
    LevelObject[] objects;
    
    // Level properties
    Vector2 playerStartPosition;
    Vector2 cameraStartPosition;
    Color backgroundColor;
    string backgroundMusic;
    
    // Physics properties
    float gravity = 56.0f / 256.0f; // Default Sonic gravity
    float waterLevel = -1.0f; // Y position of water surface (-1 = no water)
    bool hasWind = false;
    Vector2 windForce = Vector2(0, 0);
    
    this(string name, int level, int act, int w, int h) {
        levelName = name;
        levelNumber = level;
        actNumber = act;
        width = w;
        height = h;
        
        // Initialize tile layers
        groundLayer1 = new Tile[][](height, width);
        groundLayer2 = new Tile[][](height, width);
        semiSolidLayer1 = new Tile[][](height, width);
        semiSolidLayer2 = new Tile[][](height, width);
        collisionLayer = new Tile[][](height, width);
        
        // Default properties
        playerStartPosition = Vector2(64, 64);
        cameraStartPosition = Vector2(0, 0);
        backgroundColor = Color(135, 206, 235, 255); // Sky blue
        backgroundMusic = "";
    }
}

/**
 * Level Loader Class
 */
class LevelLoader {
    private static LevelLoader _instance;
    private LevelData[string] levelCache; // Cache loaded levels
    private LevelManager levelManager;
    private string baseLevelPath;
    
    private this() {
        levelManager = new LevelManager();
        baseLevelPath = "resources/data/levels/";
    }
    
    static LevelLoader getInstance() {
        if (_instance is null) {
            _instance = new LevelLoader();
        }
        return _instance;
    }

    void LoadRVWIntoCache(const char *fileName, uint position, string levelKey) {
        levelCache[levelKey] = LoadRVW(fileName, position);
    }
    void SayAndTapCache(string levelKey){
        printf(cast(string)levelCache[levelKey].semiSolidLayer1.length);
    }
    /**
     * Load a complete level by number and act
     */
    LevelData loadLevel(LevelNumber levelNum, ActNumber actNum) {
        string levelKey = format("LEVEL_%d_ACT_%d", cast(int)levelNum, cast(int)actNum);
        
        // Check cache first
        if (levelKey in levelCache) {
            writeln("Loading cached level: ", levelKey);
            return levelCache[levelKey];
        }
        
        writeln("Loading new level: ", levelKey);
        
        // Load level metadata
        auto metadata = levelManager.getLevelMetadata(cast(int)levelNum);
        string levelPath = baseLevelPath ~ levelKey ~ "/";
        
        // Initialize level data with temporary size - will be updated when loading tiles
        LevelData level = LevelData(levelKey, cast(int)levelNum, cast(int)actNum, 40, 20); // Initial size
        
        // Load each layer and update level size based on actual data
        loadTileLayer(level.groundLayer1, levelPath ~ levelKey ~ "_Ground_1.csv", TileType.SOLID);
        if (level.groundLayer1.length > 0) {
            level.height = cast(int)level.groundLayer1.length;
            level.width = cast(int)level.groundLayer1[0].length;
        }
        
        loadTileLayer(level.groundLayer2, levelPath ~ levelKey ~ "_Ground_2.csv", TileType.SOLID);
        loadTileLayer(level.semiSolidLayer1, levelPath ~ levelKey ~ "_SemiSolid_1.csv", TileType.SEMI_SOLID);
        loadTileLayer(level.semiSolidLayer2, levelPath ~ levelKey ~ "_SemiSolid_2.csv", TileType.SEMI_SOLID);
        loadTileLayer(level.collisionLayer, levelPath ~ levelKey ~ "_Collision.csv", TileType.SOLID);
        
        // Load objects
        loadObjectLayer(level.objects, levelPath ~ levelKey ~ "_Objects_1.csv");
        
        // Load level properties from metadata file if it exists
        loadLevelProperties(level, levelPath ~ levelKey ~ "_Properties.csv");
        
        // Cache the level
        levelCache[levelKey] = level;
        
        writeln("Successfully loaded level: ", levelKey);
        return level;
    }

    /**
     * Load a tile layer from CSV data
     */
    private void loadTileLayer(ref Tile[][] layer, string csvPath, TileType defaultType) {
        if (!exists(csvPath)) {
            writeln("Tile layer file not found: ", csvPath, " - using empty layer");
            return;
        }
        
        int[][] csvData = CSVLoader.loadCSVInt(csvPath);
        if (csvData.length == 0) {
            writeln("Failed to load tile data from: ", csvPath);
            return;
        }
        
        // Resize layer to match CSV data
        int height = cast(int)csvData.length;
        int width = height > 0 ? cast(int)csvData[0].length : 0;
        layer = new Tile[][](height, width);
        
        // Convert CSV data to tiles
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int tileId = (x < csvData[y].length) ? csvData[y][x] : 0;
                layer[y][x] = Tile(tileId, tileId > 0 ? defaultType : TileType.EMPTY);
            }
        }
        
        writeln("Loaded tile layer: ", csvPath, " (", width, "x", height, ")");
    }
    
    /**
     * Load object layer from CSV data
     */
    private void loadObjectLayer(ref LevelObject[] objects, string csvPath) {
        if (!exists(csvPath)) {
            writeln("Object layer file not found: ", csvPath, " - using empty object list");
            return;
        }
        
        string[][] csvData = CSVLoader.loadCSVString(csvPath);
        if (csvData.length == 0) {
            writeln("Failed to load object data from: ", csvPath);
            return;
        }
        
        objects = [];
        
        // Parse object data (expected format: objectType, x, y, subType)
        foreach (row; csvData) {
            if (row.length >= 4) {
                try {
                    ObjectType objType = cast(ObjectType)row[0].to!int;
                    float x = row[1].to!float * 16.0f; // Convert tile position to pixel position
                    float y = row[2].to!float * 16.0f;
                    int subType = row[3].to!int;
                    
                    objects ~= LevelObject(objType, x, y, subType);
                } catch (Exception e) {
                    writeln("Error parsing object row: ", row, " - ", e.msg);
                }
            }
        }
        
        writeln("Loaded ", objects.length, " objects from: ", csvPath);
    }
    
    /**
     * Load level properties from CSV data
     */
    private void loadLevelProperties(ref LevelData level, string csvPath) {
        if (!exists(csvPath)) {
            writeln("Properties file not found: ", csvPath, " - using defaults");
            return;
        }
        
        string[][] csvData = CSVLoader.loadCSVString(csvPath);
        if (csvData.length == 0) return;
        
        // Parse properties (expected format: property_name, value)
        foreach (row; csvData) {
            if (row.length >= 2) {
                string property = row[0].strip().toLower();
                string value = row[1].strip();
                
                try {
                    switch (property) {
                        case "player_start_x":
                            level.playerStartPosition.x = value.to!float;
                            break;
                        case "player_start_y":
                            level.playerStartPosition.y = value.to!float;
                            break;
                        case "camera_start_x":
                            level.cameraStartPosition.x = value.to!float;
                            break;
                        case "camera_start_y":
                            level.cameraStartPosition.y = value.to!float;
                            break;
                        case "background_music":
                            level.backgroundMusic = value;
                            break;
                        case "water_level":
                            level.waterLevel = value.to!float;
                            break;
                        case "gravity":
                            level.gravity = value.to!float;
                            break;
                        case "wind_x":
                            level.windForce.x = value.to!float;
                            level.hasWind = true;
                            break;
                        case "wind_y":
                            level.windForce.y = value.to!float;
                            level.hasWind = true;
                            break;
                        default:
                            break;
                    }
                } catch (Exception e) {
                    writeln("Error parsing property: ", property, " = ", value, " - ", e.msg);
                }
            }
        }
        
        writeln("Loaded level properties from: ", csvPath);
    }
    
    /**
     * Get tile at specific position (world coordinates)
     */
    Tile getTileAtPosition(const ref LevelData level, float worldX, float worldY, int layerIndex = 0) {
        int tileX = cast(int)(worldX / 16.0f); // Assuming 16x16 tiles
        int tileY = cast(int)(worldY / 16.0f);
        
        return getTileAtTilePosition(level, tileX, tileY, layerIndex);
    }
    
    /**
     * Get tile at specific tile coordinates
     */
    Tile getTileAtTilePosition(const ref LevelData level, int tileX, int tileY, int layerIndex = 0) {
        // Bounds check
        if (tileX < 0 || tileY < 0) return Tile(0);
        
        Tile[][] targetLayer;
        
        switch (layerIndex) {
            case 0: targetLayer = cast(Tile[][])level.groundLayer1; break;
            case 1: targetLayer = cast(Tile[][])level.groundLayer2; break;
            case 2: targetLayer = cast(Tile[][])level.semiSolidLayer1; break;
            case 3: targetLayer = cast(Tile[][])level.semiSolidLayer2; break;
            case 4: targetLayer = cast(Tile[][])level.collisionLayer; break;
            default: return Tile(0);
        }
        
        if (tileY >= targetLayer.length || tileX >= targetLayer[0].length) {
            return Tile(0);
        }
        
        return targetLayer[tileY][tileX];
    }
    
    /**
     * Check if position has solid collision
     */
    bool isSolidAtPosition(const ref LevelData level, float worldX, float worldY) {
        // Check all solid layers
        for (int layer = 0; layer <= 1; layer++) { // Ground layers
            Tile tile = getTileAtPosition(level, worldX, worldY, layer);
            if (tile.isSolid) return true;
        }
        return false;
    }
    
    /**
     * Get all objects within a specific area
     */
    LevelObject[] getObjectsInArea(const ref LevelData level, float x, float y, float width, float height) {
        LevelObject[] result;
        
        foreach (obj; level.objects) {
            if (obj.isActive && 
                obj.x >= x && obj.x <= x + width &&
                obj.y >= y && obj.y <= y + height) {
                result ~= obj;
            }
        }
        
        return result;
    }
    
    /**
     * Unload cached level data
     */
    void unloadLevel(string levelKey) {
        if (levelKey in levelCache) {
            levelCache.remove(levelKey);
            writeln("Unloaded level from cache: ", levelKey);
        }
    }
    
    /**
     * Clear all cached levels
     */
    void clearCache() {
        levelCache = null;
        writeln("Cleared all cached levels");
    }
    
    /**
     * Get memory usage statistics
     */
    string getCacheStats() {
        import std.format : format;
        return format("Level Cache: %d levels loaded", levelCache.length);
    }
}