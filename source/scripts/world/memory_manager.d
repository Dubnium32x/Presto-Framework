module memory_manager;

import raylib;
import std.stdio;
import std.string;
import std.file; 
import std.algorithm;
import std.conv;
import std.array;
import std.json;

import screen_manager;
import screen_states;
import level;

enum MemoryManagerState {
    INIT,
    LOADING,
    LOADED,
    UNLOADING,
    UNLOADED
}

bool optionsLoaded = false;
bool levelsLoaded = false;

void createOptionsFile() {
    // Create a text file with default options
    string optionsFilePath = "options.json";
    if (!exists(optionsFilePath)) {
        writeln("Creating options file: ", optionsFilePath);
        auto options = JSONValue([
            "fullscreen": JSONValue(false),
            "vsync": JSONValue(true),
            "screenWidth": JSONValue(640),
            "screenHeight": JSONValue(360),
            "virtualWidth": JSONValue(640),
            "virtualHeight": JSONValue(360)
        ]);
        auto json = options.toString();
        std.file.write(optionsFilePath, json);
    } else {
        writeln("Options file already exists: ", optionsFilePath);
    }
}