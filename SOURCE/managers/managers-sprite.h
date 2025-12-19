// Sprite manager header
#ifndef MANAGERS_SPRITE_H
#define MANAGERS_SPRITE_H

#include <raylib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../entity/entity-sprite_object.h"

#define MAX_SPRITES 256

typedef struct {
    SpriteObject* sprites[MAX_SPRITES];
    int spriteCount;
} SpriteManager;

extern SpriteManager* gSpriteManager;

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