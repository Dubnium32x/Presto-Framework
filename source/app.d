import raylib;

import screen_manager;
import screen_settings;
import screen_states;
import player.player;
import player.var;
import world.level; 
import world.tileset_manager;
import world.level_list;

import std.stdio : writeln;
import std.string;
import std.file;
import std.algorithm;
import std.format;
import std.conv;
import std.math;

// Global flag for debug visualization (accessible to other modules)
__gshared bool debugVisualizationEnabled = true;

// Add a toString function for PlayerState enum to support UI
string toString(PlayerState state) {
    switch(state) {
        case PlayerState.IDLE: return "IDLE";
        case PlayerState.RUNNING: return "RUNNING";
        case PlayerState.JUMPING: return "JUMPING";
        case PlayerState.FALLING: return "FALLING";
        case PlayerState.FALLING_ROLL: return "FALLING_ROLL";
        case PlayerState.SHIELD_ACTION: return "SHIELD_ACTION";
        case PlayerState.WALK: return "WALK";
        case PlayerState.RUN: return "RUN";
        case PlayerState.DASHING: return "DASHING";
        case PlayerState.SPINDASHING: return "SPINDASHING";
        case PlayerState.PEELING: return "PEELING";
        case PlayerState.ROLLING: return "ROLLING";
        case PlayerState.HOVERING: return "HOVERING";
        case PlayerState.CLIMBING: return "CLIMBING";
        case PlayerState.GLIDING: return "GLIDING";
        case PlayerState.HURT: return "HURT";
        case PlayerState.DEAD: return "DEAD";
        default: return "UNKNOWN";
    }
}

// Helper function for linear interpolation
float Lerp(float start, float end, float amount) {
    return start + (end - start) * amount;
}

// Helper function to clamp a value between min and max
float Clamp(float value, float min, float max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

// initialize the screen
ScreenSettings screenSettings;
ScreenManager screenManager;

// Player instance
Player playerInstance;

// Physics test mode - simple platforms for testing physics
Rectangle[] testPlatforms;
Camera2D camera;
bool physicsTestMode = true;

// Managers for CSV-based levels
TilesetManager tilesetManager;
LevelManager levelManager;
bool useCsvLevel = true; // Default to true to load CSV level on start for testing

// Array to store collision rectangles generated from CSV level
Rectangle[] csvPlatforms;

void main() {
    InitWindow(400, 224, "Presto Framework - Sonic Physics Demo");
    screenSettings = new ScreenSettings(400, 224, 400, 224);
    SetTargetFPS(60);
    
    // Initialize TilesetManager first as it's a dependency for LevelManager and ScreenManager
    tilesetManager = new TilesetManager(16, 16); 

    // Initialize LevelManager, it needs TilesetManager
    levelManager = new LevelManager(tilesetManager);

    // Initialize ScreenManager singleton instance or get existing one
    // ScreenManager.getInstance() will handle creating it with a null TilesetManager if it's the first call.
    // We then explicitly set the correct TilesetManager.
    screenManager = ScreenManager.getInstance(); 
    screenManager.setScreenSettings(screenSettings); // Set/update screen settings
    screenManager.setTilesetManager(tilesetManager); // Explicitly set the TilesetManager
    
    if (physicsTestMode) {
        initializePhysicsTest(); // Initializes player instance and sets its LevelManager
        
        if (useCsvLevel) {
            levelManager.loadLevel(LevelList.LEVEL_0, ActNumber.ACT_1); // Load default level
            Level currentLevelInfo = levelManager.getCurrentLevelInfo();
            
            // Set player start position from level AFTER player instance exists
            if (playerInstance !is null && (currentLevelInfo.playerStartPosition.x != -1 || currentLevelInfo.playerStartPosition.y != -1)) {
                Var.x = currentLevelInfo.playerStartPosition.x;
                Var.y = currentLevelInfo.playerStartPosition.y - Var.heightrad; // Adjust for center
                writeln("Initial player position set from level: ", Var.x, ", ", Var.y);
            }

            if (currentLevelInfo.layerNames.length > 0 && levelManager.layerTileData.length > 0) {
                size_t collisionLayerIdx = currentLevelInfo.layerNames.countUntil("Ground_1");
                if (collisionLayerIdx != -1 && cast(size_t)collisionLayerIdx < levelManager.layerTileData.length) {
                     csvPlatforms = generateCollisionRectangles(
                                        levelManager.layerTileData[collisionLayerIdx], 
                                        currentLevelInfo.tileWidthPx, 
                                        currentLevelInfo.tileHeightPx
                                    );
                } else {
                    writeln("Collision layer 'Ground_1' not found or data missing for initial load.");
                    csvPlatforms = [];
                }
            }
        }
    } else {
        screenManager.currentScreenState = ScreenState.GAME; // Set state before initializing
        screenManager.initialize(); 
        // If player is part of a screen managed by ScreenManager, it should be created there.
    }

    writeln("Starting main loop...");
    while (!WindowShouldClose()) {
        if (physicsTestMode) {
            if (IsKeyPressed(KeyboardKey.KEY_L)) {
                useCsvLevel = !useCsvLevel;
                writeln("Toggled CSV Level. Now: ", useCsvLevel);
                if (useCsvLevel) {
                    levelManager.loadLevel(LevelList.LEVEL_0, ActNumber.ACT_1); // Reload or load level
                    Level currentLevelInfo = levelManager.getCurrentLevelInfo();
                    
                    if (currentLevelInfo.layerNames.length > 0 && levelManager.layerTileData.length > 0) {
                        size_t collisionLayerIdx = currentLevelInfo.layerNames.countUntil("Ground_1");
                        if (collisionLayerIdx != -1 && cast(size_t)collisionLayerIdx < levelManager.layerTileData.length) {
                             csvPlatforms = generateCollisionRectangles(
                                                levelManager.layerTileData[collisionLayerIdx], 
                                                currentLevelInfo.tileWidthPx, 
                                                currentLevelInfo.tileHeightPx
                                            );
                             writeln("Generated ", csvPlatforms.length, " collision rectangles for Ground_1.");
                        } else {
                            writeln("Collision layer 'Ground_1' not found or data missing on toggle.");
                            csvPlatforms = [];
                        }
                    } else {
                         writeln("No layers loaded, cannot generate collision rectangles.");
                         csvPlatforms = [];
                    }

                    if (currentLevelInfo.playerStartPosition.x > 0 || currentLevelInfo.playerStartPosition.y > 0) {
                        Var.x = currentLevelInfo.playerStartPosition.x;
                        Var.y = currentLevelInfo.playerStartPosition.y - Var.heightrad; // Adjust for center
                        writeln("Player position set from level: ", Var.x, ", ", Var.y);
                    }
                }
            }
            
            updatePhysicsTest();
            drawPhysicsTest();
        } else {
            screenManager.update();
            screenManager.draw();
        }
    }

    if (physicsTestMode && playerInstance !is null) {
        destroy(playerInstance);
    }
    if (tilesetManager !is null) { // Unload tilesets
        tilesetManager.unloadAllTilesets();
    }

    writeln("Closing window...");
    CloseWindow();
}

void initializePhysicsTest() {
    playerInstance = new Player();
    // Set LevelManager for the player instance immediately after creation
    if (levelManager !is null) {
        playerInstance.setLevelManager(levelManager);
        writeln("LevelManager set for playerInstance in initializePhysicsTest.");
    } else {
        writeln("Error: levelManager is null when trying to set it for playerInstance in initializePhysicsTest.");
    }

    Var.x = 100; // Default start position if not overridden by level
    Var.y = 100;
    
    testPlatforms ~= Rectangle(0, 300, 800, 100);
    testPlatforms ~= Rectangle(200, 200, 150, 20);
    testPlatforms ~= Rectangle(400, 150, 200, 20);
    testPlatforms ~= Rectangle(100, 250, 80, 20);
    testPlatforms ~= Rectangle(600, 300, 150, 20);
    testPlatforms ~= Rectangle(800, 280, 150, 20);
    testPlatforms ~= Rectangle(1000, 310, 100, 20);
    testPlatforms ~= Rectangle(1150, 290, 100, 20);
    testPlatforms ~= Rectangle(1300, 300, 70, 20);
    testPlatforms ~= Rectangle(1370, 280, 70, 20);
    testPlatforms ~= Rectangle(1440, 260, 70, 20);
    testPlatforms ~= Rectangle(1550, 300, 50, 20);
    testPlatforms ~= Rectangle(1600, 280, 50, 20); 
    testPlatforms ~= Rectangle(1650, 250, 50, 20);
    testPlatforms ~= Rectangle(1700, 280, 50, 20);
    testPlatforms ~= Rectangle(1750, 300, 50, 20);
    
    camera.target = Vector2(Var.x, Var.y);
    camera.offset = Vector2(screenSettings.virtualWidth / 2.0f, screenSettings.virtualHeight / 2.0f);
    camera.rotation = 0.0f;
    camera.zoom = 1.0f;
    
    // Removed levelManager initialization from here, it's done in main
    writeln("Physics test environment initialized (player and test platforms)");
}

void updatePhysicsTest() {    
    playerInstance.update(GetFrameTime());
    
    if (IsKeyPressed(KeyboardKey.KEY_R)) {
        // Default reset position
        float resetX = 100;
        float resetY = 100;

        // If CSV level is active, reset to its start position
        if (useCsvLevel && levelManager !is null) {
            Level currentLevelInfo = levelManager.getCurrentLevelInfo();
            if (currentLevelInfo.playerStartPosition.x != -1 || currentLevelInfo.playerStartPosition.y != -1) {
                resetX = currentLevelInfo.playerStartPosition.x;
                resetY = currentLevelInfo.playerStartPosition.y - Var.heightrad;
            }
        }
        Var.x = resetX;
        Var.y = resetY;
        Var.xspeed = 0; 
        Var.yspeed = 0; 
        Var.groundspeed = 0;
        // if (playerInstance !is null) playerInstance.resetState(); // Removed as resetState() does not exist
    }
    
    if (IsKeyPressed(KeyboardKey.KEY_EQUAL) || IsKeyPressed(KeyboardKey.KEY_KP_ADD)) camera.zoom += 0.1f;
    if (IsKeyPressed(KeyboardKey.KEY_MINUS) || IsKeyPressed(KeyboardKey.KEY_KP_SUBTRACT)) camera.zoom = max(0.1f, camera.zoom - 0.1f);
    
    if (IsKeyPressed(KeyboardKey.KEY_TAB)) {
        debugVisualizationEnabled = !debugVisualizationEnabled;
        writeln("Debug visualization: ", debugVisualizationEnabled ? "ENABLED" : "DISABLED");
    }
    
    // levelManager.update() removed as it doesn't exist / isn't needed for static levels
    
    camera.target = Vector2(Var.x, Var.y);
}

void drawPhysicsTest() {
    BeginDrawing();
    ClearBackground(Color(40, 40, 80, 255));
    BeginMode2D(camera);
    
    if (useCsvLevel && levelManager !is null) {
        levelManager.draw(); // Draw all layers from LevelManager

        // Optionally, draw collision rectangles for debugging
        if (debugVisualizationEnabled) {
            foreach (Rectangle platform; csvPlatforms) {
                DrawRectangleLinesEx(platform, 1, Colors.LIME); // Bright green outline for CSV collision boxes
            }
        }
        
        Level currentLevelInfo = levelManager.getCurrentLevelInfo();
        if (currentLevelInfo.playerStartPosition.x > 0 || currentLevelInfo.playerStartPosition.y > 0) {
             if (debugVisualizationEnabled) DrawCircleV(currentLevelInfo.playerStartPosition, 5, Colors.RED);
        }
    } else {
        foreach (size_t i, platform; testPlatforms) {
            Color platformColor;
            if (i == 0) platformColor = Color(0, 100, 0, 255);
            else if (i == 4) platformColor = Color(128, 0, 128, 255);
            else if (i == 5) platformColor = Color(0, 0, 255, 255);
            else if (i >= 6) platformColor = Color(255, 140, 0, 255);
            else platformColor = Color(100, 100, 100, 255);
            DrawRectangleRec(platform, platformColor);
            if (debugVisualizationEnabled) DrawText(TextFormat("%d", i), cast(int)platform.x + 5, cast(int)platform.y + 5, 10, Colors.WHITE);
        }
    }
    
    playerInstance.draw();
    EndMode2D();
    
    Color whiteColor = Colors.WHITE;
    Color redColor = Colors.RED;
    Color greenColor = Colors.GREEN;
    Color jumpStateColor = Colors.YELLOW;
    
    DrawText(TextFormat("SPEED: %.1f, %.1f", Var.xspeed, Var.yspeed), 5, 5, 12, whiteColor);
    DrawText(TextFormat("GROUNDED: %d", Var.grounded ? 1 : 0), 5, 20, 12, Var.grounded ? greenColor : redColor);
    DrawText(TextFormat("POS: %.0f, %.0f", Var.x, Var.y), 5, 35, 12, whiteColor);
    
    string levelModeText = useCsvLevel ? "MODE: CSV LEVEL (L to toggle)" : "MODE: TEST PLATFORMS (L to toggle)";
    DrawText(levelModeText.toStringz(), 5, 50, 10, useCsvLevel ? greenColor : whiteColor);
    
    if (useCsvLevel && levelManager !is null) {
        Level currentLevelInfo = levelManager.getCurrentLevelInfo();
        string levelNameText = currentLevelInfo.levelName ? currentLevelInfo.levelName : "N/A";
        // string levelInfoText = format("Level: %s (%s)", levelNameText, currentLevelInfo.basePath); // Error: no basePath
        string levelInfoText = format("Level: %s (Folder: %s)", levelNameText, currentLevelInfo.levelName); // Using levelName again as placeholder for path info
        DrawText(levelInfoText.toStringz(), 5, 65, 10, whiteColor);
        
        string layersLoadedText = format("Layers: %d [%s]", currentLevelInfo.layerNames.length, currentLevelInfo.layerNames.join(", "));
        DrawText(layersLoadedText.toStringz(), 5, 80, 10, whiteColor);
        
        string cameraText = format("Camera: (%.0f, %.0f) Zoom: %.1f", camera.target.x, camera.target.y, camera.zoom);
        DrawText(cameraText.toStringz(), 5, 95, 10, whiteColor);
        
        string collisionText = format("Coll.Rects: %d (Ground_1)", csvPlatforms.length);
        DrawText(collisionText.toStringz(), 5, 110, 10, whiteColor);
    }
    
    // Display key states at bottom right
    bool zKeyPressed = IsKeyDown(KeyboardKey.KEY_Z);
    bool leftPressed = IsKeyDown(KeyboardKey.KEY_LEFT);
    bool rightPressed = IsKeyDown(KeyboardKey.KEY_RIGHT);
    
    // Draw key indicators in the bottom right corner
    DrawRectangle(screenSettings.virtualWidth - 50, screenSettings.virtualHeight - 20, 10, 10, 
                  leftPressed ? greenColor : redColor);
    DrawText("L", screenSettings.virtualWidth - 48, screenSettings.virtualHeight - 20, 10, whiteColor);
    
    DrawRectangle(screenSettings.virtualWidth - 35, screenSettings.virtualHeight - 20, 10, 10, 
                  rightPressed ? greenColor : redColor);
    DrawText("R", screenSettings.virtualWidth - 33, screenSettings.virtualHeight - 20, 10, whiteColor);
    
    DrawRectangle(screenSettings.virtualWidth - 20, screenSettings.virtualHeight - 20, 10, 10, 
                  zKeyPressed ? greenColor : redColor);
    DrawText("Z", screenSettings.virtualWidth - 18, screenSettings.virtualHeight - 20, 10, whiteColor);
    
    // Show current speed 
    string speedText = format("Speed: %.1f", abs(Var.xspeed));
    DrawText(speedText.toStringz(), screenSettings.virtualWidth / 2 - 30, screenSettings.virtualHeight - 30, 20, whiteColor);
    
    // Instructions - simplified and moved to bottom
    DrawText("L: Toggle Level | +/-: Zoom | TAB: Debug Vis", 
        5, screenSettings.virtualHeight - 30, 10, jumpStateColor);
    DrawText("ARROWS: Move | DOWN: Roll | Z: Jump | R: Reset", 
        5, screenSettings.virtualHeight - 15, 10, jumpStateColor);
    
    EndDrawing();
}

// Convert a specific tile layer data to collision rectangles
Rectangle[] generateCollisionRectangles(int[][] layerData, int tileWidth, int tileHeight) {
    Rectangle[] rects;
    if (layerData is null) return rects; // Return empty if layerData is null

    // Constants for Tiled flags
    const uint FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
    const uint FLIPPED_VERTICALLY_FLAG   = 0x40000000;

    for (int y = 0; y < layerData.length; y++) {
        if (layerData[y] is null) continue; // Skip if row is null
        for (int x = 0; x < layerData[y].length; x++) {
            int rawTileId = layerData[y][x];

            if (rawTileId == -1) { // Explicitly check for -1 first
                continue; // Skip empty tiles
            }
            
            // Clear the flags to get the actual tile ID (GID)
            // This actualTileId is used if you have other non-empty, non-collidable tiles
            // that are not -1. For basic solid/empty, the rawTileId == -1 check is sufficient.
            int actualTileId = cast(int)(rawTileId & ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG));

            // For generating collision rects, if it wasn't -1 initially, 
            // we assume it's collidable for now after stripping flags.
            // If you have specific non-collidable positive tile IDs, you'd check actualTileId against them here.
            rects ~= Rectangle(
                cast(float)x * tileWidth,
                cast(float)y * tileHeight,
                cast(float)tileWidth,
                cast(float)tileHeight
            );
        }
    }
    return rects;
}