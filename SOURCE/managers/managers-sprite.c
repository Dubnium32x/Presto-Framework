// Sprite Manager
#include "managers-sprite.h"

void InitSpriteManager(SpriteManager* manager) {
    if (manager == NULL) return;
    manager->spriteCount = 0;
    for (int i = 0; i < MAX_SPRITES; i++) {
        manager->sprites[i] = NULL;
    }
}

void AddSprite(SpriteManager* manager, SpriteObject* sprite) {
    if (manager == NULL || sprite == NULL) return;
    if (manager->spriteCount >= MAX_SPRITES) {
        printf("Error: Maximum sprite limit reached.\n");
        return;
    }
    manager->sprites[manager->spriteCount++] = sprite;
}

void RemoveSprite(SpriteManager* manager, int spriteId) {
    if (manager == NULL) return;
    for (int i = 0; i < manager->spriteCount; i++) {
        if (manager->sprites[i] != NULL && manager->sprites[i]->id == spriteId) {
            UnloadTexture(manager->sprites[i]->texture);
            free(manager->sprites[i]);
            manager->sprites[i] = NULL;
            // Shift remaining sprites
            for (int j = i; j < manager->spriteCount - 1; j++) {
                manager->sprites[j] = manager->sprites[j + 1];
            }
            manager->sprites[--manager->spriteCount] = NULL;
            return;
        }
    }
    printf("Warning: Sprite with ID %d not found.\n", spriteId);
}

void UpdateSprites(SpriteManager* manager, float deltaTime) {
    if (manager == NULL) return;
    for (int i = 0; i < manager->spriteCount; i++) {
        SpriteObject* sprite = manager->sprites[i];
        if (sprite != NULL && sprite->animating) {
            sprite->frameTimer += deltaTime;
            if (sprite->frameTimer >= sprite->frameTime) {
                sprite->currentFrame = (sprite->currentFrame + 1) % sprite->totalFrames;
                sprite->frameTimer = 0.0f;
            }
        }
    }
}

void DrawSprites(const SpriteManager* manager) {
    if (manager == NULL) return;
    for (int i = 0; i < manager->spriteCount; i++) {
        SpriteObject* sprite = manager->sprites[i];
        if (sprite != NULL && sprite->visible) {
            Rectangle sourceRec = GetRectangleByFrameIndex(sprite->currentFrame);
            Vector2 origin = sprite->origin;
            DrawTexturePro(sprite->texture, sourceRec, (Rectangle){ sprite->position.x, sprite->position.y, sourceRec.width * sprite->scale.x, sourceRec.height * sprite->scale.y }, origin, sprite->rotation, sprite->tint);
        }
    }
}

Rectangle GetRectangleByFrameIndex(int frameIndex) {
    // Assuming each frame is 64x64 pixels for simplicity
    int frameWidth = 64;
    int frameHeight = 64;
    return (Rectangle){ frameIndex * frameWidth, 0, frameWidth, frameHeight };
}

Texture2D GetTextureByAnimation(char* animationName) {
    (void)animationName; // Suppress unused parameter warning
    // Placeholder function: In a real implementation, this would look up the texture based on the animation name
    // For now, return a dummy texture
    Texture2D dummyTexture = LoadTexture("path/to/dummy.png");
    return dummyTexture;
}

void LoadSprite(SpriteManager* manager, const char* filePath, int id, const char* name, Vector2 position, Vector2 scale, Color tint, float rotation, SpriteType type) {
    if (manager == NULL || filePath == NULL || name == NULL) return;
    SpriteObject* sprite = (SpriteObject*)malloc(sizeof(SpriteObject));
    if (sprite == NULL) {
        printf("Error: Memory allocation for sprite failed.\n");
        return;
    }
    memset(sprite, 0, sizeof(SpriteObject));
    sprite->id = id;
    strncpy(sprite->name, name, MAX_SPRITE_NAME_LENGTH - 1);
    sprite->name[MAX_SPRITE_NAME_LENGTH - 1] = '\0';
    sprite->texture = LoadTexture(filePath);
    if (sprite->texture.id == 0) {
        printf("Error: Failed to load texture from %s\n", filePath);
        free(sprite);
        return;
    }
    sprite->position = position;
    sprite->scale = scale;
    sprite->tint = tint;
    sprite->rotation = rotation;
    sprite->type = type;
    sprite->visible = true;
    sprite->currentFrame = 0;
    sprite->totalFrames = 1; // Default to 1 frame
    sprite->frameTime = 0.1f; // Default frame time
    sprite->frameTimer = 0.0f;
    sprite->animating = false;
    sprite->origin = (Vector2){ 0.0f, 0.0f }; // Top-left by default

    AddSprite(manager, sprite);
}

void UnloadAllSprites(SpriteManager* manager) {
    if (manager == NULL) return;
    for (int i = 0; i < manager->spriteCount; i++) {
        if (manager->sprites[i] != NULL) {
            UnloadTexture(manager->sprites[i]->texture);
            free(manager->sprites[i]);
            manager->sprites[i] = NULL;
        }
    }
    manager->spriteCount = 0;
}


