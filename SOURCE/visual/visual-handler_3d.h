// 3D Visual Handler interface for Presto Framework Mini
#pragma once

#include "raylib.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

// 3D Model instance for rendering
typedef struct {
    Model model;
    Vector3 position;
    Vector3 rotation;
    Vector3 scale;
    Color tint;
    bool visible;
} ModelInstance;

// 3D Model handler
typedef struct {
    ModelInstance* models;
    size_t modelCount;
} ModelHandler;

// 3D Light types
typedef enum {
    LIGHT_DIRECTIONAL,
    LIGHT_POINT,
    LIGHT_SPOT
} LightType;

// 3D Light instance
typedef struct {
    LightType type;
    Vector3 position;
    Vector3 direction;
    Color color;
    float intensity;
    float range;      // For point and spot lights
    float innerCone;  // For spot lights
    float outerCone;  // For spot lights
    bool enabled;
} LightInstance;

// 3D Lighting handler
typedef struct {
    LightInstance* lights;
    size_t lightCount;
    Vector3 ambientColor;
    float ambientIntensity;
} LightHandler;

// 3D Particle for particle system
typedef struct {
    Vector3 position;
    Vector3 velocity;
    Vector3 acceleration;
    Color color;
    float lifetime;
    float age;
    float size;
    float rotation;
    float rotationSpeed;
} Particle3D;

// 3D Particle system
typedef struct {
    Particle3D* particles;
    size_t particleCount;
    size_t maxParticles;
    Vector3 emitterPosition;
    bool billboard;  // Face camera
} ParticleSystem3D;

// 3D Skybox
typedef struct {
    Model skybox;
    Texture2D texture;
    bool enabled;
} Skybox;

// 3D Terrain/Heightmap
typedef struct {
    Mesh mesh;
    Model model;
    Vector3 position;
    Vector3 scale;
    Texture2D heightmap;
    Texture2D texture;
    float maxHeight;
} Terrain;

// Main 3D Handler
typedef struct {
    ModelHandler* modelHandler;
    LightHandler* lightHandler;
    ParticleSystem3D** particleSystems;
    size_t particleSystemCount;
    Skybox* skybox;
    Terrain* terrain;
    Camera3D camera;
} Handler3D;

// Main 3D Handler functions
Handler3D* Handler3D_Create(void);
void Handler3D_SetCamera(Handler3D* handler, Camera3D camera);
void Handler3D_Update(Handler3D* handler, float deltaTime);
void Handler3D_Render(Handler3D* handler);
void Handler3D_Destroy(Handler3D* handler);

// Model Handler functions
ModelHandler* Handler3D_CreateModelHandler(void);
int Handler3D_AddModel(ModelHandler* handler, Model model, Vector3 position, 
                       Vector3 rotation, Vector3 scale, Color tint);
void Handler3D_UpdateModel(ModelHandler* handler, int index, Vector3 position, 
                          Vector3 rotation, Vector3 scale);
void Handler3D_SetModelVisibility(ModelHandler* handler, int index, bool visible);
void Handler3D_RenderModels(ModelHandler* handler);
void Handler3D_DestroyModelHandler(ModelHandler* handler);

// Light Handler functions
LightHandler* Handler3D_CreateLightHandler(void);
int Handler3D_AddDirectionalLight(LightHandler* handler, Vector3 direction, 
                                 Color color, float intensity);
int Handler3D_AddPointLight(LightHandler* handler, Vector3 position, 
                           Color color, float intensity, float range);
int Handler3D_AddSpotLight(LightHandler* handler, Vector3 position, Vector3 direction,
                          Color color, float intensity, float range, 
                          float innerCone, float outerCone);
void Handler3D_UpdateLight(LightHandler* handler, int index, Vector3 position, 
                          Vector3 direction, Color color, float intensity);
void Handler3D_SetLightEnabled(LightHandler* handler, int index, bool enabled);
void Handler3D_SetAmbientLight(LightHandler* handler, Vector3 color, float intensity);
void Handler3D_ApplyLighting(LightHandler* handler, Shader shader);
void Handler3D_DestroyLightHandler(LightHandler* handler);

// Particle System 3D functions
ParticleSystem3D* Handler3D_CreateParticleSystem3D(size_t maxParticles, bool billboard);
void Handler3D_EmitParticle3D(ParticleSystem3D* system, Vector3 position, Vector3 velocity,
                             Vector3 acceleration, Color color, float lifetime, float size);
void Handler3D_UpdateParticles3D(ParticleSystem3D* system, float deltaTime);
void Handler3D_RenderParticles3D(ParticleSystem3D* system, Camera3D camera);
void Handler3D_DestroyParticleSystem3D(ParticleSystem3D* system);

// Skybox functions
Skybox* Handler3D_CreateSkybox(Texture2D texture);
void Handler3D_RenderSkybox(Skybox* skybox, Camera3D camera);
void Handler3D_DestroySkybox(Skybox* skybox);

// Terrain functions
Terrain* Handler3D_CreateTerrain(Texture2D heightmap, Vector3 position, Vector3 scale, 
                                float maxHeight, Texture2D texture);
void Handler3D_RenderTerrain(Terrain* terrain);
float Handler3D_GetTerrainHeight(Terrain* terrain, float x, float z);
void Handler3D_DestroyTerrain(Terrain* terrain);

// Utility functions
Vector3 Handler3D_ScreenToWorld(Vector2 screenPos, Camera3D camera);
Vector2 Handler3D_WorldToScreen(Vector3 worldPos, Camera3D camera);
bool Handler3D_CheckRayCollision(Vector3 rayOrigin, Vector3 rayDirection, Vector3 boxMin, Vector3 boxMax);