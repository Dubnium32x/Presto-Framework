// Globals

#ifndef GLOBALS_H
#define GLOBALS_H

#include <raylib.h>
#include <stdio.h>
#include <stdlib.h>

// Global constants
#define VERSION "0.1.0"
#define GAME_TITLE "Presto Framework Demo"

// Screen dimensions
#define VIRTUAL_SCREEN_WIDTH 400
#define VIRTUAL_SCREEN_HEIGHT 240

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

#endif // GLOBALS_H