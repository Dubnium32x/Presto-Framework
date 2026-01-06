/*
    PRESTO FRAMEWORK
    Version 0.2.0

    This is a simple game framework designed to
    help developers quickly create 2D games using C23
    and the Raylib library. It is mainly focused on
    to be a Sonic the Hedgehog style framework. 

    It provides a set of tools and utilities to handle
    common game development tasks such as rendering, input handling, physics, and more.

    The framework is designed to be lightweight, easy to use, and highly extensible,
    allowing developers to focus on creating fun and engaging gameplay experiences.


    If you want to contribute to the development of the Presto Framework,
    feel free to fork the repository and submit pull requests.

    Thank you for using the Presto Framework!

*/

#include "raylib.h"
#include "util/util-global.h"
#include "visual/visual-sprite_fonts.h"
#include <stdio.h>
#include <string.h>
#include <stdint.h>

int main(void) {
    // Initialize Raylib window first
    InitWindow(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, GAME_TITLE " - " GAME_VERSION);
    SetTargetFPS(TARGET_FPS);
    // Initialize audio device
    InitAudioDevice();
    
    // Create render texture for pixel-perfect rendering
    RenderTexture2D virtualScreen = LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT);
    
    // Set texture filter to point filtering for crisp pixels
    SetTextureFilter(virtualScreen.texture, TEXTURE_FILTER_POINT);
    
    // Load options from file
    LoadOptions("options.cfg");
    ApplyCurrentOptions();

    // Now initialize screen settings (which may modify window properties)
    InitScreenSettings();
    PrestoSetWindowSize(g_Options.screenSize);
    
    // Initialize sprite fonts
    InitSpriteFontManager();

    // Init the input
    InitUnifiedInput();

    // Initialize screen manager and register screens
    InitScreenManager(&g_ScreenManager);
    RegisterScreen(&g_ScreenManager, SCREEN_STATE_INIT, InitScreen_Init, InitScreen_Update, InitScreen_Draw, InitScreen_Unload);
    RegisterScreen(&g_ScreenManager, SCREEN_STATE_TITLE, TitleScreen_Init, TitleScreen_Update, TitleScreen_Draw, TitleScreen_Unload);   
    RegisterScreen(&g_ScreenManager, SCREEN_STATE_OPTIONS, OptionsScreen_Init, OptionsScreen_Update, OptionsScreen_Draw, OptionsScreen_Unload);

    SetCurrentScreen(&g_ScreenManager, SCREEN_STATE_INIT);

    while (!WindowShouldClose()) {
        UpdateScreenManager(&g_ScreenManager, GetFrameTime());
        
        // Update unified input system
        UpdateUnifiedInput(GetFrameTime());

        // Render to virtual screen first
        BeginTextureMode(virtualScreen);
        DrawScreenManager(&g_ScreenManager);
        EndTextureMode();
        
        // Then render virtual screen to actual window, scaled up
        BeginDrawing();
        ClearBackground(BLACK);
        
        // Calculate scaling to fit window while maintaining aspect ratio
        float windowWidth = (float)GetScreenWidth();
        float windowHeight = (float)GetScreenHeight();
        float scaleX = windowWidth / VIRTUAL_SCREEN_WIDTH;
        float scaleY = windowHeight / VIRTUAL_SCREEN_HEIGHT;
        float scale = (scaleX < scaleY) ? scaleX : scaleY; // Use smaller scale to fit
        
        float scaledWidth = VIRTUAL_SCREEN_WIDTH * scale;
        float scaledHeight = VIRTUAL_SCREEN_HEIGHT * scale;
        float offsetX = (windowWidth - scaledWidth) / 2.0f;
        float offsetY = (windowHeight - scaledHeight) / 2.0f;
        
        // Draw the virtual screen texture scaled up
        Rectangle source = {0, 0, VIRTUAL_SCREEN_WIDTH, -VIRTUAL_SCREEN_HEIGHT}; // Flip Y
        Rectangle dest = {offsetX, offsetY, scaledWidth, scaledHeight};
        DrawTexturePro(virtualScreen.texture, source, dest, (Vector2){0, 0}, 0.0f, WHITE);
        
        // Draw FPS if enabled in cfg
        if (g_Options.showFPS) {
            DrawText(TextFormat("FPS: %d", GetFPS()), 10, 10, 14, GREEN);
        }
        EndDrawing();
    }

    UnloadRenderTexture(virtualScreen);
    UnloadScreenManager(&g_ScreenManager);
    UnloadScreenSettings();
    CleanupSpriteFontManager();
    CloseAudioDevice();
    CloseWindow();

    return 0;
}