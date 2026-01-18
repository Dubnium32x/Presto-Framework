// Player Physics System
// SPG-accurate Sonic physics implementation

#ifndef PLAYER_PHYSICS_H
#define PLAYER_PHYSICS_H

#include "raylib.h"
#include "player-collision.h"
#include "player-var.h"
#include <stdbool.h>
#include <math.h>

// ========== Forward Declarations ==========
// Forward declare Player - the actual typedef is in player-player.h
typedef struct Player Player;

// ========== Constants ==========

// Push radius (same for all characters per SPG)
#define PUSH_RADIUS 10.0f

// Distance limits for sensor acceptance
#define GROUND_SENSOR_MAX_DISTANCE 14.0f
#define GROUND_SENSOR_MIN_DISTANCE -14.0f

// Slip/Fall angle thresholds (Sonic 3 method)
#define SLIP_ANGLE_START_DEG 35.0f
#define SLIP_ANGLE_END_DEG 325.0f
#define FALL_ANGLE_START_DEG 69.0f
#define FALL_ANGLE_END_DEG 291.0f

// Control lock duration
#define CONTROL_LOCK_FRAMES 30

// Speed thresholds
#define SLIP_SPEED_THRESHOLD 2.5f

// ========== Enums ==========

// Air movement direction (for sensor activation)
typedef enum {
    AIR_MOSTLY_RIGHT,
    AIR_MOSTLY_LEFT,
    AIR_MOSTLY_UP,
    AIR_MOSTLY_DOWN
} AirDirection;

// ========== Function Declarations ==========

// Main physics update - call this each frame
void UpdatePlayerPhysics(Player* player, const LevelCollision* level);

// Ground physics
void UpdateGroundMovement(Player* player);
void ApplySlopeFactor(Player* player);
void CheckSlipFall(Player* player);
void ConvertGroundSpeedToVelocity(Player* player);

// Air physics
void UpdateAirMovement(Player* player);
void ApplyGravity(Player* player);
void ApplyAirDrag(Player* player);

// Collision handling
void HandleGroundCollision(Player* player, const LevelCollision* level);
void HandleAirCollision(Player* player, const LevelCollision* level);
void HandleWallCollision(Player* player, const LevelCollision* level);

// State transitions
void PlayerJump(Player* player);
void PlayerLand(Player* player, float landAngle);
float CalculateLandingGroundSpeed(Player* player, float landAngle);

// Utility
AirDirection GetAirDirection(float xSpeed, float ySpeed);
float GetSlopeFactorForState(Player* player);
bool IsPushSensorActive(Player* player, bool isRightSensor);

// Character-specific physics getters
float GetAcceleration(Player* player);
float GetDeceleration(Player* player);
float GetFriction(Player* player);
float GetTopSpeed(Player* player);
float GetGravity(Player* player);
float GetJumpForce(Player* player);
float GetAirAcceleration(Player* player);

#endif // PLAYER_PHYSICS_H
