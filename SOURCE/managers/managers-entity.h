// Entity manager header
#ifndef MANAGERS_ENTITY_H
#define MANAGERS_ENTITY_H

#include "raylib.h"
#include <stdio.h>

#define MAX_ENTITIES 256

typedef struct {
    int id;
    char name[64];
    Vector2 position;
    Vector2 velocity;
    float rotation;
    bool active;
} Entity;

typedef struct {
    Entity* entities[MAX_ENTITIES];
    int entityCount;
} EntityManager;

extern EntityManager* gEntityManager;

void InitEntityManager(EntityManager* manager);
void AddEntity(EntityManager* manager, Entity* entity);
void RemoveEntity(EntityManager* manager, int entityId);
void UpdateEntities(EntityManager* manager, float deltaTime);
void DrawEntities(const EntityManager* manager);
Entity* GetEntityById(const EntityManager* manager, int entityId);

#endif // MANAGERS_ENTITY_H