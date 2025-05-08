module screen_manager;

import raylib;
import std.stdio;
import std.string;
import std.file;
import std.algorithm;
import std.conv;
import std.array;

import parser.csv_tile_loader; // Import the CSV tile loader
import screen_states;
import screen_settings;
import level_list;
import level;
import memory_manager;

bool initialized = false; // Flag to check if the screen manager is initialized
bool debugMode = false; // Flag to check if debug mode is enabled
bool isPlaying = false; // Flag to check if the game is currently playing
bool isPaused = false; // Flag to check if the game is currently paused

interface IScreen {
    void initialize();
    void update();
    void draw();
}

class ScreenManager {
    ScreenState currentScreenState;
    GameplayState currentGameplayState;
    SettingsState currentSettingsState;
    ScreenSettings screenSettings;

    IScreen currentScreen;

    // Singleton instance
    static ScreenManager instance;
    
    static ScreenManager getInstance() {
        if (instance is null) {
            instance = new ScreenManager(new ScreenSettings(640, 360, 640, 360));
        }
        return instance;
    }

    // Constructor
    this(ScreenSettings settings) {
        this.screenSettings = settings;
        this.currentScreenState = ScreenState.DEBUG;
        this.currentScreen = null; // Initialize to null
    }

    // Initialize the screen manager
    void initialize() {
        if (!initialized) {
            // Load the initial screen
            if (currentScreenState == ScreenState.DEBUG || currentScreenState == ScreenState.GAME) {
                currentScreen = new LevelManager(); // Replace with actual gameplay screen class
            }
            else if (currentScreenState == ScreenState.INIT) {
                // currentScreen = new InitScreen(); // Replace with actual init screen class
                // i will come back to this later
            }

            currentScreen.initialize();
            initialized = true;
        }
    }

    // Update the current screen
    void update() {
        if (currentScreen is null) {
            writeln("Error: Current screen is null.");
            return;
        }
        currentScreen.update();
    }

    // Draw the current screen
    void draw() {
        if (currentScreen is null) {
            writeln("Error: Current screen is null.");
            return;
        }
        currentScreen.draw();
    }

    // Change the current screen
    void changeScreen(IScreen newScreen) {
        if (currentScreen !is null) {
            currentScreen = null; // Clean up the current screen
        }
        currentScreen = newScreen;
        currentScreen.initialize();
    }

    // Set the screen settings
    void setScreenSettings(ScreenSettings settings) {
        this.screenSettings = settings;
        SetWindowSize(settings.screenWidth, settings.screenHeight);
        SetTargetFPS(60); // Set the target frames per second
    }

    // Set the game state
    void setGameState(bool playing) {
        isPlaying = playing;
        if (playing) {
            writeln("Game is now playing.");
        }
        else {
            writeln("Game is paused.");
        }
    }

    // Set the pause state
    void setPauseState(bool paused) {
        isPaused = paused;
        if (paused) {
            writeln("Game is now paused.");
        }
        else {
            writeln("Game is resumed.");
        }
    }
}

class ResolutionManagaer {
    Resolution currentResolution;
    int screenWidth;
    int screenHeight;

    this() {
        currentResolution = Resolution.RES_1280x720; // Default resolution
        screenWidth = 1280;
        screenHeight = 720;
    }

    void setResolution(Resolution resolution) {
        currentResolution = resolution;
        final switch (resolution) {
            case Resolution.RES_640x360:
                screenWidth = 640;
                screenHeight = 360;
                break;
            case Resolution.RES_1280x720:
                screenWidth = 1280;
                screenHeight = 720;
                break;
            case Resolution.RES_1920x1080:
                screenWidth = 1920;
                screenHeight = 1080;
                break;
            case Resolution.RES_2560x1440:
                screenWidth = 2560;
                screenHeight = 1440;
                break;
            case Resolution.RES_3840x2160:
                screenWidth = 3840;
                screenHeight = 2160;
                break;
        }
        SetWindowSize(screenWidth, screenHeight);
    }
}
