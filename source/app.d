import raylib;

import screen_manager;
import screen_settings;
import screen_states;

import std.stdio : writeln;
import std.string;
import std.file;
import std.algorithm;

// initialize the screen
ScreenSettings screenSettings;
ScreenManager screenManager;

void main() {
    // Initialize the screen settings to the target window size and virtual resolution
    InitWindow(1280, 720, "Presto Framework - Version 0.1");
    screenSettings = new ScreenSettings(1280, 720, 640, 360); // Window: 1280x720, Virtual: 640x360
    SetTargetFPS(60); // Set the target frames per second
    
    // Pass the configured screenSettings to the ScreenManager
    // ScreenManager.instance will be created here if null, or use existing if already set up
    // Ensure ScreenManager uses these settings, especially for virtual resolution
    if (ScreenManager.instance is null) {
        screenManager = new ScreenManager(screenSettings);
    } else {
        screenManager = ScreenManager.instance;
        screenManager.setScreenSettings(screenSettings); // Apply new settings
    }
    
    screenManager.initialize(); // Initialize the screen manager

    // Window will be initialize through ScreenManager

    // Main game loop
    writeln("Starting main loop...");
    while (!WindowShouldClose()) {
        // Update the current screen
        screenManager.update();

        // Draw the current screen
        screenManager.draw();
    }

    // Close the window and clean up resources
    writeln("Closing window...");
    CloseWindow();
}