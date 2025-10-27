// Globals

#ifndef GLOBALS_H
#define GLOBALS_H

#include <raylib.h>
#include <stdio.h>
#include <stdlib.h>
#include "../camera/game_camera.h"
#include "../world/audio_manager.h"

// Global constants
#define VERSION "0.1.2"
#define GAME_TITLE "Presto Framework Pre-Alpha"

// Screen dimensions
#define VIRTUAL_SCREEN_WIDTH 400
#define VIRTUAL_SCREEN_HEIGHT 240

#define TILE_SIZE 16

extern GameCamera cam;
extern bool isTitleCardActive;

extern int screenWidth;
extern int screenHeight;
extern int windowSize;
extern bool isFullscreen;
extern bool isVSync;
extern bool isDebugMode;

// Fonts
extern Font s1TitleFont;
extern Font s1ClassicOpenCFont;
extern Font sonicGameworldFont;

extern Font fontFamily[3];


// Global audio manager
extern AudioManager g_audioManager;

typedef struct {
    int x, y, w, h;
} Hitbox_t;

#endif // GLOBALS_H