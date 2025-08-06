module world.screen_settings;

import raylib;

import std.stdio;
import std.file;
import std.json;
import std.path;
import std.array;
import std.process;
import std.algorithm;
import std.conv : to;

// ---- ENUMS ----
enum ScreenSettingsState {
    UNINITIALIZED,
    INITIALIZED
}

// ---- CLASS ----
class ScreenSettings {
    // Singleton instance
    private __gshared ScreenSettings instance;

    // Current state of the settings
    ScreenSettingsState state;

    // Display settings
    bool isFullscreen;
    bool isVSyncEnabled;
    int[] resolution;

    this() {
        instance = this;
        state = ScreenSettingsState.UNINITIALIZED;
        isFullscreen = false; // Default fullscreen setting
        isVSyncEnabled = true; // Default VSync setting
        resolution = [1280, 720]; // Default resolution
    }

    static ScreenSettings getInstance() {
        if (instance is null) {
            synchronized {
                if (instance is null) {
                    instance = new ScreenSettings();
                }
            }
        }
        return instance;
    }

    void initialize() {
        if (state == ScreenSettingsState.INITIALIZED) {
            writeln("ScreenSettings already initialized.");
            return;
        }

        // Load settings from a configuration file if it exists
        string configFilePath = "config/screen_settings.json";
        if (exists(configFilePath)) {
            try {
                auto configData = readText(configFilePath);
                auto jsonData = parseJSON(configData);
                
                isFullscreen = jsonData["isFullscreen"].get!bool;
                isVSyncEnabled = jsonData["isVSyncEnabled"].get!bool;
                
                // Correctly extract integer values from JSONValue array
                auto resArray = jsonData["resolution"].array;
                resolution = [];
                foreach(item; resArray) {
                    resolution ~= item.integer.to!int;
                }
                
                writeln("Screen settings loaded from config file.");
            } catch (Exception e) {
                writeln("Error loading screen settings: ", e.msg);
            }
        } else {
            writeln("No config file found, using default settings.");
        }

        state = ScreenSettingsState.INITIALIZED;
    }

    void saveSettings() {
        if (state != ScreenSettingsState.INITIALIZED) {
            writeln("ScreenSettings not initialized, cannot save settings.");
            return;
        }

        // Create a JSON object to store the settings
        auto jsonData = JSONValue([
            "isFullscreen": JSONValue(isFullscreen),
            "isVSyncEnabled": JSONValue(isVSyncEnabled),
            "resolution": JSONValue(resolution)
        ]);

        string configFilePath = "config/screen_settings.json";
        
        try {
            // Explicitly use std.file.write to avoid ambiguity
            import std.file : write;
            write(configFilePath, jsonData.toString());
            writeln("Screen settings saved to config file.");
        } catch (Exception e) {
            writeln("Error saving screen settings: ", e.msg);
        }
    }
}