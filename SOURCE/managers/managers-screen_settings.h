// Screen Settings header
#ifndef MANAGERS_SCREEN_SETTINGS_H
#define MANAGERS_SCREEN_SETTINGS_H

#include "raylib.h"
#include <stddef.h>
#include <stdint.h>
#include "../util/util-global.h"
#include "../visual/visual-root.h"

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
#endif // MANAGERS_SCREEN_SETTINGS_H