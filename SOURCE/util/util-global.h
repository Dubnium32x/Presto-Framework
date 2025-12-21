// Global file
#ifndef UTIL_GLOBAL_H
#define UTIL_GLOBAL_H

#include "util-root.h"
#include "../managers/managers-root.h"
#include "../data/data-root.h"
#include "../visual/visual-root.h"
#include "../screen/screen-root.h"
#include "../entity/camera/camera-game_camera.h"

extern int screenWidth;
extern int screenHeight;
extern int windowSize;
extern bool isFullscreen;
extern bool isVSync;
extern bool isDebugMode;
extern bool sfxEnabled;
extern bool musicEnabled;
#define VIRTUAL_SCREEN_WIDTH 400
#define VIRTUAL_SCREEN_HEIGHT 240
#define TARGET_FPS 60

#define TILE_SIZE 16

#define GAME_TITLE "Presto Framework"
#define GAME_VERSION "0.2.0"

extern Options g_Options;
extern const char* g_OptionsFilePath;
extern SaveData g_SaveData;
extern ZoneType g_currentZone;
extern ActType g_currentAct;
extern ScreenManager g_ScreenManager;
extern GameCamera g_Cam;
extern bool isTitleCardActive;

// Fonts
#define DEFAULT_FONT_SIZE 14

extern Font* fontFamily[5]; // Array to hold different fonts
extern Font bearDaysFont;
extern Font geetFont;
extern Font greaterTheoryFont;
extern Font h5hFont;
extern Font metropolisFont;

#endif // UTIL_GLOBAL_H