// Player Collision Header - SPG-accurate collision detection
#ifndef PLAYER_COLLISION_H
#define PLAYER_COLLISION_H

#include "raylib.h"
#include "player-var.h"
#include "player-player.h"
#include "../../data/collision_data/collision-generated_heightmaps.h"
#include "../../data/collision_data/collision-generated_widthmaps.h"
#include "../../data/collision_data/collision-generated_tile_angles.h"
#include <stdint.h>
#include <stdbool.h>

// Sensor result from a single sensor check
typedef struct {
    bool found;           // Did we find a tile?
    int distance;         // Distance to surface (negative = inside, 0 = touching, positive = gap)
    uint8_t angle;        // Angle of the tile found
    int tileX;            // Tile coordinates
    int tileY;
    int tileId;           // The tile ID found
    Vector2 surfacePoint; // Exact point on the surface
} SensorResult;

// All sensor results for a frame
typedef struct {
    SensorResult groundA;   // Left ground sensor
    SensorResult groundB;   // Right ground sensor
    SensorResult ceilingC;  // Left ceiling sensor
    SensorResult ceilingD;  // Right ceiling sensor
    SensorResult pushE;     // Left wall sensor
    SensorResult pushF;     // Right wall sensor
} PlayerSensorResults;

// Level collision data reference (set by game screen)
typedef struct {
    int** tileData;
    int width;
    int height;
} LevelCollision;

// Global level collision reference
extern LevelCollision g_LevelCollision;

// Initialize the collision system with level data
void InitCollisionSystem(int** levelData, int levelWidth, int levelHeight);

// Get collision mode from angle (SPG four-mode system)
CollisionMode GetCollisionModeFromAngle(uint8_t angle);

// Convert angle byte (0-255) to radians
float AngleByteToRadians(uint8_t angleByte);

// Convert angle byte to degrees
float AngleByteToDegrees(uint8_t angleByte);

// Single sensor check - returns distance to surface
// position: sensor world position
// direction: unit vector pointing in sensor direction
// mode: current collision mode
SensorResult CheckSensor(Vector2 position, Vector2 direction, CollisionMode mode);

// Ground sensor check (sensors A and B)
// Returns the winning sensor result (closest surface)
SensorResult CheckGroundSensors(Vector2 playerPos, float widthRadius, float heightRadius,
                                 CollisionMode mode, uint8_t currentAngle,
                                 SensorResult* outSensorA, SensorResult* outSensorB);

// Ceiling sensor check (sensors C and D)
SensorResult CheckCeilingSensors(Vector2 playerPos, float widthRadius, float heightRadius,
                                  CollisionMode mode, uint8_t currentAngle,
                                  SensorResult* outSensorC, SensorResult* outSensorD);

// Wall/push sensor check (sensors E and F)
void CheckWallSensors(Vector2 playerPos, float pushRadius, CollisionMode mode,
                      SensorResult* outSensorE, SensorResult* outSensorF);

// Get height at a specific X position within a tile
int GetTileHeightAtX(int tileId, int localX, bool flipH, bool flipV);

// Get width at a specific Y position within a tile
int GetTileWidthAtY(int tileId, int localY, bool flipH, bool flipV);

// Get tile at world position (handles bounds checking)
int GetTileAtPosition(int worldX, int worldY, bool* flipH, bool* flipV);

// Check if a tile is solid (non-zero)
bool IsTileSolid(int tileId);

// Regression check - when sensor finds full tile, check one tile further
SensorResult CheckSensorWithRegression(Vector2 position, Vector2 direction, CollisionMode mode);

// Extension check - when sensor finds empty tile, check one tile further
SensorResult CheckSensorWithExtension(Vector2 position, Vector2 direction, CollisionMode mode);

#endif // PLAYER_COLLISION_H
