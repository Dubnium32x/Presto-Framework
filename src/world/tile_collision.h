// Tile Collision header
#ifndef TILE_COLLISION_H
#define TILE_COLLISION_H

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <math.h>
#include <stdio.h>
#include "../util/math_utils.h"
#include "raylib.h"
#include "tileset_map.h"
#include "generated_heightmaps.h"

// Tile flip flags
#define FLIPPED_HORIZONTALLY_FLAG 0x80000000
#define FLIPPED_VERTICALLY_FLAG   0x40000000
#define FLIPPED_DIAGONALLY_FLAG   0x20000000
#define FLIPPED_ALL_FLAGS_MASK (FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG)

// Debug flag for tile angles
#define DEBUG_TILE_ANGLE 1


typedef struct {
    int groundHeights[16];
    bool isSolidBlock;
    bool isPlatform;
    bool isSlope;
} TileHeightProfile;

// TileHeightProfile creation functions
TileHeightProfile TileHeightProfile_Empty(void);
TileHeightProfile TileHeightProfile_SolidBlock(void);
TileHeightProfile TileHeightProfile_Custom(const int* heights, bool platform);

// Tile collision functions
int TileCollision_GetActualTileId(int rawTileId);
bool TileCollision_IsEmptyTile(int tileId);
TileHeightProfile TileCollision_GetTileHeightProfile(int rawTileId, const char* layerName, TilesetInfo* tilesets, int tilesetCount);
bool TileCollision_IsSemiSolidTop(int rawTileId, int rawTileIdAbove, const char* layerName, TilesetInfo* tilesets, int tilesetCount);
float TileCollision_GetTileGroundAngle(int rawTileId, const char* layerName, TilesetInfo* tilesets, int tilesetCount);


#endif // TILE_COLLISION_H
