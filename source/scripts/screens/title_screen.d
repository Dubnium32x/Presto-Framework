// title_screen.d
module prestoframework.title_screen;

import raylib;

import prestoframework.screen_manager;
import prestoframework.screen_states;
import prestoframework.screen_settings;
import prestoframework.menu_screen;

import std.stdio : writeln;
import std.string;
import std.file;

class TitleScreen : IScreen {
    private ScreenManager screenManager;
    private ScreenSettings screenSettings;

    this(ScreenManager screenManager, ScreenSettings screenSettings) {
        this.screenManager = screenManager;
        this.screenSettings = screenSettings;
    }

    void load() {
        writeln("TitleScreen loaded");
        // Load resources here (e.g., images, sounds)
    }

    void unload() {
        writeln("TitleScreen unloaded");
        // Unload resources here
    }

    void update() {
        if (IsKeyPressed(KeyboardKey.KEY_ENTER)) {
            // Transition to the next screen (e.g., MenuScreen)
            screenManager.setScreen(new MenuScreen(screenManager, screenSettings));
        }
    }

    void draw() {
        ClearBackground(Colors.RAYWHITE);
        DrawText("Welcome to Presto Framework!", 100, 100, 20, Colors.DARKGRAY);
        DrawText("Press ENTER to start", 100, 150, 20, Colors.DARKGRAY);
    }
}