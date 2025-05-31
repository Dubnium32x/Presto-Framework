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
import world.level_list;
import world.level; 
import world.tileset_manager; // Added import
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
    TilesetManager tilesetManager; // Added field to hold TilesetManager

    IScreen currentScreen;

    // Singleton instance
    static ScreenManager instance;
    
    static ScreenManager getInstance() {
        if (instance is null) {
            // Default to a common virtual size if created without explicit settings first
            // Now calls constructor with null TilesetManager by default
            instance = new ScreenManager(new ScreenSettings(1280, 720, 640, 360), null);
        }
        return instance;
    }

    // Constructor
    this(ScreenSettings settings, TilesetManager tm = null) { // tm is now optional, defaults to null
        this.screenSettings = settings;
        this.tilesetManager = tm; // Store TilesetManager
        this.currentScreenState = ScreenState.DEBUG;
        this.currentScreen = null; // Initialize to null
        if (tm is null) {
            writeln("ScreenManager Warning: Initialized without a TilesetManager. It should be set later if needed.");
        }
    }

    // Add a method to explicitly set the TilesetManager if it was null initially
    void setTilesetManager(TilesetManager tm) {
        if (this.tilesetManager is null && tm !is null) {
            this.tilesetManager = tm;
            writeln("ScreenManager: TilesetManager has been set.");
            // If a screen was waiting for a tilesetmanager, it might need re-initialization
            // For example, if currentScreen is LevelManager and it failed to init due to no TM.
            if (currentScreenState == ScreenState.GAME && currentScreen !is null) {
                // Potentially re-initialize or update the current screen if it depends on TM
                // This depends on how LevelManager handles a null TM initially.
            }
        } else if (tm !is null && this.tilesetManager !is tm) {
            this.tilesetManager = tm; // Allow replacement, though this might be less common
            writeln("ScreenManager: TilesetManager has been replaced.");
        }
    }

    // Initialize the screen manager
    void initialize() {
        if (!initialized) {
            // Load options first - this might update screenSettings
            if (!optionsLoaded) {
                createOptionsFile(); // Ensure it exists
                loadOptions();       // Load them, potentially calling setScreenSettings
            }

            // Initialize based on the current screen state
            switch (currentScreenState) {
                case ScreenState.DEBUG:
                    // No specific screen for DEBUG, or handle as needed
                    writeln("ScreenManager: Initializing in DEBUG state. No specific screen loaded by default.");
                    break;
                case ScreenState.TITLE:
                    // currentScreen = new TitleScreen(); // Example
                    break;
                case ScreenState.GAME:
                    // Ensure tilesetManager is available
                    if (this.tilesetManager is null) {
                        stderr.writeln("ScreenManager Error: TilesetManager is null. Cannot create LevelManager for LEVEL state.");
                        // Fallback or error state
                    } else {
                        // This is the line (or similar) that was causing the error (e.g. line 74)
                        currentScreen = new LevelManager(this.tilesetManager);
                        currentScreen.initialize(); // Initialize the new screen
                    }
                    break;
                // ... other cases
                default:
                    break;
            }

            // Initialize the render texture for virtual screen rendering
            // Ensure screenSettings reflects the desired virtual dimensions
            virtualScreenTexture = LoadRenderTexture(screenSettings.virtualWidth, screenSettings.virtualHeight);
            SetTextureFilter(virtualScreenTexture.texture, TextureFilter.TEXTURE_FILTER_POINT); // For pixel-art friendly scaling

            currentScreen.initialize();
            initialized = true;
            writeln("ScreenManager initialized.");
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
