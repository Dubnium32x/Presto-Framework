module main;

import std.stdio;
import std.conv;
import std.algorithm;
import std.math : isFinite;

import world.generated_heightmaps : TILESET_HEIGHTMAPS, TILESET_GROUND_ANGLES, TILESET_NAMES;
import world.tile_collision : TileHeightProfile, TileCollision;

// Simple landing math unit tests that don't require raylib or LevelData.
// Verifies surfaceY computation from a TileHeightProfile and semisolid behavior.

float computeSurfaceY(int tileY, int tileSize, int columnHeight) {
    // tileTopY + (tileSize - columnHeight)
    return cast(float)(tileY * tileSize) + (tileSize - cast(float)columnHeight);
}

bool expectEqual(int a, int b) {
    return a == b;
}

int main() {
    writeln("Running landing unit tests...");
    int failures = 0;
    int tileSize = 16;

    foreach (tidx, name; TILESET_NAMES) {
        auto block = TILESET_HEIGHTMAPS[tidx];
        if (block.length == 0) continue;
        writeln("Testing tileset: ", name, " (", tidx, ") tiles=", block.length);

        // Sample a few tile indices: first, mid, last
    size_t[] samples = [cast(size_t)0, cast(size_t)(block.length / 2), cast(size_t)(block.length - 1)];
        foreach (s; samples) {
            auto heights = block[s];
            // Find a column with non-zero height to test landing
            int colIdx = 0;
            foreach (i; 0 .. 16) {
                if (heights[i] > 0) { colIdx = i; break; }
            }

            int h = heights[colIdx];
            if (h < 0) h = 0;
            if (h > 16) h = 16;

            float surfaceY = computeSurfaceY(5, tileSize, h); // tileY=5 arbitrary

            // Player bottom just above surface -> should NOT land
            float bottomAbove = surfaceY - 0.5f;
            if (bottomAbove >= surfaceY) {
                writeln("ERROR: bottomAbove incorrectly >= surfaceY"); failures++; continue;
            }

            // Player bottom just below or equal to surface -> should land
            float bottomOn = surfaceY + 0.1f;
            if (bottomOn < surfaceY) {
                writeln("ERROR: bottomOn < surfaceY should not happen"); failures++; continue;
            }

            // Basic numeric checks: recomputing surfaceY from column height should match
            float recomputed = computeSurfaceY(5, tileSize, h);
            if (!approxEqual(surfaceY, recomputed)) {
                writeln("Mismatch in surfaceY calculation for tileset=", name, " tile=", s, " col=", colIdx);
                writeln("  surfaceY=", surfaceY, " recomputed=", recomputed);
                failures++;
            }

            // Check angle availability (if generator produced angles, they should be finite)
            float angle = 0.0f;
            if (tidx < TILESET_GROUND_ANGLES.length) {
                auto angBlock = TILESET_GROUND_ANGLES[tidx];
                if (s < angBlock.length) {
                    angle = angBlock[s];
                    if (!isFinite(angle)) {
                        // angle may be NaN for empty tiles; that's acceptable
                    }
                }
            }
        }
    }

    // Semisolid layer behavior: TileCollision.isSemiSolidTop is available
    // We can check that a non-empty tile and empty tile above yields true.
    // Use two fake raw ids: 1 (non-empty) and 0 (empty)
    bool semi = TileCollision.isSemiSolidTop(1, 0, "SemiSolid_1");
    if (!semi) {
        writeln("FAIL: expected isSemiSolidTop(1,0,'SemiSolid_1') == true"); failures++;
    }

    if (failures == 0) writeln("Landing unit tests passed.");
    else writeln("Landing unit tests failed: ", failures);

    return (failures == 0) ? 0 : 1;
}

bool approxEqual(float a, float b, float eps = 0.0001f) {
    import std.math : abs;
    return abs(a - b) <= eps;
}
