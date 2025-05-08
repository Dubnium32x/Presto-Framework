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
    // Initialize the screen settings
    InitWindow(640, 360, "Presto Framework - Version 0.1");
    screenSettings = new ScreenSettings(640, 360, 640, 360);
    SetTargetFPS(60); // Set the target frames per second
    screenManager = new ScreenManager(screenSettings);
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