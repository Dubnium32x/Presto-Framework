// Global file
#pragma once

#include "util-root.h"
#include "../managers/managers-root.h"

// Global Variables
#define VIRTUAL_SCREEN_WIDTH 400
#define VIRTUAL_SCREEN_HEIGHT 240
#define TARGET_FPS 60

#define TILE_SIZE 16

#define GAME_TITLE "Presto Framework"
#define GAME_VERSION "0.2.0"

// extern GameCamera cam;
// extern bool isTitleCardActive;

extern int screenWidth;
extern int screenHeight;
extern int windowSize;
extern bool isFullscreen;
extern bool isVSync;
extern bool isDebugMode;

// Fonts
#define DEFAULT_FONT_SIZE 14

extern Font* fontFamily[5]; // Array to hold different fonts
extern Font bearDaysFont;
extern Font geetFont;
extern Font greaterTheoryFont;
extern Font h5hFont;
extern Font metropolisFont;