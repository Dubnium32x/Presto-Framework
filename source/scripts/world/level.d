module world.level;

import std.stdio;
import std.string;
import std.file;
import std.algorithm;
import std.conv;
import std.array; // For Appender and .array()
import std.path : buildPath;

import parser.csv_tile_loader; // Assuming module name in csv_tile_loader.d is parser.csv_tile_loader
import world.level_list;

import world.tileset_manager; // Import the new TilesetManager
import screen_manager; // For IScreen interface

import raylib;

struct Level {
    LevelList levelList;
    ActNumber actNumber;
    string levelName;
    string[] layerNames;     // e.g., ["Ground_1", "SemiSolid_1", "Objects_1", ...]
    string[] layerFilePaths; // Full paths to the CSV files
    Vector2 playerStartPosition; // Added player start position
    int tileWidthPx;         // Tile width in pixels (e.g., 16)
    int tileHeightPx;        // Tile height in pixels (e.g., 16)
    int levelWidthTiles;     // Level width in number of tiles
    int levelHeightTiles;    // Level height in number of tiles

    // Constructor might need adjustment based on how LevelManager populates it.
    this(string name, LevelList ll, ActNumber an, string[] layerNames, string[] layerFiles, 
         int tw, int th, int width, int height, Vector2 playerStart) { // Added playerStart
        this.levelName = name;
        this.levelList = ll;
        this.actNumber = an;
        this.layerNames = layerNames;
        this.layerFilePaths = layerFiles;
        this.tileWidthPx = tw;
        this.tileHeightPx = th;
        this.levelWidthTiles = width;
        this.levelHeightTiles = height;
        this.playerStartPosition = playerStart; // Initialize playerStart
    }
}

class LevelManager : IScreen { // Implement IScreen
    private TilesetManager tilesetManager;
    private Level currentLevel;
    /* private */ int[][][] layerTileData; 
    private Vector2 levelPlayerStartPosition = Vector2(-1, -1); // Store the first valid player start found

    // Define the expected order and base names of layers
    private static const string[] LAYER_TYPE_SEQUENCE = [
        "Ground", "SemiSolid", "Objects" 
    ];
    private static const int NUM_REPEATING_LAYER_PARTS = 5;
    private static const string HAZARDS_LAYER_NAME = "Hazards"; 

    private static const string LEVEL_DATA_BASE_PATH = "resources/data/levels/";

    // --- Tileset Mapping ---
    private static const string TILESET_NAME_GROUND = "ground_tiles";
    private static const string TILESET_NAME_SEMISOLID = "semisolid_tiles";
    private static const string TILESET_NAME_OBJECTS = "object_tiles";
    private static const string TILESET_NAME_HAZARDS = "hazard_tiles";

    // TODO: User needs to confirm/provide actual filenames for Objects and Hazards.
    public static const string TILESET_PATH_GROUND = "resources/image/tilemap/SPGSolidTileHeightCollision.png";
    public static const string TILESET_PATH_SEMISOLID = "resources/image/tilemap/SPGSolidTileHeightSemiSolids.png";
    public static const string TILESET_PATH_OBJECTS = "resources/image/tilemap/PLACEHOLDER_OBJECTS.png"; 
    public static const string TILESET_PATH_HAZARDS = "resources/image/tilemap/PLACEHOLDER_HAZARDS.png";

    this(TilesetManager tm) {
        this.tilesetManager = tm;
        this.tilesetManager.loadTileset(TILESET_NAME_GROUND, TILESET_PATH_GROUND);
        this.tilesetManager.loadTileset(TILESET_NAME_SEMISOLID, TILESET_PATH_SEMISOLID);
        this.tilesetManager.loadTileset(TILESET_NAME_OBJECTS, TILESET_PATH_OBJECTS); 
        this.tilesetManager.loadTileset(TILESET_NAME_HAZARDS, TILESET_PATH_HAZARDS); 

        writeln("LevelManager initialized.");
    }

    string getTilesetNameForLayer(string layerNameWithPart) {
        if (layerNameWithPart.startsWith("Ground")) return TILESET_NAME_GROUND;
        if (layerNameWithPart.startsWith("SemiSolid")) return TILESET_NAME_SEMISOLID;
        if (layerNameWithPart.startsWith("Objects")) return TILESET_NAME_OBJECTS;
        if (layerNameWithPart == HAZARDS_LAYER_NAME) return TILESET_NAME_HAZARDS;
        
        stderr.writeln("LevelManager Error: Unknown layer name prefix for tileset mapping: ", layerNameWithPart);
        return ""; 
    }

    void loadLevel(LevelList levelEnum, ActNumber actNum) {
        string levelFolderName = levelEnum.to!string; 

        // Use dynamic arrays directly instead of Appenders
        string[] collectedLayerNames;
        string[] collectedLayerFilePaths;
        
        this.layerTileData = null; 

        int levelW = -1, levelH = -1;
        int tileW = 16, tileH = 16; 
        this.levelPlayerStartPosition = Vector2(-1, -1); // Reset for new level load

        foreach (string layerBaseName; LAYER_TYPE_SEQUENCE) {
            for (int i = 1; i <= NUM_REPEATING_LAYER_PARTS; i++) {
                string layerFullName = layerBaseName ~ "_" ~ i.to!string; 
                string csvFileName = levelFolderName ~ "_" ~ layerFullName ~ ".csv"; 
                string csvFilePath = buildPath(LEVEL_DATA_BASE_PATH, levelFolderName, csvFileName);

                if (std.file.exists(csvFilePath)) {
                    writeln("LevelManager: Found layer file: ", csvFilePath);
                    // Append directly to string arrays
                    collectedLayerNames ~= layerFullName;
                    collectedLayerFilePaths ~= csvFilePath;
                    
                    try {
                        LevelLoadResult csvResult = parser.csv_tile_loader.loadCSVLayer(csvFilePath, layerFullName, tileW, tileH, 0);
                        this.layerTileData ~= csvResult.layer.data; 
                        
                        if (this.levelPlayerStartPosition.x == -1 && csvResult.playerStartPosition.x != -1) {
                            this.levelPlayerStartPosition = csvResult.playerStartPosition;
                            writeln("LevelManager: Player start position set from layer '", layerFullName, "' to: ", this.levelPlayerStartPosition);
                        }

                        if (levelW == -1 && levelH == -1) { 
                            if (csvResult.layer.data.length > 0 && csvResult.layer.data[0].length > 0) {
                                levelW = cast(int)csvResult.layer.data[0].length; // Width from columns
                                levelH = cast(int)csvResult.layer.data.length;    // Height from rows
                            } else {
                                levelW = 0; levelH = 0;
                            }
                        } else { 
                            int currentLayerW = 0, currentLayerH = 0;
                            if (csvResult.layer.data.length > 0 && csvResult.layer.data[0].length > 0) {
                                currentLayerW = cast(int)csvResult.layer.data[0].length;
                                currentLayerH = cast(int)csvResult.layer.data.length;
                            }
                            if (currentLayerW != levelW || currentLayerH != levelH) {
                                stderr.writeln("LevelManager Warning: Layer '", layerFullName, "' dimensions (", currentLayerW, "x", currentLayerH, ") mismatch with previous layers (", levelW, "x", levelH, ").");
                            }
                        }
                    } catch (Exception e) {
                        stderr.writeln("LevelManager Error: Failed to load or parse CSV '", csvFilePath, "': ", e.msg);
                    }
                } else {
                    // writeln("LevelManager: Optional layer file not found: ", csvFilePath);
                }
            }
        }

        string hazardsCsvFileName = levelFolderName ~ "_" ~ HAZARDS_LAYER_NAME ~ ".csv"; 
        string hazardsCsvFilePath = buildPath(LEVEL_DATA_BASE_PATH, levelFolderName, hazardsCsvFileName);

        if (std.file.exists(hazardsCsvFilePath)) {
            writeln("LevelManager: Found layer file: ", hazardsCsvFilePath);
            // Append directly to string arrays
            collectedLayerNames ~= HAZARDS_LAYER_NAME;
            collectedLayerFilePaths ~= hazardsCsvFilePath;
            try {
                LevelLoadResult csvResult = parser.csv_tile_loader.loadCSVLayer(hazardsCsvFilePath, HAZARDS_LAYER_NAME, tileW, tileH, 0);
                this.layerTileData ~= csvResult.layer.data;

                if (this.levelPlayerStartPosition.x == -1 && csvResult.playerStartPosition.x != -1) {
                    this.levelPlayerStartPosition = csvResult.playerStartPosition;
                     writeln("LevelManager: Player start position set from layer '", HAZARDS_LAYER_NAME, "' to: ", this.levelPlayerStartPosition);
                }

                int currentLayerW = 0, currentLayerH = 0;
                if (csvResult.layer.data.length > 0 && csvResult.layer.data[0].length > 0) {
                    currentLayerW = cast(int)csvResult.layer.data[0].length;
                    currentLayerH = cast(int)csvResult.layer.data.length;
                }

                if (levelW == -1 && levelH == -1) { 
                    levelW = currentLayerW;
                    levelH = currentLayerH;
                } else if (currentLayerW != levelW || currentLayerH != levelH) {
                     stderr.writeln("LevelManager Warning: Layer '", HAZARDS_LAYER_NAME, "' dimensions (", currentLayerW, "x", currentLayerH, ") mismatch with previous layers (", levelW, "x", levelH, ").");
                }
            } catch (Exception e) {
                stderr.writeln("LevelManager Error: Failed to load or parse CSV '", hazardsCsvFilePath, "': ", e.msg);
            }
        } else {
            writeln("LevelManager: Hazards layer file not found: ", hazardsCsvFilePath);
        }
        
        if (levelW == -1) levelW = 0; 
        if (levelH == -1) levelH = 0;

        // No longer need to convert from Appenders here

        this.currentLevel = Level(
            levelFolderName,
            levelEnum,
            actNum,
            collectedLayerNames.dup, // Pass duplicates to the Level struct
            collectedLayerFilePaths.dup, // Pass duplicates to the Level struct
            tileW, tileH,
            levelW, levelH,
            this.levelPlayerStartPosition
        );
        
        writeln("LevelManager: Loaded level '", levelFolderName, "' with ", this.layerTileData.length, " layers. Dimensions: ", levelW, "x", levelH, " tiles.");
    }

    // IScreen implementation
    void initialize() {
        // Load a default level, or ensure one is loaded.
        // For now, let's load LEVEL_0, ACT_1 if no level is current,
        // or if this is the intended initialization point for a screen.
        writeln("LevelManager (IScreen) initialize called.");
        if (this.currentLevel.levelName is null || this.currentLevel.levelName.empty) {
             writeln("No current level, loading default LEVEL_0, ACT_1.");
            loadLevel(LevelList.LEVEL_0, ActNumber.ACT_1);
        } else {
            writeln("Level '", this.currentLevel.levelName, "' already loaded or set.");
        }
    }

    // IScreen implementation
    void update() {
        // Placeholder for level-specific update logic (e.g., moving platforms, animations)
        // Currently, player update is handled in app.d's physicsTestMode or would be part of a gameplay screen.
    }

    void draw() {
        if (this.layerTileData is null || this.layerTileData.length == 0) {
            return;
        }

        foreach (layerIdx, int[][] singleLayerData; this.layerTileData) {
            if (singleLayerData is null || singleLayerData.length == 0) continue;

            string currentLayerName = this.currentLevel.layerNames[layerIdx]; 
            string tilesetToUse = getTilesetNameForLayer(currentLayerName);

            if (tilesetToUse.empty) {
                continue; 
            }

            for (int y = 0; y < currentLevel.levelHeightTiles; y++) {
                if (y >= singleLayerData.length) break; 
                int[] row = singleLayerData[y];
                for (int x = 0; x < currentLevel.levelWidthTiles; x++) {
                    if (x >= row.length) break; 
                    
                    int rawTileId = row[x];
                    if (rawTileId == -1) continue; // Skip empty tiles

                    // Constants for Tiled flags (from Tiled documentation)
                    const uint FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
                    const uint FLIPPED_VERTICALLY_FLAG   = 0x40000000;
                    // const uint FLIPPED_DIAGONALLY_FLAG = 0x20000000; // Not used here

                    bool flipHorizontal = (rawTileId & FLIPPED_HORIZONTALLY_FLAG) != 0;
                    bool flipVertical = (rawTileId & FLIPPED_VERTICALLY_FLAG) != 0;
                    // bool flipDiagonal = (rawTileId & FLIPPED_DIAGONALLY_FLAG) != 0; // Not used here

                    // Clear the flags to get the actual tile ID (GID)
                    int actualTileId = cast(int)(rawTileId & ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG /* | FLIPPED_DIAGONALLY_FLAG */));

                    Vector2 position;
                    position.x = cast(float)(x * currentLevel.tileWidthPx);
                    position.y = cast(float)(y * currentLevel.tileHeightPx);
                    
                    // Pass flip flags to drawTile
                    tilesetManager.drawTile(tilesetToUse, actualTileId, position.x, position.y, flipHorizontal, flipVertical);
                }
            }
        }
    }
    
    Level getCurrentLevelInfo() {
        return this.currentLevel;
    }
}