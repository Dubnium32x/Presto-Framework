module parser.csv_tile_loader;

import std.stdio : writeln;
import std.string : strip, split, splitLines;
import std.conv : to;
import std.file : readText;
import raylib; // Import raylib for Vector2

struct TileLayer {
    string name;
    int tileWidth;
    int tileHeight;
    int[][] data;
}

// Define a struct to hold the result
struct LevelLoadResult {
    TileLayer layer;
    Vector2 playerStartPosition = Vector2(-1, -1); // Default if not found
}

// Function now returns LevelLoadResult
LevelLoadResult loadCSVLayer(string path, string name, int tileWidth, int tileHeight, int playerStartTileID = 0) { // Changed default to 0
    writeln("Loading layer: ", name, " from: ", path);

    string fileContent = readText(path);
    int[][] grid;
    Vector2 foundPlayerStart = Vector2(-1, -1);
    int currentY = 0;

    foreach (line; fileContent.strip.splitLines) {
        int[] row;
        int currentX = 0;
        foreach (cell; line.strip.split(",")) {
            int tileID = cell.strip.to!int;
            if (tileID == playerStartTileID) {
                // Found player start position
                // Position at bottom-center of the tile
                foundPlayerStart = Vector2(currentX * tileWidth + tileWidth / 2.0f,
                                          currentY * tileHeight + tileHeight);
                writeln("Player start found at tile (", currentX, ", ", currentY, ") -> position ", foundPlayerStart);
                tileID = -1; // Replace player start tile with empty tile (-1)
            }
            row ~= tileID;
            currentX++;
        }
        grid ~= row;
        currentY++;
    }

    TileLayer loadedLayer = TileLayer(name, tileWidth, tileHeight, grid);
    return LevelLoadResult(loadedLayer, foundPlayerStart);
}
