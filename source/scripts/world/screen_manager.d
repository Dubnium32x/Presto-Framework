module world.screen_manager;

import raylib;

import std.stdio;
import std.string;
import std.file;
import std.json;
import std.traits : EnumMembers;

import world.screen_settings;
import world.screen_state;
import screens.palette_swap_test_screen;
import screens.level_test_screen;
import screens.animation_test; // Import AnimationTestScreen
import world.transition_manager; // Import TransitionType
import world.transition_manager : TransitionType;

// ---- SCREEN INTERFACE ----
interface IScreen {
    void initialize();
    void update(float deltaTime);
    void draw();
    void unload();
}

// ---- GLOBAL VARIABLES ----
public ScreenSettings screenSettings;
public GameplayState currentGameplayState = GameplayState.IN_MENU;

// ---- SCREEN MANAGER CLASS ----
// ---- CLASS ----
class ScreenManager : IScreen {
    // Singleton instance
    static ScreenManager instance;

    // Current screen and state
    private IScreen currentScreen;
    private ScreenState _currentState = ScreenState.INIT;
    
    // Screen registry - maps screen states to screen objects
    private IScreen[ScreenState] screenRegistry;
    
    this() {
        screenSettings = new ScreenSettings();
        // Initialize the screen registry with null values
        foreach(state; [EnumMembers!ScreenState]) {
            screenRegistry[state] = null;
        }
    }

    // Static method to get the singleton instance
    static ScreenManager getInstance() {
        if (instance is null) {
            synchronized {
                if (instance is null) {
                    instance = new ScreenManager();
                }
            }
        }
        return instance;
    }
    
    // Getter for current state
    ScreenState currentState() {
        return _currentState;
    }

    void initialize() {
        // Register screens
        registerScreen(ScreenState.INIT, TestScreen.getInstance());
        // Register your screen of choice. By default, we register the init screen.
        // For now, we are testing Palette Swap.
        registerScreen(ScreenState.PALETTE_SWAP_TEST, PaletteSwapTestScreen.getInstance());
        registerScreen(ScreenState.LEVEL_TEST, LevelTestScreen.getInstance());
        registerScreen(ScreenState.ANIMATION_TEST, AnimationTestScreen.getInstance());

        // Start with the LEVEL_TEST state to show the new level test screen
        changeState(ScreenState.LEVEL_TEST);
    }
    
    // Register a screen implementation for a specific state
    void registerScreen(ScreenState state, IScreen screen) {
        screenRegistry[state] = screen;
        writeln("ScreenManager: Registered screen for state: ", state);
    }
    
    // Change the current state and activate corresponding screen
    void changeState(ScreenState newState) {
        // First unload the current screen if it exists
        if (currentScreen !is null) {
            currentScreen.unload();
            currentScreen = null;
        }
        
        // Update the state
        _currentState = newState;
        
        // Activate the new screen if it's registered
        if (newState in screenRegistry && screenRegistry[newState] !is null) {
            currentScreen = screenRegistry[newState];
            currentScreen.initialize();
            writeln("ScreenManager: Changed to state: ", newState);
        } else {
            writeln("ScreenManager: Warning - No screen registered for state: ", newState);
        }
    }
    
    // Legacy method for backward compatibility
    void setScreen(IScreen newScreen) {
        if (currentScreen !is null) {
            currentScreen.unload();
        }
        
        currentScreen = newScreen;
        
        if (currentScreen !is null) {
            currentScreen.initialize();
            writeln("ScreenManager: Switched to new screen: ", newScreen);
        }
        else {
            writeln("ScreenManager: Attempted to set null screen.");
        }
    }

    void update(float deltaTime) {
        if (currentScreen !is null) {
            currentScreen.update(deltaTime);
        }
    }

    void draw() {
        if (currentScreen !is null) {
            currentScreen.draw();
        } else {
            // Fallback rendering when no screen is active
            DrawText("Loading...", GetScreenWidth() / 2 - 50, GetScreenHeight() / 2, 20, Colors.DARKGRAY);
        }
    }

    void unload() {
        if (currentScreen !is null) {
            currentScreen.unload();
            currentScreen = null;
        }
        
        // Clear the screen registry
        foreach(state; [EnumMembers!ScreenState]) {
            screenRegistry[state] = null;
        }
    }
    
    // Get the active screen instance
    IScreen getActiveScreen() {
        return currentScreen;
    }
    
    // Check if a specific state is active
    bool isState(ScreenState state) {
        return _currentState == state;
    }
    
    // Transition to a new state with animated effect
    void transitionToState(ScreenState newState, TransitionType transitionType = TransitionType.WORMHOLE, float duration = 1.0f) {
        if (currentScreen !is null) {
            currentScreen.unload();
        }

        if (newState in screenRegistry && screenRegistry[newState] !is null) {
            _currentState = newState;
            currentScreen = screenRegistry[newState];
            currentScreen.initialize();
            writeln("Transitioned to state: ", newState);
        } else {
            writeln("ERROR: Screen not registered: ", newState);
        }
    }
}

// ---- TEST SCREEN ----
class TestScreen : IScreen {
    private static TestScreen _instance;
    
    static TestScreen getInstance() {
        if (_instance is null) {
            _instance = new TestScreen();
        }
        return _instance;
    }
    
    void initialize() {
        writeln("TestScreen initialized");
    }
    
    void update(float deltaTime) {
        if (IsKeyPressed(KeyboardKey.KEY_P)) {
            ScreenManager.getInstance().changeState(ScreenState.PALETTE_SWAP_TEST);
        }
        if (IsKeyPressed(KeyboardKey.KEY_L)) {
            ScreenManager.getInstance().changeState(ScreenState.LEVEL_TEST);
        }
    }
    
    void draw() {
        ClearBackground(Color(40, 40, 40, 255));
        DrawText("Test Screen", 10, 10, 24, Colors.WHITE);
        DrawText("Press P for Palette Test, L for Level Test", 10, 50, 16, Colors.LIGHTGRAY);
    }
    
    void unload() {
        writeln("TestScreen unloaded");
    }
}

// ---- PAUSE MENU ----
class PauseMenu : IScreen {
    // Singleton instance
    static PauseMenu instance;

    this() {
        instance = this;
    }

    void initialize() {
        // Initialize pause menu resources (textures, sounds, etc.)
        writeln("Pause Menu initialized.");
    }

    void update(float deltaTime) {
        // Handle input and update pause menu logic
        if (IsKeyPressed(KeyboardKey.KEY_ESCAPE)) {
            // Resume game if escape is pressed
            ScreenManager.getInstance().changeState(ScreenState.GAMEPLAY);
            currentGameplayState = GameplayState.PLAYING;
        }
    }

    void draw() {
        // Draw pause menu UI elements
        DrawText("Paused", 400, 200, 40, Colors.RED);
        DrawText("Press ESC to resume", 300, 300, 20, Colors.WHITE);
    }

    void unload() {
        // Unload pause menu resources
        writeln("Pause Menu unloaded.");
    }
}

class ResolutionManager {
    // Singleton instance
    static ResolutionManager instance;

    // Current resolution
    Resolution currentResolution;

    this() {
        instance = this;
        currentResolution = Resolution.RES_1X; // Default resolution
    }

    static ResolutionManager getInstance() {
        return instance;
    }

    void setResolution(Resolution resolution) {
        currentResolution = resolution;
        // Apply the resolution change (this is a placeholder)
        writeln("Resolution changed to: ", resolution);
    }
}