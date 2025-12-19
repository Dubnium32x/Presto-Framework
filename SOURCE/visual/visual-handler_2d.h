// 2D Visual Handler interface for Presto Framework Mini
#pragma once

#include "raylib.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

// Sprite instance for 2D rendering
typedef struct {
    Texture2D texture;
    Vector2 position;
    float rotation;
    Vector2 scale;
    Color tint;
    Rectangle sourceRect;  // For sprite sheets
} SpriteInstance;

// 2D Sprite handler
typedef struct {
    SpriteInstance* sprites;
    size_t spriteCount;
} SpriteHandler;

// 2D Background/parallax layer
typedef struct {
    Texture2D texture;
    Vector2 position;
    Vector2 scrollSpeed;
    bool repeating;
} BackgroundLayer;

// 2D Background handler
typedef struct {
    BackgroundLayer* layers;
    size_t layerCount;
} BackgroundHandler;

// 2D particle system
typedef struct {
    Vector2 position;
    Vector2 velocity;
    Color color;
    float lifetime;
    float age;
    float size;
} Particle;

typedef struct {
    Particle* particles;
    size_t particleCount;
    size_t maxParticles;
} ParticleSystem;

// SpriteHandler functions
SpriteHandler* Handler2D_CreateSpriteHandler(void);
int Handler2D_AddSprite(SpriteHandler* handler, Texture2D texture, Vector2 position, 
                        float rotation, Vector2 scale, Color tint);
int Handler2D_AddSpriteSheet(SpriteHandler* handler, Texture2D texture, Vector2 position,
                              Rectangle sourceRect, float rotation, Vector2 scale, Color tint);
void Handler2D_UpdateSprite(SpriteHandler* handler, int index, Vector2 position, float rotation, Vector2 scale);
void Handler2D_RenderSprites(SpriteHandler* handler, Vector2 cameraOffset);
void Handler2D_DestroySpriteHandler(SpriteHandler* handler);

// BackgroundHandler functions
BackgroundHandler* Handler2D_CreateBackgroundHandler(void);
int Handler2D_AddLayer(BackgroundHandler* handler, Texture2D texture, Vector2 scrollSpeed, bool repeating);
void Handler2D_UpdateBackground(BackgroundHandler* handler, float deltaTime);
void Handler2D_RenderBackground(BackgroundHandler* handler, Vector2 cameraOffset);
void Handler2D_DestroyBackgroundHandler(BackgroundHandler* handler);

// ParticleSystem functions
ParticleSystem* Handler2D_CreateParticleSystem(size_t maxParticles);
void Handler2D_EmitParticle(ParticleSystem* system, Vector2 position, Vector2 velocity, 
                            Color color, float lifetime, float size);
void Handler2D_UpdateParticles(ParticleSystem* system, float deltaTime);
void Handler2D_RenderParticles(ParticleSystem* system);
void Handler2D_DestroyParticleSystem(ParticleSystem* system);   