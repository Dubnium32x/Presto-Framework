// Screen State Implementation - Simplified for 2D focus
#include <stdio.h>
#include "raylib.h"
#include "screen_state.h"

void InitScreenState(ScreenState* state) {
    if (!state) return;

    state->currentScreen = SCREEN_INIT;
    state->frameCounter = 0;
    state->isPaused = false;

    printf("✓ Screen State initialized\n");
}

void UpdateScreenState(ScreenState* state, float deltaTime) {
    (void)deltaTime; // Suppress unused parameter warning
    if (!state) return;

    state->frameCounter++;
    
    // Handle pause state
    if (state->isPaused) {
        return; // Skip updates when paused
    }

    // Basic screen state logic
    switch (state->currentScreen) {
        case SCREEN_INIT:
            // Auto-transition to title after a frame
            if (state->frameCounter > 1) {
                state->currentScreen = SCREEN_TITLE;
            }
            break;
            
        case SCREEN_TITLE:
            // Stay in title screen until user input
            break;
            
        case SCREEN_GAMEPLAY:
            // Game update logic happens in main loop
            break;
            
        default:
            break;
    }
}

void DrawScreenState(ScreenState* state) {
    if (!state) return;

    // Simple screen rendering
    switch (state->currentScreen) {
        case SCREEN_INIT:
            DrawText("Initializing...", 10, 10, 20, WHITE);
            break;
            
        case SCREEN_SPLASH:
            DrawText("Jacky and Wacky", 50, 100, 40, WHITE);
            DrawText("A Dreamcast Homebrew Game", 50, 150, 20, LIGHTGRAY);
            break;
            
        case SCREEN_TITLE:
            DrawText("JACKY AND WACKY", 50, 80, 30, WHITE);
            DrawText("Press ENTER to Start", 50, 120, 16, LIGHTGRAY);
            DrawText("WASD: Move, Shift: Run, Space: Jump", 50, 140, 12, GRAY);
            break;
            
        case SCREEN_GAMEPLAY:
            // 3D scene rendering happens in main loop via handler3d
            break;
            
        case SCREEN_PAUSE:
            DrawText("PAUSED", 100, 100, 30, YELLOW);
            DrawText("Press P to Resume", 100, 140, 16, WHITE);
            break;
            
        default:
            DrawText("Unknown Screen", 10, 10, 20, RED);
            break;
    }
}

void UnloadScreenState(ScreenState* state) {
    if (!state) return;
    
    // Simple cleanup - no complex resources to unload in 2D focus mode
    state->currentScreen = SCREEN_INIT;
    state->frameCounter = 0;
    state->isPaused = false;
    
    printf("Screen State unloaded\n");
}

void SetScreen(ScreenState* state, ScreenType newScreen) {
    if (!state) return;
    
    printf("Screen transition: %d -> %d\n", state->currentScreen, newScreen);
    state->currentScreen = newScreen;
    state->frameCounter = 0;
}

// Transition functions moved to transition_manager.c to avoid duplicates