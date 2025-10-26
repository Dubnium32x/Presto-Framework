// Level loader header
#ifndef LEVEL_LOADER_H
#define LEVEL_LOADER_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include "raylib.h"
#include "globals.h"
#include "csv_loader.h"
#include "../world/tileset_map.h"
#include "../world/tile_collision.h"
#include "../world/generated_heightmaps.h"

extern bool levelInitialized;

typedef struct {
    int tileId;
    //int collisionId
    bool isSolid;
    bool isPlatform;
    bool isHazard;
    uint8_t flipFlags;
} Tile;

typedef struct {
    int objectId;
    float x, y;
    int objectType;
    int propertiesCount;
    char** properties;
} LevelObject;

typedef struct {
    char* levelName;
    int width;
    int height;
    
    // Multiple tile layers
    Tile** groundLayer1;
    Tile** groundLayer2;
    Tile** groundLayer3;
    Tile** semiSolidLayer1;
    Tile** semiSolidLayer2;
    Tile** semiSolidLayer3;
    Tile** collisionLayer;
    Tile** hazardLayer;
    
    // Object data
    LevelObject* objects;
    int objectCount;
    
    // Level metadata
    Vector2 playerSpawnPoint;
    char* tilesetName;
    Color backgroundColor;
    int timeLimit;
    
    // Tilesets and collision data
    TilesetInfo* tilesets;
    int tilesetCount;
    int firstgid; // from TMX tileset, default 1
    
    // Precomputed collision profiles (hash map simulation)
    char** profileKeys;
    TileHeightProfile* profileValues;
    int profileCount;
    int profileCapacity;
} LevelData;


extern LevelData currentLevel;

// Core loading functions
LevelData LoadCompleteLevel(const char* levelPath);
LevelData LoadCompleteLevelWithFormat(const char* levelPath, bool useJSON);
LevelData LoadLevelMetadata(const char* metadataPath);

// Layer and object loading
// Loads a CSV tile layer. Returns a height x width 2D array of Tiles.
// If outWidth/outHeight are provided, they're set to the parsed dimensions.
Tile** LoadTileLayer(const char* csvPath, int* outWidth, int* outHeight);
LevelObject* LoadLevelObjects(const char* csvPath, int* outCount);

// Utility functions
void CalculateLevelDimensions(LevelData* level);
Tile GetTileAtPosition(Tile** layer, int x, int y, int width, int height);
bool IsSolidAtPosition(const LevelData* level, float worldX, float worldY, int tileSize);
bool IsTileSolidAtLocalPosition(int tileId, float worldX, float worldY, int tileX, int tileY, 
                               int tileSize, const char* layerName, const LevelData* level);

// Tile creation helpers
Tile CreateEmptyTile(void);
Tile CreateTileFromId(int tileId);

// Profile management
void PrecomputeTileProfiles(LevelData* level);
bool GetPrecomputedTileProfile(const LevelData* level, int rawTileId, const char* layerName, TileHeightProfile* outProfile);

// Layer management
Tile** GetLayerByName(LevelData* level, const char* layerName);
Tile** InitializeLayer(int width, int height);

// Memory management
void FreeLevelData(LevelData* level);

#endif // LEVEL_LOADER_H