module prestoframework.debug_screen;

import raylib;

import prestoframework.screen_manager;
import prestoframework.screen_states;
import prestoframework.screen_settings;
import parser.csv_tile_loader;

import std.stdio : writeln;
import std.string;
import std.json;
import std.conv : to;

class DebugScreen : IScreen {
    private ScreenManager screenManager;
    private ScreenSettings screenSettings;

    TileLayer ground;
    TileLayer semiSolid;
    Texture2D tileset1;
    Texture2D tileset2;

    private Camera2D camera;

    this(ScreenManager screenManager, ScreenSettings screenSettings) {
        this.screenManager = screenManager;
        this.screenSettings = screenSettings;
    }

    void load() {
        writeln("DebugScreen loaded");

        // Load the tileset textures
        tileset1 = LoadTexture("source/res/image/tilemap/SPGSolidTileHeightCollision.png");
        tileset2 = LoadTexture("source/res/image/tilemap/SPGSolidTileHeightSemiSolids.png");
        // Load the tile layers
        ground = loadCSVLayer("source/res/data/levels/TestLevelA/TestLevelA_Ground_Ground.csv", "ground", 16, 16);
        semiSolid = loadCSVLayer("source/res/data/levels/TestLevelA/TestLevelA_SemiSolid1.csv", "semiSolid", 16, 16);

        // Initialize camera
        camera = Camera2D(Vector2(0, 0), Vector2(0, 0), 0.0f, 1.0f);
        camera.target = Vector2(0, 0);
    }
    void unload() {
        writeln("DebugScreen unloaded");
    }
    void update() {
        // Handle input and update logic for the debug screen

    }
    void draw() {
        BeginDrawing();
        screenSettings.applyVirtualResolution();
        ClearBackground(Colors.DARKGRAY);
        BeginMode2D(camera);

        DrawText("Debug Screen", 100, 100, 20, Colors.WHITE);
        drawTileLayer(ground, tileset1);
        drawTileLayer(semiSolid, tileset2);

        EndMode2D();
        screenSettings.endVirtualResolution();
        EndDrawing();
    }

    void setScreen(ScreenState newState) {
        // Set the screen state to the new state
        if (newState == ScreenState.DEBUG) {
            screenManager.setScreen(new DebugScreen(screenManager, screenSettings));
        }
    }

    void drawTileLayer(TileLayer layer, Texture2D tileset) {
        int tilesPerRow = tileset.width / layer.tileWidth;

        for (int y = 0; y < layer.data.length; y++) {
            for (int x = 0; x < layer.data[y].length; x++) {
                int tileID = layer.data[y][x];
                if (tileID == 0) continue;

                int localID = tileID - 1;
                int sx = (localID % tilesPerRow) * layer.tileWidth;
                int sy = (localID / tilesPerRow) * layer.tileHeight;

                Rectangle src = Rectangle(sx, sy, layer.tileWidth, layer.tileHeight);
                Vector2 pos = Vector2(x * layer.tileWidth, y * layer.tileHeight);

                DrawTextureRec(tileset, src, pos, Colors.WHITE);
            }
        }
    }
}