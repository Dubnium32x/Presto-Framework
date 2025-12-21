#include "util-global.h"
#include "raylib.h"

// Global variable definitions
int screenWidth = VIRTUAL_SCREEN_WIDTH;
int screenHeight = VIRTUAL_SCREEN_HEIGHT;
int windowSize = 1;
bool isFullscreen = false;
bool isVSync = true;
bool isDebugMode = false;

bool sfxEnabled = true;
bool musicEnabled = true;

SaveData g_SaveData = {0};
ZoneType g_currentZone = 0;
ActType g_currentAct = 0;
ScreenManager g_ScreenManager = {0};
GameCamera g_Cam = {0};


Font* fontFamily[5] = {0};
Font bearDaysFont = {0};
Font geetFont = {0};
Font greaterTheoryFont = {0};
Font h5hFont = {0};
Font metropolisFont = {0};
