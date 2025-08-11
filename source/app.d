module app;

import raylib;

import std.stdio;
import std.file;
import std.process;
import std.path;
import std.string;
import std.algorithm;
import utils.rvw_converter;

import data;
import world.screen_manager;
import world.screen_state;
import world.audio_manager;
import world.memory_manager;
import world.input_manager;
import world.screen_settings;
import screens.palette_swap_test_screen;

// Define the world settings
public const int SCREEN_WIDTH = 800;
public const int SCREEN_HEIGHT = 448;
public int VIRTUAL_SCREEN_WIDTH = 400;
public int VIRTUAL_SCREEN_HEIGHT = 224;

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
    ConvertJSON2RVW("resources/data/levels/levels.rvw", 0, "resources/data/levels/LEVEL_0/LEVEL_0.json", "resources/data/levels/LEVEL_0/metadata.json");

    InitAudioDevice();
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Presto Framework Pre-Alpha v 0.1.0");
    SetTargetFPS(60);

    SetExitKey(KeyboardKey.KEY_ESCAPE);

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
    
    // Register the palette swap test screen as the initial screen
    screenManager.registerScreen(ScreenState.PALETTE_SWAP_TEST, PaletteSwapTestScreen.getInstance());
    screenManager.changeState(ScreenState.PALETTE_SWAP_TEST);
    
    auto screenSettings = new ScreenSettings();
    
    // Main game loop
    writeln("Starting Presto Framework main loop...");
    
    while (!WindowShouldClose()) {
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
        
        // Draw virtual screen to actual window with scaling
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

