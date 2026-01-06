// Player header file
#ifndef PLAYER_PLAYER_H
#define PLAYER_PLAYER_H

#include "raylib.h"
#include "player-var.h"
#include "../entity-sprite_object.h"
#include "../../managers/managers-animation.h"
#include "../../data/data-data.h"
#include <math.h>
#include <stdint.h>

// ========== Player Structures and Enums ========== 
// Player State
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
    SPRING_RISE,
    SLIDE,
    HURT,
    DEAD
} PlayerState;

typedef enum {
    IDLE_NORMAL,
    IMPATIENT_LOOK,
    TIRED,
    IMPATIENT_ANIMATION
} PlayerIdleState;

typedef enum {
    ANIM_IDLE,
    ANIM_IMPATIENT_LOOK,
    ANIM_TIRED,
    ANIM_IMPATIENT,
    ANIM_IM_OUTTA_HERE_LOOK,
    ANIM_IM_OUTTA_HERE,
    ANIM_JUMP_OFF_SCREEN_1,
    ANIM_JUMP_OFF_SCREEN_2,
    ANIM_WALK,
    ANIM_CROUCH,
    ANIM_LOOK_UP,
    ANIM_LOOK_DOWN,
    ANIM_SKID,
    ANIM_RUN,
    ANIM_DASH,
    ANIM_PUSH,
    ANIM_JUMP,
    ANIM_FALL,
    ANIM_ROLL,
    ANIM_ROLL_FALL,
    ANIM_SPINDASH,
    ANIM_PEELOUT,
    ANIM_PEELOUT_CHARGED,
    ANIM_FLY,
    ANIM_GLIDE,
    ANIM_CLIMB,
    ANIM_SWIM,
    ANIM_MONKEYBARS,
    ANIM_MONKEYBARS_MOVE,
    ANIM_WALLJUMP,
    ANIM_SLIDE,
    ANIM_AIRBUBBLE,
    ANIM_HURT,
    ANIM_DEAD,
    ANIM_WOBBLE_FRONT,
    ANIM_WOBBLE_BACK,
    ANIM_SPRING_1,
    ANIM_SPRING_2,
    ANIM_BURN,
    ANIM_DROWN,
    ANIM_FANSPIN,
    ANIM_FANSPIN_FALL,
    ANIM_TAUNT,
    ANIM_CELEBRATE,
    ANIM_SURPRISED
} PlayerAnimationState;

// Player Ground Direction
typedef enum {
    NOINPUT,
    DOWN,
    DOWN_RIGHT,
    RIGHT,
    UP_RIGHT,
    UP,
    UP_LEFT,
    LEFT,
    DOWN_LEFT
} PlayerGroundDirection;

// Slip Angle Type
typedef enum {
    SONIC_1_2_CD,
    SONIC_3K
} SlipAngleType;

// Player Sensors
typedef struct {
    Vector2 left;
    Vector2 right;
    Vector2 topLeft;
    Vector2 topRight;
    Vector2 bottomLeft;
    Vector2 bottomRight;
} PlayerSensors;

// Player Structure
typedef struct {
    Vector2 position;
    Vector2 velocity;
    bool isOnGround;
    bool isJumping;
    bool hasJumped;
    bool jumpPressed; // Added for jump input tracking
    bool isFalling;
    bool isRolling;
    bool isCrouching;
    bool isLookingUp;
    bool isSpindashing;
    bool isSuper;
    bool isPeelOut;
    bool isFlying;
    bool isGliding;
    bool isClimbing;
    bool isHurt;
    bool isDead;
    bool isGravityApplied;
    float groundSpeed;
    float groundAngle; // In degrees
    float playerRotation; // In degrees

    // Input tracking fields
    bool inputLeft;
    bool inputRight;
    bool inputUp;
    bool inputDown;

    // Facing direction
    uint8_t facing; // 1 = right, -1 = left

    // Player state and related info
    PlayerType type;
    PlayerState state;
    PlayerIdleState idleState;
    PlayerSensors sensors;
    PlayerGroundDirection groundDirection;

    bool isImpatient;
    float impatientTimer;

    uint8_t spindashCharge;

    float idleTimer; // Time spent idle
    float idleLookTimer; // Time spent looking in idle state

    SpriteObject* sprite;
    PlayerAnimationState animationState;
    AnimationManager* animationManager;

    uint8_t controlLockTimer; // Frames to lock controls
    uint8_t invincibilityTimer; // Frames of invincibility after being hurt
    uint8_t jumpButtonHoldTimer; // Timer for how long the jump button has been held (seconds)
    uint8_t blinkTimer; // Timer for blinking effect
    uint8_t blinkInterval; // Interval between blinks
    uint8_t blinkDuration; // Duration of a blink
    uint16_t slipAngleType;

    Rectangle collisionBox;
} Player;
#endif // PLAYER_PLAYER_H