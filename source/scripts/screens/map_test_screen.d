module screens.map_test_screen;

import raylib;
import std.stdio;
import std.conv : to;
import std.string : toStringz;
import world.screen_manager : IScreen;
import utils.csv_loader;

class MapTestScreen : IScreen {
    private int[][][string] levelLayers; // All layers for the level
    private LevelManager levelManager;
    private Texture2D tileset;
    private int tileSize = 16; // Adjust to your tile size
    private int tilesetColumns = 16; // Number of tiles per row in the tileset
    private int currentLevel = 0;

    void initialize() {
        writeln("MapTestScreen initialized");
        levelManager = new LevelManager();
        
        // Load all layers for the current level
        levelLayers = levelManager.loadLevel(currentLevel, "resources/data/");
        writeln("Loaded level layers: ", levelLayers.keys);
        
        // Load the tileset image
        tileset = LoadTexture("resources/image/tilemap/SPGSolidTileHeightCollision.png");
        writeln("Loaded tileset: ", tileset.width, "x", tileset.height);
    }

    void update(float deltaTime) {
        // Level switching for testing
        if (IsKeyPressed(KeyboardKey.KEY_LEFT) && currentLevel > 0) {
            currentLevel--;
            levelLayers = levelManager.loadLevel(currentLevel, "resources/data/");
            writeln("Switched to level ", currentLevel);
        }
        if (IsKeyPressed(KeyboardKey.KEY_RIGHT) && currentLevel < levelManager.getLevelCount() - 1) {
            currentLevel++;
            levelLayers = levelManager.loadLevel(currentLevel, "resources/data/");
            writeln("Switched to level ", currentLevel);
        }
    }

    void draw() {
        // Define layer rendering order (back to front)
        string[] renderOrder = ["Ground_1", "SemiSolid_1", "Ground_2", "SemiSolid_2", "Objects_1", "Collision"];
        
        // Draw each layer in order
        foreach (layerName; renderOrder) {
            if (layerName in levelLayers) {
                drawLayer(levelLayers[layerName], layerName);
            }
        }
        DrawText(("Map Test Screen - Level " ~ currentLevel.to!string).toStringz, 10, 10, 20, Colors.RAYWHITE);
        DrawText("Layers: Ground_1, SemiSolid_1, Objects_1, Ground_2, SemiSolid_2, Collision".toStringz, 10, 35, 16, Colors.LIGHTGRAY);
        DrawText("Use LEFT/RIGHT arrows to switch levels".toStringz, 10, 55, 16, Colors.YELLOW);
    }
    
    // Helper method to draw a single layer
    private void drawLayer(int[][] layer, string layerName) {
        // Use different tints for different layers for debugging
        Color layerTint = Colors.WHITE;
        if (layerName == "Collision") {
            layerTint = Color(255, 255, 255, 180); // Slightly transparent for collision layer
        } else if (layerName == "Objects_1") {
            layerTint = Color(255, 240, 240, 255); // Slight red tint for objects
        } else if (layerName == "SemiSolid_1" || layerName == "SemiSolid_2") {
            layerTint = Color(240, 255, 240, 255); // Slight green tint for semi-solids
        }
        
        for (int y = 0; y < layer.length; ++y) {
            for (int x = 0; x < layer[y].length; ++x) {
                int tile = layer[y][x];
                if (tile != -1) { // -1 = empty tile
                    // Calculate tile position in tileset
                    int tileX = tile % tilesetColumns;
                    int tileY = tile / tilesetColumns;
                    Rectangle sourceRect = Rectangle(tileX * tileSize, tileY * tileSize, tileSize, tileSize);
                    Vector2 destPos = Vector2(x * tileSize, y * tileSize);
                    DrawTextureRec(tileset, sourceRect, destPos, layerTint);
                }
            }
        }
    }

    void unload() {
        writeln("MapTestScreen unloaded");
        UnloadTexture(tileset);
    }
    
    // Utility methods for accessing layer data
    int[][] getLayer(string layerName) {
        if (layerName in levelLayers) {
            return levelLayers[layerName];
        }
        return [];
    }
    
    // Get tile at specific coordinates for collision detection
    int getTileAt(string layerName, int x, int y) {
        auto layer = getLayer(layerName);
        if (y >= 0 && y < layer.length && x >= 0 && x < layer[y].length) {
            return layer[y][x];
        }
        return -1; // Out of bounds or empty
    }
    
    // Check if there's collision at a world position
    bool hasCollisionAt(float worldX, float worldY) {
        int tileX = cast(int)(worldX / tileSize);
        int tileY = cast(int)(worldY / tileSize);
        
        // Check collision layer first
        int collisionTile = getTileAt("Collision", tileX, tileY);
        if (collisionTile != -1) return true;
        
        // Then check solid ground layers
        int ground1Tile = getTileAt("Ground_1", tileX, tileY);
        if (ground1Tile != -1) return true;
        
        int ground2Tile = getTileAt("Ground_2", tileX, tileY);
        if (ground2Tile != -1) return true;
        
        return false;
    }
}
