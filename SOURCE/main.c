/*
    PRESTO FRAMEWORK
    Version 0.2.0

    This is a simple game framework designed to
    help developers quickly create 2D games using C23
    and the Raylib library. It is mainly focused on
    to be a Sonic the Hedgehog style framework. 

    It provides a set of tools and utilities to handle
    common game development tasks such as rendering, input handling, physics, and more.

    The framework is designed to be lightweight, easy to use, and highly extensible,
    allowing developers to focus on creating fun and engaging gameplay experiences.


    If you want to contribute to the development of the Presto Framework,
    feel free to fork the repository and submit pull requests.

    Thank you for using the Presto Framework!

*/

#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

// Ensure PATH_MAX is defined on all platforms
#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"

#include "util/util-global.h"
#include "managers/managers-root.h"
#include "screen/screen-root.h"

// GameCamera cam;
// Player player;

// Global variables
const int scrMult = 2;
int screenWidth = 400 * scrMult;
int screenHeight = 240 * scrMult;

// Function to get mouse position in virtual screen coordinates
Vector2 GetMousePositionVirtual(void) {
    Vector2 mouseScreenPos = GetMousePosition();
    
    float scale = fminf((float)GetScreenWidth() / VIRTUAL_SCREEN_WIDTH, 
                        (float)GetScreenHeight() / VIRTUAL_SCREEN_HEIGHT);
                        
    // Calculate the top-left position of the scaled virtual screen on the actual screen
    float destX = (GetScreenWidth() - (VIRTUAL_SCREEN_WIDTH * scale)) / 2.0f;
    float destY = (GetScreenHeight() - (VIRTUAL_SCREEN_HEIGHT * scale)) / 2.0f;

    // Convert screen mouse position to virtual screen mouse position
    float virtualMouseX = (mouseScreenPos.x - destX) / scale;
    float virtualMouseY = (mouseScreenPos.y - destY) / scale;

    return (Vector2){virtualMouseX, virtualMouseY};
}