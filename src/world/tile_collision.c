// Tile Collision implementation
#include "tile_collision.h"

// Tile collision functions
int TileCollision_GetActualTileId(int rawTileId) {
    return rawTileId & ~FLIPPED_ALL_FLAGS_MASK;
}

bool TileCollision_IsEmptyTile(int tileId) {
    return tileId == -1 || TileCollision_GetActualTileId(tileId) == 0;
}

int* TileCollision_GetHWMap(int tileId, const char* layerName, bool isWidth) {
    bool isSemiSolidLayer = (layerName != NULL && strncmp(layerName, "SemiSolid", 9) == 0);

    if( isWidth ) {
        if (isSemiSolidLayer) {
            return GetPrecomputedSemiSolidHeightmap(tileId);
        } else {
            return GetPrecomputedSolidHeightmap(tileId);
        }
    }
    else{
        if (isSemiSolidLayer) {
            return GetPrecomputedSemiSolidHeightmap(tileId);
        } else {
            return GetPrecomputedSolidHeightmap(tileId);
        }
    }
}

bool TileCollision_IsSemiSolidTop(int rawTileId, int rawTileIdAbove, const char* layerName, TilesetInfo* tilesets, int tilesetCount) {
    (void)tilesets; (void)tilesetCount; // Unused parameters
    bool isSemiSolidLayer = (layerName != NULL && strncmp(layerName, "SemiSolid", 9) == 0);

    if (!isSemiSolidLayer)
        return false;

    int actualTileId = TileCollision_GetActualTileId(rawTileId);
    if (actualTileId == -1 || actualTileId == 0)
        return false;
    int actualTileIdAbove = TileCollision_GetActualTileId(rawTileIdAbove);
    if (actualTileIdAbove != 0)
        return false;

    return !TileCollision_IsEmptyTile(actualTileId) && TileCollision_IsEmptyTile(actualTileIdAbove);
}

float TileCollision_GetTileGroundAngle(int rawTileId, const char* layerName, TilesetInfo* tilesets, int tilesetCount) {
    // Debug specific tiles that cause problems
    bool debugThis = (rawTileId == 221);
    if (debugThis) printf("[DEBUG 221] getTileGroundAngle called for rawTileId=%d\n", rawTileId);
    
    // For now, we'll skip caching and compute directly
    // In the future, a hash table could be implemented for caching
    
    TileHeightProfile profile = TileCollision_GetTileHeightProfile(rawTileId, layerName, tilesets, tilesetCount);
    
    // Empty or fully solid or platform tiles -> angle 0
    if (profile.isPlatform || profile.isSolidBlock) {
        if (DEBUG_TILE_ANGLE) printf("TileAngleDbg: profile isPlatform=%d isSolidBlock=%d raw=%d\n", profile.isPlatform, profile.isSolidBlock, rawTileId);
        return 0.0f;
    }

    // Prepare x, y data: x = 0..15, y = heights (use double for precision)
    if (debugThis) printf("[DEBUG 221] Computing angle from height profile\n");
    
    double sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
    for (int i = 0; i < 16; i++) {
        double x = (double)i;
        double y = (double)profile.groundHeights[i];
        if (debugThis && i < 4) printf("[DEBUG 221] Height[%d]=%f\n", i, y);
        sx += x;
        sy += y;
        sxx += x * x;
        sxy += x * y;
    }
    
    double n = 16.0;
    double denom = (n * sxx - sx * sx);
    double slope = 0.0;
    if (denom != 0.0) slope = (n * sxy - sx * sy) / denom;
    
    if (debugThis) {
        printf("[DEBUG 221] sx=%f sy=%f sxx=%f sxy=%f\n", sx, sy, sxx, sxy);
        printf("[DEBUG 221] denom=%f slope=%f\n", denom, slope);
    }

    double angleRad = atan(slope);
    double angleDeg = angleRad * 180.0 / PI;
    float angleF = (float)angleDeg;
    
    if (debugThis) {
        printf("[DEBUG 221] angleRad=%f angleDeg=%f angleF=%f\n", angleRad, angleDeg, angleF);
    }
    
    // Safety check: ensure we never return NaN
    if (isnan(angleF) || isnan(slope)) {
        printf("[ERROR] TileAngle: NaN detected! rawTileId=%d slope=%f angleF=%f\n", rawTileId, slope, angleF);
        printf("[ERROR] Heights: ");
        for (int i = 0; i < 16; i++) printf("%d ", profile.groundHeights[i]);
        printf("\n");
        printf("[ERROR] Stats: sx=%f sy=%f sxx=%f sxy=%f denom=%f\n", sx, sy, sxx, sxy, denom);
        angleF = 0.0f; // Safe fallback
    }
    
    if (debugThis) {
        printf("[DEBUG 221] Final angle after safety check=%f\n", angleF);
    }
    
    if (DEBUG_TILE_ANGLE) {
        printf("TileAngleDbg: computed angle -> raw=%d layer=%s slope=%f deg=%f heights=[%d,%d,%d,...]\n", 
            rawTileId, layerName ? layerName : "", slope, angleF, 
            profile.groundHeights[0], profile.groundHeights[1], profile.groundHeights[2]);
        printf("TileAngleDbg heights full: ");
        for (int i = 0; i < 16; i++) printf("%d ", profile.groundHeights[i]);
        printf("\n");
    }
    
    return angleF;
}