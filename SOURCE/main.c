// Presto Framework Mini - Simple main entry point
#include "raylib.h"
#include "util/util-global.h"
#include "screen/screen-init.h"
#include "screen/screen-debug1.h"
#include "screen/screen-debug2.h"
#include "screen/screen-debug3.h"
#include "screen/screen-debug4.h"
#include "data/data-data.h"
#include <stdio.h>

int main(void) {
    // Initialize the fonts
    bearDaysFont = LoadFont("resources/fonts/bear-days.regular.ttf");
    geetFont = LoadFont("resources/fonts/geet.regular.ttf");
    greaterTheoryFont = LoadFont("resources/fonts/greater-theory.regular.otf");
    h5hFont = LoadFont("resources/fonts/h5h.regular.ttf");
    metropolisFont = LoadFont("resources/fonts/metropolis.regular.otf");

    // Load global options
    g_OptionsFilePath = "options.ini";
    InitOptions();

    // Initialize screen manager first
    printf("Initializing screen manager...\n");
    InitScreenManager(gScreenManager);
    
    // Register the screens
    printf("Registering screens...\n");
    RegisterScreen(gScreenManager, SCREEN_STATE_INIT, InitScreenInit, InitScreenUpdate, InitScreenDraw, InitScreenUnload);
    RegisterScreen(gScreenManager, SCREEN_STATE_DEBUG1, Debug1ScreenInit, Debug1ScreenUpdate, Debug1ScreenDraw, Debug1ScreenUnload);
    RegisterScreen(gScreenManager, SCREEN_STATE_DEBUG2, Debug2ScreenInit, Debug2ScreenUpdate, Debug2ScreenDraw, Debug2ScreenUnload);
    RegisterScreen(gScreenManager, SCREEN_STATE_DEBUG3, Debug3ScreenInit, Debug3ScreenUpdate, Debug3ScreenDraw, Debug3ScreenUnload);
    RegisterScreen(gScreenManager, SCREEN_STATE_DEBUG4, Debug4ScreenInit, Debug4ScreenUpdate, Debug4ScreenDraw, Debug4ScreenUnload);
    printf("Screens registered.\n");

    // Set initial screen
    printf("Setting initial screen...\n");
    SetCurrentScreen(gScreenManager, SCREEN_STATE_INIT);
    printf("Initial screen set.\n");

    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, WINDOW_TITLE " " GAME_VERSION);
    SetTargetFPS(TARGET_FPS);
    
    printf("Presto Framework Mini initialized!\n");
    printf("Window: %dx%d\n", SCREEN_WIDTH, SCREEN_HEIGHT);
    printf("Ready for screen management...\n");
    
    // Main game loop using screen manager
    while (!WindowShouldClose()) {
        float deltaTime = GetFrameTime();
        
        // Update current screen
        UpdateScreenManager(gScreenManager, deltaTime);
        
        // Draw current screen
        BeginDrawing();
        DrawScreenManager(gScreenManager);
        EndDrawing();
    }
    
    // Cleanup
    UnloadScreenManager(gScreenManager);
    CloseWindow();
    
    printf("Presto Framework Mini shutdown complete.\n");
    return 0;
}