// Screen Settings header
#ifndef SCREEN_SETTINGS_H
#define SCREEN_SETTINGS_H

#include "raylib.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include "../util/globals.h"

// Screen setting aliases - these reference the global variables
#define PRESTO_SCREEN_WIDTH screenWidth
#define PRESTO_SCREEN_HEIGHT screenHeight
#define PRESTO_WINDOW_SIZE windowSize
#define PRESTO_FULLSCREEN isFullscreen
#define PRESTO_VSYNC isVSync
#define PRESTO_DEBUG_MODE isDebugMode

typedef enum {
    SCREEN_SETTING_UNINITIALIZED,
    SCREEN_SETTING_INITIALIZED
} ScreenSettingState;

typedef enum {
    ONE_X = 1,
    TWO_X = 2,
    THREE_X = 3,
    FOUR_X = 4
} WindowSize;

typedef enum {
    WINDOW_TYPE_FULLSCREEN,
    WINDOW_TYPE_WINDOWED,
    WINDOW_TYPE_BORDERLESS
} WindowType;

void InitScreenSettings();
void ApplyScreenSettings(int width, int height, int windowSize, bool fullscreen, bool vsync, bool debugMode);
void ToggleGameFullscreen();
void SetVSync(bool vsync);
void SetDebugMode(bool debugMode);
void PrestoSetWindowSize(int size);
void UpdateScreenSettings(int width, int height, int windowSize, bool fullscreen, bool vsync, bool debugMode);
void GetScreenSettings(int* width, int* height, int* windowSize, bool* fullscreen, bool* vsync, bool* debugMode);
void InitScreenSettings();
void UnloadScreenSettings();
#endif // SCREEN_SETTINGS_H