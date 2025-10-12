// Screen Settings implementation
#include "screen_settings.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"
#include "../util/globals.h"
#include "screen_manager.h"

void InitScreenSettings() {
    // Initialize screen settings with default values
    windowSize = ONE_X;
    screenWidth = VIRTUAL_SCREEN_WIDTH * windowSize;
    screenHeight = VIRTUAL_SCREEN_HEIGHT * windowSize;
    isFullscreen = false;
    isVSync = true;
    isDebugMode = false;

    // Apply initial settings
    ApplyScreenSettings(screenWidth, screenHeight, windowSize, isFullscreen, isVSync, isDebugMode);
}

void ApplyScreenSettings(int width, int height, int winSize, bool fullscreen, bool vsync, bool debugMode) {
    // Set screen dimensions
    screenWidth = width;
    screenHeight = height;
    windowSize = winSize;
    isFullscreen = fullscreen;
    isVSync = vsync;
    isDebugMode = debugMode;

    // Calculate actual window size
    int actualWidth = screenWidth * (windowSize + 1);
    int actualHeight = screenHeight * (windowSize + 1);

    // Set window mode
    if (isFullscreen) {
        SetWindowState(FLAG_FULLSCREEN_MODE);
        SetWindowSize(actualWidth, actualHeight);
    } else {
        ClearWindowState(FLAG_FULLSCREEN_MODE);
        SetWindowSize(actualWidth, actualHeight);
        SetWindowPosition((GetMonitorWidth(0) - actualWidth) / 2, (GetMonitorHeight(0) - actualHeight) / 2);
    }

    // Set VSync
    SetConfigFlags(isVSync ? FLAG_VSYNC_HINT : 0);

    // Set debug mode (if applicable)
    if (isDebugMode) {
        // Enable debug features here
        printf("Debug mode enabled\n");
    } else {
        // Disable debug features here
        printf("Debug mode disabled\n");
    }

    // Apply changes
    SetWindowTitle(GAME_TITLE " - " VERSION);
}

void ToggleGameFullscreen() {
    if (IsWindowFullscreen()) {
        ToggleBorderlessWindowed();
        SetWindowSize(screenWidth, screenHeight);
    } else {
        ToggleBorderlessWindowed();
    }
}

void SetVSync(bool vsync) {
    isVSync = vsync;
    ApplyScreenSettings(screenWidth, screenHeight, windowSize, isFullscreen, isVSync, isDebugMode);
}

void SetDebugMode(bool debugMode) {
    isDebugMode = debugMode;
    ApplyScreenSettings(screenWidth, screenHeight, windowSize, isFullscreen, isVSync, isDebugMode);
}

void PrestoSetWindowSize(int size) {
    if (size < ONE_X || size > FOUR_X) {
        printf("Error: Invalid window size %d\n", size);
        return;
    }
    windowSize = size;
    ApplyScreenSettings(screenWidth, screenHeight, windowSize, isFullscreen, isVSync, isDebugMode);
}

void UpdateScreenSettings(int width, int height, int winSize, bool fullscreen, bool vsync, bool debugMode) {
    ApplyScreenSettings(width, height, winSize, fullscreen, vsync, debugMode);
}

void GetScreenSettings(int* width, int* height, int* winSize, bool* fullscreen, bool* vsync, bool* debugMode) {
    if (width) *width = screenWidth;
    if (height) *height = screenHeight;
    if (winSize) *winSize = windowSize;
    if (fullscreen) *fullscreen = isFullscreen;
    if (vsync) *vsync = isVSync;
    if (debugMode) *debugMode = isDebugMode;
}

void UnloadScreenSettings() {
    // Cleanup if necessary
    // Currently nothing to unload
}