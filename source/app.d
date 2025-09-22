/*
    ---------------------------------------
    Presto Framework - Pre-Alpha v 0.1.4
    ---------------------------------------

    Constructed by Dylan "DiSKO" Kleven
*/

module app;

import raylib;

import std.stdio;
import std.file;
import std.process;
import std.path;
import std.string;
import std.algorithm;
import std.conv;

import data;
import world.screen_manager;
import world.screen_state;
import world.audio_manager;
import world.memory_manager;
import world.input_manager;
import world.screen_settings;
import screens.palette_swap_test_screen;
import screens.init_screen; // Importing the missing module

// Define the world settings
public int windowSize;
public int SCREEN_WIDTH;
public int SCREEN_HEIGHT;
public int VIRTUAL_SCREEN_WIDTH = 400;
public int VIRTUAL_SCREEN_HEIGHT = 240;

// Fonts
Font s1TitleFont;
Font s1ClassicOpenCFont;
Font sonicGameworldFont;

// global variables
__gshared Font[] fontFamily;

// Function to get mouse position in virtual screen coordinates
Vector2 GetMousePositionVirtual() {
    Vector2 mouseScreenPos = GetMousePosition();
    
    float scale = min(cast(float)GetScreenWidth() / VIRTUAL_SCREEN_WIDTH, 
                      cast(float)GetScreenHeight() / VIRTUAL_SCREEN_HEIGHT);
                      
    // Calculate the top-left position of the scaled virtual screen on the actual screen
    float destX = (GetScreenWidth() - (VIRTUAL_SCREEN_WIDTH * scale)) / 2.0f;
    float destY = (GetScreenHeight() - (VIRTUAL_SCREEN_HEIGHT * scale)) / 2.0f;

    // Convert screen mouse position to virtual screen mouse position
    float virtualMouseX = (mouseScreenPos.x - destX) / scale;
    float virtualMouseY = (mouseScreenPos.y - destY) / scale;

    // Clamp to virtual screen bounds if necessary, though often not strictly needed
    // virtualMouseX = clamp(virtualMouseX, 0, VIRTUAL_SCREEN_WIDTH);
    // virtualMouseY = clamp(virtualMouseY, 0, VIRTUAL_SCREEN_HEIGHT);

    return Vector2(virtualMouseX, virtualMouseY);
}

// ---- MAIN FUNCTION ----
void main() {
    writeln("Starting Presto Framework...");

    if (exists("options.ini")) {
        foreach (line; File("options.ini").byLine()) {
            auto parts = line.idup.split("=");
            if (parts.length == 2) {
                string key = parts[0].strip;
                string value = parts[1].strip;
                if (key == "windowSize") {
                    windowSize = to!int(value);
                }
            }
        }
    }
    SCREEN_WIDTH = 400 * windowSize;
    SCREEN_HEIGHT = 240 * windowSize;

    SetConfigFlags(ConfigFlags.FLAG_VSYNC_HINT); // Use the correct namespace for the flag

    InitAudioDevice();

    // If fullscreen is enabled, match window size to display resolution
    bool fullscreen = false;
    if (exists("options.ini")) {
        foreach (line; File("options.ini").byLine()) {
            auto parts = line.idup.split("=");
            if (parts.length == 2) {
                string key = parts[0].strip;
                string value = parts[1].strip;
                if (key == "fullscreen" && value == "true") {
                    fullscreen = true;
                }
            }
        }
    }
    if (fullscreen) {
        int displayWidth = GetMonitorWidth(GetCurrentMonitor());
        int displayHeight = GetMonitorHeight(GetCurrentMonitor());
        SCREEN_WIDTH = displayWidth;
        SCREEN_HEIGHT = displayHeight;
    }
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Presto Framework Pre-Alpha v 0.1.4");
    if (fullscreen) {
        ToggleBorderlessWindowed();
    } else {
        // Ensure borderless windowed is off if not fullscreen
        if (IsWindowFullscreen()) {
            ToggleBorderlessWindowed();
        }
    }
    SetTargetFPS(60);

    SetExitKey(KeyboardKey.KEY_NULL);

    auto virtualScreen = LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT);
    SetTextureFilter(virtualScreen.texture, TextureFilter.TEXTURE_FILTER_POINT);

    auto memManager = MemoryManager.instance();
    memManager.initialize();
    
    auto inputManager = InputManager.getInstance();
    inputManager.initialize();
    
    auto audioManager = AudioManager.getInstance();
    audioManager.initialize();
    
    auto screenManager = ScreenManager.getInstance();
    screenManager.initialize();
    
    // Register the fonts in fontFamily
    s1TitleFont = LoadFont("resources/font/sonic-1-title-card-fixed.ttf/sonic-1-title-card-fixed.ttf");
    s1ClassicOpenCFont = LoadFont("resources/font/sonic-classic-open-c.ttf/sonic-classic-open-c.ttf");
    sonicGameworldFont = LoadFont("resources/font/sonic-gameworld-ui.ttf/sonic-gameworld-ui.ttf");

    fontFamily = [s1TitleFont, s1ClassicOpenCFont, sonicGameworldFont];

    // Register the palette swap test screen as the initial screen
    screenManager.registerScreen(ScreenState.INIT, InitScreen.getInstance());
    screenManager.changeState(ScreenState.INIT);
    
    auto screenSettings = new ScreenSettings();
    
    // Main game loop
    writeln("Starting Presto Framework main loop...");
    
    while (!WindowShouldClose()) {
    int lastWindowSize = windowSize;
        float deltaTime = GetFrameTime();
        
        // Update managers
        inputManager.update(deltaTime);
        audioManager.update(deltaTime);
        screenManager.update(deltaTime);
        
        // Draw everything to virtual screen
        BeginTextureMode(virtualScreen);
            ClearBackground(Colors.BLACK);
            screenManager.draw();
        EndTextureMode();
        
        // Check options.ini for fullscreen and window size
        string iniPath = "options.ini";
        int newWindowSize = windowSize;
        if (exists(iniPath)) {
            foreach (line; File(iniPath).byLine()) {
                auto parts = line.idup.split("=");
                if (parts.length == 2) {
                    string key = parts[0].strip;
                    string value = parts[1].strip;
                    if (key == "windowSize") {
                        newWindowSize = to!int(value);
                    }
                }
            }
        }

        // Only allow dynamic window size changes if not in fullscreen
        if (!fullscreen && newWindowSize != lastWindowSize && newWindowSize > 0) {
            windowSize = newWindowSize;
            SCREEN_WIDTH = 400 * windowSize;
            SCREEN_HEIGHT = 224 * windowSize;
            SetWindowSize(SCREEN_WIDTH, SCREEN_HEIGHT);
            lastWindowSize = windowSize;
        }
        BeginDrawing();
            ClearBackground(Colors.BLACK);
            
            // Calculate scale to fit virtual screen into actual screen, maintaining aspect ratio
            float scale = min(cast(float)GetScreenWidth() / VIRTUAL_SCREEN_WIDTH, 
                              cast(float)GetScreenHeight() / VIRTUAL_SCREEN_HEIGHT);
            
            // Calculate position to center the scaled virtual screen
            float destX = (GetScreenWidth() - (VIRTUAL_SCREEN_WIDTH * scale)) / 2.0f;
            float destY = (GetScreenHeight() - (VIRTUAL_SCREEN_HEIGHT * scale)) / 2.0f;

            // Define source and destination rectangles for drawing the texture
            Rectangle sourceRec = Rectangle(0, 0, VIRTUAL_SCREEN_WIDTH, -VIRTUAL_SCREEN_HEIGHT); 
            Rectangle destRec = Rectangle(destX, destY, VIRTUAL_SCREEN_WIDTH * scale, VIRTUAL_SCREEN_HEIGHT * scale);
            Vector2 origin = Vector2(0, 0);

            DrawTexturePro(virtualScreen.texture, sourceRec, destRec, origin, 0.0f, Colors.WHITE);
            
            // Optional: Display FPS
            DrawFPS(10, 10);
            
        EndDrawing();
    }
    
    // Cleanup
    screenManager.unload();
    memManager.unloadAllResources();
    UnloadRenderTexture(virtualScreen);
    CloseAudioDevice();
    CloseWindow();
}

