// Spritesheet splitter header
#ifndef SPRITESHEET_SPLITTER_H
#define SPRITESHEET_SPLITTER_H

#include "raylib.h"

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
