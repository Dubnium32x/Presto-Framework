// Sprite Object
// Used for rendering sprites in 2D space with position, scale, rotation, and texture
#include "sprite_object.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <raylib.h>

void InitSpriteObject(SpriteObject* sprite, int id, const char* name, Texture2D texture, Vector2 position, Vector2 scale, Color tint, float rotation, SpriteType type) {
    if (!sprite) return;

    sprite->id = id;
    sprite->name = (char*)malloc(MAX_SPRITE_NAME_LENGTH);
    strncpy(sprite->name, name, MAX_SPRITE_NAME_LENGTH - 1);
    sprite->name[MAX_SPRITE_NAME_LENGTH - 1] = '\0'; // Ensure null-termination
    sprite->texture = texture;
    sprite->position = position;
    sprite->scale = scale;
    sprite->tint = tint;
    sprite->rotation = rotation;
    sprite->type = type;
    sprite->visible = true;

    sprite->currentFrame = 0;
    sprite->totalFrames = 1;
    sprite->frameTime = 0.1f; // Default to 0.1s per frame
    sprite->frameTimer = 0.0f;
    sprite->animating = false;
    sprite->origin = (Vector2){ texture.width / 2.0f, texture.height / 2.0f }; // Center origin
}

void UpdateSpriteObject(SpriteObject* sprite, float deltaTime) {
    if (!sprite || !sprite->visible) return;

    if (sprite->animating && sprite->totalFrames > 1) {
        sprite->frameTimer += deltaTime;
        if (sprite->frameTimer >= sprite->frameTime) {
            sprite->frameTimer -= sprite->frameTime;
            sprite->currentFrame = (sprite->currentFrame + 1) % sprite->totalFrames;
        }
    }
}

void DrawSpriteObject(const SpriteObject* sprite) {
    if (!sprite || !sprite->visible) return;

    Rectangle sourceRec = { 0.0f, 0.0f, (float)sprite->texture.width, (float)sprite->texture.height };
    if (sprite->totalFrames > 1) {
        float frameWidth = (float)sprite->texture.width / (float)sprite->totalFrames;
        sourceRec.x = frameWidth * sprite->currentFrame;
        sourceRec.width = frameWidth;
    }

    DrawTexturePro(
        sprite->texture,
        sourceRec,
        (Rectangle){ sprite->position.x, sprite->position.y, sourceRec.width * sprite->scale.x, sourceRec.height * sprite->scale.y },
        sprite->origin,
        sprite->rotation,
        sprite->tint
    );
}

void SetPosition(SpriteObject* sprite, Vector2 position) {
    if (!sprite) return;
    sprite->position = position;
}

void SetScale(SpriteObject* sprite, Vector2 scale) {
    if (!sprite) return;
    sprite->scale = scale;
}

void SetTint(SpriteObject* sprite, Color tint) {
    if (!sprite) return;
    sprite->tint = tint;
}

void SetSpriteVisible(SpriteObject* sprite, bool visible) {
    if (!sprite) return;
    sprite->visible = visible;
}

void SetRotation(SpriteObject* sprite, float rotation) {
    if (!sprite) return;
    sprite->rotation = rotation;
}

void StartAnimation(SpriteObject* sprite, int totalFrames, float frameTime) {
    if (!sprite || totalFrames <= 1 || frameTime <= 0.0f) return;
    sprite->totalFrames = (totalFrames > MAX_SPRITE_FRAMES) ? MAX_SPRITE_FRAMES : totalFrames;
    sprite->frameTime = frameTime;
    sprite->currentFrame = 0;
    sprite->frameTimer = 0.0f;
    sprite->animating = true;
}

void StopSpriteAnimation(SpriteObject* sprite) {
    if (!sprite) return;
    sprite->animating = false;
    sprite->currentFrame = 0;
    sprite->frameTimer = 0.0f;
}

void SetSpriteAnimationFrame(SpriteObject* sprite, int frame) {
    if (!sprite || frame < 0 || frame >= sprite->totalFrames) return;
    sprite->currentFrame = frame;
    sprite->frameTimer = 0.0f;
}

