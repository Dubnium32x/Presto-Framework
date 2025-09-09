module screens.game_screen;

import raylib;

import std.stdio;
import std.algorithm;
import std.array;
import std.conv;
import std.math;
import std.string;
import std.file;

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
import data;

import game.hud;
import game.title_card;
import game.camera;
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

    GameCamera gameCamera;
    Camera2D renderCamera; // For raylib rendering
    
    // Load camera type from options.ini
    CameraType loadCameraTypeFromOptions() {
        writeln("[DEBUG] Loading camera type from options.ini...");
        if (exists("options.ini")) {
            foreach (line; File("options.ini").byLine()) {
                auto parts = line.idup.split("=");
                if (parts.length == 2) {
                    string key = parts[0].strip;
                    string value = parts[1].strip;
                    writeln("[DEBUG] Found option: ", key, " = ", value);
                    if (key == "cameraType") {
                        string lowerValue = value.toLower();
                        writeln("[DEBUG] Camera type value: '", value, "' -> '", lowerValue, "'");
                        switch (lowerValue) {
                            case "genesis": 
                                writeln("[DEBUG] Selected GENESIS camera");
                                return CameraType.GENESIS;
                            case "cd": 
                                writeln("[DEBUG] Selected CD camera");
                                return CameraType.CD;
                            case "pocket": 
                                writeln("[DEBUG] Selected POCKET camera");
                                return CameraType.POCKET;
                            default: 
                                writeln("[DEBUG] Unknown camera type '", lowerValue, "', defaulting to POCKET");
                                return CameraType.POCKET; // Default fallback
                        }
                    }
                }
            }
        }
        writeln("[DEBUG] No camera type found, defaulting to POCKET");
        return CameraType.POCKET; // Default if not found
    }

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

    // Initialize the new GameCamera system
    CameraType cameraType = loadCameraTypeFromOptions();
    gameCamera = GameCamera(cameraType);
    
    // For SPG cameras, position represents camera world position, target represents what we're looking at
    // Initially, set the camera to look at the player spawn point
    gameCamera.target = currentLevel.playerSpawnPoint;    
    // Set up render camera for raylib
    renderCamera = gameCamera.toCamera2D();
    
    writeln("[DEBUG] Initialized camera type: ", cameraType);
    writeln("[DEBUG] Player spawn point: ", currentLevel.playerSpawnPoint);
    writeln("[DEBUG] Initial camera target: ", gameCamera.target);


    // Initialize player at spawn point (do not modify collision internals here)
    player = Player.create(currentLevel.playerSpawnPoint.x, currentLevel.playerSpawnPoint.y);
    player.initialize(currentLevel.playerSpawnPoint.x, currentLevel.playerSpawnPoint.y);
    // Attach the loaded level so player can use precomputed tile profiles for collisions
    player.setLevel(&currentLevel);
    // Restore normal start state (title card sequence)
    currentState = GameState.TITLECARDMOVEIN;
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

        // Update player and camera when playing
        if (currentState == GameState.PLAYING) {
            // Update the player (input, physics, animation)
            player.update(deltaTime);

            // Get player input for camera look up/down
            bool inputUp = player.vars.keyUp;
            bool inputDown = player.vars.keyDown;

            // Update camera using SPG-compliant system
            Vector2 playerPos = Vector2(player.vars.xPosition, player.vars.yPosition);
            gameCamera.update(playerPos, player.vars.groundSpeed, player.vars.isGrounded, 
                              inputUp, inputDown, deltaTime);
            
            // Update render camera for raylib
            renderCamera = gameCamera.toCamera2D();
            
            // Debug output every 60 frames
            static int debugFrameCounter = 0;
            debugFrameCounter++;
            if (debugFrameCounter >= 60) {
                debugFrameCounter = 0;
                writeln("[CAM DEBUG] PlayerPos: ", playerPos);
                writeln("[CAM DEBUG] GameCamera target: ", gameCamera.target);
                writeln("[CAM DEBUG] RenderCamera target: ", renderCamera.target);
                writeln("[CAM DEBUG] RenderCamera offset: ", renderCamera.offset);
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
        BeginMode2D(renderCamera);

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
    // drawLayerIfNotEmpty(currentLevel.collisionLayer, ground1Tileset, "CollisionLayer");
    // drawLayerIfNotEmpty(currentLevel.hazardLayer, ground1Tileset, "HazardLayer");

        // Draw player (in world space so camera affects it)
        player.draw();

        // Debug: always draw a simple magenta marker at the player's world position
        // so we can tell whether the player is on-screen even if animation fails.
        DrawCircleV(Vector2(player.vars.xPosition, player.vars.yPosition), 8, Colors.MAGENTA);
        // Debug: draw a small cross at the camera target
        DrawLineV(renderCamera.target - Vector2(6,0), renderCamera.target + Vector2(6,0), Colors.SKYBLUE);
        DrawLineV(renderCamera.target - Vector2(0,6), renderCamera.target + Vector2(0,6), Colors.SKYBLUE);

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

        drewDbg = false;
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
    posText ~= "Camera: (" ~ to!string(renderCamera.target.x) ~ "," ~ to!string(renderCamera.target.y) ~ ") Zoom:" ~ to!string(renderCamera.zoom);
    DrawText(posText.toStringz, 10, GetScreenHeight() - 28, 12, Colors.LIGHTGRAY);

    // Additional check: map player's world position to screen space using the camera
    // and draw a screen-space marker so we can see whether the camera transform is correct
    Vector2 playerScreen = GetWorldToScreen2D(Vector2(player.vars.xPosition, player.vars.yPosition), renderCamera);
    DrawCircleV(playerScreen, 6, Colors.LIME);
    // Also show camera offset to validate centering behaviour
    string offsetText = "CamOffset: (" ~ to!string(renderCamera.offset.x) ~ "," ~ to!string(renderCamera.offset.y) ~ ")";
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



