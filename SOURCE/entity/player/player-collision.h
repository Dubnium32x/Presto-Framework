// Player Collision System
// SPG-accurate sensor-based collision for Sonic physics

#ifndef PLAYER_COLLISION_H
#define PLAYER_COLLISION_H

#include "raylib.h"
#include <stdint.h>
#include <stdbool.h>
#include <math.h>

// ========== Constants ==========

#define TILE_SIZE 16
#define SENSOR_EXTENSION_LIMIT 32  // Max distance a sensor can reach

// ========== Enums ==========

// Collision mode determines how sensors are oriented
// Mode switches based on groundAngle
typedef enum {
    MODE_FLOOR,      // 0-45 and 315-360 degrees
    MODE_RIGHT_WALL, // 46-134 degrees
    MODE_CEILING,    // 135-225 degrees
    MODE_LEFT_WALL   // 226-314 degrees
} CollisionMode;

// Direction a sensor is pointing
typedef enum {
    SENSOR_DOWN,
    SENSOR_UP,
    SENSOR_LEFT,
    SENSOR_RIGHT
} SensorDirection;

// Which sensor is being used
typedef enum {
    SENSOR_A,  // Left ground/floor sensor
    SENSOR_B,  // Right ground/floor sensor
    SENSOR_C,  // Left ceiling sensor
    SENSOR_D,  // Right ceiling sensor
    SENSOR_E,  // Left push sensor
    SENSOR_F   // Right push sensor
} SensorID;

// ========== Structures ==========

// Result of a sensor cast
typedef struct {
    float distance;     // Distance to surface (negative = inside solid, positive = outside)
    float angle;        // Angle of the tile found (in degrees)
    int tileId;         // ID of the tile found
    bool found;         // Whether a valid tile was found
    bool flagged;       // Whether the tile is flagged (angle=255 in original)
} SensorResult;

// Level collision data reference
typedef struct LevelCollision {
    int** tileData;     // 2D array of tile IDs from level
    int levelWidth;     // Width in tiles
    int levelHeight;    // Height in tiles
} LevelCollision;

// ========== Function Declarations ==========

// Mode determination
CollisionMode GetCollisionModeFromAngle(float groundAngle);
CollisionMode GetPushSensorModeFromAngle(float groundAngle);

// Core sensor casting
SensorResult CastSensor(float anchorX, float anchorY, SensorDirection direction,
                        const LevelCollision* level);

// Ground sensors (A and B)
SensorResult CastGroundSensors(float playerX, float playerY,
                                float widthRadius, float heightRadius,
                                CollisionMode mode, const LevelCollision* level,
                                SensorResult* outSensorA, SensorResult* outSensorB);

// Ceiling sensors (C and D)
SensorResult CastCeilingSensors(float playerX, float playerY,
                                 float widthRadius, float heightRadius,
                                 CollisionMode mode, const LevelCollision* level,
                                 SensorResult* outSensorC, SensorResult* outSensorD);

// Push sensors (E and F)
SensorResult CastPushSensorE(float playerX, float playerY,
                              float pushRadius, float heightRadius,
                              CollisionMode mode, float groundAngle,
                              const LevelCollision* level);

SensorResult CastPushSensorF(float playerX, float playerY,
                              float pushRadius, float heightRadius,
                              CollisionMode mode, float groundAngle,
                              const LevelCollision* level);

// Tile data access
int GetTileAtPosition(float worldX, float worldY, const LevelCollision* level);
int GetHeightAtPosition(int tileId, int localX, bool flipH, bool flipV);
int GetWidthAtPosition(int tileId, int localY, bool flipH, bool flipV);
float GetTileAngleFlipped(int tileId, bool flipH, bool flipV);
bool IsTileFlagged(int tileId);

// Utility
float SnapAngleToCardinal(float currentAngle);
SensorDirection GetSensorDirectionForMode(CollisionMode mode, bool isGroundSensor);

// Initialize the collision system with level data
void InitLevelCollision(LevelCollision* collision, int** tileData, int width, int height);

#endif // PLAYER_COLLISION_H
