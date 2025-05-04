module prestoframework.debug_screen;

import raylib;

import prestoframework.screen_manager;
import prestoframework.screen_states;
import prestoframework.screen_settings;
import parser.csv_tile_loader;
import prestoframework.player; // Import the Player class

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
    private float cameraSpeed = 5.0f; // Reduced speed
    private float zoomSpeed = 0.1f;   // Speed of camera zoom

    private Player player; // Add Player instance

    this(ScreenManager screenManager, ScreenSettings screenSettings) {
        this.screenManager = screenManager;
        this.screenSettings = screenSettings;
    }

    void load() {
        writeln("DebugScreen loaded");

        // Load the tileset textures
        tileset1 = LoadTexture("source/res/image/tilemap/SPGSolidTileHeightCollision.png");
        tileset2 = LoadTexture("source/res/image/tilemap/SPGSolidTileHeightSemiSolids.png");

        // Load the tile layers and find player start (using default ID 0)
        Vector2 playerStartPos = Vector2(100, 100); // Default start position
        // Corrected filename: TestLevelA_Ground 1.csv
        auto groundResult = loadCSVLayer("source/res/data/levels/TestLevelA/TestLevelA_Ground 1.csv", "ground", 16, 16);
        ground = groundResult.layer;
        if (groundResult.playerStartPosition.x != -1 && groundResult.playerStartPosition.y != -1) {
            playerStartPos = groundResult.playerStartPosition;
            writeln("Using player start position from ground layer (ID 0): ", playerStartPos);
        }
        // Corrected filename: TestLevelA_SemiSolid 1.csv
        auto semiSolidResult = loadCSVLayer("source/res/data/levels/TestLevelA/TestLevelA_SemiSolid 1.csv", "semiSolid", 16, 16);
        semiSolid = semiSolidResult.layer;

        // Initialize Player using the found or default start position
        player = new Player(playerStartPos);
        player.load();

        // Initialize camera
        camera = Camera2D(Vector2(screenSettings.getScreenWidth() / 2.0f, screenSettings.getScreenHeight() / 2.0f), Vector2(0, 0), 0.0f, 1.0f); // Center offset using getters
        camera.target = Vector2(0, 0);
    }
    void unload() {
        writeln("DebugScreen unloading...");
        player.unload(); // Unload player assets
        UnloadTexture(tileset1);
        UnloadTexture(tileset2);
    }
    void update() {
        // Camera Movement (Re-enabled A/D)
        if (IsKeyDown(KeyboardKey.KEY_W)) camera.target.y -= cameraSpeed / camera.zoom;
        if (IsKeyDown(KeyboardKey.KEY_S)) camera.target.y += cameraSpeed / camera.zoom;
        if (IsKeyDown(KeyboardKey.KEY_A)) camera.target.x -= cameraSpeed / camera.zoom; // Re-enabled
        if (IsKeyDown(KeyboardKey.KEY_D)) camera.target.x += cameraSpeed / camera.zoom; // Re-enabled

        // Camera Zoom
        float wheel = GetMouseWheelMove();
        if (wheel != 0) {
            // Get the world point that is under the mouse
            Vector2 mouseWorldPos = GetScreenToWorld2D(GetMousePosition(), camera);

            // Set the offset to where the mouse is
            camera.offset = GetMousePosition();

            // Set the target to match, so that the camera maps the world space point
            // under the cursor to the screen space point under the cursor at any zoom
            camera.target = mouseWorldPos;

            // Zoom
            camera.zoom += wheel * zoomSpeed * camera.zoom; // Make zoom speed proportional to current zoom
            if (camera.zoom < 0.1f) camera.zoom = 0.1f; // Prevent zoom from becoming too small or negative
        }

        // Reset camera zoom and position with middle mouse button
        if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_MIDDLE)) {
            camera.zoom = 1.0f;
            camera.target = Vector2(0, 0);
             camera.offset = Vector2(screenSettings.getScreenWidth() / 2.0f, screenSettings.getScreenHeight() / 2.0f); // Use getters
        }

        player.update(); // Update the player
    }
    void draw() {
        BeginDrawing();
        screenSettings.applyVirtualResolution();
        ClearBackground(Colors.DARKGRAY);
        BeginMode2D(camera);

        // Draw world content (tiles, player)
        drawTileLayer(ground, tileset1);
        drawTileLayer(semiSolid, tileset2);
        player.draw(); // Draw the player

        EndMode2D();

        // Draw UI elements (like FPS) outside the camera view
        // Use TextFormat for safe C-style string formatting
        DrawText(TextFormat("FPS: %i", GetFPS()), 10, 10, 20, Colors.LIME);

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
                int tileID = layer.data[y][x]; // Removed modulo for now, assuming IDs are direct indices or -1
                if (tileID == -1) // Check specifically for -1 to skip empty tiles
                    continue;

                // Ensure tileID is within the valid range for the tileset
                int maxTileID = tilesPerRow * (tileset.height / layer.tileHeight);
                if (tileID < 0 || tileID >= maxTileID) {
                     // Optionally draw an error tile or log a warning
                     // DrawRectangle(x * layer.tileWidth, y * layer.tileHeight, layer.tileWidth, layer.tileHeight, Colors.RED);
                     continue; // Skip invalid tile IDs
                }


                int localID = tileID; // Use tileID directly
                int sx = (localID % tilesPerRow) * layer.tileWidth;
                int sy = (localID / tilesPerRow) * layer.tileHeight;

                Rectangle src = Rectangle(sx, sy, layer.tileWidth, layer.tileHeight);
                Vector2 pos = Vector2(x * layer.tileWidth, y * layer.tileHeight);

                DrawTextureRec(tileset, src, pos, Colors.WHITE);
            }
        }
    }
}