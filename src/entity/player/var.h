// Variables used by player entity
#ifndef ENTITY_PLAYER_VAR_H
#define ENTITY_PLAYER_VAR_H

#include "raylib.h"
#include <stdio.h>
#include <math.h>

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
#define PLAYER_MAX_COLLISION_POINTS 6

// Physics constants - running state
#define ACCELERATION_SPEED 0.046875f
#define DECELERATION_SPEED 0.5f
#define TOP_SPEED 6.0f
#define FRICTION_SPEED 0.046875f

// Physics constants - air state
#define AIR_ACCELERATION_SPEED 0.09375f
#define AIR_DRAG_FORCE 0.03125f  // Gradual air resistance when no input
#define GRAVITY_FORCE 0.21875f
#define TOP_Y_SPEED 16.0f

// Physics constants - jumping state
#define INITIAL_JUMP_VELOCITY -7.5f
#define RELEASE_JUMP_VELOCITY -8.0f
#define JUMP_HOLD_VELOCITY_INCREASE 0.25f
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

// Angle constants
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
#define SPINDASH_BASE_SPEED 6.0f
#define SPINDASH_CONTROL_LOCK_TIME 0.05f

// Peelout constants
#define PEELOUT_ACCELERATION 0.5f
#define PEELOUT_TOP_SPEED 10.0f
#define PEELOUT_HOLD_TIME 0.5f

// Define player state threshold constants
#define PLAYER_WALK_SPEED_MIN 0.1f
#define PLAYER_RUN_SPEED_MIN 4.0f
#define PLAYER_SPRINT_SPEED_MIN 7.0f
#define PLAYER_SUPER_SPEED_MIN 12.0f

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
    float radians = groundAngle * (PI / 180.0f);
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
    if (fabsf(playerSpeedX) < 0.01f && (fabsf(playerSpeedY) < 0.01f)) {
        playerSpeedX = 0;
        return;
    }

    float angleRad = GroundAngleRadians();
    groundSpeed = (cosf(angleRad) * playerSpeedX) - (sinf(angleRad) * playerSpeedY);

    if (isnan(groundSpeed) || fabsf(groundSpeed) < 0.01f) {
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

    if (fabsf(groundAngle) < 1.0f) return;

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
    if (!isOnGround || fabsf(groundAngle) < 1.0f) {
        return 1.0f;
    }

    float angleRad = GroundAngleRadians();
    float slopeSign = (sinf(angleRad));
    float movementSign = (groundSpeed >= 0) ? 1.0f : -1.0f;

    bool goingUpHill = (slopeSign > 0 && movementSign > 0) || (slopeSign < 0 && movementSign < 0);

    float slopeIntensity = fabsf(sinf(angleRad));

    if (goingUpHill) {
        return 1.0f - (slopeIntensity * 0.25f);
    } else {
        return 1.0f + (slopeIntensity * 0.5f);
    }
}

static inline void DebugPrint() {
    printf("Player X: %.2f Y: %.2f SpeedX: %.2f SpeedY: %.2f GroundAngle: %.2f GroundSpeed: %.2f OnGround: %d Jumped: %d Spindash: %d Rolling: %d Hurt: %d Dead: %d Super: %d ControlLock: %d Facing: %d\n",
           playerX, playerY, playerSpeedX, playerSpeedY, groundAngle, groundSpeed, isOnGround, hasJumped, isSpindashing, isRolling, isHurt, isDead, isSuper, controlLockTimer, facing);
}

#endif // ENTITY_PLAYER_VAR_H
