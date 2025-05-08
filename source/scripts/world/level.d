module level;

import raylib;
import std.stdio;
import std.string;
import std.file;
import std.algorithm;
import std.conv;
import std.array;

import parser.csv_tile_loader; // Import the CSV tile loader
import screen_states;
import screen_manager;
import screen_settings;
import level_list;
import memory_manager;

// Define a struct to hold the level data
struct Level {
    string name;
    int tileWidth;
    int tileHeight;
    int[][] data;
    Vector2 playerStartPosition = Vector2(-1, -1); // Default if not found
}

class LevelManager : IScreen { // Implement IScreen
    Level[] levels;
    int currentLevelIndex;
    Level currentLevel;

    // Constructor
    this() {
        currentLevelIndex = 0;
        loadLevels(LevelList.LEVEL_0, ActNumber.ACT_1);
    }

    void loadLevels(LevelList levelList, ActNumber actNumber) { // Changed parameter type
        // Convert LevelList enum member to string for the level name
        string levelEnumString = to!string(levelList); // Example: "LEVEL_0"
        // Iterate through LayerNames, not LevelNames
        for (int i = 0; i < LayerNames.length; i++) {
            string layerName = LayerNames[i];
            // Construct filePath based on new understanding from README
            // e.g., resources/data/levels/LEVEL_0/LEVEL_0_Ground_1.csv
            // Assuming actNumber might be part of the layerName or a subfolder if needed
            // For now, let's assume actNumber isn't directly in this basic CSV path structure yet
            // and that LayerNames already incorporate any act-specific parts if necessary,
            // or that levels are structured in folders like LEVEL_0/ACT_1/Ground_1.csv
            // Based on README: resources/data/levels/[LevelName]/
            // And CSVs are like [LevelName]_[LayerName]_[ActNumber].csv
            // However, the current loadLevels iterates LayerNames and tries to load a single CSV per layer.
            // This seems to imply each "Level" struct might actually be a "LevelLayer"
            // Or, a Level should contain multiple TileLayer structs.

            // Let's adjust to load multiple layers for the given levelList and actNumber
            // The current `Level` struct seems to hold data for one layer.
            // If `levels` is an array of these `Level` (layers), then the loop over `LayerNames` makes sense.

            string currentLevelName = to!string(levelList); // e.g., "LEVEL_0"
            // The filePath was "levels/" ~ levelName ~ ".csv";
            // Based on README, it should be more like "resources/data/levels/[LevelName]/[LayerName].csv"
            // Or, if one CSV contains all data for a level, then "resources/data/levels/[LevelName].csv"

            // Given the error was about LevelNames, and the loop structure,
            // it seems the intention was to load multiple *levels* (like LEVEL_0, LEVEL_1)
            // not multiple *layers* for a single level in this specific loop.
            // However, the constructor calls loadLevels with a specific level (LEVEL_0).

            // Let's assume `loadLevels` is meant to load all layers for THE GIVEN `levelList` and `actNumber`.
            // And `LevelNames` was a mistake, it should use `LayerNames`.

            // The `Level` struct has `name`, `tileWidth`, `tileHeight`, `data`. This looks like one layer.
            // If `levels` is an array of these `Level` (layers), then the loop over `LayerNames` makes sense.

            string filePath = "resources/data/levels/" ~ currentLevelName ~ "/" ~ currentLevelName ~ "_" ~ layerName ~ "_" ~ to!string(actNumber) ~ ".csv";
            writeln("Attempting to load: ", filePath);

            if (exists(filePath)) {
                writeln("Loading layer for level: ", currentLevelName, ", Layer: ", layerName, ", Act: ", to!string(actNumber));
                // loadCSVLayer expects path, name, tileWidth, tileHeight, playerStartTileID
                // We need to decide what tileWidth/Height to pass. Maybe from screenSettings or a constant?
                // For now, let's use placeholder values. These should be defined properly.
                int placeholderTileWidth = 16;
                int placeholderTileHeight = 16;
                auto loadResult = loadCSVLayer(filePath, layerName, placeholderTileWidth, placeholderTileHeight, 0); // Use loadCSVLayer
                
                // Assuming the Level struct is for one layer's data
                auto levelLayer = Level(
                    currentLevelName ~ "_" ~ layerName ~ "_" ~ to!string(actNumber), // Name for this specific layer
                    loadResult.layer.tileWidth, 
                    loadResult.layer.tileHeight, 
                    loadResult.layer.data,
                    loadResult.playerStartPosition
                );
                levels ~= levelLayer; // Add this layer to the list
            }
            else {
                writeln("Layer file not found: ", filePath);
            }
        }
        if (levels.length > 0) {
            // currentLevel would be the first loaded layer/level by default.
            // This might need adjustment if you expect currentLevel to be a composite of layers.
            currentLevel = levels[0]; // Or handle currentLevelIndex appropriately
            writeln("Loaded first layer as current: ", currentLevel.name);
        }
        else {
            writeln("No levels loaded.");
        }
    }

    // IScreen interface methods
    void initialize() {
        writeln("LevelManager initialized.");
        // Potentially load initial level or ensure it's loaded
        if (levels.length == 0) {
            // Default load if not already done, or handle error
            loadLevels(LevelList.LEVEL_0, ActNumber.ACT_1); // Example default
        }
    }

    void update() {
        // writeln("LevelManager updated.");
        // Game logic for the current level/screen would go here
        // For example, player input, enemy AI, physics, etc.
        // This will depend on what LevelManager is responsible for in terms of active gameplay.
    }

    void draw() {
        // writeln("LevelManager drawn.");
        // Drawing logic for the current level/screen
        // NO BeginDrawing(), EndDrawing(), or ClearBackground() here.
        // ScreenManager handles the render target.
        // All coordinates are relative to the virtual screen (e.g., 640x360).

        // Add drawing calls for the level content here
        // e.g., draw tiles from currentLevel.data
        if (currentLevel.data.length > 0) {
            for (int y = 0; y < currentLevel.data.length; y++) {
                for (int x = 0; x < currentLevel.data[y].length; x++) {
                    // This is a very basic drawing example.
                    // You\'d need to map tile IDs to actual graphics/textures.
                    if (currentLevel.data[y][x] != -1) { // Assuming -1 is an empty tile
                        // Replace 16 with actual tile dimensions from currentLevel or constants
                        DrawRectangle(x * currentLevel.tileWidth, y * currentLevel.tileHeight, currentLevel.tileWidth, currentLevel.tileHeight, Colors.BLUE); 
                    }
                }
            }
            // Draw player start position for debugging
            if(currentLevel.playerStartPosition.x != -1 && currentLevel.playerStartPosition.y != -1) {
                // Ensure player start position is also drawn relative to virtual screen
                DrawCircleV(currentLevel.playerStartPosition, 5, Colors.RED);
            }
        } else {
            DrawText("No level data to draw.", 10, 30, 20, Colors.LIGHTGRAY); // Adjusted position
        }
        DrawText("GAME SCREEN (LevelManager)", 10, 10, 20, Colors.MAROON);
        // NO EndDrawing();
    }
}
