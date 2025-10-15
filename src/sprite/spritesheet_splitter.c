// Spritesheet splitter
#include "spritesheet_splitter.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"
#include "../util/math_utils.h"
#include "sprite_manager.h"
#include "../entity/sprite_object.h"

Texture2D* SplitSpritesheet(Spritesheet* sheet, int* outSpriteCount) {
    if (sheet == NULL || outSpriteCount == NULL || sheet->texture.id == 0 || sheet->spriteWidth <= 0 || sheet->spriteHeight <= 0) {
        *outSpriteCount = 0;
        return NULL;
    }

    int columns = (sheet->texture.width - 2 * sheet->margin + sheet->spacing) / (sheet->spriteWidth + sheet->spacing);
    int rows = (sheet->texture.height - 2 * sheet->margin + sheet->spacing) / (sheet->spriteHeight + sheet->spacing);
    int totalSprites = columns * rows;

    Texture2D* sprites = (Texture2D*)malloc(sizeof(Texture2D) * totalSprites);
    if (sprites == NULL) {
        printf("Error: Memory allocation for sprites failed.\n");
        *outSpriteCount = 0;
        return NULL;
    }

    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {
            int index = y * columns + x;
            Rectangle sourceRect = {
                sheet->margin + x * (sheet->spriteWidth + sheet->spacing),
                sheet->margin + y * (sheet->spriteHeight + sheet->spacing),
                (float)sheet->spriteWidth,
                (float)sheet->spriteHeight
            };
            Image img = LoadImageFromTexture(sheet->texture);
            Image spriteImg = ImageFromImage(img, sourceRect);
            sprites[index] = LoadTextureFromImage(spriteImg);
            UnloadImage(spriteImg);
            UnloadImage(img);
        }
    }

    *outSpriteCount = totalSprites;
    return sprites;
}