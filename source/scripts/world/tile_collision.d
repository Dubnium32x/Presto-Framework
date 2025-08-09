module world.tile_collision;

import std.algorithm : all;
import std.array : array;
import std.conv : to;
import std.string : startsWith;

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

    static TileHeightProfile getTileHeightProfile(int rawTileId, string layerName = "") {
        int actualTileId = getActualTileId(rawTileId);

        // Only tile IDs -1 and 0 are non-collidable
        if (actualTileId == -1 || actualTileId == 0)
            return TileHeightProfile.empty();

        // For semi-solid layers, all non-empty tiles are platforms
        bool isSemiSolidLayer = layerName.startsWith("SemiSolid");
        if (isSemiSolidLayer) {
            int[16] platformHeights;
            platformHeights[] = 15;
            return TileHeightProfile( platformHeights, false, true );
        }

        // Define specific tile types with special collision profiles
        // Note: Adjust these tile IDs based on your actual tileset
        if (actualTileId == 4) {
            // 45° slope rising from left to right (/)
            int[] heights = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
            return TileHeightProfile.custom(heights);
        } else if (actualTileId == 5) {
            // 45° slope rising from right to left (\)
            int[] heights = [15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0];
            return TileHeightProfile.custom(heights);
        } else if (actualTileId == 6) {
            // Gentle up-slope from left to right
            int[] heights = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7];
            return TileHeightProfile.custom(heights);
        } else if (actualTileId == 7) {
            // Gentle up-slope from right to left
            int[] heights = [7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 0];
            return TileHeightProfile.custom(heights);
        } else {
            // ALL other tile IDs (except -1 and 0) are collidable by default as solid blocks
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
}
