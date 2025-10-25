# Collision System Redesign: From Heightmaps to Raycasting

## Current System Analysis

### Overview
The Presto Framework currently implements a **heightmap-based collision system** designed for Sonic-style physics with precise slope handling and 360-degree movement.

### Current Architecture

#### 1. Heightmap-Based Collision (`tile_collision.c`)
```c
typedef struct {
    int groundHeights[16];  // 16-point height profile per tile
    bool isSolidBlock;
    bool isPlatform;
    bool isSlope;
} TileHeightProfile;
```

**Key Functions:**
- `TileCollision_GetTileHeightProfile()` - Generates height profiles for tiles
- `TileCollision_GetTileGroundAngle()` - Calculates slope angles using linear regression
- Generated heightmaps from `TILESET_HEIGHTMAPS` with flip transformations

#### 2. Player Sensor System (`player.c`, `player.h`)
```c
typedef struct {
    Vector2 center;
    Vector2 left;
    Vector2 right;
    Vector2 topLeft;
    Vector2 topRight;
    Vector2 bottomLeft;
    Vector2 bottomRight;
} PlayerSensors;
```

**Collision Logic:**
1. Position 6 sensors around player hitbox
2. Get ground angles from both bottom sensors
3. Compare left vs right sensor angles
4. Classify surface type (floor/wall/ceiling) based on angle ranges
5. Align player to dominant surface angle

#### 3. Current Issues
- **Missing Implementation**: `GetGroundAngleForTile(Vector2 sensorPos)` function not implemented
- **Compilation Errors**: Function calls don't match available APIs
- **Complexity**: Height profile generation and flip transformations are complex
- **Performance**: 16-point height arrays per tile + linear regression calculations
- **Maintenance**: Generated heightmaps need manual updates for new tilesets

---

## Proposed Raycast-Based System

### Design Philosophy
Replace pixel-perfect heightmaps with **intelligent raycasting** that:
- Simplifies tile collision data requirements
- Provides smoother uphill movement
- Reduces memory usage and computational complexity
- Maintains Sonic-style physics capabilities

### New Architecture

#### 1. Raycast Collision Engine
```c
typedef struct {
    bool hit;
    Vector2 point;
    Vector2 normal;
    float distance;
    float normal_angle;
    int tileId;
    const char* layerName;
} RaycastHit;

typedef enum {
    RAYCAST_DOWN,
    RAYCAST_UP,
    RAYCAST_LEFT,
    RAYCAST_RIGHT
} RaycastDirection;
```

**Core Functions:**
- `TileCollision_CastRay()` - Cast ray in cardinal directions
- `TileCollision_CastRayWithAngle()` - Cast ray at specific angle
- `TileCollision_GetGroundHeight()` - Ray-based ground detection
- `TileCollision_GetGroundAngle()` - Surface normal calculation

#### 2. Ray Marching Algorithm
```c
RaycastHit TileCollision_CastRayWithAngle(Vector2 origin, float angleRadians, float maxDistance, const LevelData* level) {
    Vector2 direction = TileCollision_AngleToVector(angleRadians);
    Vector2 currentPos = origin;
    float stepSize = 0.5f; // Half-pixel precision
    
    for (float distance = 0; distance < maxDistance; distance += stepSize) {
        // Check if current position hits solid tile
        int tileId = TileCollision_GetTileIdAtPosition(currentPos, level, layerName);
        if (TileCollision_IsSolidTile(tileId, layerName, tilesets, tilesetCount)) {
            // Calculate surface normal and return hit data
            return CreateRaycastHit(currentPos, distance, tileId, layerName);
        }
        currentPos = Vector2Add(currentPos, Vector2Scale(direction, stepSize));
    }
    
    return CreateEmptyRaycastHit(); // No collision
}
```

#### 3. Simplified Tile Data
Instead of 16-point height profiles, tiles only need:
```c
typedef struct {
    int tileId;
    bool isSolid;
    bool isPlatform;
    bool isHazard;
    uint8_t flipFlags;
    // No height profile needed!
} Tile;
```

**Tile Classification:**
- `TileCollision_IsSolidTile()` - Simple boolean solid check
- `TileCollision_IsPlatformTile()` - One-way platform detection
- `TileCollision_IsEmptyTile()` - Air/empty space

#### 4. Enhanced Player Collision
```c
void PlayerUpdate(Player* player, float dt, const LevelData* level) {
    // Ground detection using raycasts
    RaycastHit leftHit = TileCollision_CastRay(player->playerSensors.bottomLeft, RAYCAST_DOWN, 32.0f, level);
    RaycastHit rightHit = TileCollision_CastRay(player->playerSensors.bottomRight, RAYCAST_DOWN, 32.0f, level);
    
    // Determine ground angle from surface normals
    if (leftHit.hit && rightHit.hit) {
        player->groundAngle = (leftHit.normal_angle + rightHit.normal_angle) / 2.0f;
    } else if (leftHit.hit) {
        player->groundAngle = leftHit.normal_angle;
    } else if (rightHit.hit) {
        player->groundAngle = rightHit.normal_angle;
    }
    
    // Wall collision using horizontal rays
    RaycastHit wallHit = TileCollision_CastRay(player->position, player->facingRight ? RAYCAST_RIGHT : RAYCAST_LEFT, 16.0f, level);
    if (wallHit.hit) {
        // Handle wall collision
        player->position.x = wallHit.point.x - (player->facingRight ? player->width/2 : -player->width/2);
        player->velocity.x = 0;
    }
}
```

---

## Migration Benefits

### Advantages of Raycast System

#### 1. **Smoother Uphill Movement**
- Rays can detect surfaces at any angle
- No discrete height points to cause bumping
- Continuous surface normal calculation

#### 2. **Simplified Data Structure**
- Remove complex `TileHeightProfile` system
- No need for generated heightmaps
- Tiles are just solid/empty boolean flags

#### 3. **Better Performance**
- O(1) ray marching vs O(16) height array processing
- No linear regression angle calculations
- Reduced memory usage per tile

#### 4. **Easier Maintenance**
- New tilesets don't need heightmap generation
- Tile collision is determined by visual solid/empty areas
- Less complex flip transformation logic

#### 5. **More Flexible Collision**
- Can cast rays at any angle for advanced movement
- Easy to implement wall-running and ceiling collision
- Better support for non-axis-aligned surfaces

### Potential Challenges

#### 1. **Ray Precision**
- Need appropriate step size for accuracy vs. performance
- May require sub-pixel positioning for smooth movement

#### 2. **Surface Normal Calculation**
- Need algorithm to determine surface angle from solid/empty tile boundaries
- May require sampling multiple points around collision

#### 3. **Platform Collision**
- One-way platforms need special raycast handling
- Should only collide when moving downward

---

## Implementation Plan

### Phase 1: Core Raycast Engine
1. ✅ Create `RaycastHit` and `RaycastDirection` structures
2. ✅ Implement `TileCollision_CastRay()` functions
3. ✅ Add ray marching algorithm with configurable precision
4. ✅ Create utility functions for angle/direction conversion

### Phase 2: Tile System Integration
1. 🔄 Simplify `Tile` structure (remove height profiles)
2. 🔄 Update `LevelData` to remove heightmap references
3. 🔄 Implement `TileCollision_GetTileIdAtPosition()`
4. 🔄 Add solid/platform tile classification functions

### Phase 3: Player Integration
1. 🔄 Replace `GetGroundAngleForTile()` with raycast calls
2. 🔄 Update ground detection logic in `PlayerUpdate()`
3. 🔄 Implement wall and ceiling collision with rays
4. 🔄 Test and tune movement feel

### Phase 4: Advanced Features
1. ⏳ Add angled surface normal calculation
2. ⏳ Implement one-way platform raycasting
3. ⏳ Add debug visualization for rays
4. ⏳ Performance optimization and fine-tuning

---

## Code Migration Examples

### Before (Heightmap System)
```c
// Complex height profile generation
TileHeightProfile profile = TileCollision_GetTileHeightProfile(rawTileId, layerName, tilesets, tilesetCount);
float angle = TileCollision_GetTileGroundAngle(rawTileId, layerName, tilesets, tilesetCount);

// 16-point height arrays with flip transformations
for (int i = 0; i < 16; i++) {
    profile.groundHeights[i] = heights[i];
    // Complex flip logic...
}
```

### After (Raycast System)
```c
// Simple raycast collision
RaycastHit hit = TileCollision_CastRay(position, RAYCAST_DOWN, maxDistance, level);
if (hit.hit) {
    float angle = hit.normal_angle;
    Vector2 groundPoint = hit.point;
    // Direct collision data - no complex processing needed
}
```

---

## Conclusion

The raycast-based collision system offers significant improvements in:
- **Simplicity**: Easier to understand and maintain
- **Performance**: Faster collision detection with less memory
- **Smoothness**: Better uphill movement without height quantization
- **Flexibility**: Support for complex movement patterns

The migration preserves the sophisticated Sonic-style physics while modernizing the underlying collision detection approach. The sensor-based player system remains intact, but now uses intelligent raycasting instead of pixel-perfect heightmaps.

**Status**: ✅ Raycast engine implemented, 🔄 Currently integrating with player system, ⏳ Advanced features planned