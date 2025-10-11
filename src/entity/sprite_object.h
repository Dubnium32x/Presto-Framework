// Sprite object header
#ifndef SPRITE_OBJECT_H
#define SPRITE_OBJECT_H

#include <raylib.h>
#include <stdbool.h>
#include <math.h>
#include <stdio.h>

#define MAX_SPRITE_NAME_LENGTH 64
#define MAX_SPRITE_FRAMES 64

typedef enum {
    PLAYER,
    ENEMY,
    ITEM,
    BACKGROUND,
    EFFECT,
    UI,
    NORMAL,
    DECOR,
    OTHER,
    NULL_TYPE
} SpriteType;

typedef struct {
    int id;
    char* name;
    Texture2D texture;
    Vector2 position;
    Vector2 scale;
    Color tint;
    float rotation; // in degrees
    SpriteType type;
    bool visible;

    int currentFrame;
    int totalFrames;
    float frameTime; // Time per frame in seconds
    float frameTimer; // Accumulated time for frame switching
    bool animating;
    Vector2 origin; // Origin point for rotation and scaling
} SpriteObject;

void InitSpriteObject(SpriteObject* sprite, int id, const char* name, Texture2D texture, Vector2 position, Vector2 scale, Color tint, float rotation, SpriteType type);
void UpdateSpriteObject(SpriteObject* sprite, float deltaTime);
void DrawSpriteObject(const SpriteObject* sprite);
void SetPosition(SpriteObject* sprite, Vector2 position);
void SetScale(SpriteObject* sprite, Vector2 scale);
void SetTint(SpriteObject* sprite, Color tint);
void SetPaletteColor(SpriteObject* sprite, Color color); // Example of additional function
void SetSpriteVisible(SpriteObject* sprite, bool visible);
void SetRotation(SpriteObject* sprite, float rotation);
void StartAnimation(SpriteObject* sprite, int totalFrames, float frameTime);
void StopSpriteAnimation(SpriteObject* sprite);
void SetSpriteAnimationFrame(SpriteObject* sprite, int frame);
void UnloadSpriteObject(SpriteObject* sprite);