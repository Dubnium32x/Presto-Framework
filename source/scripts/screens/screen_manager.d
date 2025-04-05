// screen_manager.d
module prestoframework.screen_manager;

import prestoframework.screen_settings;
import prestoframework.screen_states;
import prestoframework.title_screen;
import prestoframework.debug_screen;

import raylib;

import std.stdio;
import std.string;
import std.file;
import std.algorithm;

interface IScreen {
    void load();
    void unload();
    void update();
    void draw();
}

class ScreenManager {
    private IScreen currentScreen;
    private ScreenState currentState;
    private ScreenSettings screenSettings;

    this(ScreenSettings screenSettings) {
        this.screenSettings = screenSettings;
        // Initialize the first screen (TitleScreen)
        currentState = ScreenState.DEBUG;
        currentScreen = new DebugScreen(this, screenSettings);
        writeln("ScreenManager initialized with screen settings: ", screenSettings);
        writeln("Current screen state: ", currentState);
        currentScreen.load();
    }

    void setScreen(IScreen newScreen) {
        if (currentScreen !is null) {
            currentScreen.unload();
        }
        currentScreen = newScreen;
        currentScreen.load();
    }
    void update() {
        if (currentScreen !is null) {
            currentScreen.update();
        }
    }
    void draw() {
        if (currentScreen !is null) {
            currentScreen.draw();
        }
    }
}