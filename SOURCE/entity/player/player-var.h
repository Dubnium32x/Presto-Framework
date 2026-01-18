// Player Variables

/*
    This goes over all the variables we will need to handle
    player physics and state.

    This covers Sonic and Tails for now.
    Knuckles, Amy and other characters will be added later.
*/

#pragma once
#include "raylib.h"
#include <stdint.h>
#include <math.h>

// ==== Sonic ====
// Player box dimensions
static const uint8_t SONIC_PLAYER_WIDTH_RAD = 6;
static const uint8_t SONIC_PLAYER_HEIGHT_RAD = 17;

// Physics constants - running state
static const float SONIC_ACCELERATION_SPEED = 0.046875f;
static const float SONIC_DECELERATION_SPEED = 0.5f;
static const uint8_t SONIC_TOP_SPEED = 6;
static const float SONIC_FRICTION_SPEED = 0.046875f;

// Physics constants - air state
static const float SONIC_AIR_ACCELERATION_SPEED = 0.09375f;
static const float SONIC_AIR_DRAG_FORCE = 0.03125f;  // Gradual air resistance when no input
static const float SONIC_GRAVITY_FORCE = 0.21875f;
static const uint8_t SONIC_TOP_Y_SPEED = 16;

// Physics constants - jumping state
static const float SONIC_INITIAL_JUMP_VELOCITY = -7.5f;
static const float SONIC_RELEASE_JUMP_VELOCITY = -8.0f;
static const float SONIC_JUMP_HOLD_VELOCITY_INCREASE = 0.25f;
static const float SONIC_MAX_JUMP_HOLD_TIME = 0.25f;

// Physics constants - rolling state
static const float SONIC_ROLLING_FRICTION = 0.046875f;
static const float SONIC_ROLLING_DECELERATION = 0.125f;
static const uint8_t SONIC_ROLLING_TOP_SPEED = 16;
static const float SONIC_ROLLING_GRAVITY_FORCE = 0.15625f;

// Physics constants - slopes
static const float SONIC_SLOPE_FACTOR_NORMAL = 0.125f;
static const float SONIC_SLOPE_FACTOR_ROLLUP = 0.078125f;
static const float SONIC_SLOPE_FACTOR_ROLLDOWN = 0.3125f;
static const float SONIC_SLIP_THRESHOLD = 2.5f;

// Physics constants - Super Sonic
static const float SONIC_SUPER_ACCELERATION_SPEED = 0.09375f;
static const float SONIC_SUPER_DECELERATION_SPEED = 0.5f;
static const float SONIC_SUPER_TOP_SPEED = 18.0f;
static const float SONIC_SUPER_AIR_ACCELERATION_SPEED = 0.1875f;
static const float SONIC_SUPER_ROLLING_FRICTION = 0.09375f;

// Speed reduction on slope
static const float SONIC_DOWNHILL_SPEED_INCREASE = SONIC_SLOPE_FACTOR_NORMAL + 0.1f;
static const float SONIC_UPHILL_SPEED_DECREASE = SONIC_SLOPE_FACTOR_NORMAL + 0.1f;

// ==== Tails ====
// Player box dimensions (from SPG)
static const uint8_t TAILS_PLAYER_WIDTH_RAD = 9;  // Standing: 9, Jump/Roll: 7
static const uint8_t TAILS_PLAYER_HEIGHT_RAD = 15;  // Standing: 15, Jump/Roll: 14

// Physics constants - running state (same as Sonic per SPG)
static const float TAILS_ACCELERATION_SPEED = 0.046875f;  // 12 subpixels
static const float TAILS_DECELERATION_SPEED = 0.5f;       // 128 subpixels
static const uint8_t TAILS_TOP_SPEED = 6;                 // 6 pixels/frame
static const float TAILS_FRICTION_SPEED = 0.046875f;      // 12 subpixels

// Physics constants - air state (same as Sonic per SPG)
static const float TAILS_AIR_ACCELERATION_SPEED = 0.09375f;  // 24 subpixels
static const float TAILS_AIR_DRAG_FORCE = 0.03125f;         // Air resistance when no input
static const float TAILS_GRAVITY_FORCE = 0.21875f;          // 56 subpixels
static const uint8_t TAILS_TOP_Y_SPEED = 16;

// Physics constants - jumping state (same as Sonic per SPG)
static const float TAILS_JUMP_FORCE = -6.5f;  // 6.5 pixels/frame upward (same as Sonic)
static const float TAILS_RELEASE_JUMP_VELOCITY = -4.0f;  // When jump button released
static const float TAILS_JUMP_HOLD_VELOCITY_INCREASE = 0.25f;
static const float TAILS_MAX_JUMP_HOLD_TIME = 0.25f;

// Physics constants - rolling state (same as Sonic per SPG)
static const float TAILS_ROLLING_FRICTION = 0.0234375f;     // 6 subpixels
static const float TAILS_ROLLING_DECELERATION = 0.125f;     // 32 subpixels
static const uint8_t TAILS_ROLLING_TOP_SPEED = 16;
static const float TAILS_ROLLING_GRAVITY_FORCE = 0.15625f;

// Physics constants - slopes (same as Sonic per SPG)
static const float TAILS_SLOPE_FACTOR_NORMAL = 0.125f;
static const float TAILS_SLOPE_FACTOR_ROLLUP = 0.078125f;
static const float TAILS_SLOPE_FACTOR_ROLLDOWN = 0.3125f;
static const float TAILS_SLIP_THRESHOLD = 2.5f;

// Physics constants - Flying (from SPG - Tails specific!)
static const float TAILS_FLYING_AIR_ACCELERATION = 0.09375f;  // 24 subpixels (same as normal air)
static const float TAILS_FLYING_GRAVITY_NORMAL = 0.03125f;    // 8 subpixels (reduced gravity while flying)
static const float TAILS_FLYING_GRAVITY_LIFT = -0.125f;      // -32 subpixels (negative gravity when pressing jump)
static const float TAILS_FLYING_LIFT_SPEED_THRESHOLD = -1.0f;  // Must be < -1 to return to normal gravity
static const uint16_t TAILS_FLYING_TIME_LIMIT = 480;         // 8 seconds at 60fps before getting tired
static const float TAILS_FLYING_MAX_SPEED_UP = 3.0f;         // Max horizontal speed when moving up (due to air drag)
static const float TAILS_FLYING_MAX_SPEED_DOWN = 6.0f;       // Max horizontal speed when moving down (normal max)

// Physics constants - Super Tails (from SPG)
static const float TAILS_SUPER_ACCELERATION_SPEED = 0.09375f;    // Double normal
static const float TAILS_SUPER_DECELERATION_SPEED = 0.75f;       // 192 subpixels
static const float TAILS_SUPER_TOP_SPEED = 8.0f;                 // Increased top speed
static const float TAILS_SUPER_AIR_ACCELERATION_SPEED = 0.1875f; // 48 subpixels
static const float TAILS_SUPER_ROLLING_FRICTION = 0.0234375f;    // Same as normal

// Speed reduction on slope
static const float TAILS_DOWNHILL_SPEED_INCREASE = TAILS_SLOPE_FACTOR_NORMAL + 0.1f;
static const float TAILS_UPHILL_SPEED_DECREASE = TAILS_SLOPE_FACTOR_NORMAL + 0.1f;

// ==== Common Variables ====
// Angle constants
static const uint8_t ANGLE_DOWN = 0;
static const uint8_t ANGLE_UP = 128;
static const uint8_t ANGLE_RIGHT = 64;
static const uint8_t ANGLE_LEFT = 192;
static const uint8_t ANGLE_DOWN_RIGHT = 32;
static const uint8_t ANGLE_DOWN_LEFT = 96;
static const uint8_t ANGLE_UP_RIGHT = 224;
static const uint8_t ANGLE_UP_LEFT = 160;

// Slope angle constants (using uint16_t to fit larger angles)
static const uint16_t SLIP_ANGLE_START = 46;
static const uint16_t SLIP_ANGLE_END = 315;

// Alternate slope angle ranges (Sonic 3)
static const uint16_t SLIP_ANGLE_START_S3 = 35;
static const uint16_t SLIP_ANGLE_END_S3 = 326;
static const uint16_t FALL_ANGLE_START_S3 = 75;
static const uint16_t FALL_ANGLE_END_S3 = 286;

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