module entity.entity_manager;

import raylib;

import std.stdio;
import std.string;
import std.array;
import std.algorithm : remove, filter;
import std.conv : to;
import std.json;
import std.math;

import entity.player.player;
import entity.sprite_object;
import utils.level_loader;

// Base interface for all entities
interface IEntity {
    void initialize();
    void update(float deltaTime);
    void draw();
    void destroy();
    bool isActive();
    Vector2 getPosition();
    void setPosition(Vector2 pos);
    int getId();
    string getType();
}

// Entity types enum
enum EntityType {
    PLAYER,
    ENEMY,
    ITEM,
    COLLECTIBLE,
    TRIGGER,
    CHECKPOINT,
    PLATFORM,
    DECORATION,
    HAZARD
}

// Base entity class
abstract class Entity : IEntity {
    protected int id;
    protected string entityType;
    protected Vector2 position;
    protected bool active = true;
    protected SpriteObject sprite;
    protected float width = 16.0f;
    protected float height = 16.0f;
    
    this(int entityId, string type, Vector2 pos) {
        id = entityId;
        entityType = type;
        position = pos;
    }
    
    // Interface implementations
    bool isActive() { return active; }
    Vector2 getPosition() { return position; }
    void setPosition(Vector2 pos) { position = pos; }
    int getId() { return id; }
    string getType() { return entityType; }
    
    // Abstract methods to be implemented by derived classes
    abstract void initialize();
    abstract void update(float deltaTime);
    abstract void draw();
    
    void destroy() {
        active = false;
    }
}

// Collectible entity (rings, power-ups, etc.)
class CollectibleEntity : Entity {
    private int value;
    private string collectibleType;
    
    this(int entityId, Vector2 pos, string type = "ring", int val = 10) {
        super(entityId, "collectible", pos);
        collectibleType = type;
        value = val;
    }
    
    override void initialize() {
        sprite = SpriteObject();
        sprite.x = position.x;
        sprite.y = position.y;
        sprite.visible = true;
        writeln("Collectible initialized: ", collectibleType, " at (", position.x, ", ", position.y, ")");
    }
    
    override void update(float deltaTime) {
        if (!active) return;
        
        // Simple floating animation
        sprite.y = position.y + sin(GetTime() * 2.0f) * 2.0f;
        
        // TODO: Check collision with player
        // if (checkPlayerCollision()) {
        //     onCollect();
        // }
    }
    
    override void draw() {
        if (!active) return;
        
        // Draw simple rectangle for now
        DrawRectangle(
            cast(int)(sprite.x - width/2),
            cast(int)(sprite.y - height/2),
            cast(int)width,
            cast(int)height,
            Colors.YELLOW
        );
        
        // Draw outline
        DrawRectangleLines(
            cast(int)(sprite.x - width/2),
            cast(int)(sprite.y - height/2),
            cast(int)width,
            cast(int)height,
            Colors.GOLD
        );
    }
    
    void onCollect() {
        writeln("Collected ", collectibleType, " worth ", value);
        destroy();
    }
    
    int getValue() { return value; }
    string getCollectibleType() { return collectibleType; }
}

// Enemy entity
class EnemyEntity : Entity {
    private string enemyType;
    private float speed = 50.0f;
    private Vector2 velocity;
    private int health = 1;
    
    this(int entityId, Vector2 pos, string type = "badnik") {
        super(entityId, "enemy", pos);
        enemyType = type;
        velocity = Vector2(speed, 0);
    }
    
    override void initialize() {
        sprite = SpriteObject();
        sprite.x = position.x;
        sprite.y = position.y;
        sprite.visible = true;
        writeln("Enemy initialized: ", enemyType, " at (", position.x, ", ", position.y, ")");
    }
    
    override void update(float deltaTime) {
        if (!active) return;
        
        // Simple left-right movement
        position.x += velocity.x * deltaTime;
        
        // Reverse direction at boundaries (simple AI)
        if (position.x <= 50 || position.x >= 750) {
            velocity.x = -velocity.x;
        }
        
        sprite.x = position.x;
        sprite.y = position.y;
    }
    
    override void draw() {
        if (!active) return;
        
        // Draw simple rectangle for enemy
        DrawRectangle(
            cast(int)(position.x - width/2),
            cast(int)(position.y - height/2),
            cast(int)width,
            cast(int)height,
            Colors.RED
        );
        
        // Draw eyes
        DrawCircle(cast(int)(position.x - 4), cast(int)(position.y - 4), 2, Colors.WHITE);
        DrawCircle(cast(int)(position.x + 4), cast(int)(position.y - 4), 2, Colors.WHITE);
    }
    
    void takeDamage(int damage = 1) {
        health -= damage;
        if (health <= 0) {
            onDestroy();
        }
    }
    
    void onDestroy() {
        writeln("Enemy destroyed: ", enemyType);
        destroy();
    }
}

// Checkpoint entity
class CheckpointEntity : Entity {
    private bool activated = false;
    
    this(int entityId, Vector2 pos) {
        super(entityId, "checkpoint", pos);
        width = 24.0f;
        height = 48.0f;
    }
    
    override void initialize() {
        sprite = SpriteObject();
        sprite.x = position.x;
        sprite.y = position.y;
        sprite.visible = true;
        writeln("Checkpoint initialized at (", position.x, ", ", position.y, ")");
    }
    
    override void update(float deltaTime) {
        if (!active) return;
        
        // TODO: Check player collision to activate
        // if (!activated && checkPlayerCollision()) {
        //     activate();
        // }
    }
    
    override void draw() {
        if (!active) return;
        
        Color checkpointColor = activated ? Colors.GREEN : Colors.GRAY;
        
        // Draw checkpoint post
        DrawRectangle(
            cast(int)(position.x - 2),
            cast(int)(position.y - height/2),
            4,
            cast(int)height,
            checkpointColor
        );
        
        // Draw checkpoint flag
        DrawRectangle(
            cast(int)(position.x + 2),
            cast(int)(position.y - height/2),
            cast(int)(width - 4),
            cast(int)(height/2),
            checkpointColor
        );
    }
    
    void activate() {
        if (!activated) {
            activated = true;
            writeln("Checkpoint activated at (", position.x, ", ", position.y, ")");
            // TODO: Set as player respawn point
        }
    }
    
    bool isActivated() { return activated; }
}

// Entity Manager class
class EntityManager {
    private static EntityManager instance;
    private IEntity[] entities;
    private int nextEntityId = 1;
    private Player* playerReference; // Reference to the player
    
    // Singleton pattern
    static EntityManager getInstance() {
        if (instance is null) {
            instance = new EntityManager();
        }
        return instance;
    }
    
    private this() {
        entities = [];
        writeln("EntityManager initialized");
    }
    
    // Set player reference for collision checks
    void setPlayerReference(Player* player) {
        playerReference = player;
    }
    
    // Add entity to management
    void addEntity(IEntity entity) {
        entities ~= entity;
        entity.initialize();
        writeln("Added entity: ", entity.getType(), " with ID: ", entity.getId());
    }
    
    // Remove entity by ID
    void removeEntity(int entityId) {
        entities = entities.remove!(e => e.getId() == entityId);
        writeln("Removed entity with ID: ", entityId);
    }
    
    // Remove inactive entities
    void cleanupInactiveEntities() {
        size_t initialCount = entities.length;
        entities = entities.filter!(e => e.isActive()).array;
        size_t finalCount = entities.length;
        
        if (finalCount < initialCount) {
            writeln("Cleaned up ", (initialCount - finalCount), " inactive entities");
        }
    }
    
    // Create specific entity types
    void createCollectible(Vector2 pos, string type = "ring", int value = 10) {
        auto collectible = new CollectibleEntity(nextEntityId++, pos, type, value);
        addEntity(collectible);
    }
    
    void createEnemy(Vector2 pos, string type = "badnik") {
        auto enemy = new EnemyEntity(nextEntityId++, pos, type);
        addEntity(enemy);
    }
    
    void createCheckpoint(Vector2 pos) {
        auto checkpoint = new CheckpointEntity(nextEntityId++, pos);
        addEntity(checkpoint);
    }
    
    // Load entities from level data
    void loadEntitiesFromLevel(const LevelData level) {
        writeln("Loading entities from level: ", level.levelName);
        
        foreach (obj; level.objects) {
            Vector2 objPos = Vector2(obj.x, obj.y);
            
            switch (obj.objectType) {
                case 1: // Collectible
                    createCollectible(objPos, "ring", 10);
                    break;
                case 2: // Enemy
                    createEnemy(objPos, "badnik");
                    break;
                case 3: // Checkpoint
                    createCheckpoint(objPos);
                    break;
                default:
                    writeln("Unknown object type: ", obj.objectType, " at (", obj.x, ", ", obj.y, ")");
                    break;
            }
        }
        
        writeln("Loaded ", entities.length, " entities from level");
    }
    
    // Clear all entities
    void clearAllEntities() {
        foreach (entity; entities) {
            entity.destroy();
        }
        entities = [];
        writeln("Cleared all entities");
    }
    
    // Update all entities
    void update(float deltaTime) {
        foreach (entity; entities) {
            if (entity.isActive()) {
                entity.update(deltaTime);
            }
        }
        
        // Cleanup inactive entities periodically
        static float cleanupTimer = 0.0f;
        cleanupTimer += deltaTime;
        if (cleanupTimer >= 1.0f) { // Cleanup every second
            cleanupInactiveEntities();
            cleanupTimer = 0.0f;
        }
    }
    
    // Draw all entities
    void draw() {
        foreach (entity; entities) {
            if (entity.isActive()) {
                entity.draw();
            }
        }
    }
    
    // Get entities by type
    IEntity[] getEntitiesByType(string entityType) {
        return entities.filter!(e => e.getType() == entityType && e.isActive()).array;
    }
    
    // Get entity by ID
    IEntity getEntityById(int entityId) {
        foreach (entity; entities) {
            if (entity.getId() == entityId && entity.isActive()) {
                return entity;
            }
        }
        return null;
    }
    
    // Check collision between two entities (simple rectangle collision)
    bool checkCollision(IEntity entity1, IEntity entity2) {
        if (!entity1.isActive() || !entity2.isActive()) {
            return false;
        }
        
        Vector2 pos1 = entity1.getPosition();
        Vector2 pos2 = entity2.getPosition();
        
        // Simple distance check for now
        float distance = Vector2Distance(pos1, pos2);
        return distance < 20.0f; // Simple collision radius
    }
    
    // Get entity count
    size_t getEntityCount() {
        return entities.filter!(e => e.isActive()).array.length;
    }
    
    // Debug information
    void debugPrint() {
        writeln("=== Entity Manager Debug ===");
        writeln("Total entities: ", entities.length);
        writeln("Active entities: ", getEntityCount());
        
        foreach (entity; entities) {
            if (entity.isActive()) {
                Vector2 pos = entity.getPosition();
                writeln("  ", entity.getType(), " (ID:", entity.getId(), ") at (", pos.x, ", ", pos.y, ")");
            }
        }
        writeln("============================");
    }
}
