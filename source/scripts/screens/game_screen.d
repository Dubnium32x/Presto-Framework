module screens.game_screen;

import raylib;

import std.stdio;
import std.algorithm;
import std.array;
import std.conv;
import std.math;
import std.string;

import world.audio_manager;
import world.screen_manager;
import world.screen_state;
import world.input_manager;
import world.memory_manager;
import sprite.sprite_manager;
import entity.sprite_object;
import entity.player.player;
import sprite.sprite_fonts;
import world.level_list;
import utils.level_loader;

import game.hud;
import game.title_card;
import app : VIRTUAL_SCREEN_HEIGHT, VIRTUAL_SCREEN_WIDTH;

GameState currentState;

enum GameState {
    TITLECARDMOVEIN,
    TITLECARDHOLD,
    TITLECARDFADEOUT,
    PLAYING,
    PAUSED,
    ACTCLEAR,
    GAMEOVER
};

class GameScreen : IScreen {
    Texture2D ground1Tileset, ground2Tileset, ground3Tileset;
    Texture2D semiSolid1Tileset, semiSolid2Tileset, semiSolid3Tileset;
    HUD hud;
    TitleCard titleCard;

    int score, rings, lives;

    float titleCardTimer = 0.0f;
    this() {
        hud = new HUD();
        titleCard = new TitleCard("ZONE NAME", 1); // TODO: Replace with actual zone/act
        currentState = GameState.TITLECARDMOVEIN;
        titleCardTimer = 0.0f;
    }

    LevelData currentLevel;
    Player player;

    Camera2D debugCamera;
    // Debugging fields: throttle terminal logging and track last positions
    int dbgLogInterval = 30; // frames between forced logs
    int dbgFrameCounter = 0;
    Vector2 dbgLastPlayerPos = Vector2(-9999, -9999);
    Vector2 dbgLastCameraTarget = Vector2(-9999, -9999);
    // Camera smoothing state
    Vector2 cameraTarget = Vector2(0,0);
    float cameraLerpSpeed = 8.0f; // how quickly camera follows target

    void initialize() {
        // Load tileset textures for visual layers
        ground1Tileset = LoadTexture("resources/image/tilemap/Ground_1.png");
        ground2Tileset = LoadTexture("resources/image/tilemap/Ground_2.png");
        ground3Tileset = LoadTexture("resources/image/tilemap/Ground_1.png"); // Fallback for now
        semiSolid1Tileset = LoadTexture("resources/image/tilemap/SemiSolids_1.png");
        semiSolid2Tileset = LoadTexture("resources/image/tilemap/SemiSolids_2.png");
        semiSolid3Tileset = LoadTexture("resources/image/tilemap/SemiSolids_1.png"); // Fallback for now
        // Play music (debug)
        AudioManager.getInstance().playMusic("resources/sound/music/01. Sonic World.mp3");

        // Load the level
        string levelPath = "resources/data/levels/LEVEL_0"; // Example path
        currentLevel = loadCompleteLevel(levelPath);

        // Debug: Print level dimensions
        writeln("[DEBUG] Loaded level dimensions: ", currentLevel.width, "x", currentLevel.height);
        if (currentLevel.width == 0 || currentLevel.height == 0) {
            writeln("[ERROR] Level size is 0. Check level data.");
        }

        // Debug: Print the size of each layer
        writeln("[DEBUG] Ground Layer 1 size: ", currentLevel.groundLayer1.length, "x", (currentLevel.groundLayer1.length > 0 ? currentLevel.groundLayer1[0].length : 0));
        writeln("[DEBUG] Ground Layer 2 size: ", currentLevel.groundLayer2.length, "x", (currentLevel.groundLayer2.length > 0 ? currentLevel.groundLayer2[0].length : 0));
        writeln("[DEBUG] Ground Layer 3 size: ", currentLevel.groundLayer3.length, "x", (currentLevel.groundLayer3.length > 0 ? currentLevel.groundLayer3[0].length : 0));
        writeln("[DEBUG] Semi-Solid Layer 1 size: ", currentLevel.semiSolidLayer1.length, "x", (currentLevel.semiSolidLayer1.length > 0 ? currentLevel.semiSolidLayer1[0].length : 0));
        writeln("[DEBUG] Semi-Solid Layer 2 size: ", currentLevel.semiSolidLayer2.length, "x", (currentLevel.semiSolidLayer2.length > 0 ? currentLevel.semiSolidLayer2[0].length : 0));
        writeln("[DEBUG] Semi-Solid Layer 3 size: ", currentLevel.semiSolidLayer3.length, "x", (currentLevel.semiSolidLayer3.length > 0 ? currentLevel.semiSolidLayer3[0].length : 0));
        writeln("[DEBUG] Collision Layer size: ", currentLevel.collisionLayer.length, "x", (currentLevel.collisionLayer.length > 0 ? currentLevel.collisionLayer[0].length : 0));
        writeln("[DEBUG] Hazard Layer size: ", currentLevel.hazardLayer.length, "x", (currentLevel.hazardLayer.length > 0 ? currentLevel.hazardLayer[0].length : 0));

    debugCamera = Camera2D();
    // Start camera target at player spawn
    debugCamera.target = currentLevel.playerSpawnPoint;
    // Use actual screen center for offset so centering works on any resolution
    // Use virtual screen center so the Camera2D offset lines up with the game's render target
    debugCamera.offset = Vector2(VIRTUAL_SCREEN_WIDTH / 2.0f, VIRTUAL_SCREEN_HEIGHT / 2.0f);
        debugCamera.rotation = 0.0f;
        debugCamera.zoom = 1.0f;

    // Ensure desired camera target starts at the current camera target (player spawn)
    // This prevents cameraTarget from being (0,0) which could cause the camera to
    // lerp toward the world origin on the first update.
    cameraTarget = debugCamera.target;


    // Initialize player at spawn point (do not modify collision internals here)
    player = Player.create(currentLevel.playerSpawnPoint.x, currentLevel.playerSpawnPoint.y);
    player.initialize(currentLevel.playerSpawnPoint.x, currentLevel.playerSpawnPoint.y);
    // Attach the loaded level so player can use precomputed tile profiles for collisions
    player.setLevel(&currentLevel);
    // Restore normal start state (title card sequence)
    currentState = GameState.TITLECARDMOVEIN;
    // Initialize debug tracking positions to the player's start so initial logs are correct
    dbgLastPlayerPos = Vector2(player.vars.xPosition, player.vars.yPosition);
    dbgLastCameraTarget = debugCamera.target;
    }

    void update(float deltaTime) {
        // Update HUD timer and values
        hud.update(deltaTime); // Always update timer (HUD manages when active)
        hud.updateValues(score, rings, lives);

        // Always update title card until bgAlpha is 0
        if (currentState == GameState.TITLECARDMOVEIN || currentState == GameState.TITLECARDHOLD || currentState == GameState.TITLECARDFADEOUT) {
            titleCard.update(deltaTime);
            // Debug: print state and title card info
            writeln("[DEBUG] State: ", currentState, " | Alpha: ", titleCard.alpha, " | AnimatingIn: ", titleCard.animatingIn, " | bgAlpha: ", titleCard.bgAlpha);
            // Transition to TITLECARDHOLD when animatingIn becomes false
            if (currentState == GameState.TITLECARDMOVEIN && !titleCard.animatingIn) {
                currentState = GameState.TITLECARDHOLD;
                writeln("[DEBUG] Transition to TITLECARDHOLD");
            }
            // Transition to FADEOUT after hold
            if (currentState == GameState.TITLECARDHOLD && titleCard.rectHoldTimer > 2.0f) {
                currentState = GameState.TITLECARDFADEOUT;
                writeln("[DEBUG] Transition to TITLECARDFADEOUT");
            }
            // Transition to PLAYING only after both bgAlpha and alpha are 0
            if (currentState == GameState.TITLECARDFADEOUT && titleCard.bgAlpha == 0 && titleCard.alpha == 0.0f) {
                currentState = GameState.PLAYING;
                hud.startTimer(); // Start HUD timer when gameplay begins
                writeln("[DEBUG] Transition to PLAYING");
            }
        }

        // Debug camera manual pan when not following
        float cameraSpeed = 10.0f;
        if (IsKeyDown(KeyboardKey.KEY_LEFT) || IsKeyDown(KeyboardKey.KEY_A)) {
            debugCamera.target.x -= cameraSpeed;
        }
        if (IsKeyDown(KeyboardKey.KEY_RIGHT) || IsKeyDown(KeyboardKey.KEY_D)) {
            debugCamera.target.x += cameraSpeed;
        }
        if (IsKeyDown(KeyboardKey.KEY_UP) || IsKeyDown(KeyboardKey.KEY_W)) {
            debugCamera.target.y -= cameraSpeed;
        }
        if (IsKeyDown(KeyboardKey.KEY_DOWN) || IsKeyDown(KeyboardKey.KEY_S)) {
            debugCamera.target.y += cameraSpeed;
        }
        // Zoom controls
        if (IsKeyDown(KeyboardKey.KEY_Q) || IsKeyDown(KeyboardKey.KEY_KP_ADD)) {
            debugCamera.zoom += 0.05f;
        }
        if (IsKeyDown(KeyboardKey.KEY_E) || IsKeyDown(KeyboardKey.KEY_KP_SUBTRACT)) {
            debugCamera.zoom -= 0.05f;
            if (debugCamera.zoom < 0.1f) debugCamera.zoom = 0.1f;
        }

        // Update player and camera when playing
            if (currentState == GameState.PLAYING) {
                // Update the player (input, physics, animation)
                player.update(deltaTime);

                // Update desired camera target (world space)
                import std.math : isNaN;
                float px = player.vars.xPosition;
                float py = player.vars.yPosition;
                if (isNaN(px) || isNaN(py)) {
                    writeln("[WARN] Player position is NaN; skipping camera target update");
                } else {
                    cameraTarget = Vector2(px, py);
                }

                // Smoothly move actual camera target toward cameraTarget
                debugCamera.target.x += (cameraTarget.x - debugCamera.target.x) * cameraLerpSpeed * deltaTime;
                debugCamera.target.y += (cameraTarget.y - debugCamera.target.y) * cameraLerpSpeed * deltaTime;
            // Debug logging: print when player/camera move noticeably or every interval
            dbgFrameCounter++;
            float playerDX = debugCamera.target.x - dbgLastPlayerPos.x;
            float playerDY = debugCamera.target.y - dbgLastPlayerPos.y;
            float camDX = debugCamera.target.x - dbgLastCameraTarget.x;
            float camDY = debugCamera.target.y - dbgLastCameraTarget.y;
            if (dbgFrameCounter >= dbgLogInterval || abs(playerDX) > 1.0f || abs(playerDY) > 1.0f || abs(camDX) > 1.0f || abs(camDY) > 1.0f) {
                dbgFrameCounter = 0;
                dbgLastPlayerPos = Vector2(player.vars.xPosition, player.vars.yPosition);
                dbgLastCameraTarget = debugCamera.target;
                writeln("[DBG] PlayerPos=", dbgLastPlayerPos, " CameraTarget=", dbgLastCameraTarget, " Zoom=", debugCamera.zoom);
            }

            // Additional runtime diagnostics: log the tile under the player's bottom point
            import std.math : floor;
            int tileSize = 16;
            float bottom = player.vars.yPosition + player.vars.heightRadius;
            int tx = cast(int)floor(player.vars.xPosition / tileSize);
            int ty = cast(int)floor(bottom / tileSize);
            // Try each ground/semi layer and print the tile id found
            Tile t0 = utils.level_loader.getTileAtPosition(currentLevel.groundLayer1, tx, ty);
            Tile t1 = utils.level_loader.getTileAtPosition(currentLevel.groundLayer2, tx, ty);
            Tile t2 = utils.level_loader.getTileAtPosition(currentLevel.groundLayer3, tx, ty);
            Tile s1 = utils.level_loader.getTileAtPosition(currentLevel.semiSolidLayer1, tx, ty);
            if (dbgFrameCounter == 0) {
                writeln("[TILE DBG] player bottom -> tile (", tx, ",", ty, ") ground1=", t0.tileId, " ground2=", t1.tileId, " ground3=", t2.tileId, " semis1=", s1.tileId);
            }
        }

    }

    void drawLayer(Tile[][] layer, Color color) {
        // This function is now unused; replaced by drawTileLayer below
    }

    void drawTileLayer(Tile[][] layer, Texture2D tileset) {
        int tileSize = 16;
        int tilesPerRow = tileset.width / tileSize;
        foreach (y, row; layer) {
            foreach (x, tile; row) {
                if (tile.tileId > 0) {
                    int tileIndex = tile.tileId - 1;
                    int srcX = tileIndex % tilesPerRow;
                    int srcY = tileIndex / tilesPerRow;
                    Rectangle source = Rectangle(srcX * tileSize, srcY * tileSize, tileSize, tileSize);
                    Vector2 dest = Vector2(x * tileSize, y * tileSize);
                    DrawTextureRec(tileset, source, dest, Colors.WHITE);
                }
            }
        }
    }

    void drawLayerIfNotEmpty(Tile[][] layer, Texture2D tileset, string layerName) {
        import std.conv : to;
        if (layer.length > 0 && layer[0].length > 0 && tileset.id != 0) {
            writeln("[DEBUG] Drawing tile layer: " ~ layerName ~ " size: " ~ layer.length.to!string ~ "x" ~ layer[0].length.to!string);
            drawTileLayer(layer, tileset);
        } else {
            writeln("[DEBUG] Skipping empty tile layer: " ~ layerName);
        }
    }

    void draw() {
        BeginMode2D(debugCamera);

        // Clear background
        ClearBackground(Colors.DARKGRAY);

    // Draw all visual layers with their tilesets
    drawLayerIfNotEmpty(currentLevel.groundLayer1, ground1Tileset, "Ground_1");
    drawLayerIfNotEmpty(currentLevel.groundLayer2, ground2Tileset, "Ground_2");
    drawLayerIfNotEmpty(currentLevel.groundLayer3, ground3Tileset, "Ground_3");
    drawLayerIfNotEmpty(currentLevel.semiSolidLayer1, semiSolid1Tileset, "SemiSolids_1");
    drawLayerIfNotEmpty(currentLevel.semiSolidLayer2, semiSolid2Tileset, "SemiSolids_2");
    drawLayerIfNotEmpty(currentLevel.semiSolidLayer3, semiSolid3Tileset, "SemiSolids_3");

        // Optionally draw collision/hazard layers for debug only
        // drawLayerIfNotEmpty(currentLevel.collisionLayer, Colors.MAROON, "CollisionLayer");
        // drawLayerIfNotEmpty(currentLevel.hazardLayer, Colors.ORANGE, "HazardLayer");

    // Draw player (in world space so camera affects it)
    player.draw();

    // Debug: always draw a simple magenta marker at the player's world position
    // so we can tell whether the player is on-screen even if animation fails.
    DrawCircleV(Vector2(player.vars.xPosition, player.vars.yPosition), 8, Colors.MAGENTA);
    // Debug: draw a small cross at the camera target
    DrawLineV(debugCamera.target - Vector2(6,0), debugCamera.target + Vector2(6,0), Colors.SKYBLUE);
    DrawLineV(debugCamera.target - Vector2(0,6), debugCamera.target + Vector2(0,6), Colors.SKYBLUE);

    // Debug overlay: visualize the TileHeightProfile for the tile under the player
    // This helps diagnose missing collision / invisible player issues by drawing
    // the per-column heights and surface marker in world space (camera transformed).
    import std.math : floor;
    int dbgTileSize = 16;
    float dbgBottom = player.vars.yPosition + player.vars.heightRadius;
    int dbgTileX = cast(int)floor(player.vars.xPosition / dbgTileSize);
    int dbgTileY = cast(int)floor(dbgBottom / dbgTileSize);

    struct DbgLayer { Tile[][]* layer; string name; }
    DbgLayer[7] dbgChecks = [
        DbgLayer(&currentLevel.collisionLayer, "Collision"),
        DbgLayer(&currentLevel.groundLayer1, "Ground_1"),
        DbgLayer(&currentLevel.groundLayer2, "Ground_2"),
        DbgLayer(&currentLevel.groundLayer3, "Ground_3"),
        DbgLayer(&currentLevel.semiSolidLayer1, "SemiSolid_1"),
        DbgLayer(&currentLevel.semiSolidLayer2, "SemiSolid_2"),
        DbgLayer(&currentLevel.semiSolidLayer3, "SemiSolid_3")
    ];

    bool drewDbg = false;
    foreach (ch; dbgChecks) {
        Tile[][] layer = *ch.layer;
        if (layer.length == 0) continue;
        Tile tile = utils.level_loader.getTileAtPosition(layer, dbgTileX, dbgTileY);
        if (tile.tileId <= 0) continue;

        // Try precomputed profile first, else ask runtime
        import world.tile_collision : TileHeightProfile, TileCollision;
        TileHeightProfile profile;
        bool hadProfile = utils.level_loader.getPrecomputedTileProfile(currentLevel, tile.tileId, ch.name, profile);
        if (!hadProfile) {
            profile = TileCollision.getTileHeightProfile(tile.tileId, ch.name, currentLevel.tilesets);
        }

        // Draw per-column heights (columns are 0..15 mapped to world X = tileX*16 + col)
        for (int col = 0; col < 16; col++) {
            int h = profile.groundHeights[col]; // 0..16
            float colWorldX = cast(float)(dbgTileX * dbgTileSize + col) + 0.5f; // center the line
            float colBottomY = cast(float)(dbgTileY * dbgTileSize + dbgTileSize);
            float colTopY = cast(float)(dbgTileY * dbgTileSize + (dbgTileSize - h));
            // Draw column line
            DrawLineV(Vector2(colWorldX, colBottomY), Vector2(colWorldX, colTopY), Colors.YELLOW);
            // Draw a small marker at the top of the column
            DrawPixel(cast(int)colWorldX, cast(int)colTopY, Colors.ORANGE);
        }

        // Draw surface marker at player's local column
        int localX = cast(int)floor(player.vars.xPosition) - dbgTileX * dbgTileSize;
        if (localX < 0) localX = 0;
        if (localX > 15) localX = 15;
        float surfaceY = cast(float)(dbgTileY * dbgTileSize) + (dbgTileSize - profile.groundHeights[localX]);
        DrawCircleV(Vector2(player.vars.xPosition, surfaceY), 3, Colors.RED);

        // Draw debug text (tile id, layer, whether profile was precomputed, angle)
        float textWorldX = cast(float)(dbgTileX * dbgTileSize);
        float textWorldY = cast(float)(dbgTileY * dbgTileSize) - 12.0f;
    float angle = TileCollision.getTileGroundAngle(tile.tileId, ch.name, currentLevel.tilesets);
    string dbgText = "TID:" ~ to!string(tile.tileId) ~ " L:" ~ ch.name ~ " precomp:" ~ (hadProfile ? "Y" : "N") ~ " ang:" ~ to!string(angle);
        DrawText(dbgText.toStringz, cast(int)textWorldX, cast(int)textWorldY, 10, Colors.WHITE);

        drewDbg = true;
        break; // only draw the first matching layer
    }

    // If nothing drawn, optionally show player position info
    if (!drewDbg) {
        string info = "Player: (" ~ to!string(player.vars.xPosition) ~ "," ~ to!string(player.vars.yPosition) ~ ") grd:" ~ (player.vars.isGrounded ? "Y" : "N");
        DrawText(info.toStringz, cast(int)(player.vars.xPosition - 40), cast(int)(player.vars.yPosition - 30), 10, Colors.LIGHTGRAY);
    }

    EndMode2D();

    // Debug: show player and camera positions in screen space for quick inspection
    import std.conv : to;
    string posText = "Player: (" ~ to!string(player.vars.xPosition) ~ "," ~ to!string(player.vars.yPosition) ~ ")  ";
    posText ~= "Camera: (" ~ to!string(debugCamera.target.x) ~ "," ~ to!string(debugCamera.target.y) ~ ") Zoom:" ~ to!string(debugCamera.zoom);
    DrawText(posText.toStringz, 10, GetScreenHeight() - 28, 12, Colors.LIGHTGRAY);

    // Additional check: map player's world position to screen space using the camera
    // and draw a screen-space marker so we can see whether the camera transform is correct
    Vector2 playerScreen = GetWorldToScreen2D(Vector2(player.vars.xPosition, player.vars.yPosition), debugCamera);
    DrawCircleV(playerScreen, 6, Colors.LIME);
    // Also show camera offset to validate centering behaviour
    string offsetText = "CamOffset: (" ~ to!string(debugCamera.offset.x) ~ "," ~ to!string(debugCamera.offset.y) ~ ")";
    DrawText(offsetText.toStringz, 10, GetScreenHeight() - 44, 10, Colors.LIGHTGRAY);

    // Draw HUD
    hud.draw();

        // Draw title card if in title card state
        if (currentState == GameState.TITLECARDMOVEIN || currentState == GameState.TITLECARDHOLD || currentState == GameState.TITLECARDFADEOUT) {
            titleCard.draw();
        }
    }

    void unload() {
        // ...cleanup...
    }
}



