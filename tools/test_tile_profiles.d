import std.stdio : writeln, writefln;
import std.string : join;
import std.array : array;
import std.conv : to;

import world.tile_collision : TileHeightProfile, TileCollision;
import world.generated_heightmaps : TILESET_HEIGHTMAPS, TILESET_NAMES;
import world.tileset_map : TilesetInfo, normalizeTilesetName;
// Avoid importing the full level_loader (pulls in raylib). Provide minimal local helpers
// used only by this test harness.
struct TestLevelData {
    TilesetInfo[] tilesets;
    int[] sampleTileIds; // flat list of gids to precompute
    TileHeightProfile[string] tileProfiles;
}

// Precompute profiles for the tiles listed in sampleTileIds and store in tileProfiles keyed by "<raw>::<layer>"
void precomputeTileProfilesLocal(ref TestLevelData level, string layerName = "Ground_1") {
    foreach (gid; level.sampleTileIds) {
        TileHeightProfile p = TileCollision.getTileHeightProfile(gid, layerName, level.tilesets);
        string key = to!string(gid) ~ ":" ~ layerName;
        level.tileProfiles[key] = p;
    }
}

bool getPrecomputedTileProfileLocal(const TestLevelData level, int rawTileId, string layerName, out TileHeightProfile profile) {
    string key = to!string(rawTileId) ~ ":" ~ layerName;
    if (key in level.tileProfiles) {
        profile = level.tileProfiles[key];
        return true;
    }
    return false;
}

// Simple smoke-test harness for tile profiles and angles.
void main() {
    // Common firstgid offsets observed in LEVEL_0 (from Tiled JSON used previously).
    int[] firstgids = [1, 225, 449, 673, 897, 1121];

    // Build tileset info list from generated names.
    TilesetInfo[] tilesets;
    foreach (i, name; TILESET_NAMES) {
        TilesetInfo t;
        t.nameCandidates = [ normalizeTilesetName(name) ];
        // ensure firstgid is int
        t.firstgid = (i < firstgids.length) ? firstgids[i] : cast(int)(cast(int)i * 256 + 1);
        tilesets ~= t;
    }

    // Pick some sample tiles (take first, some middle, and last index from each tileset)
    writeln("Running tile profile smoke tests...");
    foreach (i, block; TILESET_HEIGHTMAPS) {
        auto blockLen = block.length;
        if (blockLen == 0) continue;
        int gidBase = tilesets[i].firstgid;
    int bl = cast(int)blockLen;
    int[] sampleLocal = [0, 1, bl / 2, bl - 1];
    // prepare a string list for printing
    string[] sampleLocalStr;
    foreach (s; sampleLocal) sampleLocalStr ~= s.to!string;
    writefln("\nTileset %s (firstgid=%s) has %s tiles; testing samples: %s", TILESET_NAMES[i], gidBase, blockLen, sampleLocalStr.join(", "));

    foreach (localIdx; sampleLocal) {
            if (localIdx < 0 || localIdx >= blockLen) continue;
            int gid = gidBase + localIdx;
            // Raw forms: base, hflip, vflip, dflip, combos
            int baseRaw = gid;
            int hRaw = cast(int)(gid | TileCollision.FLIPPED_HORIZONTALLY_FLAG);
            int vRaw = cast(int)(gid | TileCollision.FLIPPED_VERTICALLY_FLAG);
            int dRaw = cast(int)(gid | TileCollision.FLIPPED_DIAGONALLY_FLAG);
            int hdRaw = cast(int)(gid | (TileCollision.FLIPPED_HORIZONTALLY_FLAG | TileCollision.FLIPPED_DIAGONALLY_FLAG));
            int vdRaw = cast(int)(gid | (TileCollision.FLIPPED_VERTICALLY_FLAG | TileCollision.FLIPPED_DIAGONALLY_FLAG));
            int hvdRaw = cast(int)(gid | (TileCollision.FLIPPED_HORIZONTALLY_FLAG | TileCollision.FLIPPED_VERTICALLY_FLAG | TileCollision.FLIPPED_DIAGONALLY_FLAG));

            int[] variants = [baseRaw, hRaw, vRaw, dRaw, hdRaw, vdRaw, hvdRaw];
            // Prepare a minimal TestLevelData that contains the tiles so we can use precomputed profiles
            TestLevelData level;
            level.tilesets = tilesets;
            level.sampleTileIds = [];
            foreach (s; sampleLocal) {
                if (s >= 0 && s < blockLen) {
                    level.sampleTileIds ~= (gidBase + s);
                }
            }
            // Build precomputed profiles
            precomputeTileProfilesLocal(level, "Ground_1");

            foreach (raw; variants) {
                TileHeightProfile profile;
                bool usedPre = false;
                if (getPrecomputedTileProfileLocal(level, raw, "Ground_1", profile)) {
                    usedPre = true;
                } else {
                    profile = TileCollision.getTileHeightProfile(raw, "Ground_1", tilesets);
                }
                auto angle = TileCollision.getTileGroundAngle(raw, "Ground_1", tilesets);
                // format heights
                string[] hs;
                foreach (h; profile.groundHeights) hs ~= to!string(h);
                writefln("raw=0x%08X local=%3d variant -> angle=%6.2f deg heights=%s", raw, localIdx, angle, hs.join(","));
            }
        }
    }

    writeln("\nSmoke tests complete.");
}
