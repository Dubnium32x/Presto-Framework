// Sprite manager header
#ifndef SPRITE_MANAGER_H
#define SPRITE_MANAGER_H

#include "raylib.h"
#include "../entity/sprite_object.h"
#include "../util/math_utils.h"
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define MAX_SPRITES 256
#define MAX_SPRITES_PER_TYPE 64
#define MAX_SPRITE_NAME_LENGTH 64

typedef enum {
    SPRITE_MANAGER_UNINITIALIZED = 0,
    SPRITE_MANAGER_INITIALIZED = 1
} SpriteManagerState;

typedef struct {
    SpriteObject* sprites[MAX_SPRITES];
    int spriteCount;
    SpriteManagerState state;
} SpriteManager;

void InitSpriteManager(SpriteManager* manager);
void AddSprite(SpriteManager* manager, SpriteObject* sprite);
void RemoveSprite(SpriteManager* manager, int spriteId);
void UpdateSprites(SpriteManager* manager, float deltaTime);
void DrawSprites(const SpriteManager* manager);
Rectangle GetRectangleByFrameIndex(int frameIndex);
Texture2D GetTextureByAnimation(char* animationName);
void LoadSprite(SpriteManager* manager, const char* filePath, int id, const char* name, Vector2 position, Vector2 scale, Color tint, float rotation, SpriteType type);
void UnloadAllSprites(SpriteManager* manager);
#endif // SPRITE_MANAGER_H