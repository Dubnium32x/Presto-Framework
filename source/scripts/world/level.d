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

class LevelManager {
    Level[] levels;
    int currentLevelIndex;
    Level currentLevel;

    // Constructor
    this() {
        currentLevelIndex = 0;
        loadLevels(LevelList.LEVEL_0, ActNumber.ACT_1);
    }

    void loadLevels(LevelList levelList, LevelList actNumber) {
        for (int i = 0; i < LevelNames.length; i++) {
            string levelName = LevelNames[i];
            string filePath = "levels/" ~ levelName ~ ".csv";
            if (exists(filePath)) {
                writeln("Loading level: ", filePath);
                auto levelData = loadCSV(filePath);
                auto level = new Level(levelName, levelData[0].length, levelData.length, levelData);
                levels ~= level;
            }
            else {
                writeln("Level file not found: ", filePath);
            }
        }
        if (levels.length > 0) {
            currentLevel = levels[currentLevelIndex];
            writeln("Loaded level: ", currentLevel.name);
        }
        else {
            writeln("No levels loaded.");
        }
    }
}
