module parser.csv_tile_loader;

import std.stdio : writeln;
import std.string : strip, split, splitLines;
import std.conv : to;
import std.file : readText;

struct TileLayer {
    string name;
    int tileWidth;
    int tileHeight;
    int[][] data;
}

TileLayer loadCSVLayer(string path, string name, int tileWidth, int tileHeight) {
    writeln("Loading layer: ", name, " from: ", path);

    string fileContent = readText(path);
    int[][] grid;

    foreach (line; fileContent.strip.splitLines) {
        int[] row;
        foreach (cell; line.strip.split(",")) {
            row ~= cell.strip.to!int;
        }
        grid ~= row;
    }

    return TileLayer(name, tileWidth, tileHeight, grid);
}
