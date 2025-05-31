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
import world.level; // Corrected import path
import screen_settings; // Added import

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
            "screenWidth": JSONValue(1280),    // Default window width
            "screenHeight": JSONValue(720),   // Default window height
            "virtualWidth": JSONValue(640),   // Virtual game width
            "virtualHeight": JSONValue(360)   // Virtual game height
        ]);
        auto json = options.toString();
        std.file.write(optionsFilePath, json);
    }
    else {
        writeln("Options file already exists: ", optionsFilePath);
    }
}

void loadOptions() {
    // Load options from the JSON file
    string optionsFilePath = "options.json";
    if (exists(optionsFilePath)) {
        writeln("Loading options from: ", optionsFilePath);
        auto jsonText = std.file.readText(optionsFilePath); // Renamed to avoid conflict
        auto optionsData = parseJSON(jsonText); // Renamed to avoid conflict
        screen_settings.ScreenSettings screenSettings = new screen_settings.ScreenSettings( // Fully qualify or ensure no naming conflict
            optionsData["screenWidth"].get!int(),
            optionsData["screenHeight"].get!int(),
            optionsData["virtualWidth"].get!int(),
            optionsData["virtualHeight"].get!int()
        );
        screenSettings.fullscreen = optionsData["fullscreen"].get!bool();
        screenSettings.vsync = optionsData["vsync"].get!bool();
        // TODO: Apply these settings to the actual game window/ScreenManager
        // For example, by calling a method on ScreenManager.instance
        if (ScreenManager.instance !is null) {
            ScreenManager.instance.setScreenSettings(screenSettings);
        }
        optionsLoaded = true; // Set flag
        writeln("Options loaded successfully.");
    }
    else {
        writeln("Options file not found: ", optionsFilePath);
    }
}