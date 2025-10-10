// Globals

#ifndef GLOBALS_H
#define GLOBALS_H

#include <raylib.h>
#include <stdio.h>
#include <stdlib.h>

// Screen dimensions
#define VIRTUAL_SCREEN_WIDTH 400
#define VIRTUAL_SCREEN_HEIGHT 240

extern int screenWidth;
extern int screenHeight;
extern int windowSize;

// Fonts
Font s1TitleFont;
Font s1ClassicOpenCFont;
Font sonicGameworldFont;

Font fontFamily[] = {s1TitleFont, s1ClassicOpenCFont, sonicGameworldFont};

