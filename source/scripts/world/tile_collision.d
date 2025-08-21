module world.tile_collision;

import std.algorithm : all;
import std.array : array;
import std.conv : to;
import std.string : startsWith;
import std.math : atan, PI;
import std.stdio : writeln, writefln;
import world.generated_heightmaps : TILESET_HEIGHTMAPS, TILESET_NAMES, TILESET_GROUND_ANGLES, TILESET_HEIGHTMAPS_VARIANTS, TILESET_GROUND_ANGLES_VARIANTS;
import world.tileset_map;

struct TileHeightProfile {
    int[16] groundHeights;
    bool isFullySolidBlock;
    bool isPlatform;

    static TileHeightProfile empty() {
        TileHeightProfile profile;
        profile.groundHeights[] = -1;
        profile.isFullySolidBlock = false;
        profile.isPlatform = false;
        return profile;
    }

    static TileHeightProfile solidBlock() {
        TileHeightProfile profile;
        profile.groundHeights[] = 15;
        profile.isFullySolidBlock = true;
        profile.isPlatform = false;
        return profile;
    }

    static TileHeightProfile custom(int[] heights, bool platform = false) {
        TileHeightProfile profile;
        foreach (i, h; heights)
            profile.groundHeights[i] = h;
        profile.isPlatform = platform;
        profile.isFullySolidBlock = heights.all!(h => h == 15);
        return profile;
    }
}

struct TileCollision {
    // Tile flip constants
    enum FLIPPED_HORIZONTALLY_FLAG = 0x8000_0000;
    enum FLIPPED_VERTICALLY_FLAG   = 0x4000_0000;
    enum FLIPPED_DIAGONALLY_FLAG   = 0x2000_0000;
    enum FLIPPED_ALL_FLAGS_MASK    = FLIPPED_HORIZONTALLY_FLAG
                                   | FLIPPED_VERTICALLY_FLAG
                                   | FLIPPED_DIAGONALLY_FLAG;

    static int getActualTileId(int rawTileId) {
        if (rawTileId == -1) return -1;
        return rawTileId & ~FLIPPED_ALL_FLAGS_MASK;
    }

    static bool isEmptyTile(int tileId) {
        return tileId == -1 || tileId == 0;
    }

    // Note: Optionally accepts a LevelData reference in future to access tilesets; for now we'll expect callers to pass normalized context
    static TileHeightProfile getTileHeightProfile(int rawTileId, string layerName = "", world.tileset_map.TilesetInfo[] tilesets = null) {
        int actualTileId = getActualTileId(rawTileId);

        // Only tile IDs -1 and 0 are non-collidable
        if (actualTileId == -1 || actualTileId == 0)
            return TileHeightProfile.empty();

        // For semi-solid layers, all non-empty tiles are platforms
        bool isSemiSolidLayer = layerName.startsWith("SemiSolid");
        if (isSemiSolidLayer) {
            int[16] platformHeights;
            platformHeights[] = 15;
            return TileHeightProfile.custom(platformHeights, true);
        }

        // If tileset info was provided, try to resolve generated heightmaps first
        if (tilesets !is null && tilesets.length > 0) {
            world.tileset_map.TilesetInfo chosenInfo;
            int localIndex;
            if (world.tileset_map.resolveGlobalGid(actualTileId, tilesets, chosenInfo, localIndex)) {
                // Try each candidate name in the chosen tileset against generated names
                foreach (candidate; chosenInfo.nameCandidates) {
                    string candNorm = candidate; // already normalized in loader
                    int idx = -1;
                    foreach (i, n; TILESET_NAMES) {
                        string genNorm = world.tileset_map.normalizeTilesetName(n);
                        if (genNorm == candNorm) { idx = cast(int)i; break; }
                    }
                    if (idx != -1) {
                        // If rawTileId includes flip bits, prefer precomputed variant tables if available
                        bool hadHFlip = (rawTileId & TileCollision.FLIPPED_HORIZONTALLY_FLAG) != 0;
                        bool hadVFlip = (rawTileId & TileCollision.FLIPPED_VERTICALLY_FLAG) != 0;
                        bool hadDFlip = (rawTileId & TileCollision.FLIPPED_DIAGONALLY_FLAG) != 0;
                        int variantIdx = 0;
                        if (hadHFlip) variantIdx |= 1;
                        if (hadVFlip) variantIdx |= 2;
                        if (hadDFlip) variantIdx |= 4;

                        // If variant tables exist and in-bounds, read directly
                        if (idx >= 0 && idx < TILESET_HEIGHTMAPS_VARIANTS.length) {
                            auto varBlock = TILESET_HEIGHTMAPS_VARIANTS[idx]; // [variantIdx][tileIdx][cols]
                            if (variantIdx >= 0 && variantIdx < varBlock.length) {
                                auto tilesForVariant = varBlock[variantIdx];
                                if (localIndex >= 0 && localIndex < tilesForVariant.length) {
                                    int[] heights = tilesForVariant[localIndex];
                                    // normalize/clamp
                                    int[] outHeights = new int[](16);
                                    foreach (i; 0 .. 16) {
                                        int val = i < heights.length ? heights[i] : 0;
                                        if (val < 0) val = 0;
                                        if (val > 16) val = 16;
                                        outHeights[i] = val;
                                    }
                                    return TileHeightProfile.custom(outHeights[], false);
                                }
                            }
                        }

                        // Fall back to original behavior: read base block and transform at runtime
                        auto block = TILESET_HEIGHTMAPS[idx];
                        if (localIndex >= 0 && localIndex < block.length) {
                            int[] heights = block[localIndex];
                            // original transform logic follows (unchanged)
                            bool hFlip = hadHFlip;
                            bool vFlip = hadVFlip;
                            bool dFlip = hadDFlip;

                            int[16] src;
                            foreach (i; 0 .. 16) {
                                int val = i < heights.length ? heights[i] : 0;
                                if (val < 0) val = 0;
                                if (val > 16) val = 16;
                                src[i] = val;
                            }

                            bool[16][16] occ; // occ[y][x]
                            foreach (x; 0 .. 16) {
                                foreach (y; 0 .. 16) {
                                    occ[y][x] = (y < src[x]);
                                }
                            }

                            if (dFlip) {
                                bool[16][16] occT;
                                foreach (y; 0 .. 16) {
                                    foreach (x; 0 .. 16) {
                                        occT[y][x] = occ[x][y];
                                    }
                                }
                                occ = occT;
                                bool tmp = hFlip;
                                hFlip = vFlip;
                                vFlip = tmp;
                            }

                            if (hFlip) {
                                bool[16][16] occH;
                                foreach (y; 0 .. 16) {
                                    foreach (x; 0 .. 16) {
                                        occH[y][x] = occ[y][15 - x];
                                    }
                                }
                                occ = occH;
                            }

                            if (vFlip) {
                                bool[16][16] occV;
                                foreach (y; 0 .. 16) {
                                    foreach (x; 0 .. 16) {
                                        occV[y][x] = occ[15 - y][x];
                                    }
                                }
                                occ = occV;
                            }

                            int[] outHeights = new int[](16);
                            foreach (x; 0 .. 16) {
                                int cnt = 0;
                                foreach (y; 0 .. 16) {
                                    if (occ[y][x]) cnt += 1;
                                }
                                if (cnt < 0) cnt = 0;
                                if (cnt > 16) cnt = 16;
                                outHeights[x] = cnt;
                            }

                            return TileHeightProfile.custom(outHeights[], false);
                        }
                    }
                }
            }
        }

        // Fallback heuristics and explicit mappings below
        // Define specific tile types with special collision profiles
        if (actualTileId == 4) {
            int[] heights = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
            return TileHeightProfile.custom(heights);
        } else if (actualTileId == 5) {
            int[] heights = [15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0];
            return TileHeightProfile.custom(heights);
        } else if (actualTileId == 6) {
            int[] heights = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7];
            return TileHeightProfile.custom(heights);
        } else if (actualTileId == 7) {
            int[] heights = [7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 0];
            return TileHeightProfile.custom(heights);
        } else {
            return TileHeightProfile.solidBlock();
        }
    }

    static bool isSemiSolidTop(int rawTileId, int rawTileIdAbove, string layerName) {
        bool isSemiSolidLayer = (layerName.length >= 9 && layerName[0 .. 9] == "SemiSolid");
        if (!isSemiSolidLayer) return false;

        int actualTileId = getActualTileId(rawTileId);
        int actualTileIdAbove = getActualTileId(rawTileIdAbove);

        // If the current tile is not empty and the one above is empty, it's a semi-solid top
        return !isEmptyTile(actualTileId) && isEmptyTile(actualTileIdAbove);
    }

    // Compute a ground angle (degrees) for a tile's height profile.
    // Angle is computed by fitting a line to column heights (y per x) using
    // least-squares and returning atan(slope) in degrees. Results are cached per rawTileId.
    private static float[int] groundAngleCache;
    enum bool DEBUG_TILE_ANGLE = true; // set true to enable verbose tile-angle debug prints

    static float getTileGroundAngle(int rawTileId, string layerName = "", world.tileset_map.TilesetInfo[] tilesets = null) {
        // Use rawTileId as cache key (includes flip bits so flipped variants are cached separately)
        float cached;
        if (groundAngleCache.get(rawTileId, cached)) return cached;

        // If tilesets provided and the tile has no flip bits, prefer precomputed angle
        int actualTileId = getActualTileId(rawTileId);
        if (tilesets !is null && tilesets.length > 0 && actualTileId == rawTileId) {
            world.tileset_map.TilesetInfo chosenInfo;
            int localIndex;
            if (world.tileset_map.resolveGlobalGid(actualTileId, tilesets, chosenInfo, localIndex)) {
                foreach (candidate; chosenInfo.nameCandidates) {
                    string candNorm = candidate;
                    int idx = -1;
                    foreach (i, n; TILESET_NAMES) {
                        string genNorm = world.tileset_map.normalizeTilesetName(n);
                        if (genNorm == candNorm) { idx = cast(int)i; break; }
                    }
                            if (idx != -1) {
                        // If rawTileId includes flips, try the variant angle table first
                        bool hadHFlip = (rawTileId & TileCollision.FLIPPED_HORIZONTALLY_FLAG) != 0;
                        bool hadVFlip = (rawTileId & TileCollision.FLIPPED_VERTICALLY_FLAG) != 0;
                        bool hadDFlip = (rawTileId & TileCollision.FLIPPED_DIAGONALLY_FLAG) != 0;
                        int variantIdx = 0;
                        if (hadHFlip) variantIdx |= 1;
                        if (hadVFlip) variantIdx |= 2;
                        if (hadDFlip) variantIdx |= 4;

                        if (idx >= 0 && idx < TILESET_GROUND_ANGLES_VARIANTS.length) {
                            auto varAngBlock = TILESET_GROUND_ANGLES_VARIANTS[idx]; // [variantIdx][tileIdx]
                            if (variantIdx >= 0 && variantIdx < varAngBlock.length) {
                                auto angList = varAngBlock[variantIdx];
                                if (localIndex >= 0 && localIndex < angList.length) {
                                    float angleF = cast(float)angList[localIndex];
                                    if (DEBUG_TILE_ANGLE) writeln("TileAngleDbg: variant table hit -> tilesetIdx=", idx, " variant=", variantIdx, " localIndex=", localIndex, " raw=", rawTileId, " angle=", angleF);
                                    groundAngleCache[rawTileId] = angleF;
                                    return angleF;
                                }
                            }
                        }

                        // Fall back to original per-tile angle if variant not present
                        if (idx >= 0 && idx < TILESET_GROUND_ANGLES.length) {
                            auto angBlock = TILESET_GROUND_ANGLES[idx];
                            if (localIndex >= 0 && localIndex < angBlock.length) {
                                float angleF = cast(float)angBlock[localIndex];
                                if (DEBUG_TILE_ANGLE) writeln("TileAngleDbg: base table hit -> tilesetIdx=", idx, " localIndex=", localIndex, " raw=", rawTileId, " angle=", angleF);
                                groundAngleCache[rawTileId] = angleF;
                                return angleF;
                            }
                        }
                    }
                }
            }
        }

        auto profile = getTileHeightProfile(rawTileId, layerName, tilesets);
        // Empty or fully solid or platform tiles -> angle 0
        if (profile.isPlatform || profile.isFullySolidBlock) {
            if (DEBUG_TILE_ANGLE) writeln("TileAngleDbg: profile isPlatform=", profile.isPlatform, " isFullySolid=", profile.isFullySolidBlock, " raw=", rawTileId);
            groundAngleCache[rawTileId] = 0.0f;
            return 0.0f;
        }

        // Prepare x, y data: x = 0..15, y = heights (use double for precision)
        double sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
        foreach (i; 0 .. 16) {
            double x = cast(double)i;
            double y = cast(double)profile.groundHeights[i];
            sx += x;
            sy += y;
            sxx += x * x;
            sxy += x * y;
        }
        double n = 16.0;
        double denom = (n * sxx - sx * sx);
        double slope = 0.0;
        if (denom != 0.0) slope = (n * sxy - sx * sy) / denom;

    double angleRad = atan(slope);
    double angleDeg = angleRad * 180.0 / PI;
    float angleF = cast(float)angleDeg;
        if (DEBUG_TILE_ANGLE) {
            writeln("TileAngleDbg: computed angle -> raw=", rawTileId, " slope=", slope, " deg=", angleF, " heights=[", profile.groundHeights[0], ",", profile.groundHeights[1], ",", profile.groundHeights[2], ",...]");
            // print full heights for deeper inspection
            writefln("TileAngleDbg heights full: %s", profile.groundHeights[]);
        }
    groundAngleCache[rawTileId] = angleF;
    return angleF;
    }
}
