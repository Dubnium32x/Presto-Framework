// Entity Manager header
#ifndef ENTITY_MANAGER_H
#define ENTITY_MANAGER_H

#include "raylib.h"
#include "sprite_object.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "../util/globals.h"

#define MAX_ENTITIES 100
#define MAX_ENTITY_NAME_LENGTH 64

typedef struct {
    void(*Initialize)(void);
    void(*Update)(float deltaTime);
    void(*Draw)(void);
    void(*Destroy)(void);
    bool(*IsActive)(void);
    Vector2(*GetPosition)(void);
    void(*SetPosition)(Vector2 position);
    int(*GetID)(void);
    const char*(*GetType)(void);
} IEntity;

typedef enum {
    ENTITY_PLAYER,
    ENTITY_ENEMY,
    ENTITY_ITEM,
    ENTITY_POWERUP,
    ENTITY_COLLECTIBLE,
    ENTITY_MISC
} EntityType;

typedef struct {
    int id;
    const char* entityType;
    char name[MAX_ENTITY_NAME_LENGTH];
    Vector2 position;
    bool isActive;
    SpriteObject* sprite;
    IEntity* interface;
    float width, height;
    Hitbox_t hitbox;
} Entity;

typedef struct {
    Entity* entities[MAX_ENTITIES];
    size_t entityCount;
    int state;
} EntityManager;

typedef enum {
    ENTITY_MANAGER_UNINITIALIZED,
    ENTITY_MANAGER_INITIALIZED
} EntityManagerState;

void InitEntityManager(EntityManager* manager);
void AddEntity(EntityManager* manager, Entity* entity);
void RemoveEntity(EntityManager* manager, int entityId);
void UpdateEntities(EntityManager* manager, float deltaTime);
void DrawEntities(const EntityManager* manager);
void UnloadAllEntities(EntityManager* manager);
Entity* GetEntityByID(const EntityManager* manager, int entityId);
Entity* GetEntityByName(const EntityManager* manager, const char* name);
Entity** GetEntitiesByType(const EntityManager* manager, const char* type, size_t* outCount);
#endif // ENTITY_MANAGER_H 
