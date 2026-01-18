// Game Screen implementation
#include "screen-game.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "raylib.h"
#include "../managers/managers-input.h"
#include "../managers/managers-screen_settings.h"
#include "../entity/camera/camera-title_card.h"
#include "../entity/camera/camera-hud.h"
#include "../entity/player/player-player.h"
#include "../entity/player/player-collision.h"
#include "../util/util-global.h"

// Game state
static GameScreenState gameState = GAME_INIT;
static float fadeAlpha = 0.0f;
static float fadeDuration = 0.5f;
static float fadeTimer = 0.0f;
static bool titleCardFinished = false;

// Level data
static int** levelData = NULL;
static int levelWidth = 0;
static int levelHeight = 0;
static Texture2D tilesetTexture = {0};

// Player
static Player player;
static LevelCollision levelCollision;
static bool showDebug = false;

// Camera state
static Camera2D camera = {0};
static float cameraSpeed = 200.0f;
static bool cameraFollowPlayer = true;

// Forward declarations
static void LoadTestLevel(void);
static void DrawTileLayer(int** layer, int width, int height, Texture2D tileset);
static void UpdateCameraControls(float deltaTime);
static void UpdateCameraFollowPlayer(void);

void GameScreen_Init(void) {
    // Reset state
    gameState = GAME_INIT;
    fadeAlpha = 0.0f;
    fadeTimer = 0.0f;
    titleCardFinished = false;
    showDebug = true;  // Start with debug on for testing

    // Initialize camera
    camera.offset = (Vector2){ VIRTUAL_SCREEN_WIDTH / 2.0f, VIRTUAL_SCREEN_HEIGHT / 2.0f };
    camera.target = (Vector2){ 0, 0 };
    camera.rotation = 0.0f;
    camera.zoom = 1.0f;

    // Load test level and tileset
    LoadTestLevel();

    // Load tileset texture
    tilesetTexture = LoadTexture("RESOURCES/sprite/spritesheet/tileset/SPGSolidTileHeightCollision.png");
    if (tilesetTexture.id == 0) {
        TraceLog(LOG_WARNING, "Failed to load tileset texture");
        // Create a simple colored rectangle as fallback
        Image img = GenImageColor(256, 256, (Color){100, 150, 200, 255});
        tilesetTexture = LoadTextureFromImage(img);
        UnloadImage(img);
    }

    // Initialize level collision data
    InitLevelCollision(&levelCollision, levelData, levelWidth, levelHeight);

    // Set up player collision reference
    SetPlayerLevelCollision(&levelCollision);

    // Initialize player - spawn above the ground
    Vector2 playerStart = {100.0f, 100.0f};  // Start position (will fall to ground)
    InitPlayer(&player, SONIC, playerStart);

    // Initialize HUD
    InitHUD();

    // Initialize title card with zone name and act number
    // TODO: Get these from level data when level system is complete
    const char* zoneName = "ATLANTIS HIGHWAY";
    int actNumber = (int)g_currentAct + 1; // ACT_1 = 0, so add 1
    TitleCardCamera_Init(zoneName, actNumber);

    gameState = GAME_PLAYING;
}

static void LoadTestLevel(void) {
    // Load level from LEVEL_0 folder
    const char* levelPath = "RESOURCES/data/levels/LEVEL_0/LEVEL_0.csv";

    printf("Attempting to load level from: %s\n", levelPath);

    // Try to load from CSV first
    levelData = LoadCSVIntWithDimensions(levelPath, &levelWidth, &levelHeight);

    if (!levelData) {
        printf("Failed to load CSV, creating test level programmatically\n");
        // Create a simple test level programmatically
        levelWidth = 50;
        levelHeight = 20;

        levelData = malloc(sizeof(int*) * levelHeight);
        for (int y = 0; y < levelHeight; y++) {
            levelData[y] = malloc(sizeof(int) * levelWidth);
            for (int x = 0; x < levelWidth; x++) {
                // Empty by default
                levelData[y][x] = 0;

                // Create ground at bottom (y = 15-19)
                if (y >= 15) {
                    // Use tile 1 (flat solid block based on heightmap)
                    levelData[y][x] = 1;
                }

                // Add some slopes using tile 2 (gentle slope)
                if (y == 14 && x >= 10 && x < 18) {
                    levelData[y][x] = 2;  // Slope tile
                }
                if (y == 13 && x >= 18 && x < 22) {
                    levelData[y][x] = 1;  // Platform
                }
                if (y == 14 && x >= 18 && x < 22) {
                    levelData[y][x] = 1;
                }

                // Add a wall for testing wall collision
                if (x == 30 && y >= 10 && y < 15) {
                    levelData[y][x] = 1;
                }

                // Add some platforms
                if (y == 12 && x >= 35 && x < 40) {
                    levelData[y][x] = 1;
                }
            }
        }
        TraceLog(LOG_INFO, "Created test level programmatically (%dx%d)", levelWidth, levelHeight);
    } else {
        printf("Successfully loaded level: %dx%d\n", levelWidth, levelHeight);
        TraceLog(LOG_INFO, "Loaded level from CSV: %s (%dx%d)", levelPath, levelWidth, levelHeight);
    }
}

static void UpdateCameraFollowPlayer(void) {
    // Smooth camera follow
    float targetX = player.position.x;
    float targetY = player.position.y;

    // Lerp towards player
    camera.target.x += (targetX - camera.target.x) * 0.1f;
    camera.target.y += (targetY - camera.target.y) * 0.1f;

    // Clamp camera to level bounds
    float halfWidth = (VIRTUAL_SCREEN_WIDTH / 2.0f) / camera.zoom;
    float halfHeight = (VIRTUAL_SCREEN_HEIGHT / 2.0f) / camera.zoom;

    float levelPixelWidth = levelWidth * TILE_SIZE;
    float levelPixelHeight = levelHeight * TILE_SIZE;

    if (camera.target.x < halfWidth) camera.target.x = halfWidth;
    if (camera.target.x > levelPixelWidth - halfWidth) camera.target.x = levelPixelWidth - halfWidth;
    if (camera.target.y < halfHeight) camera.target.y = halfHeight;
    if (camera.target.y > levelPixelHeight - halfHeight) camera.target.y = levelPixelHeight - halfHeight;
}

static void UpdateCameraControls(float deltaTime) {
    // Toggle camera mode with C
    if (IsKeyPressed(KEY_C)) {
        cameraFollowPlayer = !cameraFollowPlayer;
    }

    if (cameraFollowPlayer) {
        UpdateCameraFollowPlayer();
    } else {
        // Manual camera movement with WASD (when not following player)
        if (IsKeyDown(KEY_D)) {
            camera.target.x += cameraSpeed * deltaTime;
        }
        if (IsKeyDown(KEY_A)) {
            camera.target.x -= cameraSpeed * deltaTime;
        }
        if (IsKeyDown(KEY_S)) {
            camera.target.y += cameraSpeed * deltaTime;
        }
        if (IsKeyDown(KEY_W)) {
            camera.target.y -= cameraSpeed * deltaTime;
        }
    }

    // Zoom controls
    if (IsKeyPressed(KEY_EQUAL) || IsKeyPressed(KEY_KP_ADD)) {
        camera.zoom *= 1.25f;
    }
    if (IsKeyPressed(KEY_MINUS) || IsKeyPressed(KEY_KP_SUBTRACT)) {
        camera.zoom /= 1.25f;
    }

    // Clamp zoom
    if (camera.zoom < 0.25f) camera.zoom = 0.25f;
    if (camera.zoom > 4.0f) camera.zoom = 4.0f;
}

void GameScreen_Update(float deltaTime) {
    // Always update title card if active
    if (titleCardState != TITLE_CARD_STATE_INACTIVE) {
        TitleCardCamera_Update(deltaTime);

        // Check if title card just finished
        if (titleCardState == TITLE_CARD_STATE_INACTIVE && !titleCardFinished) {
            titleCardFinished = true;
        }
    }

    // Update HUD timer
    UpdateHUD(deltaTime);

    // Toggle debug display
    if (IsKeyPressed(KEY_F1)) {
        showDebug = !showDebug;
    }

    // Reset player position with R
    if (IsKeyPressed(KEY_R)) {
        ResetPlayer(&player, (Vector2){100.0f, 100.0f});
    }

    switch (gameState) {
        case GAME_INIT:
            // Initialization fade in
            fadeTimer += deltaTime;
            fadeAlpha = 1.0f - (fadeTimer / fadeDuration);
            if (fadeTimer >= fadeDuration) {
                fadeAlpha = 0.0f;
                gameState = GAME_PLAYING;
            }
            break;

        case GAME_PLAYING:
            // Update player (physics, input, etc.)
            if (titleCardFinished) {
                UpdatePlayer(&player, deltaTime);
                UpdateCameraControls(deltaTime);
            }

            // Handle pause
            if (IsInputPressed(INPUT_START) || IsKeyPressed(KEY_ESCAPE)) {
                gameState = GAME_PAUSED;
            }

            // Handle back to title
            if (IsKeyPressed(KEY_BACKSPACE)) {
                gameState = GAME_FADE_OUT;
                fadeTimer = 0.0f;
            }
            break;

        case GAME_PAUSED:
            // Handle unpause
            if (IsInputPressed(INPUT_START) || IsKeyPressed(KEY_ESCAPE)) {
                gameState = GAME_PLAYING;
            }

            // Handle back to title
            if (IsKeyPressed(KEY_BACKSPACE)) {
                gameState = GAME_FADE_OUT;
                fadeTimer = 0.0f;
            }
            break;

        case GAME_FADE_OUT:
            fadeTimer += deltaTime;
            fadeAlpha = fadeTimer / fadeDuration;
            if (fadeTimer >= fadeDuration) {
                fadeAlpha = 1.0f;
                SetCurrentScreenGlobal(SCREEN_STATE_TITLE);
            }
            break;
    }
}

void GameScreen_Draw(void) {
    // Clear background
    ClearBackground((Color){135, 206, 250, 255}); // Sky blue

    // Draw title card back fade (behind everything)
    if (titleCardState != TITLE_CARD_STATE_INACTIVE) {
        TitleCardCamera_DrawBackFade();
    }

    BeginMode2D(camera);

    // Draw level tiles
    if (levelData && tilesetTexture.id > 0) {
        DrawTileLayer(levelData, levelWidth, levelHeight, tilesetTexture);
    }

    // Draw grid for debugging (optional)
    if (IsKeyDown(KEY_G)) {
        for (int x = 0; x <= levelWidth; x++) {
            DrawLine(x * TILE_SIZE, 0, x * TILE_SIZE, levelHeight * TILE_SIZE,
                    (Color){255, 255, 255, 100});
        }
        for (int y = 0; y <= levelHeight; y++) {
            DrawLine(0, y * TILE_SIZE, levelWidth * TILE_SIZE, y * TILE_SIZE,
                    (Color){255, 255, 255, 100});
        }
    }

    // Draw player
    DrawPlayer(&player);

    // Draw player debug info (sensors, etc.)
    if (showDebug) {
        DrawPlayerDebug(&player, &levelCollision);
    }

    EndMode2D();

    // Draw HUD (only after title card exits or during display)
    if (titleCardFinished || titleCardState == TITLE_CARD_STATE_INACTIVE) {
        DrawHUD();
    }

    // Draw player debug HUD (screen space)
    if (showDebug) {
        DrawPlayerHUD(&player);
    }

    // Draw title card elements (on top of game world, but HUD shows through)
    if (titleCardState != TITLE_CARD_STATE_INACTIVE) {
        TitleCardCamera_Draw();
        TitleCardCamera_DrawFrontFade();
    }

    // Draw UI elements (screen space)
    if (gameState == GAME_PAUSED) {
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT,
                     (Color){0, 0, 0, 128});
        const char* pauseText = "PAUSED";
        int textWidth = MeasureText(pauseText, 20);
        DrawText(pauseText, (VIRTUAL_SCREEN_WIDTH - textWidth) / 2,
                VIRTUAL_SCREEN_HEIGHT / 2 - 10, 20, WHITE);
    }

    // Draw controls info (only when title card is done)
    if (titleCardFinished) {
        DrawText("Arrows: Move  Space: Jump  Down+Move: Roll  F1: Debug  R: Reset  C: Camera  G: Grid",
                10, VIRTUAL_SCREEN_HEIGHT - 12, 8, WHITE);
    }

    // Draw fade overlay
    if (fadeAlpha > 0) {
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT,
                     (Color){0, 0, 0, (unsigned char)(fadeAlpha * 255)});
    }
}

static void DrawTileLayer(int** layer, int width, int height, Texture2D tileset) {
    if (!layer || tileset.id == 0) return;

    // Calculate tiles per row in tileset (assuming 16x16 tiles in 256px wide texture)
    int tilesPerRow = tileset.width / TILE_SIZE;

    // Tiled flip flags
    const uint32_t FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
    const uint32_t FLIPPED_VERTICALLY_FLAG   = 0x40000000;
    const uint32_t FLIPPED_DIAGONALLY_FLAG   = 0x20000000;
    const uint32_t TILE_ID_MASK              = 0x1FFFFFFF;

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int rawTileValue = layer[y][x];

            // Skip empty tiles (0 or exactly -1, but not other negative values which are flipped tiles)
            if (rawTileValue == 0 || rawTileValue == -1) continue;

            uint32_t rawValue = (uint32_t)rawTileValue;

            // Extract flip flags
            bool flipH = (rawValue & FLIPPED_HORIZONTALLY_FLAG) != 0;
            bool flipV = (rawValue & FLIPPED_VERTICALLY_FLAG) != 0;
            bool flipD = (rawValue & FLIPPED_DIAGONALLY_FLAG) != 0;

            // Extract actual tile ID
            int tileId = (int)(rawValue & TILE_ID_MASK);
            if (tileId == 0) continue; // Skip if tile ID is 0 after masking

            // Tile IDs in CSV are direct indices into tileset (0-based after skipping 0)
            int tileIndex = tileId;
            int srcX = (tileIndex % tilesPerRow) * TILE_SIZE;
            int srcY = (tileIndex / tilesPerRow) * TILE_SIZE;

            // Set up source rectangle with flipping
            float srcWidth = (float)TILE_SIZE;
            float srcHeight = (float)TILE_SIZE;

            if (flipH) srcWidth = -srcWidth;
            if (flipV) srcHeight = -srcHeight;

            Rectangle source = {
                (float)srcX, (float)srcY,
                srcWidth, srcHeight
            };

            Rectangle dest = {
                (float)(x * TILE_SIZE), (float)(y * TILE_SIZE),
                (float)TILE_SIZE, (float)TILE_SIZE
            };

            // Handle diagonal flip (90° rotation) by rotating the destination
            float rotation = flipD ? 90.0f : 0.0f;
            Vector2 origin = flipD ? (Vector2){0, (float)TILE_SIZE} : (Vector2){0, 0};

            DrawTexturePro(tileset, source, dest, origin, rotation, WHITE);
        }
    }
}

void GameScreen_Unload(void) {
    // Free level data
    if (levelData) {
        for (int y = 0; y < levelHeight; y++) {
            free(levelData[y]);
        }
        free(levelData);
        levelData = NULL;
    }

    // Clear player collision reference
    SetPlayerLevelCollision(NULL);

    // Unload tileset texture
    if (tilesetTexture.id > 0) {
        UnloadTexture(tilesetTexture);
        tilesetTexture = (Texture2D){0};
    }

    // Unload title card resources
    TitleCardCamera_Unload();

    // Unload HUD resources
    UnloadHUD();
}
