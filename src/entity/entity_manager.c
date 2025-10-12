// Entity Manager implementation
#include "entity_manager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"

void InitEntityManager(EntityManager* manager) {
    if (manager == NULL) return;
    manager->entityCount = 0;
    manager->state = ENTITY_MANAGER_INITIALIZED;
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
            if (manager->entities[i]->sprite != NULL) {
                UnloadTexture(manager->entities[i]->sprite->texture);
                free(manager->entities[i]->sprite);
            }
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
        if (entity != NULL && entity->isActive && entity->interface != NULL && entity->interface->Update != NULL) {
            entity->interface->Update(deltaTime);
        }
    }
}

void DrawEntities(const EntityManager* manager) {
    if (manager == NULL) return;
    for (int i = 0; i < manager->entityCount; i++) {
        Entity* entity = manager->entities[i];
        if (entity != NULL && entity->isActive) {
            if (entity->sprite != NULL) {
                DrawSpriteObject(entity->sprite);
            }
            if (entity->interface != NULL && entity->interface->Draw != NULL) {
                entity->interface->Draw();
            }
        }
    }
}

void UnloadAllEntities(EntityManager* manager) {
    if (manager == NULL) return;
    for (int i = 0; i < manager->entityCount; i++) {
        if (manager->entities[i] != NULL) {
            if (manager->entities[i]->sprite != NULL) {
                UnloadTexture(manager->entities[i]->sprite->texture);
                free(manager->entities[i]->sprite);
            }
            free(manager->entities[i]);
            manager->entities[i] = NULL;
        }
    }
    manager->entityCount = 0;
    manager->state = ENTITY_MANAGER_UNINITIALIZED;
}

Entity* GetEntityByID(const EntityManager* manager, int entityId) {
    if (manager == NULL) return NULL;
    for (int i = 0; i < manager->entityCount; i++) {
        if (manager->entities[i] != NULL && manager->entities[i]->id == entityId) {
            return manager->entities[i];
        }
    }
    return NULL;
}

Entity* GetEntityByName(const EntityManager* manager, const char* name) {
    if (manager == NULL || name == NULL) return NULL;
    for (int i = 0; i < manager->entityCount; i++) {
        if (manager->entities[i] != NULL && strcmp(manager->entities[i]->name, name) == 0) {
            return manager->entities[i];
        }
    }
    return NULL;
}

Entity** GetEntitiesByType(const EntityManager* manager, const char* type, size_t* outCount) {
    if (manager == NULL || type == NULL || outCount == NULL) return NULL;
    Entity** matchedEntities = (Entity**)malloc(MAX_ENTITIES * sizeof(Entity*));
    if (matchedEntities == NULL) {
        *outCount = 0;
        return NULL;
    }
    size_t count = 0;
    for (int i = 0; i < manager->entityCount; i++) {
        if (manager->entities[i] != NULL && strcmp(manager->entities[i]->entityType, type) == 0) {
            matchedEntities[count++] = manager->entities[i];
        }
    }
    *outCount = count;
    return matchedEntities;
}

