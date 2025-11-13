// Tile Collision header
#ifndef TILE_COLLISION_H
#define TILE_COLLISION_H

#include <stdint.h>
#include <stdbool.h>

#include "raylib.h"
#include "tileset_map.h"


// Tile flip flags
#define FLIPPED_HORIZONTALLY_FLAG 0x80000000
#define FLIPPED_VERTICALLY_FLAG   0x40000000
#define FLIPPED_DIAGONALLY_FLAG   0x20000000
#define FLIPPED_ALL_FLAGS_MASK (FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG)

// Debug flag for tile angles
#define DEBUG_TILE_ANGLE 1

typedef struct {
    int tileID;
    int groundHeight;
    int groundWidth;
    uint8_t groundAngle;
} TileProfile;

// Tile collision functions
TileProfile Tile_GetProfile(int tileId);
int TileCollision_GetActualTileId(int rawTileId);
bool TileCollision_IsEmptyTile(int tileId);
int** TileCollision_GetHWMap(int tileId, const char* layerName);
uint8_t TileCollision_GetAngle(int tileId);
bool TileCollision_IsSemiSolidTop(int rawTileId, int rawTileIdAbove, const char* layerName, TilesetInfo* tilesets, int tilesetCount);
RayCollision TileCollision_Raycast(Vector2 start, Vector2 direction, float length);

#endif // TILE_COLLISION_H
