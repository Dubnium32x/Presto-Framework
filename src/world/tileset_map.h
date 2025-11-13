// Tileset map header
#pragma once
#include <stdint.h>
#include <stdbool.h>

// Tile structure
typedef struct {
    const char** nameCandidates;
    int firstgid;
} TilesetInfo;

// Function declarations
const char* NormalizeTileSetName(const char* raw);
bool ResolveGlobalGid(int gid, TilesetInfo* tilesets, int tilesetCount, TilesetInfo* chosen, int* localIndex);
bool IsTilesetNameMatch(const char* name, TilesetInfo* tileset);
bool FindTilesetByName(const char* name, TilesetInfo* tilesets, int tilesetCount, TilesetInfo* found);
