/*
    PRESTO FRAMEWORK
    Developed in Raylib-D by Dylan Kleven "Leven"
    This is a simple framework for creating Sonic fan games in D.
    It is designed to be easy to use and understand, while still being powerful enough to create complex games.

    WHY D?
    D is a systems programming language with a focus on performance, safety, and expressiveness.
    It is a compiled language, which means it is fast and efficient.
    It's also a high-level language, which means it is easy to read and write. It's also my favorite language.
    D is a great choice for game development because it has a lot of features that make it easy to create games.

    WHY RAYLIB?
    Raylib is a simple and easy-to-use library for creating games in C.
    It is designed to be simple and easy to use, while still being powerful enough to create complex games.
    Raylib D is a D binding for Raylib, which means it allows you to use Raylib in D.
    It is a great choice for game development because it is simple and easy to use, while still being powerful enough to create complex games.
    It is also a great choice for game development because it is cross-platform, which means it can be used on Windows, Mac, and Linux.

    WHY PRESTO FRAMEWORK?
    If you know me well, I was the lead developer behind Sonic Harmony back in 2020.
    I was also the lead developer behind Sonic Two-Tone. This was an attempt at putting Sonic in the Playdate.
    These were both setbacks on my game development career. I have been seeking redemption ever since.
    I have been wanting to create a Sonic fan game for a long time, but I never had the time or resources to do so. Until now.

    SONIC THE HEDGEHOG IS A TRADEMARK OF SEGA.
    THIS FRAMEWORK IS NOT AFFILIATED WITH SEGA IN ANY WAY.
    THIS FRAMEWORK IS NOT INTENDED FOR COMMERCIAL USE.
    IT IS INTENDED FOR EDUCATIONAL PURPOSES ONLY.
    IT IS PUBLICLY AVAILABLE AS OPEN SOURCE SOFTWARE.
*/

// app.d
module app;

import raylib;

import prestoframework.screen_manager;
import prestoframework.screen_settings;
import prestoframework.screen_states;

import std.stdio : writeln;
import std.string;
import std.file;
import std.algorithm;

// initialize the screen
ScreenSettings screenSettings;
ScreenManager screenManager;

void main() {
    // Initialize the screen settings
    screenSettings = new ScreenSettings(640, 360, 640, 360);
    screenManager = new ScreenManager(screenSettings);

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