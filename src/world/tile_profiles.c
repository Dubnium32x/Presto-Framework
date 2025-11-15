// Tile profiles container and simple precompute stub
#include "tile_collision.h"
#include "generated_tile_angles.h"
#include "../util/level_loader.h"

// Provide a simple TileProfiles array so other modules can query basic info.
// This is a minimal implementation: groundHeight/groundWidth are left as 0.
// A more complete precompute can be implemented later to extract values from
// generated height/width maps.

TileProfile TileProfiles[TILESET_TILE_COUNT];

void PrecomputeTileProfiles(LevelData* level) {
    (void)level; // currently unused
    for (int i = 0; i < TILESET_TILE_COUNT; ++i) {
        TileProfiles[i].tileID = i;
        TileProfiles[i].groundHeight = 0;
        TileProfiles[i].groundWidth = 0;
        TileProfiles[i].groundAngle = GetTileAngle(i);
    }
}
