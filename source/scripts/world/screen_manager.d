module screen_manager;

import raylib;
import std.stdio;
import std.string;
import std.file;
import std.algorithm;
import std.conv;
import std.array;

import parser.csv_tile_loader;
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
    RenderTexture2D virtualScreenTexture; // Added for virtual screen rendering

    IScreen currentScreen;

    // Singleton instance
    static ScreenManager instance;
    
    static ScreenManager getInstance() {
        if (instance is null) {
            // Default to a common virtual size if created without explicit settings first
            instance = new ScreenManager(new ScreenSettings(1280, 720, 640, 360));
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
            // Load options first - this might update screenSettings
            if (!optionsLoaded) {
                createOptionsFile(); // Ensure it exists
                loadOptions();       // Load them, potentially calling setScreenSettings
            }

            // Initialize the render texture for virtual screen rendering
            // Ensure screenSettings reflects the desired virtual dimensions
            virtualScreenTexture = LoadRenderTexture(screenSettings.virtualWidth, screenSettings.virtualHeight);
            SetTextureFilter(virtualScreenTexture.texture, TextureFilter.TEXTURE_FILTER_POINT); // For pixel-art friendly scaling

            // Load the initial screen
            if (currentScreenState == ScreenState.DEBUG || currentScreenState == ScreenState.GAME) {
                // currentScreen should be an instance of a class that implements IScreen
                // LevelManager now implements IScreen
                currentScreen = new LevelManager(); 
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

        // 1. Draw current game screen to the virtual render texture
        BeginTextureMode(virtualScreenTexture);
            ClearBackground(Colors.DARKGRAY); // Clear the texture with a base color (e.g., white or black)
            currentScreen.draw();      // All game drawing happens here, to the virtual texture
        EndTextureMode();

        // 2. Draw the virtual render texture to the actual screen, scaled and centered
        BeginDrawing();
            ClearBackground(Colors.BLACK); // Clear the actual window (e.g., black for letterboxing)

            float scale = min(cast(float)GetScreenWidth() / screenSettings.virtualWidth, 
                              cast(float)GetScreenHeight() / screenSettings.virtualHeight);

            Rectangle sourceRec = Rectangle(
                0.0f, 
                0.0f, 
                cast(float)virtualScreenTexture.texture.width, 
                -cast(float)virtualScreenTexture.texture.height // NOTE: Negative height to flip texture Y
            );

            Rectangle destRec = Rectangle(
                (GetScreenWidth() - (screenSettings.virtualWidth * scale)) * 0.5f,
                (GetScreenHeight() - (screenSettings.virtualHeight * scale)) * 0.5f,
                screenSettings.virtualWidth * scale,
                screenSettings.virtualHeight * scale
            );

            Vector2 origin = Vector2(0, 0);

            DrawTexturePro(
                virtualScreenTexture.texture,
                sourceRec,
                destRec,
                origin,
                0.0f,
                Colors.WHITE
            );
        EndDrawing();
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
        // If window size changes, and we have a virtual texture, it might need re-creation or adjustment
        // For now, assume virtual size is fixed and only window size might change via options.
        // If virtual size changes, render texture must be reloaded.
        if (virtualScreenTexture.id != 0 && // Check if texture is loaded
            (virtualScreenTexture.texture.width != settings.virtualWidth || 
             virtualScreenTexture.texture.height != settings.virtualHeight)) {
            UnloadRenderTexture(virtualScreenTexture);
            virtualScreenTexture = LoadRenderTexture(settings.virtualWidth, settings.virtualHeight);
            SetTextureFilter(virtualScreenTexture.texture, TextureFilter.TEXTURE_FILTER_POINT);
        }
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
