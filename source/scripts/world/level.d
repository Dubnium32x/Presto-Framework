module world.level;

import raylib;

import std.stdio;
import std.string;
import std.array;
import std.conv : to;
import std.format;

import world.level_list;
import utils.csv_loader;
import utils.level_loader;
import utils.csv_converter;
import utils.rvw_loader;

/**
 * Level Management System for Presto Framework
 * 
 * Provides high-level interface for working with levels in the game.
 * Handles level loading, rendering, collision detection, and object management.
 */

/**
 * Active Level Manager - manages the currently loaded level
 */
class Level {
    private static Level _instance;
    private LevelLoader levelLoader;
    private RVWLoader rvwLoader;
    private LevelData currentLevel;
    private bool isLevelLoaded = false;
    
    // Rendering properties
    private int tileSize = 16; // Size of each tile in pixels
    private Camera2D camera;
    private Vector2 cameraOffset;
    
    // Collision optimization
    private int lastCheckedTileX = -1;
    private int lastCheckedTileY = -1;
    private Tile lastCheckedTile;
    
    private this() {
        levelLoader = LevelLoader.getInstance();
        rvwLoader = RVWLoader.getInstance();
        rvwLoader.initialize();
        camera = Camera2D();
        camera.target = Vector2(0, 0);
        camera.offset = Vector2(400, 224); // Half of virtual screen size
        camera.rotation = 0.0f;
        camera.zoom = 1.0f;
        cameraOffset = Vector2(0, 0);
    }
    
    static Level getInstance() {
        if (_instance is null) {
            _instance = new Level();
        }
        return _instance;
    }
    
    /**
     * Load and set a level as the current active level
     */
    bool loadLevel(LevelNumber levelNum, ActNumber actNum) {
        try {
            currentLevel = levelLoader.loadLevel(levelNum, actNum);
            isLevelLoaded = true;
            
            // Set camera to level start position
            camera.target = currentLevel.cameraStartPosition;
            
            writeln("Successfully loaded and activated level: ", currentLevel.levelName);
            return true;
        } catch (Exception e) {
            writeln("Failed to load level: ", e.msg);
            isLevelLoaded = false;
            return false;
        }
    }
    
    /**
     * Update level systems (called every frame)
     */
    void update(float deltaTime) {
        if (!isLevelLoaded) return;
        
        // Update any dynamic level elements here
        // For now, just update the camera smoothly
        updateCamera(deltaTime);
    }
    
    /**
     * Render the current level
     */
    void draw() {
        if (!isLevelLoaded) {
            DrawText("No Level Loaded", 10, 10, 20, Colors.RED);
            return;
        }
        
        BeginMode2D(camera);
        
        // Draw background color
        ClearBackground(currentLevel.backgroundColor);
        
        // Draw tile layers (back to front)
        drawTileLayer(currentLevel.groundLayer1, 0);
        drawTileLayer(currentLevel.groundLayer2, 1);
        drawTileLayer(currentLevel.semiSolidLayer1, 2);
        drawTileLayer(currentLevel.semiSolidLayer2, 3);
        
        // Draw objects
        drawObjects();
        
        // Draw collision layer for debugging (optional)
        static bool showCollision = false;
        if (IsKeyPressed(KeyboardKey.KEY_F1)) {
            showCollision = !showCollision;
        }
        if (showCollision) {
            drawCollisionLayer();
        }
        
        EndMode2D();
        
        // Draw level HUD/UI elements
        drawLevelHUD();
    }
    
    /**
     * Update camera position and movement
     */
    private void updateCamera(float deltaTime) {
        // For now, just allow manual camera control for testing
        float cameraSpeed = 200.0f * deltaTime;
        
        if (IsKeyDown(KeyboardKey.KEY_A)) camera.target.x -= cameraSpeed;
        if (IsKeyDown(KeyboardKey.KEY_D)) camera.target.x += cameraSpeed;
        if (IsKeyDown(KeyboardKey.KEY_W)) camera.target.y -= cameraSpeed;
        if (IsKeyDown(KeyboardKey.KEY_S)) camera.target.y += cameraSpeed;
        
        // TODO: Implement proper camera following for player character
    }
    
    /**
     * Draw a specific tile layer using RVW loader and tilesets
     */
    private void drawTileLayer(const Tile[][] layer, int layerIndex) {
        if (layer.length == 0 || !rvwLoader.hasTilesetLoaded()) return;
        
        // Convert Tile[][] to int[][] for RVW loader
        int[][] tileData = new int[][](layer.length);
        for (int y = 0; y < layer.length; y++) {
            tileData[y] = new int[](layer[y].length);
            for (int x = 0; x < layer[y].length; x++) {
                tileData[y][x] = layer[y][x].tileId;
            }
        }
        
        // Set tileset based on layer type
        switch (layerIndex) {
            case 0: // Ground Layer 1
            case 1: // Ground Layer 2
            case 4: // Collision Layer
                rvwLoader.setCurrentTileset("spg_solid");
                break;
            case 2: // Semi-Solid Layer 1  
            case 3: // Semi-Solid Layer 2
                rvwLoader.setCurrentTileset("spg_semisolid");
                break;
            default:
                rvwLoader.setCurrentTileset("spg_solid");
                break;
        }
        
        // Apply transparency for overlay layers
        Color layerTint = Colors.WHITE;
        if (layerIndex > 0) {
            layerTint = Color(255, 255, 255, 180); // Semi-transparent
        }
        
        // Draw using RVW loader with culling for performance
        rvwLoader.drawTileLayerCulled(tileData, camera, Vector2(0, 0), layerTint);
    }
    
    /**
     * Draw a single tile using RVW loader
     */
    private void drawTile(const Tile tile, float x, float y, int layerIndex) {
        if (!rvwLoader.hasTilesetLoaded()) {
            // Fallback to colored rectangles if no tileset
            Color tileColor = getDebugTileColor(tile, layerIndex);
            DrawRectangle(cast(int)x, cast(int)y, tileSize, tileSize, tileColor);
            
            // Draw tile ID for debugging
            if (tile.tileId < 100) {
                DrawText(tile.tileId.to!string.toStringz, cast(int)x + 2, cast(int)y + 2, 8, Colors.WHITE);
            }
            return;
        }
        
        // Set appropriate tileset based on tile type and layer
        if (tile.tileType == TileType.SEMI_SOLID) {
            rvwLoader.setCurrentTileset("spg_semisolid");
        } else {
            rvwLoader.setCurrentTileset("spg_solid");
        }
        
        // Apply transparency for overlay layers
        Color tint = Colors.WHITE;
        if (layerIndex > 0) {
            tint = Color(255, 255, 255, 180);
        }
        
        // Draw tile using RVW loader
        rvwLoader.drawTile(tile.tileId, x, y, tint);
    }
    
    /**
     * Get debug color for tile when tileset isn't available
     */
    private Color getDebugTileColor(const Tile tile, int layerIndex) {
        Color tileColor = Colors.WHITE;
        
        // Color code tiles based on type
        switch (tile.tileType) {
            case TileType.SOLID:
                tileColor = Color(139, 69, 19, 255); // Brown
                break;
            case TileType.SEMI_SOLID:
                tileColor = Color(160, 82, 45, 255); // Saddle brown
                break;
            case TileType.WATER:
                tileColor = Color(64, 164, 223, 255); // Blue
                break;
            case TileType.LAVA:
                tileColor = Color(255, 69, 0, 255); // Red orange
                break;
            case TileType.ICE:
                tileColor = Color(173, 216, 230, 255); // Light blue
                break;
            case TileType.SPIKES:
                tileColor = Color(128, 128, 128, 255); // Gray
                break;
            default:
                tileColor = Color(100, 100, 100, 255); // Default gray
                break;
        }
        
        // Make deeper layers slightly transparent
        if (layerIndex > 0) {
            tileColor.a = 180;
        }
        
        return tileColor;
    }
    
    /**
     * Draw level objects
     */
    private void drawObjects() {
        // Get objects in visible area
        float viewX = camera.target.x - camera.offset.x;
        float viewY = camera.target.y - camera.offset.y;
        float viewWidth = camera.offset.x * 2;
        float viewHeight = camera.offset.y * 2;
        
        LevelObject[] visibleObjects = levelLoader.getObjectsInArea(
            currentLevel, viewX, viewY, viewWidth, viewHeight
        );
        
        foreach (obj; visibleObjects) {
            if (!obj.isActive) continue;
            
            drawObject(obj);
        }
    }
    
    /**
     * Draw a single object
     */
    private void drawObject(const LevelObject obj) {
        Color objColor = Colors.YELLOW;
        int objSize = 12;
        
        // Color code objects based on type
        switch (obj.objectType) {
            case ObjectType.RING:
                objColor = Colors.YELLOW;
                objSize = 8;
                break;
            case ObjectType.SPRING_YELLOW:
                objColor = Colors.YELLOW;
                objSize = 16;
                break;
            case ObjectType.SPRING_RED:
                objColor = Colors.RED;
                objSize = 16;
                break;
            case ObjectType.SPRING_BLUE:
                objColor = Colors.BLUE;
                objSize = 16;
                break;
            case ObjectType.ENEMY_MOTOBUG:
            case ObjectType.ENEMY_CRABMEAT:
            case ObjectType.ENEMY_BUZZER:
            case ObjectType.ENEMY_CHOPPER:
                objColor = Colors.RED;
                objSize = 14;
                break;
            case ObjectType.CHECKPOINT_LAMP:
                objColor = Colors.GREEN;
                objSize = 20;
                break;
            case ObjectType.GOAL_POST:
                objColor = Colors.LIME;
                objSize = 24;
                break;
            default:
                objColor = Colors.MAGENTA;
                break;
        }
        
        // Draw object as a circle for now
        // TODO: Replace with actual object sprites
        DrawCircle(cast(int)obj.x, cast(int)obj.y, objSize / 2, objColor);
        
        // Draw object type ID
        string objText = format("%d", cast(int)obj.objectType);
        DrawText(objText.toStringz, cast(int)obj.x - 8, cast(int)obj.y - 4, 8, Colors.BLACK);
    }
    
    /**
     * Draw collision layer for debugging
     */
    private void drawCollisionLayer() {
        if (currentLevel.collisionLayer.length == 0) return;
        
        // Calculate visible tile range
        int startX = cast(int)((camera.target.x - camera.offset.x) / tileSize) - 1;
        int endX = cast(int)((camera.target.x + camera.offset.x) / tileSize) + 2;
        int startY = cast(int)((camera.target.y - camera.offset.y) / tileSize) - 1;
        int endY = cast(int)((camera.target.y + camera.offset.y) / tileSize) + 2;
        
        // Clamp to level bounds
        if (startX < 0) startX = 0;
        if (startY < 0) startY = 0;
        if (endX >= currentLevel.collisionLayer[0].length) endX = cast(int)currentLevel.collisionLayer[0].length;
        if (endY >= currentLevel.collisionLayer.length) endY = cast(int)currentLevel.collisionLayer.length;
        
        // Draw collision tiles as semi-transparent overlay
        for (int y = startY; y < endY; y++) {
            for (int x = startX; x < endX; x++) {
                Tile tile = currentLevel.collisionLayer[y][x];
                if (tile.isSolid) {
                    DrawRectangle(
                        x * tileSize, y * tileSize, tileSize, tileSize,
                        Color(255, 0, 0, 100) // Semi-transparent red
                    );
                }
            }
        }
    }
    
    /**
     * Draw level HUD/UI elements
     */
    private void drawLevelHUD() {
        if (!isLevelLoaded) return;
        
        // Level name
        DrawText(currentLevel.levelName.toStringz, 10, 10, 16, Colors.WHITE);
        
        // Camera position
        string cameraInfo = format("Camera: (%.1f, %.1f)", camera.target.x, camera.target.y);
        DrawText(cameraInfo.toStringz, 10, 30, 12, Colors.WHITE);
        
        // Level info
        string levelInfo = format("Size: %dx%d tiles, Objects: %d", 
                                 currentLevel.width, currentLevel.height, currentLevel.objects.length);
        DrawText(levelInfo.toStringz, 10, 45, 12, Colors.WHITE);
        
        // Controls
        DrawText("Controls: WASD = Camera, F1 = Toggle Collision", 10, 400, 12, Colors.YELLOW);
    }
    
    // ---- Collision Detection Methods ----
    
    /**
     * Check if a position has solid collision
     */
    bool isSolidAtPosition(float worldX, float worldY) {
        if (!isLevelLoaded) return false;
        return levelLoader.isSolidAtPosition(currentLevel, worldX, worldY);
    }
    
    /**
     * Get tile at world position with caching for performance
     */
    Tile getTileAtPosition(float worldX, float worldY, int layerIndex = 0) {
        if (!isLevelLoaded) return Tile(0);
        
        int tileX = cast(int)(worldX / tileSize);
        int tileY = cast(int)(worldY / tileSize);
        
        // Use cached result if checking the same tile
        if (tileX == lastCheckedTileX && tileY == lastCheckedTileY && layerIndex == 0) {
            return lastCheckedTile;
        }
        
        Tile result = levelLoader.getTileAtTilePosition(currentLevel, tileX, tileY, layerIndex);
        
        // Cache the result
        if (layerIndex == 0) {
            lastCheckedTileX = tileX;
            lastCheckedTileY = tileY;
            lastCheckedTile = result;
        }
        
        return result;
    }
    
    /**
     * Get all objects within a specific area
     */
    LevelObject[] getObjectsInArea(float x, float y, float width, float height) {
        if (!isLevelLoaded) return [];
        return levelLoader.getObjectsInArea(currentLevel, x, y, width, height);
    }
    
    // ---- Getters ----
    
    bool isLoaded() { return isLevelLoaded; }
    LevelData getCurrentLevel() { return currentLevel; }
    Camera2D getCamera() { return camera; }
    int getTileSize() { return tileSize; }
    
    /**
     * Get level bounds
     */
    Rectangle getLevelBounds() {
        if (!isLevelLoaded) return Rectangle(0, 0, 0, 0);
        return Rectangle(0, 0, currentLevel.width * tileSize, currentLevel.height * tileSize);
    }
    
    /**
     * Convert world position to tile coordinates
     */
    Vector2 worldToTile(float worldX, float worldY) {
        return Vector2(worldX / tileSize, worldY / tileSize);
    }
    
    /**
     * Convert tile coordinates to world position
     */
    Vector2 tileToWorld(int tileX, int tileY) {
        return Vector2(tileX * tileSize, tileY * tileSize);
    }
    
    /**
     * Unload current level
     */
    void unloadLevel() {
        if (isLevelLoaded) {
            writeln("Unloading current level: ", currentLevel.levelName);
            isLevelLoaded = false;
        }
    }
}

