module screens.level_test_screen;

import raylib;
import std.stdio;
import std.string : toStringz;
import std.conv : to;
import std.format : format;
import std.math : abs;
import std.file;

import world.screen_state;
import world.screen_manager;
import world.input_manager;
import utils.level_loader;
import entity.entity_manager;

class LevelTestScreen : IScreen {
    private static LevelTestScreen _instance;
    private LevelData currentLevel;
    private bool levelLoaded = false;
    private bool initialized = false;
    
    // Camera and rendering
    private Camera2D camera;
    private Vector2 cameraTarget;
    private float cameraSpeed = 300.0f;
    private float zoomSpeed = 0.1f;
    
    // Tile rendering
    private int tileSize = 16;
    private float renderScale = 2.0f; // Scale factor for rendering tiles
    private Texture2D[string] tilesets; // Multiple tilesets for different layers
    private bool tilesetsLoaded = false;
    
    // Layer visibility toggles
    private bool showGroundLayer1 = true;
    private bool showGroundLayer2 = true;
    private bool showGroundLayer3 = true;
    private bool showSemiSolid1 = true;
    private bool showSemiSolid2 = true;
    private bool showSemiSolid3 = true;
    private bool showCollisionLayer = false;
    private bool showHazardLayer = true;
    private bool showObjects = true;
    private bool showGrid = false;
    private bool showDebugInfo = true;
    
    // Current level selection
    private string[] availableLevels;
    private int currentLevelIndex = 0;
    //private bool useJSONLoading = false; // Toggle between CSV and JSON loading
    private int levelLoadingType = 0; // 0 = CSV, 1 = JSON, 2 = RVW

    // Entity management
    private EntityManager entityManager;
    
    static LevelTestScreen getInstance() {
        if (_instance is null) {
            _instance = new LevelTestScreen();
        }
        return _instance;
    }

    void initialize() {
        if (initialized) return;
        writeln("LevelTestScreen initialized");
        
        // Initialize entity manager
        entityManager = EntityManager.getInstance();
        
        // Initialize camera
        camera.target = Vector2(0, 0);
        camera.offset = Vector2(GetScreenWidth() / 2.0f, GetScreenHeight() / 2.0f);
        camera.rotation = 0.0f;
        camera.zoom = 1.0f;
        cameraTarget = camera.target;
        
        // Load tilesets for different layers
        loadTilesets();
        
        // Scan for available levels
        scanForLevels();
        
        // Load first available level
        if (availableLevels.length > 0) {
            loadLevel(availableLevels[0]);
        } else {
            // Create a simple test level if no levels found
            createTestLevel();
        }
        
        initialized = true;
    }
    
    void scanForLevels() {
        import std.file : dirEntries, SpanMode, isDir;
        import std.path : baseName;
        
        availableLevels = [];
        
        try {
            // Scan resources/data/levels/ directory
            string levelDir = "resources/data/levels/";
            if (std.file.exists(levelDir)) {
                foreach (entry; dirEntries(levelDir, SpanMode.shallow)) {
                    if (entry.isDir) {
                        availableLevels ~= entry.name;
                    }
                }
            }
            
            if (availableLevels.length > 0) {
                writefln("Found %d levels: %s", availableLevels.length, availableLevels);
            } else {
                writeln("No levels found in resources/data/levels/");
            }
        } catch (Exception e) {
            writeln("Error scanning for levels: ", e.msg);
        }
    }
    
    void loadTilesets() {
        import std.file : exists;
        
        string[string] tilesetPaths = [
            "ground1": "resources/image/tilemap/Ground_1.png",
            "ground2": "resources/image/tilemap/Ground_2.png",
            "ground3": "resources/image/tilemap/Ground_1.png", // Fallback to Ground_1
            "semisolid1": "resources/image/tilemap/SemiSolids_1.png",
            "semisolid2": "resources/image/tilemap/SemiSolids_2.png",
            "semisolid3": "resources/image/tilemap/SemiSolids_1.png", // Fallback to SemiSolids_1
            "collision": "resources/image/tilemap/SPGSolidTileHeightCollision.png",
            "hazard": "resources/image/tilemap/SPGSolidTileHeightSemiSolids.png"
        ];
        
        writeln("Loading tilesets...");
        foreach (layerName, path; tilesetPaths) {
            if (!exists(path)) {
                writeln("Tileset file not found: ", path);
                continue;
            }
            
            try {
                writeln("Attempting to load: ", path);
                Texture2D texture = LoadTexture(path.toStringz);
                if (texture.id != 0) {
                    tilesets[layerName] = texture;
                    writeln("Successfully loaded tileset for ", layerName, ": ", path, " (ID: ", texture.id, ", Size: ", texture.width, "x", texture.height, ")");
                } else {
                    writeln("Failed to load tileset for ", layerName, ": ", path, " (texture ID is 0)");
                }
            } catch (Exception e) {
                writeln("Exception loading tileset for ", layerName, ": ", e.msg);
            }
        }
        
        tilesetsLoaded = (tilesets.length > 0);
        writeln("Total tilesets loaded: ", tilesets.length);
    }
    
    void loadTileset(string tilesetPath) {
        // Legacy method - kept for compatibility but not used
        writeln("Legacy loadTileset called with: ", tilesetPath);
    }
    
    void loadLevel(string levelPath) {
        try {
            // Use JSON loading if enabled, otherwise fall back to CSV
            switch(levelLoadingType) {
            case 0: // CSV
                currentLevel = loadCompleteLevel(levelPath);
                writeln("Loading level using CSV format");
                break;
            case 1: // JSON
                currentLevel = loadCompleteLevel(levelPath, true);
                writeln("Loading level using JSON format");
                break;
            case 2: // RVW 
                //currentLevel = loadCompleteLevel(0);
                //writeln("Loading level 0 using RVW format");

                currentLevel = loadCompleteLevel(levelPath);
                writeln("Loading level using placeholder CSV format");
            break;
            default: // Default to CSV
                currentLevel = loadCompleteLevel(levelPath);
                writeln("Loading level using placeholder CSV format");
            break;
            }
            
            levelLoaded = true;
            
            // Center camera on level
            cameraTarget = Vector2(
                (currentLevel.width * tileSize * renderScale) / 2.0f,
                (currentLevel.height * tileSize * renderScale) / 2.0f
            );
            camera.target = cameraTarget;
            
            writefln("Level loaded: %s (%dx%d) using %s format", 
                     currentLevel.levelName, currentLevel.width, currentLevel.height,
                     levelLoadingType == 0 ? "CSV" : (levelLoadingType == 1 ? "JSON" : "RVW" ));
            
            // Clear existing entities and load new ones from level
            entityManager.clearAllEntities();
            entityManager.loadEntitiesFromLevel(currentLevel);
            
            // Add some test entities if no entities were loaded from the level
            if (entityManager.getEntityCount() == 0) {
                writeln("No entities found in level data, adding test entities");
                addTestEntities();
            }
        } catch (Exception e) {
            writeln("Error loading level: ", e.msg);
            levelLoaded = false;
        }
    }
    
    void addTestEntities() {
        // Add some test collectibles
        entityManager.createCollectible(Vector2(200, 350), "ring", 10);
        entityManager.createCollectible(Vector2(250, 300), "ring", 10);
        entityManager.createCollectible(Vector2(300, 350), "ring", 10);
        entityManager.createCollectible(Vector2(400, 280), "power_up", 100);
        
        // Add some test enemies
        entityManager.createEnemy(Vector2(500, 350), "badnik");
        entityManager.createEnemy(Vector2(700, 350), "badnik");
        
        // Add test checkpoints
        entityManager.createCheckpoint(Vector2(600, 350));
        entityManager.createCheckpoint(Vector2(1000, 350));
        
        writeln("Added test entities to level");
    }
    
    void createTestLevel() {
        writeln("Creating test level...");
        currentLevel = LevelData();
        currentLevel.levelName = "Test Level";
        currentLevel.width = 20;
        currentLevel.height = 15;
        currentLevel.backgroundColor = Color(135, 206, 235, 255);
        currentLevel.playerSpawnPoint = Vector2(100, 100);
        
        // Create simple test data
        currentLevel.groundLayer1 = new Tile[][](currentLevel.height, currentLevel.width);
        for (int y = 0; y < currentLevel.height; y++) {
            for (int x = 0; x < currentLevel.width; x++) {
                if (y >= currentLevel.height - 3) {
                    // Ground tiles at bottom
                    currentLevel.groundLayer1[y][x] = Tile(1, true, false, false, 0, 0);
                } else {
                    // Empty tiles
                    currentLevel.groundLayer1[y][x] = Tile(0, false, false, false, 0, 0);
                }
            }
        }
        
        levelLoaded = true;
        writeln("Test level created");
    }

    void update(float deltaTime) {
        handleInput(deltaTime);
        updateCamera(deltaTime);
        
        // Update entities
        if (levelLoaded) {
            entityManager.update(deltaTime);
        }
    }
    
    void handleInput(float deltaTime) {
        // Screen switching
        if (IsKeyPressed(KeyboardKey.KEY_P)) {
            ScreenManager.getInstance().changeState(ScreenState.PALETTE_SWAP_TEST);
            return;
        }
        
        // Level switching
        if (IsKeyPressed(KeyboardKey.KEY_N) && availableLevels.length > 0) {
            currentLevelIndex = (currentLevelIndex + 1) % cast(int)availableLevels.length;
            loadLevel(availableLevels[currentLevelIndex]);
        }
        if (IsKeyPressed(KeyboardKey.KEY_B) && availableLevels.length > 0) {
            currentLevelIndex = (currentLevelIndex - 1 + cast(int)availableLevels.length) % cast(int)availableLevels.length;
            loadLevel(availableLevels[currentLevelIndex]);
        }
        
        // Camera movement
        Vector2 movement = Vector2(0, 0);
        if (IsKeyDown(KeyboardKey.KEY_LEFT) || IsKeyDown(KeyboardKey.KEY_A)) {
            movement.x -= cameraSpeed * deltaTime;
        }
        if (IsKeyDown(KeyboardKey.KEY_RIGHT) || IsKeyDown(KeyboardKey.KEY_D)) {
            movement.x += cameraSpeed * deltaTime;
        }
        if (IsKeyDown(KeyboardKey.KEY_UP) || IsKeyDown(KeyboardKey.KEY_W)) {
            movement.y -= cameraSpeed * deltaTime;
        }
        if (IsKeyDown(KeyboardKey.KEY_DOWN) || IsKeyDown(KeyboardKey.KEY_S)) {
            movement.y += cameraSpeed * deltaTime;
        }
        
        cameraTarget.x += movement.x;
        cameraTarget.y += movement.y;
        
        // Camera zoom
        float wheel = GetMouseWheelMove();
        if (wheel != 0) {
            camera.zoom += wheel * zoomSpeed;
            if (camera.zoom < 0.1f) camera.zoom = 0.1f;
            if (camera.zoom > 5.0f) camera.zoom = 5.0f;
        }
        
        // Reset camera
        if (IsKeyPressed(KeyboardKey.KEY_R)) {
            cameraTarget = Vector2(
                (currentLevel.width * tileSize * renderScale) / 2.0f,
                (currentLevel.height * tileSize * renderScale) / 2.0f
            );
            camera.zoom = 1.0f;
        }
        
        // Debug key to reload tilesets
        if (IsKeyPressed(KeyboardKey.KEY_T)) {
            writeln("Reloading tilesets...");
            foreach (layerName, texture; tilesets) {
                if (texture.id != 0) {
                    UnloadTexture(texture);
                }
            }
            tilesets.clear();
            loadTilesets();
        }
        
        // Layer visibility toggles
        if (IsKeyPressed(KeyboardKey.KEY_ONE)) showGroundLayer1 = !showGroundLayer1;
        if (IsKeyPressed(KeyboardKey.KEY_TWO)) showGroundLayer2 = !showGroundLayer2;
        if (IsKeyPressed(KeyboardKey.KEY_THREE)) showGroundLayer3 = !showGroundLayer3;
        if (IsKeyPressed(KeyboardKey.KEY_FOUR)) showSemiSolid1 = !showSemiSolid1;
        if (IsKeyPressed(KeyboardKey.KEY_FIVE)) showSemiSolid2 = !showSemiSolid2;
        if (IsKeyPressed(KeyboardKey.KEY_SIX)) showSemiSolid3 = !showSemiSolid3;
        if (IsKeyPressed(KeyboardKey.KEY_SEVEN)) showCollisionLayer = !showCollisionLayer;
        if (IsKeyPressed(KeyboardKey.KEY_EIGHT)) showHazardLayer = !showHazardLayer;
        if (IsKeyPressed(KeyboardKey.KEY_NINE)) showObjects = !showObjects;
        if (IsKeyPressed(KeyboardKey.KEY_ZERO)) showGrid = !showGrid;
        if (IsKeyPressed(KeyboardKey.KEY_I)) showDebugInfo = !showDebugInfo;
        
        // Toggle between JSON and CSV loading
        if (IsKeyPressed(KeyboardKey.KEY_J)) {
            levelLoadingType = (levelLoadingType + 1) % 3; // Cycle through 0, 1, 2
            writeln("Switched to ", levelLoadingType == 0 ? "CSV" : (levelLoadingType == 1 ? "JSON" : "RVW" ), " loading mode");
            
            // Reload current level with new format
            if (levelLoaded && availableLevels.length > 0) {
                loadLevel(availableLevels[currentLevelIndex]);
            }
        }
        
        // Entity management controls
        if (IsKeyPressed(KeyboardKey.KEY_E)) {
            if (levelLoaded) {
                addTestEntities();
            }
        }
        
        if (IsKeyPressed(KeyboardKey.KEY_C)) {
            entityManager.clearAllEntities();
            writeln("Cleared all entities");
        }
        
        if (IsKeyPressed(KeyboardKey.KEY_G)) {
            entityManager.debugPrint();
        }
    }
    
    void updateCamera(float deltaTime) {
        // Smooth camera movement
        float lerpSpeed = 5.0f;
        camera.target.x += (cameraTarget.x - camera.target.x) * lerpSpeed * deltaTime;
        camera.target.y += (cameraTarget.y - camera.target.y) * lerpSpeed * deltaTime;
    }

    void draw() {
        ClearBackground(levelLoaded ? currentLevel.backgroundColor : Color(30, 30, 30, 255));
        
        if (!levelLoaded) {
            DrawText("No level loaded", GetScreenWidth() / 2 - 80, GetScreenHeight() / 2, 20, Colors.WHITE);
            return;
        }
        
        // Begin camera mode for level rendering
        BeginMode2D(camera);
        
        // Draw level layers
        drawLevel();
        
        // End camera mode
        EndMode2D();
        
        // Draw UI (not affected by camera)
        drawUI();
    }
    
    void drawLevel() {
        // Draw layers in order (back to front)
        if (showGroundLayer3) drawTileLayer(currentLevel.groundLayer3, Color(255, 255, 255, 255), "ground3");
        if (showGroundLayer2) drawTileLayer(currentLevel.groundLayer2, Color(255, 255, 255, 255), "ground2");
        if (showGroundLayer1) drawTileLayer(currentLevel.groundLayer1, Color(255, 255, 255, 255), "ground1");
        if (showSemiSolid3) drawTileLayer(currentLevel.semiSolidLayer3, Color(255, 255, 255, 200), "semisolid3");
        if (showSemiSolid2) drawTileLayer(currentLevel.semiSolidLayer2, Color(255, 255, 255, 200), "semisolid2");
        if (showSemiSolid1) drawTileLayer(currentLevel.semiSolidLayer1, Color(255, 255, 255, 200), "semisolid1");
        if (showHazardLayer) drawTileLayer(currentLevel.hazardLayer, Color(255, 100, 100, 255), "hazard");
        if (showCollisionLayer) drawTileLayer(currentLevel.collisionLayer, Color(255, 255, 0, 128), "collision");
        
        // Draw objects
        if (showObjects) {
            drawObjects();
            
            // Draw entities
            entityManager.draw();
        }
        
        // Draw player spawn point
        Vector2 spawnPos = Vector2(
            currentLevel.playerSpawnPoint.x * renderScale,
            currentLevel.playerSpawnPoint.y * renderScale
        );
        DrawCircleV(spawnPos, 8.0f * renderScale, Color(0, 255, 0, 200));
        DrawText("SPAWN".toStringz, cast(int)spawnPos.x - 20, cast(int)spawnPos.y - 25, 12, Colors.WHITE);
        
        // Draw grid
        if (showGrid) {
            drawGrid();
        }
    }
    
    void drawTileLayer(const Tile[][] layer, Color tint, string layerType) {
        if (layer.length == 0) return;
        
        // Get the appropriate tileset for this layer
        Texture2D* tileset = (layerType in tilesets);
        
        for (int y = 0; y < layer.length; y++) {
            for (int x = 0; x < layer[y].length; x++) {
                const Tile tile = layer[y][x];
                if (tile.tileId <= 0) continue;
                
                Vector2 position = Vector2(
                    x * tileSize * renderScale,
                    y * tileSize * renderScale
                );
                
                if (tileset !is null && tileset.id != 0) {
                    // Calculate source rectangle from tileset
                    // Assuming tileset is organized as a grid
                    int tilesPerRow = tileset.width / tileSize;
                    if (tilesPerRow <= 0) tilesPerRow = 1; // Prevent division by zero
                    
                    // Debug: Show original tile ID from CSV and adjusted ID
                    int originalCsvId = tile.tileId - 1; // Show what was in CSV
                    int adjustedTileId = tile.tileId - 1; // Adjust for tileset offset
                    
                    int srcX = adjustedTileId % tilesPerRow;
                    int srcY = adjustedTileId / tilesPerRow;
                    
                    Rectangle source = Rectangle(
                        srcX * tileSize,
                        srcY * tileSize,
                        tileSize,
                        tileSize
                    );
                    
                    Rectangle dest = Rectangle(
                        position.x,
                        position.y,
                        tileSize * renderScale,
                        tileSize * renderScale
                    );
                    
                    DrawTexturePro(*tileset, source, dest, Vector2(0, 0), 0.0f, tint);
                    
                    // (Removed debug DrawText for tile IDs)
                } else {
                    // Fallback: draw colored rectangles
                    Color tileColor = getTileColor(tile);
                    tileColor.a = tint.a;
                    
                    DrawRectangleV(position, Vector2(tileSize * renderScale, tileSize * renderScale), tileColor);
                    
                    // Draw tile ID for debugging
                    if (renderScale >= 1.0f) {
                        DrawText(to!string(tile.tileId).toStringz, 
                                cast(int)position.x + 2, 
                                cast(int)position.y + 2, 
                                8, Colors.WHITE);
                    }
                }
            }
        }
    }
    
    Color getTileColor(const Tile tile) {
        if (tile.isHazard) return Color(255, 0, 0, 255);
        if (tile.isPlatform) return Color(255, 255, 0, 255);
        if (tile.isSolid) return Color(100, 100, 100, 255);
        return Color(200, 200, 200, 255);
    }
    
    void drawObjects() {
        foreach (obj; currentLevel.objects) {
            Vector2 position = Vector2(
                obj.x * renderScale,
                obj.y * renderScale
            );
            
            Color objColor = getObjectColor(obj.objectType);
            DrawCircleV(position, 6.0f * renderScale, objColor);
            
            if (renderScale >= 1.0f) {
                DrawText(format("ID:%d T:%d", obj.objectId, obj.objectType).toStringz,
                        cast(int)position.x - 15,
                        cast(int)position.y - 20,
                        8, Colors.WHITE);
            }
        }
    }
    
    Color getObjectColor(int objectType) {
        switch (objectType) {
            case 1: return Color(255, 0, 255, 255); // Enemy
            case 2: return Color(0, 255, 255, 255); // Item
            case 3: return Color(255, 255, 0, 255); // Trigger
            default: return Color(255, 255, 255, 255);
        }
    }
    
    void drawGrid() {
        float gridSize = tileSize * renderScale;
        Color gridColor = Color(255, 255, 255, 50);
        
        // Calculate visible grid bounds
        Vector2 screenStart = GetScreenToWorld2D(Vector2(0, 0), camera);
        Vector2 screenEnd = GetScreenToWorld2D(Vector2(GetScreenWidth(), GetScreenHeight()), camera);
        
        int startX = cast(int)(screenStart.x / gridSize) - 1;
        int endX = cast(int)(screenEnd.x / gridSize) + 1;
        int startY = cast(int)(screenStart.y / gridSize) - 1;
        int endY = cast(int)(screenEnd.y / gridSize) + 1;
        
        // Draw vertical lines
        for (int x = startX; x <= endX; x++) {
            float xPos = x * gridSize;
            DrawLine(cast(int)xPos, cast(int)screenStart.y, cast(int)xPos, cast(int)screenEnd.y, gridColor);
        }
        
        // Draw horizontal lines
        for (int y = startY; y <= endY; y++) {
            float yPos = y * gridSize;
            DrawLine(cast(int)screenStart.x, cast(int)yPos, cast(int)screenEnd.x, cast(int)yPos, gridColor);
        }
    }
    
    void drawUI() {
        if (!showDebugInfo) return;
        
        int y = 10;
        int lineHeight = 20;
        
        DrawText("LEVEL TEST SCREEN", 10, y, 20, Colors.WHITE);
        y += lineHeight + 5;
        
        if (levelLoaded) {
            DrawText(("Level: " ~ currentLevel.levelName).toStringz, 10, y, 16, Colors.LIGHTGRAY);
            y += lineHeight;
            
            DrawText(format("Size: %dx%d", currentLevel.width, currentLevel.height).toStringz, 10, y, 16, Colors.LIGHTGRAY);
            y += lineHeight;
            
            DrawText(format("Objects: %d", currentLevel.objects.length).toStringz, 10, y, 16, Colors.LIGHTGRAY);
            y += lineHeight;
            
            DrawText(format("Tilesets loaded: %d", tilesets.length).toStringz, 10, y, 16, Colors.LIGHTGRAY);
            y += lineHeight;
            
            DrawText(format("Loading mode: %s", levelLoadingType == 0 ? "CSV" : (levelLoadingType == 1 ? "JSON" : "RVW" )).toStringz, 10, y, 16, Colors.LIGHTGRAY);
            y += lineHeight;
            
            DrawText(format("Entities: %d", entityManager.getEntityCount()).toStringz, 10, y, 16, Colors.LIGHTGRAY);
            y += lineHeight;
        }
        
        y += 10;
        DrawText("CONTROLS:", 10, y, 16, Colors.YELLOW);
        y += lineHeight;
        DrawText("WASD/Arrows: Move camera", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("Mouse wheel: Zoom", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("R: Reset camera", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("N/B: Next/Previous level", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("1-9: Toggle layers", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("0: Toggle grid", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("I: Toggle debug info", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("T: Reload tilesets", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("J: Toggle JSON/CSV loading", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("E: Add test entities", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("C: Clear all entities", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("G: Debug entity info", 10, y, 14, Colors.LIGHTGRAY);
        y += lineHeight - 2;
        DrawText("P: Back to Palette Test", 10, y, 14, Colors.LIGHTGRAY);
        
        // Layer visibility status
        y += 20;
        DrawText("LAYERS:", 10, y, 16, Colors.YELLOW);
        y += lineHeight;
        drawLayerStatus("1: Ground 1", showGroundLayer1, 10, y); y += lineHeight - 2;
        drawLayerStatus("2: Ground 2", showGroundLayer2, 10, y); y += lineHeight - 2;
        drawLayerStatus("3: Ground 3", showGroundLayer3, 10, y); y += lineHeight - 2;
        drawLayerStatus("4: SemiSolid 1", showSemiSolid1, 10, y); y += lineHeight - 2;
        drawLayerStatus("5: SemiSolid 2", showSemiSolid2, 10, y); y += lineHeight - 2;
        drawLayerStatus("6: SemiSolid 3", showSemiSolid3, 10, y); y += lineHeight - 2;
        drawLayerStatus("7: Collision", showCollisionLayer, 10, y); y += lineHeight - 2;
        drawLayerStatus("8: Hazards", showHazardLayer, 10, y); y += lineHeight - 2;
        drawLayerStatus("9: Objects", showObjects, 10, y); y += lineHeight - 2;
        
        // Tileset status
        if (tilesets.length > 0) {
            y += 10;
            DrawText("LOADED TILESETS:", 10, y, 16, Colors.YELLOW);
            y += lineHeight;
            foreach (layerName, texture; tilesets) {
                DrawText(format("%s: %dx%d", layerName, texture.width, texture.height).toStringz, 10, y, 14, Colors.GREEN);
                y += lineHeight - 2;
            }
        }
        
        // Camera info
        y += 10;
        DrawText(format("Camera: (%.1f, %.1f) Zoom: %.2f", camera.target.x, camera.target.y, camera.zoom).toStringz, 10, y, 14, Colors.DARKGRAY);
    }
    
    void drawLayerStatus(string label, bool visible, int x, int y) {
        Color color = visible ? Colors.GREEN : Colors.RED;
        string status = visible ? " [ON]" : " [OFF]";
        DrawText((label ~ status).toStringz, x, y, 14, color);
    }

    void unload() {
        writeln("LevelTestScreen unloaded");
        
        // Unload all tilesets
        foreach (layerName, texture; tilesets) {
            if (texture.id != 0) {
                UnloadTexture(texture);
            }
        }
        tilesets.clear();
        tilesetsLoaded = false;
        
        levelLoaded = false;
        initialized = false;
    }
}
