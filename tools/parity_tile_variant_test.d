module main;

import std.stdio;
import std.conv;
import std.math;
import std.array;
import std.random;

import world.generated_heightmaps : TILESET_HEIGHTMAPS, TILESET_HEIGHTMAPS_VARIANTS, TILESET_NAMES;
import world.tile_collision : TileCollision, TileHeightProfile;
import world.tileset_map : TilesetInfo, normalizeTilesetName, resolveGlobalGid;

// Parity test: For each tileset and each tile, for each variant (0..7),
// compare the generator-provided variant heightmap with the runtime transform of the base heightmap.

void main() {
    writeln("Running parity test for generated variant tables vs runtime transform...");
    int totalMismatch = 0;

    foreach (tidx, name; TILESET_NAMES) {
        string norm = normalizeTilesetName(name);
        writeln("Testing tileset [", tidx, "] name=", name, " (", norm, ")");
        auto baseBlock = TILESET_HEIGHTMAPS[tidx];
        auto varBlock = (tidx < TILESET_HEIGHTMAPS_VARIANTS.length) ? TILESET_HEIGHTMAPS_VARIANTS[tidx] : null;
        if (baseBlock.length == 0) continue;
        size_t tiles = baseBlock.length;
        foreach (size_t tileIdx; 0 .. tiles) {
            int[] base = baseBlock[tileIdx];
            // build occupancy grid from base
            bool[16][16] occ;
            foreach (x; 0 .. 16) {
                int val = x < base.length ? base[x] : 0;
                if (val < 0) val = 0;
                if (val > 16) val = 16;
                foreach (y; 0 .. 16) {
                    occ[y][x] = (y < val);
                }
            }

            foreach (variant; 0 .. 8) {
                int[] transformed = new int[](16);
                // apply dFlip (bit 2) => transpose
                bool h = (variant & 1) != 0;
                bool v = (variant & 2) != 0;
                bool d = (variant & 4) != 0;
                bool[16][16] occ2;
                occ2 = occ;
                if (d) {
                    bool[16][16] occT;
                    foreach (y; 0 .. 16) foreach (x; 0 .. 16) occT[y][x] = occ2[x][y];
                    occ2 = occT;
                    bool tmp = h; h = v; v = tmp;
                }
                if (h) {
                    bool[16][16] occH;
                    foreach (y; 0 .. 16) foreach (x; 0 .. 16) occH[y][x] = occ2[y][15-x];
                    occ2 = occH;
                }
                if (v) {
                    bool[16][16] occV;
                    foreach (y; 0 .. 16) foreach (x; 0 .. 16) occV[y][x] = occ2[15-y][x];
                    occ2 = occV;
                }
                foreach (x; 0 .. 16) {
                    int cnt = 0;
                    foreach (y; 0 .. 16) if (occ2[y][x]) cnt += 1;
                    transformed[x] = cnt;
                }

                // If generator variant exists, compare
                if (varBlock !is null && variant < varBlock.length) {
                    auto genTiles = varBlock[variant];
                    if (tileIdx < genTiles.length) {
                        int[] gen = genTiles[tileIdx];
                        bool eq = true;
                        foreach (i; 0 .. 16) if (gen[i] != transformed[i]) { eq = false; break; }
                        if (!eq) {
                            totalMismatch++;
                            writeln("Mismatch tileset=", name, " tile=", tileIdx, " variant=", variant);
                            writeln("  transformed=", transformed);
                            writeln("  generated  =", gen);
                        }
                    } else {
                        // missing tile in generator variant block
                        totalMismatch++;
                        writeln("Generator missing tile entry: tileset=", name, " tile=", tileIdx, " variant=", variant);
                    }
                }
            }
        }
    }

    if (totalMismatch == 0) writeln("Parity test passed: all variants match runtime transforms.");
    else writeln("Parity test found mismatches: ", totalMismatch);
}
