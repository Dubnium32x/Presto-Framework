// Player header
#ifndef PLAYER_H
#define PLAYER_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "raylib.h"
#include "../util/math_utils.h"
#include "var.h"
#include "../entity_manager.h"
#include "../sprite_object.h"
#include "../../world/tile_collision.h"
#include "../../world/tileset_map.h"
#include "../../sprite/animation_manager.h"
#include "../../sprite/sprite_manager.h"
#include "../../sprite/spritesheet_splitter.h"
#include "../../world/audio_manager.h"
#include "../../world/input.h"

// Skid constants
#define SKID_MIN_SPEED 2.5f
#define SKID_DECEL_FACTOR 0.5f

// Idle impatience time (in seconds)
#define IDLE_IMPATIENCE_TIME 5.0f
#define IDLE_IMPATIENCE_LOOK_TIME 1.5f

// Input constants
#define SPINDASH_CHARGE_MAX 7
#define SPINDASH_MIN_SPEED 6.0f
#define SPINDASH_SPEED_PER_CHARGE 1.5f

typedef enum {
    IDLE,
    WALK,
    CROUCH,
    LOOK_UP,
    SKID,
    RUN,
    DASH,
    PUSH,
    JUMP,
    FALL,
    ROLL,
    ROLL_FALL,
    SPINDASH,
    PEELOUT,
    FLY,
    GLIDE,
    CLIMB,
    SWIM,
    MONKEYBARS,
    WALLJUMP,
    SLIDE,
    HURT,
    DEAD
} PlayerState;

typedef enum {
    NORMAL,
    IMPATIENT_LOOK,
    TIRED,
    IMPATIENT_ANIMATION
} PlayerIdleState;

typedef enum {
    NONE,
    DOWN,
    DOWN_RIGHT,
    RIGHT,
    UP_RIGHT,
    UP,
    UP_LEFT,
    LEFT,
    DOWN_LEFT
} PlayerGroundDirection;

typedef struct {
    Vector2 position;
    Vector2 velocity;
    float groundSpeed;
    float verticalSpeed;
    float groundAngle; // In degrees
    bool isOnGround;
    bool isJumping;
    bool isFalling;
    bool isRolling;
    bool isCrouching;
    bool isLookingUp;
    bool isSpindashing;
    bool isPeelOut;
    bool isFlying;
    bool isGliding;
    bool isClimbing;
    bool isHurt;
    bool isDead;
    bool facingRight;
    PlayerState state;
    PlayerIdleState idleState;
    PlayerGroundDirection groundDirection;
    int spindashCharge; // 0 to SPINDASH_CHARGE_MAX
    float idleTimer; // Time spent idle
    float idleLookTimer; // Time spent looking in idle state
    SpriteObject* sprite;
    AnimationManager* animationManager;
    PlayerAnimations animations;
    int controlLockTimer; // Frames to lock controls
    int invincibilityTimer; // Frames of invincibility after being hurt
    int blinkTimer; // Timer for blinking effect
    int blinkInterval; // Interval between blinks
    int blinkDuration; // Duration of a blink
    int jumpButtonHoldTimer; // Timer for how long the jump button has been held
    int slipAngleType; // Type of slip angle behavior
} Player;




#endif