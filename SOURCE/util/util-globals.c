// Global variable definitions
#include "util-global.h"
#include "raylib.h"

// Font definitions
Font* fontFamily[5] = {NULL}; // Array to hold different fonts
Font bearDaysFont = {0};
Font geetFont = {0};
Font greaterTheoryFont = {0};
Font h5hFont = {0};
Font metropolisFont = {0};

// Screen manager definition
ScreenManager gScreenManagerInstance = {0};
ScreenManager* gScreenManager = &gScreenManagerInstance;

bool screenManagerInitialized = false;