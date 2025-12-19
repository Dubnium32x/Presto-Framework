// 2D Visual Handler implementation for Presto Framework Mini
#include "visual-handler_2d.h"
#include <string.h>

// ===== SpriteHandler =====

SpriteHandler* Handler2D_CreateSpriteHandler(void) {
    SpriteHandler* handler = (SpriteHandler*)malloc(sizeof(SpriteHandler));
    if (!handler) return NULL;
    
    handler->sprites = NULL;
    handler->spriteCount = 0;
    
    return handler;
}

int Handler2D_AddSprite(SpriteHandler* handler, Texture2D texture, Vector2 position, 
                        float rotation, Vector2 scale, Color tint) {
    if (!handler) return -1;
    
    SpriteInstance* newSprites = (SpriteInstance*)realloc(handler->sprites, 
                                                          sizeof(SpriteInstance) * (handler->spriteCount + 1));
    if (!newSprites) return -1;
    
    handler->sprites = newSprites;
    handler->sprites[handler->spriteCount].texture = texture;
    handler->sprites[handler->spriteCount].position = position;
    handler->sprites[handler->spriteCount].rotation = rotation;
    handler->sprites[handler->spriteCount].scale = scale;
    handler->sprites[handler->spriteCount].tint = tint;
    handler->sprites[handler->spriteCount].sourceRect = (Rectangle){0, 0, texture.width, texture.height};
    
    handler->spriteCount++;
    return handler->spriteCount - 1;
}

int Handler2D_AddSpriteSheet(SpriteHandler* handler, Texture2D texture, Vector2 position,
                              Rectangle sourceRect, float rotation, Vector2 scale, Color tint) {
    if (!handler) return -1;
    
    SpriteInstance* newSprites = (SpriteInstance*)realloc(handler->sprites, 
                                                          sizeof(SpriteInstance) * (handler->spriteCount + 1));
    if (!newSprites) return -1;
    
    handler->sprites = newSprites;
    handler->sprites[handler->spriteCount].texture = texture;
    handler->sprites[handler->spriteCount].position = position;
    handler->sprites[handler->spriteCount].rotation = rotation;
    handler->sprites[handler->spriteCount].scale = scale;
    handler->sprites[handler->spriteCount].tint = tint;
    handler->sprites[handler->spriteCount].sourceRect = sourceRect;
    
    handler->spriteCount++;
    return handler->spriteCount - 1;
}

void Handler2D_UpdateSprite(SpriteHandler* handler, int index, Vector2 position, float rotation, Vector2 scale) {
    if (!handler || index < 0 || index >= handler->spriteCount) return;
    
    handler->sprites[index].position = position;
    handler->sprites[index].rotation = rotation;
    handler->sprites[index].scale = scale;
}

void Handler2D_RenderSprites(SpriteHandler* handler, Vector2 cameraOffset) {
    if (!handler) return;
    
    for (size_t i = 0; i < handler->spriteCount; i++) {
        SpriteInstance* sprite = &handler->sprites[i];
        
        Vector2 screenPos = {
            sprite->position.x - cameraOffset.x,
            sprite->position.y - cameraOffset.y
        };
        
        Rectangle destRect = {
            screenPos.x,
            screenPos.y,
            sprite->sourceRect.width * sprite->scale.x,
            sprite->sourceRect.height * sprite->scale.y
        };
        
        Vector2 origin = {
            (sprite->sourceRect.width * sprite->scale.x) / 2.0f,
            (sprite->sourceRect.height * sprite->scale.y) / 2.0f
        };
        
        DrawTexturePro(sprite->texture, sprite->sourceRect, destRect, origin, sprite->rotation, sprite->tint);
    }
}

void Handler2D_DestroySpriteHandler(SpriteHandler* handler) {
    if (!handler) return;
    
    if (handler->sprites) {
        free(handler->sprites);
    }
    free(handler);
}

// ===== BackgroundHandler =====

BackgroundHandler* Handler2D_CreateBackgroundHandler(void) {
    BackgroundHandler* handler = (BackgroundHandler*)malloc(sizeof(BackgroundHandler));
    if (!handler) return NULL;
    
    handler->layers = NULL;
    handler->layerCount = 0;
    
    return handler;
}

int Handler2D_AddLayer(BackgroundHandler* handler, Texture2D texture, Vector2 scrollSpeed, bool repeating) {
    if (!handler) return -1;
    
    BackgroundLayer* newLayers = (BackgroundLayer*)realloc(handler->layers, 
                                                           sizeof(BackgroundLayer) * (handler->layerCount + 1));
    if (!newLayers) return -1;
    
    handler->layers = newLayers;
    handler->layers[handler->layerCount].texture = texture;
    handler->layers[handler->layerCount].position = (Vector2){0, 0};
    handler->layers[handler->layerCount].scrollSpeed = scrollSpeed;
    handler->layers[handler->layerCount].repeating = repeating;
    
    handler->layerCount++;
    return handler->layerCount - 1;
}

void Handler2D_UpdateBackground(BackgroundHandler* handler, float deltaTime) {
    if (!handler) return;
    
    for (size_t i = 0; i < handler->layerCount; i++) {
        BackgroundLayer* layer = &handler->layers[i];
        
        layer->position.x += layer->scrollSpeed.x * deltaTime;
        layer->position.y += layer->scrollSpeed.y * deltaTime;
        
        // Wrap repeating backgrounds
        if (layer->repeating) {
            if (layer->position.x >= layer->texture.width) layer->position.x -= layer->texture.width;
            if (layer->position.x <= -layer->texture.width) layer->position.x += layer->texture.width;
            if (layer->position.y >= layer->texture.height) layer->position.y -= layer->texture.height;
            if (layer->position.y <= -layer->texture.height) layer->position.y += layer->texture.height;
        }
    }
}

void Handler2D_RenderBackground(BackgroundHandler* handler, Vector2 cameraOffset) {
    if (!handler) return;
    
    for (size_t i = 0; i < handler->layerCount; i++) {
        BackgroundLayer* layer = &handler->layers[i];
        
        float x = layer->position.x - cameraOffset.x;
        float y = layer->position.y - cameraOffset.y;
        
        if (layer->repeating) {
            // Draw tiled background
            int tilesX = (GetScreenWidth() / layer->texture.width) + 2;
            int tilesY = (GetScreenHeight() / layer->texture.height) + 2;
            
            for (int ty = -1; ty < tilesY; ty++) {
                for (int tx = -1; tx < tilesX; tx++) {
                    DrawTexture(layer->texture, 
                               x + (tx * layer->texture.width), 
                               y + (ty * layer->texture.height), 
                               WHITE);
                }
            }
        } else {
            DrawTexture(layer->texture, x, y, WHITE);
        }
    }
}

void Handler2D_DestroyBackgroundHandler(BackgroundHandler* handler) {
    if (!handler) return;
    
    if (handler->layers) {
        free(handler->layers);
    }
    free(handler);
}

// ===== ParticleSystem =====

ParticleSystem* Handler2D_CreateParticleSystem(size_t maxParticles) {
    ParticleSystem* system = (ParticleSystem*)malloc(sizeof(ParticleSystem));
    if (!system) return NULL;
    
    system->particles = (Particle*)malloc(sizeof(Particle) * maxParticles);
    if (!system->particles) {
        free(system);
        return NULL;
    }
    
    system->particleCount = 0;
    system->maxParticles = maxParticles;
    
    return system;
}

void Handler2D_EmitParticle(ParticleSystem* system, Vector2 position, Vector2 velocity, 
                            Color color, float lifetime, float size) {
    if (!system || system->particleCount >= system->maxParticles) return;
    
    Particle* p = &system->particles[system->particleCount];
    p->position = position;
    p->velocity = velocity;
    p->color = color;
    p->lifetime = lifetime;
    p->age = 0.0f;
    p->size = size;
    
    system->particleCount++;
}

void Handler2D_UpdateParticles(ParticleSystem* system, float deltaTime) {
    if (!system) return;
    
    for (size_t i = 0; i < system->particleCount; i++) {
        Particle* p = &system->particles[i];
        
        p->age += deltaTime;
        
        // Remove dead particles
        if (p->age >= p->lifetime) {
            // Swap with last particle and decrease count
            system->particles[i] = system->particles[system->particleCount - 1];
            system->particleCount--;
            i--;
            continue;
        }
        
        // Update particle
        p->position.x += p->velocity.x * deltaTime;
        p->position.y += p->velocity.y * deltaTime;
        
        // Fade out over lifetime
        float alpha = 1.0f - (p->age / p->lifetime);
        p->color.a = (unsigned char)(alpha * 255);
    }
}

void Handler2D_RenderParticles(ParticleSystem* system) {
    if (!system) return;
    
    for (size_t i = 0; i < system->particleCount; i++) {
        Particle* p = &system->particles[i];
        DrawCircleV(p->position, p->size, p->color);
    }
}

void Handler2D_DestroyParticleSystem(ParticleSystem* system) {
    if (!system) return;
    
    if (system->particles) {
        free(system->particles);
    }
    free(system);
}