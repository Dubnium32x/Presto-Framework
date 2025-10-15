// Level Demo Screen: loads and renders a CSV- or TMX-based level
#include "level_demo_screen.h"
#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../util/level_loader.h"
#include "../world/generated_heightmaps.h"

// Simple camera for panning
static Camera2D cam = {0};
static LevelData level = {0};
static Texture2D tilesetTex = {0};

// Config
static const int TILE_SIZE = 16; // matches heightmap tile width/height

static void DrawTileLayer(Tile** layer, int width, int height, Texture2D tiles);

void LevelDemo_Init(void) {
    // Load level from the provided folder
    // Expecting CSVs like LEVEL_0_Ground_1.csv etc in this directory
    const char* levelFolder = "res/data/levels/LEVEL_0";
    level = LoadCompleteLevel(levelFolder);

    // Load the visual tileset texture used by the level
    tilesetTex = LoadTexture("res/sprite/spritesheet/tileset/SPGSolidTileHeightCollision.png");
    if (tilesetTex.id == 0) {
        TraceLog(LOG_WARNING, "Failed to load tileset texture; tiles won't render");
    }

    // Setup camera
    cam.target = (Vector2){ 0, 0 };
    cam.offset = (Vector2){ 0, 0 };
    cam.rotation = 0.0f;
    cam.zoom = 1.0f;
}

void LevelDemo_Update(float dt) {
    // Basic camera controls
    const float speed = 120.0f;
    if (IsKeyDown(KEY_RIGHT)) cam.target.x += speed * dt;
    if (IsKeyDown(KEY_LEFT))  cam.target.x -= speed * dt;
    if (IsKeyDown(KEY_DOWN))  cam.target.y += speed * dt;
    if (IsKeyDown(KEY_UP))    cam.target.y -= speed * dt;

    if (IsKeyPressed(KEY_EQUAL)) cam.zoom *= 1.125f;
    if (IsKeyPressed(KEY_MINUS)) cam.zoom /= 1.125f;
}

void LevelDemo_Draw(void) {
    BeginMode2D(cam);
    ClearBackground((Color){ 80, 160, 220, 255 });

    // Draw ground layers back-to-front
    if (level.groundLayer1) DrawTileLayer(level.groundLayer1, level.width, level.height, tilesetTex);
    if (level.groundLayer2) DrawTileLayer(level.groundLayer2, level.width, level.height, tilesetTex);
    if (level.groundLayer3) DrawTileLayer(level.groundLayer3, level.width, level.height, tilesetTex);

    // Optional: draw collision tiles semi-transparent for debug
    if (level.collisionLayer) {
        Color tint = (Color){255, 0, 0, 100};
        // Temporarily reuse draw with a tint by changing global draw color
        // We'll just draw rectangles as overlay to show occupied cells
        for (int y = 0; y < level.height; y++) {
            for (int x = 0; x < level.width; x++) {
                if (level.collisionLayer[y][x].tileId > 0) {
                    DrawRectangleLines(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE, tint);
                }
            }
        }
    }

    EndMode2D();

    // HUD
    DrawText("Level Demo: Arrow keys to pan, +/- to zoom", 8, 8, 10, WHITE);
    DrawText(TextFormat("Level: %s  %dx%d", level.levelName ? level.levelName : "LEVEL_0", level.width, level.height), 8, 22, 10, WHITE);
}

void LevelDemo_Unload(void) {
    if (tilesetTex.id) UnloadTexture(tilesetTex);
    FreeLevelData(&level);
}

static void DrawTileLayer(Tile** layer, int width, int height, Texture2D tiles) {
    if (!layer || tiles.id == 0) return;

    const int columns = tiles.width / TILE_SIZE; // 256/16 = 16

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int rawId = layer[y][x].tileId;
            if (rawId <= 0) continue;
            // rawId may be a global gid (>= firstgid). Normalize to tileset-local 1-based id.
            int localId = rawId;
            // If rawId looks like a global gid (>= firstgid and >> columns), normalize by firstgid.
            if (rawId >= level.firstgid && rawId > (int)(level.firstgid + tiles.width / TILE_SIZE)) {
                localId = rawId - level.firstgid + 1;
            }
            int idx = localId - 1;
            int sx = (idx % columns) * TILE_SIZE;
            int sy = (idx / columns) * TILE_SIZE;
            Rectangle src = { (float)sx, (float)sy, (float)TILE_SIZE, (float)TILE_SIZE };
            Rectangle dst = { (float)(x * TILE_SIZE), (float)(y * TILE_SIZE), (float)TILE_SIZE, (float)TILE_SIZE };
            DrawTexturePro(tiles, src, dst, (Vector2){0,0}, 0.0f, WHITE);
        }
    }
}
