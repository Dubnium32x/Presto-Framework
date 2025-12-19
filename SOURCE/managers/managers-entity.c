// Entity manager implementation
#include "managers-entity.h"
#include <stdio.h>
#include <stdlib.h>

void InitEntityManager(EntityManager* manager) {
    if (manager == NULL) return;
    manager->entityCount = 0;
    for (int i = 0; i < MAX_ENTITIES; i++) {
        manager->entities[i] = NULL;
    }
}

void AddEntity(EntityManager* manager, Entity* entity) {
    if (manager == NULL || entity == NULL) return;
    if (manager->entityCount >= MAX_ENTITIES) {
        printf("Error: Maximum entity limit reached.\n");
        return;
    }
    manager->entities[manager->entityCount++] = entity;
}

void RemoveEntity(EntityManager* manager, int entityId) {
    if (manager == NULL) return;
    for (int i = 0; i < manager->entityCount; i++) {
        if (manager->entities[i] != NULL && manager->entities[i]->id == entityId) {
            free(manager->entities[i]);
            manager->entities[i] = NULL;
            // Shift remaining entities
            for (int j = i; j < manager->entityCount - 1; j++) {
                manager->entities[j] = manager->entities[j + 1];
            }
            manager->entities[--manager->entityCount] = NULL;
            return;
        }
    }
    printf("Warning: Entity with ID %d not found.\n", entityId);
}

void UpdateEntities(EntityManager* manager, float deltaTime) {
    if (manager == NULL) return;
    for (int i = 0; i < manager->entityCount; i++) {
        Entity* entity = manager->entities[i];
        if (entity != NULL && entity->active) {
            entity->position.x += entity->velocity.x * deltaTime;
            entity->position.y += entity->velocity.y * deltaTime;
        }
    }
}

void DrawEntities(const EntityManager* manager) {
    if (manager == NULL) return;
    for (int i = 0; i < manager->entityCount; i++) {
        Entity* entity = manager->entities[i];
        if (entity != NULL && entity->active) {
            DrawCircleV(entity->position, 10.0f, BLUE); // Simple representation
        }
    }
}

Entity* GetEntityById(const EntityManager* manager, int entityId) {
    if (manager == NULL) return NULL;
    for (int i = 0; i < manager->entityCount; i++) {
        if (manager->entities[i] != NULL && manager->entities[i]->id == entityId) {
            return manager->entities[i];
        }
    }
    return NULL;
}