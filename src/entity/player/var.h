// Variables used by player entity
#ifndef ENTITY_PLAYER_VAR_H
#define ENTITY_PLAYER_VAR_H

#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "../../util/math_utils.h"
#include "../../util/globals.h"

// Player variables
extern float playerX;
extern float playerY;
extern float playerSpeedX;
extern float playerSpeedY;
extern float groundAngle;
extern float groundSpeed;
extern bool hasJumped;
extern bool isOnGround;
extern bool isSpindashing;
extern bool isRolling;
extern bool isHurt;
extern bool isDead;
extern bool isSuper;
extern int controlLockTimer;
extern int facing; // 1 = right, -1 = left


// Player box dimensions
#define PLAYER_WIDTH_RAD 6
#define PLAYER_HEIGHT_RAD 17
#define PLAYER_WIDTH ((PLAYER_WIDTH_RAD * 2) + 1)
#define PLAYER_HEIGHT ((PLAYER_HEIGHT_RAD * 2) + 1)
#define PLAYER_MAX_COLLISION_POINTS 6

// Physics constants - running state
#define ACCELERATION_SPEED 0.046875f
#define DECELERATION_SPEED 0.5f
#define TOP_SPEED 6.0f
#define FRICTION_SPEED 0.046875f

// Physics constants - air state
#define AIR_ACCELERATION_SPEED 0.09375f
#define GRAVITY_FORCE 0.21875f
#define TOP_Y_SPEED 16.0f

// Physics constants - jumping state
#define INITIAL_JUMP_VELOCITY -7.5f
#define RELEASE_JUMP_VELOCITY -4.0f
#define JUMP_HOLD_VELOCITY_INCREASE 0.1f
#define MAX_JUMP_HOLD_TIME 0.25f

// Physics constants - rolling state
#define ROLLING_FRICTION 0.046875f
#define ROLLING_DECELERATION 0.125f
#define ROLLING_TOP_SPEED 16.0f
#define ROLLING_GRAVITY_FORCE 0.15625f

// Physcis constants - slopes
#define SLOPE_FACTOR_NORMAL 0.125f
#define SLOPE_FACTOR_ROLLUP 0.078125f
#define SLOPE_FACTOR_ROLLDOWN 0.3125f
#define SLIP_THRESHOLD 2.5f

// Physics constants - Super Sonic
#define SUPER_ACCELERATION_SPEED 0.09375f
#define SUPER_DECELERATION_SPEED 0.5f
#define SUPER_TOP_SPEED 18.0f
#define SUPER_AIR_ACCELERATION_SPEED 0.1875f
#define SUPER_ROLLING_FRICTION 0.09375f

// Angle constants (in Sonic's hex angle system: 256 units = 360 degrees)
#define SONIC_ANGLE_MAX 256
#define SONIC_TO_DEG_FACTOR (360.0f / SONIC_ANGLE_MAX)
#define DEG_TO_SONIC_FACTOR (SONIC_ANGLE_MAX / 360.0f)

#define ANGLE_DOWN 0
#define ANGLE_UP 128
#define ANGLE_RIGHT 64
#define ANGLE_LEFT 192
#define ANGLE_DOWN_RIGHT 32
#define ANGLE_DOWN_LEFT 96
#define ANGLE_UP_RIGHT 224
#define ANGLE_UP_LEFT 160

// Slope angle constants
#define SLIP_ANGLE_START 46
#define SLIP_ANGLE_END 315


// Alternate slope angle ranges (Sonic 3)
#define SLIP_ANGLE_START_S3 35
#define SLIP_ANGLE_END_S3 326
#define FALL_ANGLE_START_S3 75
#define FALL_ANGLE_END_S3 286

// Speed reduction
#define UPHILL_SPEED_REDUCTION SLOPE_FACTOR_NORMAL + 0.1f
#define DOWNHILL_SPEED_INCREASE SLOPE_FACTOR_NORMAL + 0.1f

// Spindash constants
#define SPINDASH_BASE_SPEED 4.0f
#define SPINDASH_MAX_CHARGE 6
#define SPINDASH_SPEED_PER_CHARGE 1.0f
#define SPINDASH_MAX_SPEED (SPINDASH_BASE_SPEED + (SPINDASH_MAX_CHARGE * SPINDASH_SPEED_PER_CHARGE))
#define SPINDASH_CHARGE_DECAY_RATE 0.1f
#define SPINDASH_CONTROL_LOCK_TIME 0.05f

// Peelout constants
#define PEELOUT_ACCELERATION 0.5f
#define PEELOUT_TOP_SPEED 10.0f
#define PEELOUT_HOLD_TIME 0.5f

// Timing constants
#define SECONDS_TO_FRAMES(seconds) ((int)((seconds) * 60.0f))
#define FRAMES_TO_SECONDS(frames) ((float)(frames) / 60.0f)

// Position conversion constants
#define WORLD_TO_TILE_X(worldX) ((int)((worldX) / TILE_SIZE))
#define WORLD_TO_TILE_Y(worldY) ((int)((worldY) / TILE_SIZE))
#define TILE_TO_WORLD_X(tileX) ((float)(tileX) * TILE_SIZE)
#define TILE_TO_WORLD_Y(tileY) ((float)(tileY) * TILE_SIZE)

// Define player state threshold constants
#define PLAYER_WALK_SPEED_MIN 0.1f
#define PLAYER_RUN_SPEED_MIN 4.0f
#define PLAYER_SPRINT_SPEED_MIN 7.0f
#define PLAYER_SUPER_SPEED_MIN 12.0f

// Physics calculation constants
#define MIN_SPEED_THRESHOLD 0.01f
#define GROUND_ANGLE_THRESHOLD 1.0f
#define SLOPE_MOVEMENT_UPHILL_FACTOR 0.25f
#define SLOPE_MOVEMENT_DOWNHILL_FACTOR 0.5f

typedef enum {
    SONIC_1_2_CD,
    SONIC_3K
} SlipAngleType;

extern SlipAngleType slipAngleType;

static inline void ResetPosition(float x, float y) {
    playerX = x;
    playerY = y;
    playerSpeedX = 0;
    playerSpeedY = 0;
    groundAngle = 0;
    hasJumped = false;
    isOnGround = false;
    isSpindashing = false;
    isRolling = false;
    isHurt = false;
    isDead = false;
    isSuper = false;
    controlLockTimer = 0;
}

static inline void SetFacing(int dir) {
    if (dir != 0) {
        facing = dir;
    }
}

static inline float GroundAngleRadians() {
    if(isnan(groundAngle) || groundAngle < -180.0f || groundAngle > 180.0f) {
        return 0.0f;
    }
    float radians = groundAngle * DEG2RAD;
    if (isnan(radians)) {
        return 0.0f;
    }
    return radians;
}

static inline float GetAngleFromHexDirection(int hexDir) {
    switch (hexDir) {
        case ANGLE_RIGHT: return 0.0f;
        case ANGLE_DOWN_RIGHT: return 45.0f;
        case ANGLE_DOWN: return 90.0f;
        case ANGLE_DOWN_LEFT: return 135.0f;
        case ANGLE_LEFT: return 180.0f;
        case ANGLE_UP_LEFT: return 225.0f;
        case ANGLE_UP: return 270.0f;
        case ANGLE_UP_RIGHT: return 315.0f;
        default: return 0.0f;
    }
}

static inline float GetHexDirectionFromAngle(float angle) {
    angle = fmodf(angle, 360.0f);
    if (angle < 0) angle += 360.0f;

    if (angle >= 337.5f || angle < 22.5f) return ANGLE_RIGHT;
    else if (angle >= 22.5f && angle < 67.5f) return ANGLE_DOWN_RIGHT;
    else if (angle >= 67.5f && angle < 112.5f) return ANGLE_DOWN;
    else if (angle >= 112.5f && angle < 157.5f) return ANGLE_DOWN_LEFT;
    else if (angle >= 157.5f && angle < 202.5f) return ANGLE_LEFT;
    else if (angle >= 202.5f && angle < 247.5f) return ANGLE_UP_LEFT;
    else if (angle >= 247.5f && angle < 292.5f) return ANGLE_UP;
    else if (angle >= 292.5f && angle < 337.5f) return ANGLE_UP_RIGHT;

    return ANGLE_RIGHT; // Default case
}

static inline void UpdateSpeedsFromGroundSpeed() {
    float angleRad = GroundAngleRadians();
    playerSpeedX = cosf(angleRad) * fabsf(playerSpeedX);
    playerSpeedY = sinf(angleRad) * fabsf(playerSpeedX);
}

static inline void UpdateGroundSpeedFromSpeeds() {
    if (fabsf(playerSpeedX) < MIN_SPEED_THRESHOLD && (fabsf(playerSpeedY) < MIN_SPEED_THRESHOLD)) {
        playerSpeedX = 0;
        return;
    }

    float angleRad = GroundAngleRadians();
    groundSpeed = (cosf(angleRad) * playerSpeedX) - (sinf(angleRad) * playerSpeedY);

    if (isnan(groundSpeed) || fabsf(groundSpeed) < MIN_SPEED_THRESHOLD) {
        groundSpeed = 0;
    }
}

static inline bool ShouldSlipOnSlope() {
    if (!isOnGround || controlLockTimer > 0) return false;

    return (fabsf(groundAngle) < SLIP_THRESHOLD && fabsf(groundAngle) > SLIP_ANGLE_START) ||
           (slipAngleType == SONIC_1_2_CD && (groundAngle > SLIP_ANGLE_START || groundAngle < SLIP_ANGLE_END)) ||
           (slipAngleType == SONIC_3K && ((groundAngle > SLIP_ANGLE_START_S3 && groundAngle < FALL_ANGLE_START_S3) || 
                                          (groundAngle < SLIP_ANGLE_END_S3 && groundAngle > FALL_ANGLE_END_S3)));
}

static inline void ApplySlopeFactor() {
    if (!isOnGround) return;

    if (fabsf(groundAngle) < GROUND_ANGLE_THRESHOLD) return;

    float slopeFactor = SLOPE_FACTOR_NORMAL;

    if (isRolling) {
        float groundSpeedSign  = (groundSpeed >= 0) ? 1.0f : -1.0f;
        float angleRad = GroundAngleRadians();
        if (isnan(angleRad)) { angleRad = 0.0f;}
        float slopeSign = (sinf(angleRad) >= 0) ? 1.0f : -1.0f;

        if (groundSpeedSign == slopeSign) {
            slopeFactor = SLOPE_FACTOR_ROLLUP;
        } else {
            slopeFactor = SLOPE_FACTOR_ROLLDOWN;
        }
    }

    float angleRad = GroundAngleRadians();
    if (isnan(angleRad)) { angleRad = 0.0f;}
    float sinAngle = sinf(angleRad);
    if (isnan(sinAngle)) { sinAngle = 0.0f;}

    float oldGroundSpeed = groundSpeed;
    groundSpeed -= sinAngle * slopeFactor;

    if (isnan(groundSpeed)) {
        groundSpeed = oldGroundSpeed;
    }
}

static inline float GetSlopeMovementModifier() {
    if (!isOnGround || fabsf(groundAngle) < GROUND_ANGLE_THRESHOLD) {
        return 1.0f;
    }

    float angleRad = GroundAngleRadians();
    float slopeSign = (sinf(angleRad));
    float movementSign = (groundSpeed >= 0) ? 1.0f : -1.0f;

    bool goingUpHill = (slopeSign > 0 && movementSign > 0) || (slopeSign < 0 && movementSign < 0);

    float slopeIntensity = fabsf(sinf(angleRad));

    if (goingUpHill) {
        return 1.0f - (slopeIntensity * SLOPE_MOVEMENT_UPHILL_FACTOR);
    } else {
        return 1.0f + (slopeIntensity * SLOPE_MOVEMENT_DOWNHILL_FACTOR);
    }
}

// Utility functions using constants
static inline Vector2 GetPlayerTilePosition() {
    return (Vector2){ WORLD_TO_TILE_X(playerX), WORLD_TO_TILE_Y(playerY) };
}

static inline Rectangle GetPlayerScreenBounds() {
    return (Rectangle){
        playerX - PLAYER_WIDTH_RAD,
        playerY - PLAYER_HEIGHT_RAD,
        (float)PLAYER_WIDTH,
        (float)PLAYER_HEIGHT
    };
}

static inline bool IsPlayerMovingSignificantly() {
    return fabsf(playerSpeedX) > MIN_SPEED_THRESHOLD || fabsf(playerSpeedY) > MIN_SPEED_THRESHOLD;
}

static inline float SonicAngleToRadians(int sonicAngle) {
    return (sonicAngle * SONIC_TO_DEG_FACTOR) * DEG2RAD;
}

static inline int RadiansToSonicAngle(float radians) {
    return (int)((radians * RAD2DEG) * DEG_TO_SONIC_FACTOR);
}

static inline void DebugPrint() {
    printf("Player X: %.2f Y: %.2f SpeedX: %.2f SpeedY: %.2f GroundAngle: %.2f GroundSpeed: %.2f OnGround: %d Jumped: %d Spindash: %d Rolling: %d Hurt: %d Dead: %d Super: %d ControlLock: %d Facing: %d\n",
           playerX, playerY, playerSpeedX, playerSpeedY, groundAngle, groundSpeed, isOnGround, hasJumped, isSpindashing, isRolling, isHurt, isDead, isSuper, controlLockTimer, facing);
}

#endif // ENTITY_PLAYER_VAR_H