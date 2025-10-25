// Tile Collision implementation
#include "tile_collision.h"

// TileHeightProfile creation functions
TileHeightProfile TileHeightProfile_Empty(void) {
    TileHeightProfile profile;
    for (int i = 0; i < 16; i++) {
        profile.groundHeights[i] = 0;
    }
    profile.isSolidBlock = false;
    profile.isPlatform = false;
    profile.isSlope = false;
    return profile;
}

TileHeightProfile TileHeightProfile_SolidBlock(void) {
    TileHeightProfile profile;
    for (int i = 0; i < 16; i++) {
        profile.groundHeights[i] = 16;
    }
    profile.isSolidBlock = true;
    profile.isPlatform = false;
    profile.isSlope = false;
    return profile;
}

TileHeightProfile TileHeightProfile_Custom(const int* heights, bool platform) {
    TileHeightProfile profile;
    for (int i = 0; i < 16; i++) {
        profile.groundHeights[i] = heights[i];
    }
    profile.isSolidBlock = false;
    profile.isPlatform = platform;
    profile.isSlope = true;
    return profile;
}

// Tile collision functions
int TileCollision_GetActualTileId(int rawTileId) {
    return rawTileId & ~FLIPPED_ALL_FLAGS_MASK;
}

bool TileCollision_IsEmptyTile(int tileId) {
    return tileId == -1 || TileCollision_GetActualTileId(tileId) == 0;
}

// HitboxRotation definition : 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270° - Birb64 u_int8_t HitboxRotation
TileHeightProfile TileCollision_GetTileHeightProfile(int rawTileId, const char* layerName, TilesetInfo* tilesets, int tilesetCount) {
    int actualTileId = TileCollision_GetActualTileId(rawTileId);

    // Only tile IDs -1 and 0 are non-collidable
    if (actualTileId == -1 || actualTileId == 0)
        return TileHeightProfile_Empty();

    // For semi-solid layers, use runtime collision based on actual tile graphics instead of treating all as platforms
    bool isSemiSolidLayer = false;
    if (layerName) {
        isSemiSolidLayer = (
            strncmp(layerName, "SemiSolid", 9) == 0 ||
            strcmp(layerName, "SemiSolid_1") == 0 ||
            strcmp(layerName, "SemiSolid_2") == 0
        );
    }
    // Layer type checking (variables removed as they're currently unused)
    // bool isGroundLayer, isObjectsLayer, isCollisionLayer can be added when needed
    if (isSemiSolidLayer) {
        // Fall through to use tileset-based collision or 16x16 fallback
        // Don't return early - let the system analyze the actual tile graphics
    }

    // If tileset info was provided, try to resolve generated heightmaps first
    if (tilesets != NULL && tilesetCount > 0) {
        TilesetInfo chosenInfo;
        int localIndex;
        bool resolved = ResolveGlobalGid(actualTileId, tilesets, tilesetCount, &chosenInfo, &localIndex);
        
        if (resolved) {
            // For our simple implementation, check if any candidate matches our tileset name
            const char** candidate = chosenInfo.nameCandidates;
            while (candidate && *candidate) {
                if (strcmp(*candidate, TILESET_NAME) == 0) {
                    // Use our generated heightmaps
                    if (localIndex >= 0 && localIndex < TILESET_TILE_COUNT) {
                        const int* heights = TILESET_HEIGHTMAPS[localIndex];
                        
                        // Handle tile flipping at runtime
                        bool hadHFlip = (rawTileId & FLIPPED_HORIZONTALLY_FLAG) != 0;
                        bool hadVFlip = (rawTileId & FLIPPED_VERTICALLY_FLAG) != 0;
                        bool hadDFlip = (rawTileId & FLIPPED_DIAGONALLY_FLAG) != 0;
                        
                        if (!hadHFlip && !hadVFlip && !hadDFlip) {
                            // No flipping, use heights directly
                            return TileHeightProfile_Custom(heights, false);
                        } else {
                            // Apply transformations for flipped tiles
                            int src[16];
                            for (int i = 0; i < 16; i++) {
                                int val = heights[i];
                                if (val < 0) val = 0;
                                if (val > 16) val = 16;
                                src[i] = val;
                            }

                            // Convert to occupancy grid for transformation
                            bool occ[16][16]; // occ[y][x]
                            for (int x = 0; x < 16; x++) {
                                for (int y = 0; y < 16; y++) {
                                    occ[y][x] = (y < src[x]);
                                }
                            }

                            bool hFlip = hadHFlip;
                            bool vFlip = hadVFlip;
                            bool dFlip = hadDFlip;

                            if (dFlip) {
                                // Transpose
                                bool occT[16][16];
                                for (int y = 0; y < 16; y++) {
                                    for (int x = 0; x < 16; x++) {
                                        occT[y][x] = occ[x][y];
                                    }
                                }
                                memcpy(occ, occT, sizeof(occ));
                                // Swap h and v flip flags
                                bool tmp = hFlip;
                                hFlip = vFlip;
                                vFlip = tmp;
                            }

                            if (hFlip) {
                                // Horizontal flip
                                bool occH[16][16];
                                for (int y = 0; y < 16; y++) {
                                    for (int x = 0; x < 16; x++) {
                                        occH[y][x] = occ[y][15 - x];
                                    }
                                }
                                memcpy(occ, occH, sizeof(occ));
                            }

                            if (vFlip) {
                                // Vertical flip
                                bool occV[16][16];
                                for (int y = 0; y < 16; y++) {
                                    for (int x = 0; x < 16; x++) {
                                        occV[y][x] = occ[15 - y][x];
                                    }
                                }
                                memcpy(occ, occV, sizeof(occ));
                            }

                            // Convert back to heights
                            int outHeights[16];
                            for (int x = 0; x < 16; x++) {
                                int cnt = 0;
                                for (int y = 0; y < 16; y++) {
                                    if (occ[y][x]) cnt += 1;
                                }
                                if (cnt < 0) cnt = 0;
                                if (cnt > 16) cnt = 16;
                                outHeights[x] = cnt;
                            }

                            return TileHeightProfile_Custom(outHeights, false);
                        }
                    }
                    break;
                }
                candidate++;
            }
        }
    }

    // Fallback heuristics and explicit mappings below
    // Define specific tile types with special collision profiles
    if (actualTileId == 4) {
        int heights[16] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
        return TileHeightProfile_Custom(heights, false);
    } else if (actualTileId == 5) {
        int heights[16] = {15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0};
        return TileHeightProfile_Custom(heights, false);
    } else if (actualTileId == 6) {
        int heights[16] = {0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7};
        return TileHeightProfile_Custom(heights, false);
    } else if (actualTileId == 7) {
        int heights[16] = {7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 0};
        return TileHeightProfile_Custom(heights, false);
    } else {
        return TileHeightProfile_SolidBlock();
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