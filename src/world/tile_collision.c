// Tile collision
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "raylib.h"
#include "tile_collision.h"

// Simple flip helpers (stubs). Proper flip-mapping can be implemented later.
static int Tile_GetFlippedHorizontallyTileId(int id) { return id; }
static int Tile_GetFlippedVerticallyTileId(int id) { return id; }
static int Tile_GetFlippedDiagonallyTileId(int id) { return id; }

// Declare external TileProfiles array if defined elsewhere
extern TileProfile TileProfiles[];

TileProfile Tile_GetProfile(int tileId) {
    TileProfile profile = {0};
    profile.tileID = tileId;

    // Get the ground height, width, and angle for the specified tile ID
    profile.groundHeight = TileProfiles[profile.tileID].groundHeight;
    profile.groundWidth = TileProfiles[profile.tileID].groundWidth;
    profile.groundAngle = TileProfiles[profile.tileID].groundAngle;

    return profile;
}

int TileCollision_GetActualTileId(int rawTileId) {
    if (TileCollision_IsEmptyTile(rawTileId)) return -1;

    // Check for flipped tiles
    if (rawTileId & FLIPPED_ALL_FLAGS_MASK) {
        // Get the base tile ID (without flip flags)
        int baseTileId = rawTileId & ~FLIPPED_ALL_FLAGS_MASK;

        // Apply the flip transformations
        if (rawTileId & FLIPPED_HORIZONTALLY_FLAG) {
            baseTileId = Tile_GetFlippedHorizontallyTileId(baseTileId);
        }
        if (rawTileId & FLIPPED_VERTICALLY_FLAG) {
            baseTileId = Tile_GetFlippedVerticallyTileId(baseTileId);
        }
        if (rawTileId & FLIPPED_DIAGONALLY_FLAG) {
            baseTileId = Tile_GetFlippedDiagonallyTileId(baseTileId);
        }

        return baseTileId;
    }

    return rawTileId;
}

bool TileCollision_IsEmptyTile(int tileId) {
    if (tileId == -1 || tileId == 0) return true;
    return false;
}

int** TileCollision_GetHWMap(int tileId, const char* layerName) {
    if (strcmp(layerName, "Ground_Collision1") == 0 ||
        strcmp(layerName, "Ground_Collision2") == 0 ||
        strcmp(layerName, "Ground_Collision3") == 0 ||
        strcmp(layerName, "SemiSolid_Collision1") == 0 ||
        strcmp(layerName, "SemiSolid_Collision2") == 0 ||
        strcmp(layerName, "SemiSolid_Collision3") == 0) {
        int* heightMap = GetTileHeightMap(tileId);
        int* widthMap = GetTileWidthMap(tileId);
        int** hwMap = (int**)malloc(2 * sizeof(int*));
        hwMap[0] = heightMap;
        hwMap[1] = widthMap;
        return hwMap;
    }
    return NULL;
}

uint8_t TileCollision_GetAngle(int tileId) {
    if (TileCollision_IsEmptyTile(tileId)) return 0;
    return GetTileAngle(tileId);
}

bool TileCollision_IsSemiSolidTop(int rawTileId, int rawTileIdAbove, const char* layerName, TilesetInfo* tilesets, int tilesetCount) {
    // Check if the current tile is semi-solid
    if (!TileCollision_IsEmptyTile(rawTileId) && TileCollision_IsEmptyTile(rawTileIdAbove)) {
        // Get the angle of the current tile
        uint8_t angle = TileCollision_GetAngle(rawTileId);
        // Check if the angle is within the semi-solid range
        if (angle >= 45 && angle <= 135) {
            return true;
        }
    }
    return false;
}

RayCollision TileCollision_Raycast(Vector2 start, Vector2 direction, float length) {
    RayCollision hit;
    hit.point = (Vector3){0, 0, 0};
    hit.distance = 0;

    // TODO: Implement actual raycast logic
    // This is a placeholder implementation
    hit.point = (Vector3){start.x + direction.x * length, start.y + direction.y * length, 0};
    hit.distance = length;
    return hit;
}