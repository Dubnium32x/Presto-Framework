// 3D Visual Handler implementation for Presto Framework Mini
#include "visual-handler_3d.h"
#include "../util/util-math_utils.h"
#include <string.h>
#include <math.h>

// ===== Main 3D Handler =====

Handler3D* Handler3D_Create(void) {
    Handler3D* handler = (Handler3D*)malloc(sizeof(Handler3D));
    if (!handler) return NULL;
    
    handler->modelHandler = Handler3D_CreateModelHandler();
    handler->lightHandler = Handler3D_CreateLightHandler();
    handler->particleSystems = NULL;
    handler->particleSystemCount = 0;
    handler->skybox = NULL;
    handler->terrain = NULL;
    
    // Default camera setup
    handler->camera.position = (Vector3){ 0.0f, 10.0f, 10.0f };
    handler->camera.target = (Vector3){ 0.0f, 0.0f, 0.0f };
    handler->camera.up = (Vector3){ 0.0f, 1.0f, 0.0f };
    handler->camera.fovy = 45.0f;
    handler->camera.projection = CAMERA_PERSPECTIVE;
    
    return handler;
}

void Handler3D_SetCamera(Handler3D* handler, Camera3D camera) {
    if (!handler) return;
    handler->camera = camera;
}

void Handler3D_Update(Handler3D* handler, float deltaTime) {
    if (!handler) return;
    
    // Update particle systems
    for (size_t i = 0; i < handler->particleSystemCount; i++) {
        Handler3D_UpdateParticles3D(handler->particleSystems[i], deltaTime);
    }
}

void Handler3D_Render(Handler3D* handler) {
    if (!handler) return;
    
    BeginMode3D(handler->camera);
    
    // Render skybox first
    if (handler->skybox && handler->skybox->enabled) {
        Handler3D_RenderSkybox(handler->skybox, handler->camera);
    }
    
    // Render terrain
    if (handler->terrain) {
        Handler3D_RenderTerrain(handler->terrain);
    }
    
    // Render models
    if (handler->modelHandler) {
        Handler3D_RenderModels(handler->modelHandler);
    }
    
    // Render particle systems
    for (size_t i = 0; i < handler->particleSystemCount; i++) {
        Handler3D_RenderParticles3D(handler->particleSystems[i], handler->camera);
    }
    
    EndMode3D();
}

void Handler3D_Destroy(Handler3D* handler) {
    if (!handler) return;
    
    if (handler->modelHandler) {
        Handler3D_DestroyModelHandler(handler->modelHandler);
    }
    
    if (handler->lightHandler) {
        Handler3D_DestroyLightHandler(handler->lightHandler);
    }
    
    for (size_t i = 0; i < handler->particleSystemCount; i++) {
        Handler3D_DestroyParticleSystem3D(handler->particleSystems[i]);
    }
    if (handler->particleSystems) {
        free(handler->particleSystems);
    }
    
    if (handler->skybox) {
        Handler3D_DestroySkybox(handler->skybox);
    }
    
    if (handler->terrain) {
        Handler3D_DestroyTerrain(handler->terrain);
    }
    
    free(handler);
}

// ===== Model Handler =====

ModelHandler* Handler3D_CreateModelHandler(void) {
    ModelHandler* handler = (ModelHandler*)malloc(sizeof(ModelHandler));
    if (!handler) return NULL;
    
    handler->models = NULL;
    handler->modelCount = 0;
    
    return handler;
}

int Handler3D_AddModel(ModelHandler* handler, Model model, Vector3 position, 
                       Vector3 rotation, Vector3 scale, Color tint) {
    if (!handler) return -1;
    
    ModelInstance* newModels = (ModelInstance*)realloc(handler->models, 
                                                       sizeof(ModelInstance) * (handler->modelCount + 1));
    if (!newModels) return -1;
    
    handler->models = newModels;
    handler->models[handler->modelCount].model = model;
    handler->models[handler->modelCount].position = position;
    handler->models[handler->modelCount].rotation = rotation;
    handler->models[handler->modelCount].scale = scale;
    handler->models[handler->modelCount].tint = tint;
    handler->models[handler->modelCount].visible = true;
    
    handler->modelCount++;
    return handler->modelCount - 1;
}

void Handler3D_UpdateModel(ModelHandler* handler, int index, Vector3 position, 
                          Vector3 rotation, Vector3 scale) {
    if (!handler || index < 0 || index >= handler->modelCount) return;
    
    handler->models[index].position = position;
    handler->models[index].rotation = rotation;
    handler->models[index].scale = scale;
}

void Handler3D_SetModelVisibility(ModelHandler* handler, int index, bool visible) {
    if (!handler || index < 0 || index >= handler->modelCount) return;
    
    handler->models[index].visible = visible;
}

void Handler3D_RenderModels(ModelHandler* handler) {
    if (!handler) return;
    
    for (size_t i = 0; i < handler->modelCount; i++) {
        ModelInstance* model = &handler->models[i];
        
        if (!model->visible) continue;
        
        // Create transformation matrix manually
        Matrix transform = {
            .m0 = 1.0f, .m4 = 0.0f, .m8 = 0.0f, .m12 = 0.0f,
            .m1 = 0.0f, .m5 = 1.0f, .m9 = 0.0f, .m13 = 0.0f,
            .m2 = 0.0f, .m6 = 0.0f, .m10 = 1.0f, .m14 = 0.0f,
            .m3 = 0.0f, .m7 = 0.0f, .m11 = 0.0f, .m15 = 1.0f
        };
        // Apply scale
        transform.m0 *= model->scale.x;
        transform.m5 *= model->scale.y;
        transform.m10 *= model->scale.z;

        // Apply rotation (YZX order)
        float radX = model->rotation.x * (PI / 180.0f);
        float radY = model->rotation.y * (PI / 180.0f);
        float radZ = model->rotation.z * (PI / 180.0f);
        Matrix rotX = {
            .m0 = 1, .m4 = 0, .m8 = 0, .m12 = 0,
            .m1 = 0, .m5 = cosf(radX), .m9 = -sinf(radX), .m13 = 0,
            .m2 = 0, .m6 = sinf(radX), .m10 = cosf(radX), .m14 = 0,
            .m3 = 0, .m7 = 0, .m11 = 0, .m15 = 1
        };
        Matrix rotY = {
            .m0 = cosf(radY), .m4 = 0, .m8 = sinf(radY), .m12 = 0,
            .m1 = 0, .m5 = 1, .m9 = 0, .m13 = 0,
            .m2 = -sinf(radY), .m6 = 0, .m10 = cosf(radY), .m14 = 0,
            .m3 = 0, .m7 = 0, .m11 = 0, .m15 = 1
        };
        // Draw model with transformation
        model->model.transform = transform;
        DrawModel(model->model, (Vector3){0, 0, 0}, 1.0f, model->tint);
    }
}

void Handler3D_DestroyModelHandler(ModelHandler* handler) {
    if (!handler) return;
    
    if (handler->models) {
        free(handler->models);
    }
    free(handler);
}

// ===== Light Handler =====

LightHandler* Handler3D_CreateLightHandler(void) {
    LightHandler* handler = (LightHandler*)malloc(sizeof(LightHandler));
    if (!handler) return NULL;
    
    handler->lights = NULL;
    handler->lightCount = 0;
    handler->ambientColor = (Vector3){ 0.2f, 0.2f, 0.2f };
    handler->ambientIntensity = 1.0f;
    
    return handler;
}

int Handler3D_AddDirectionalLight(LightHandler* handler, Vector3 direction, 
                                 Color color, float intensity) {
    if (!handler) return -1;
    
    LightInstance* newLights = (LightInstance*)realloc(handler->lights, 
                                                       sizeof(LightInstance) * (handler->lightCount + 1));
    if (!newLights) return -1;
    
    handler->lights = newLights;
    handler->lights[handler->lightCount].type = LIGHT_DIRECTIONAL;
    handler->lights[handler->lightCount].position = (Vector3){0, 0, 0};
    Vector3 normDir = Vector3Normalize(direction);
    handler->lights[handler->lightCount].direction = normDir;
    handler->lights[handler->lightCount].color = color;
    handler->lights[handler->lightCount].intensity = intensity;
    handler->lights[handler->lightCount].enabled = true;
    
    handler->lightCount++;
    return handler->lightCount - 1;
}

int Handler3D_AddPointLight(LightHandler* handler, Vector3 position, 
                           Color color, float intensity, float range) {
    if (!handler) return -1;
    
    LightInstance* newLights = (LightInstance*)realloc(handler->lights, 
                                                       sizeof(LightInstance) * (handler->lightCount + 1));
    if (!newLights) return -1;
    
    handler->lights = newLights;
    handler->lights[handler->lightCount].type = LIGHT_POINT;
    handler->lights[handler->lightCount].position = position;
    handler->lights[handler->lightCount].direction = (Vector3){0, 0, 0};
    handler->lights[handler->lightCount].color = color;
    handler->lights[handler->lightCount].intensity = intensity;
    handler->lights[handler->lightCount].range = range;
    handler->lights[handler->lightCount].enabled = true;
    
    handler->lightCount++;
    return handler->lightCount - 1;
}

int Handler3D_AddSpotLight(LightHandler* handler, Vector3 position, Vector3 direction,
                          Color color, float intensity, float range, 
                          float innerCone, float outerCone) {
    if (!handler) return -1;
    
    LightInstance* newLights = (LightInstance*)realloc(handler->lights, 
                                                       sizeof(LightInstance) * (handler->lightCount + 1));
    if (!newLights) return -1;
    
    handler->lights = newLights;
    handler->lights[handler->lightCount].type = LIGHT_SPOT;
    handler->lights[handler->lightCount].position = position;
    Vector3 normDir = Vector3Normalize(direction);
    handler->lights[handler->lightCount].direction = normDir;
    handler->lights[handler->lightCount].color = color;
    handler->lights[handler->lightCount].intensity = intensity;
    handler->lights[handler->lightCount].range = range;
    handler->lights[handler->lightCount].innerCone = innerCone;
    handler->lights[handler->lightCount].outerCone = outerCone;
    handler->lights[handler->lightCount].enabled = true;
    
    handler->lightCount++;
    return handler->lightCount - 1;
}

void Handler3D_UpdateLight(LightHandler* handler, int index, Vector3 position, 
                          Vector3 direction, Color color, float intensity) {
    if (!handler || index < 0 || index >= handler->lightCount) return;
    
    handler->lights[index].position = position;
    Vector3 normDir = Vector3Normalize(direction);
    handler->lights[index].direction = normDir;
    handler->lights[index].color = color;
    handler->lights[index].intensity = intensity;
}

void Handler3D_SetLightEnabled(LightHandler* handler, int index, bool enabled) {
    if (!handler || index < 0 || index >= handler->lightCount) return;
    
    handler->lights[index].enabled = enabled;
}

void Handler3D_SetAmbientLight(LightHandler* handler, Vector3 color, float intensity) {
    if (!handler) return;
    
    handler->ambientColor = color;
    handler->ambientIntensity = intensity;
}

void Handler3D_ApplyLighting(LightHandler* handler, Shader shader) {
    if (!handler) return;
    
    // Apply ambient lighting
    int ambientLoc = GetShaderLocation(shader, "ambientColor");
    if (ambientLoc != -1) {
        Vector3 ambient = Vector3Scale(handler->ambientColor, handler->ambientIntensity);
        SetShaderValue(shader, ambientLoc, &ambient, SHADER_UNIFORM_VEC3);
    }
    
    // Apply lights (simplified - would need proper shader implementation)
    for (size_t i = 0; i < handler->lightCount && i < 8; i++) {
        if (!handler->lights[i].enabled) continue;
        
        // This would require a proper lighting shader setup
        // For now, just set basic light properties
    }
}

void Handler3D_DestroyLightHandler(LightHandler* handler) {
    if (!handler) return;
    
    if (handler->lights) {
        free(handler->lights);
    }
    free(handler);
}

// ===== Particle System 3D =====

ParticleSystem3D* Handler3D_CreateParticleSystem3D(size_t maxParticles, bool billboard) {
    ParticleSystem3D* system = (ParticleSystem3D*)malloc(sizeof(ParticleSystem3D));
    if (!system) return NULL;
    
    system->particles = (Particle3D*)malloc(sizeof(Particle3D) * maxParticles);
    if (!system->particles) {
        free(system);
        return NULL;
    }
    
    system->particleCount = 0;
    system->maxParticles = maxParticles;
    system->emitterPosition = (Vector3){0, 0, 0};
    system->billboard = billboard;
    
    return system;
}

void Handler3D_EmitParticle3D(ParticleSystem3D* system, Vector3 position, Vector3 velocity,
                             Vector3 acceleration, Color color, float lifetime, float size) {
    if (!system || system->particleCount >= system->maxParticles) return;
    
    Particle3D* p = &system->particles[system->particleCount];
    p->position = position;
    p->velocity = velocity;
    p->acceleration = acceleration;
    p->color = color;
    p->lifetime = lifetime;
    p->age = 0.0f;
    p->size = size;
    p->rotation = 0.0f;
    p->rotationSpeed = 0.0f;
    
    system->particleCount++;
}

void Handler3D_UpdateParticles3D(ParticleSystem3D* system, float deltaTime) {
    if (!system) return;
    
    for (size_t i = 0; i < system->particleCount; i++) {
        Particle3D* p = &system->particles[i];
        
        p->age += deltaTime;
        
        // Remove dead particles
        if (p->age >= p->lifetime) {
            system->particles[i] = system->particles[system->particleCount - 1];
            system->particleCount--;
            i--;
            continue;
        }
        
        // Update particle physics
        p->velocity = Vector3Add(p->velocity, Vector3Scale(p->acceleration, deltaTime));
        p->position = Vector3Add(p->position, Vector3Scale(p->velocity, deltaTime));
        p->rotation += p->rotationSpeed * deltaTime;
        
        // Fade out over lifetime
        float alpha = 1.0f - (p->age / p->lifetime);
        p->color.a = (unsigned char)(alpha * 255);
    }
}

void Handler3D_RenderParticles3D(ParticleSystem3D* system, Camera3D camera) {
    if (!system) return;
    
    for (size_t i = 0; i < system->particleCount; i++) {
        Particle3D* p = &system->particles[i];
        
        if (system->billboard) {
            // Billboard particles always face camera
            DrawBillboard(camera, (Texture2D){0}, p->position, p->size, p->color);
        } else {
            // Draw as 3D cube or sphere
            DrawCube(p->position, p->size, p->size, p->size, p->color);
        }
    }
}

void Handler3D_DestroyParticleSystem3D(ParticleSystem3D* system) {
    if (!system) return;
    
    if (system->particles) {
        free(system->particles);
    }
    free(system);
}

// ===== Skybox =====

Skybox* Handler3D_CreateSkybox(Texture2D texture) {
    Skybox* skybox = (Skybox*)malloc(sizeof(Skybox));
    if (!skybox) return NULL;
    
    // Create a simple cube mesh for skybox
    skybox->skybox = LoadModelFromMesh(GenMeshCube(1.0f, 1.0f, 1.0f));
    skybox->texture = texture;
    skybox->enabled = true;
    
    // Set texture to the skybox model
    skybox->skybox.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture;
    
    return skybox;
}

void Handler3D_RenderSkybox(Skybox* skybox, Camera3D camera) {
    if (!skybox || !skybox->enabled) return;
    
    // Draw skybox centered at camera position
    Vector3 scale = {1000.0f, 1000.0f, 1000.0f}; // Large scale
    DrawModel(skybox->skybox, camera.position, 1000.0f, WHITE);
}

void Handler3D_DestroySkybox(Skybox* skybox) {
    if (!skybox) return;
    
    UnloadModel(skybox->skybox);
    free(skybox);
}

// ===== Terrain =====

Terrain* Handler3D_CreateTerrain(Texture2D heightmap, Vector3 position, Vector3 scale, 
                                float maxHeight, Texture2D texture) {
    Terrain* terrain = (Terrain*)malloc(sizeof(Terrain));
    if (!terrain) return NULL;
    
    // Generate terrain mesh from heightmap
    terrain->mesh = GenMeshHeightmap(LoadImageFromTexture(heightmap), (Vector3){heightmap.width, maxHeight, heightmap.height});
    terrain->model = LoadModelFromMesh(terrain->mesh);
    terrain->position = position;
    terrain->scale = scale;
    terrain->heightmap = heightmap;
    terrain->texture = texture;
    terrain->maxHeight = maxHeight;
    
    // Set terrain texture
    terrain->model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture;
    
    return terrain;
}

void Handler3D_RenderTerrain(Terrain* terrain) {
    if (!terrain) return;
    
    // Apply transformation and draw
    DrawModelEx(terrain->model, terrain->position, (Vector3){1, 0, 0}, 0.0f, terrain->scale, WHITE);
}

float Handler3D_GetTerrainHeight(Terrain* terrain, float x, float z) {
    if (!terrain) return 0.0f;
    
    // Convert world coordinates to heightmap coordinates
    float mapX = (x - terrain->position.x) / terrain->scale.x;
    float mapZ = (z - terrain->position.z) / terrain->scale.z;
    
    // Sample heightmap (simplified - would need proper interpolation)
    if (mapX >= 0 && mapX < terrain->heightmap.width && 
        mapZ >= 0 && mapZ < terrain->heightmap.height) {
        
        // This is a simplified version - real implementation would sample the heightmap texture
        return terrain->position.y;
    }
    
    return 0.0f;
}

void Handler3D_DestroyTerrain(Terrain* terrain) {
    if (!terrain) return;
    
    UnloadModel(terrain->model);
    free(terrain);
}

// ===== Utility Functions =====

Vector3 Handler3D_ScreenToWorld(Vector2 screenPos, Camera3D camera) {
    return GetScreenToWorldRay(screenPos, camera).position;
}

Vector2 Handler3D_WorldToScreen(Vector3 worldPos, Camera3D camera) {
    return GetWorldToScreen(worldPos, camera);
}

bool Handler3D_CheckRayCollision(Vector3 rayOrigin, Vector3 rayDirection, Vector3 boxMin, Vector3 boxMax) {
    BoundingBox box = {boxMin, boxMax};
    Ray ray = {rayOrigin, rayDirection};
    return GetRayCollisionBox(ray, box).hit;
}