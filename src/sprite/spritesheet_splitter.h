// Spritesheet splitter header
#ifndef SPRITESHEET_SPLITTER_H
#define SPRITESHEET_SPLITTER_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"
#include "../util/math_utils.h"
#include "sprite_manager.h"

// Function to split a spritesheet into individual sprites
typedef struct {
    Texture2D texture;
    int spriteWidth;
    int spriteHeight;
    int margin;
    int spacing;
} Spritesheet;

Texture2D* SplitSpritesheet(Spritesheet* sheet, int* outSpriteCount);
void FreeSplitSpritesheet(Texture2D* sprites, int spriteCount);
#endif // SPRITESHEET_SPLITTER_H