module world.tileset_map;

import std.algorithm : find;
import std.array : array;
import std.string : toLower, replace;
import std.path : baseName;

struct TilesetInfo {
    string[] nameCandidates; // normalized candidate names (basename, image name, tsx name, etc.)
    int firstgid;
}

// Normalize a tileset source/name to a form that matches generated tileset basenames
string normalizeTilesetName(string raw) {
    // Take basename if a path
    raw = baseName(raw);

    // Remove common TSX suffixes
    raw = raw.replace(".tsx", "");
    raw = raw.replace(".png", "");

    // Remove known extra suffixes used in exported tsx names
    raw = raw.replace("_flipped-table-16-16", "");
    raw = raw.replace("_flipped", "");
    raw = raw.replace("-flipped", "");

    // Lowercase for case-insensitive compare
    return raw.toLower();
}

// Given an array of TilesetInfo (sorted by firstgid asc), resolve a global gid to (tilesetName, localIndex)
bool resolveGlobalGid(int gid, TilesetInfo[] tilesets, out TilesetInfo chosen, out int localIndex) {
    chosen = TilesetInfo();
    if (gid <= 0) return false;
    // Find the tileset with highest firstgid <= gid
    int bestIdx = -1;
    foreach (i, ref t; tilesets) {
        // i is ulong; compare and assign to bestIdx as int
        if (t.firstgid <= gid) {
            if (bestIdx == -1 || t.firstgid > tilesets[bestIdx].firstgid) bestIdx = cast(int)i;
        }
    }
    if (bestIdx == -1) return false;
    chosen = tilesets[bestIdx];
    localIndex = gid - chosen.firstgid; // zero-based local index
    return true;
}
