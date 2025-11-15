// Level Demo Screen: loads and renders a CSV- or TMX-based level
#include "level_demo_screen.h"
#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../util/level_loader.h"
#include "../world/generated_heightmaps.h"
#include "../camera/title_card.h"
#include "../world/audio_manager.h"
#include "../camera/hud.h"
#include "../entity/player/player.h"
#include "../world/input.h"
#include "../util/globals.h"

// Simple camera for panning
Texture2D tilesetTex;
// Use the global player instance defined in main.c
extern Player player;

static void DrawTileLayer(Tile **layer, int width, int height, Texture2D tiles);

void LevelDemo_Init(void)
{
    // Load level from the provided folder
    // Expecting CSVs like LEVEL_0_Ground_1.csv etc in this directory
    const char *levelFolder = "res/data/levels/LEVEL_0";
    // Free any existing level data first
    FreeLevelData(&currentLevel);
    // Load the new level into the existing struct
    LevelData newLevel = LoadCompleteLevel(levelFolder);
    memcpy(&currentLevel, &newLevel, sizeof(LevelData));

    // Load the visual tileset texture used by the level
    tilesetTex = LoadTexture("res/sprite/spritesheet/tileset/SPGSolidTileHeightCollision.png");
    if (tilesetTex.id == 0)
    {
        TraceLog(LOG_WARNING, "Failed to load tileset texture; tiles won't render");
    }

    // Initialize title card system
    TitleCardCamera_Init();

    // Initialize HUD
    InitHUD();

    // Player is initialized in main.c; ensure camera starts centered on player
    MoveCamTo(&cam, (Vector2){player.position.x, player.position.y});

    // Set initial HUD values
    UpdateValues(0, 3, 0); // Start with 3 lives

    // Play module music for the level
    extern AudioManager g_audioManager;
    PlayModuleMusic(&g_audioManager, "res/audio/music/modules/atlantishighway.it", 1.0f, true);
}

void LevelDemo_Update(float dt)
{
    // Update title card system first
    TitleCardCamera_Update(dt);

    // Update HUD
    UpdateHUD(dt);

    // Basic camera controls (for debugging)
    const float speed = 120.0f;
    if (IsKeyDown(KEY_RIGHT))
        cam.position.x += speed * dt;
    if (IsKeyDown(KEY_LEFT))
        cam.position.x -= speed * dt;
    if (IsKeyDown(KEY_DOWN))
        cam.position.y += speed * dt;
    if (IsKeyDown(KEY_UP))
        cam.position.y -= speed * dt;

    if (IsKeyPressed(KEY_EQUAL))
        cam.zoom *= 1.125f;
    if (IsKeyPressed(KEY_MINUS))
        cam.zoom /= 1.125f;

    // Update player and have camera follow
    Player_Update(&player, dt);
    MoveCamTo(&cam, (Vector2){player.position.x, player.position.y});
}

void LevelDemo_Draw(void)
{
    Camera2D newCam = {0};
    // Center camera on screen
    newCam.offset.x = VIRTUAL_SCREEN_WIDTH * 0.5f;
    newCam.offset.y = VIRTUAL_SCREEN_HEIGHT * 0.5f;
    newCam.rotation = cam.rotation;
    newCam.target.x = cam.position.x;
    newCam.target.y = cam.position.y;
    newCam.zoom = cam.zoom;

    BeginMode2D(newCam);
    ClearBackground((Color){80, 160, 220, 255});

    // Draw ground layers back-to-front
    if (currentLevel.groundLayer1)
        DrawTileLayer(currentLevel.groundLayer1, currentLevel.width, currentLevel.height, tilesetTex);
    if (currentLevel.groundLayer2)
        DrawTileLayer(currentLevel.groundLayer2, currentLevel.width, currentLevel.height, tilesetTex);
    if (currentLevel.groundLayer3)
        DrawTileLayer(currentLevel.groundLayer3, currentLevel.width, currentLevel.height, tilesetTex);

    // Optional: draw collision tiles semi-transparent for debug
    if (currentLevel.collisionLayer)
    {
        Color tint = (Color){255, 0, 0, 100};
        // Temporarily reuse draw with a tint by changing global draw color
        // We'll just draw rectangles as overlay to show occupied cells
        for (int y = 0; y < currentLevel.height; y++)
        {
            for (int x = 0; x < currentLevel.width; x++)
            {
                if (currentLevel.collisionLayer[y][x].tileId > 0)
                {
                    DrawRectangleLines(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE, tint);
                }
            }
        }
    }

    // Draw player in world space
    Player_Draw(&player);

    EndMode2D();

    // Draw the HUD behind the second fade
    DrawHUD();

    // Draw back fade first (behind everything)
    TitleCardCamera_DrawBackFade();

    // Draw title card overlay (screen space, not world space)
    TitleCardCamera_Draw();

    // Draw debug HUD for the player
    DrawDebugHUD(&player);

    // Draw front fade last (on top of everything)
    TitleCardCamera_DrawFrontFade();
}

void LevelDemo_Unload(void)
{
    if (tilesetTex.id)
        UnloadTexture(tilesetTex);
    FreeLevelData(&currentLevel);
    TitleCardCamera_Unload();

    // Unload HUD
    UnloadHUD();

    // Stop module music when level ends
    extern AudioManager g_audioManager;
    StopModuleMusic(&g_audioManager);
}

static void DrawTileLayer(Tile **layer, int width, int height, Texture2D tiles)
{
    if (!layer || tiles.id == 0)
        return;

    const int columns = tiles.width / TILE_SIZE; // 256/16 = 16

    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            int rawId = layer[y][x].tileId;
            if (rawId == 0)
                continue;

            uint32_t uRawId = (uint32_t)rawId;
            bool flipH = (uRawId & FLIPPED_HORIZONTALLY_FLAG) != 0;
            bool flipV = (uRawId & FLIPPED_VERTICALLY_FLAG) != 0;
            bool flipD = (uRawId & FLIPPED_DIAGONALLY_FLAG) != 0;

            uint32_t gid = uRawId & ~FLIPPED_ALL_FLAGS_MASK;
            if (gid == 0)
                continue;

            int localId = (int)gid - currentLevel.firstgid + 1;
            int idx = localId - 1;

            int sx = (idx % columns) * TILE_SIZE;
            int sy = (idx / columns) * TILE_SIZE;

            Rectangle src = {(float)sx, (float)sy, (float)TILE_SIZE, (float)TILE_SIZE};

            if (flipH)
            {
                src.x += TILE_SIZE;
                src.width = -src.width;
            }
            if (flipV)
            {
                src.y += TILE_SIZE;
                src.height = -src.height;
            }

            Rectangle dst = {(float)(x * TILE_SIZE), (float)(y * TILE_SIZE), (float)TILE_SIZE, (float)TILE_SIZE};

            DrawTexturePro(tiles, src, dst, (Vector2){0, 0}, 0.0f, WHITE);
        }
    }
}