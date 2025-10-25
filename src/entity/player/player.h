// Player header
#ifndef PLAYER_H
#define PLAYER_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "raylib.h"
#include "../../util/math_utils.h"
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
#include "animations/animations.h"

#include "../../util/globals.h"

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

// Player dimensions
#define PLAYER_WIDTH ((PLAYER_WIDTH_RAD * 2) + 1)
#define PLAYER_HEIGHT ((PLAYER_HEIGHT_RAD * 2) + 1)

// Define Player sensors
#define PLAYER_CENTER (PLAYER_WIDTH_RAD + 1.0f), (PLAYER_HEIGHT_RAD + 1.0f)
#define SENSOR_LEFT (PLAYER_CENTER - PLAYER_WIDTH_RAD), PLAYER_CENTER
#define SENSOR_RIGHT (PLAYER_CENTER + PLAYER_WIDTH_RAD), PLAYER_CENTER
#define SENSOR_TOPLEFT (PLAYER_CENTER - PLAYER_WIDTH_RAD), (PLAYER_CENTER + PLAYER_HEIGHT_RAD)
#define SENSOR_TOPRIGHT (PLAYER_CENTER + PLAYER_WIDTH_RAD), (PLAYER_CENTER + PLAYER_HEIGHT_RAD)
#define SENSOR_BOTTOMLEFT (PLAYER_CENTER - PLAYER_WIDTH_RAD), (PLAYER_CENTER - PLAYER_HEIGHT_RAD)
#define SENSOR_BOTTOMRIGHT (PLAYER_CENTER + PLAYER_WIDTH_RAD), (PLAYER_CENTER - PLAYER_HEIGHT_RAD)

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

typedef struct {
    float bottomLeftAngle;
    float bottomRightAngle;
} PlayerGroundAngles;

typedef struct {
    Vector2 center;
    Vector2 left;
    Vector2 right;
    Vector2 topLeft;
    Vector2 topRight;
    Vector2 bottomLeft;
    Vector2 bottomRight;
} PlayerSensors;

typedef struct {
    Vector2 position;
    Vector2 velocity;
    float groundSpeed;
    PlayerSensors playerSensors;
    float verticalSpeed;
    float groundAngle; // In degrees
    int playerRotation; // In degrees
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
    
    // Input tracking fields
    bool inputLeft;
    bool inputRight;
    bool inputUp;
    bool inputDown;
    
    int facing; // 1 = right, -1 = left
    PlayerState state;
    PlayerIdleState idleState;
    PlayerGroundAngles groundAngles;
    PlayerGroundDirection groundDirection;
    bool isImpatient;
    float impatientTimer;
    int spindashCharge; // 0 to SPINDASH_CHARGE_MAX
    float idleTimer; // Time spent idle
    float idleLookTimer; // Time spent looking in idle state
    SpriteObject* sprite;
    PlayerAnimationState animationState;
    AnimationManager* animationManager;
    //PlayerAnimations animations;
    int controlLockTimer; // Frames to lock controls
    int invincibilityTimer; // Frames of invincibility after being hurt
    int blinkTimer; // Timer for blinking effect
    int blinkInterval; // Interval between blinks
    int blinkDuration; // Duration of a blink
    int jumpButtonHoldTimer; // Timer for how long the jump button has been held
    int slipAngleType; // Type of slip angle behavior
    TilesetInfo* currentTileset; // Current tileset info for friction and other properties

    Hitbox_t hitbox;
} Player;

/*
    We need to figure out how to handle player physics and initialization.
    I am a little lost on how to do this properly. The transition from D to
    C is not too difficult, but knowing that I want to rewrite things, I need to
    figure out how to do this properly. There were some issues with the player script
    in the original game, and I want to avoid those issues here.

    I hope Present has an idea on how to handle this. Or the AI, I don't know.

    So lets just write some notes down then. What can we gather from the SPG?
    - Player has a position and velocity
    - Player has a state (idle, walking, running, jumping, etc.)
    - Player has a six sensor collision system (ground, left, right, ceiling, etc.)
    - Player has animations for each state
    - Player can interact with the environment (ground, walls, etc.)
    - Player can be controlled by input (left, right, jump, etc.)
    - Player has physics properties (gravity, friction, etc.)
    - Player can take damage and become invincible for a short time
    - Player can die and respawn
    - Player can perform special moves (spindash, peel out, etc.)

    - Player has a groundAngle that affects X and Y speed
    - Player can rotate based on groundAngle
    - Player has a groundDirection based on input and facing direction
    - Player has a slipAngleType that affects how they slide on slopes
    - Player has a frictionCoefficient that affects movement on different surfaces
    - Player has a topSpeed and a maxSpeed that can be achieved with powerups or downhill slopes.
    - Player has a jumpHeight and a jumpDuration that affects how high and how long they can jump.
    - Player has a fallSpeed and a terminalVelocity that affects how fast they fall.
    - Player has a rollSpeed and a rollDuration that affects how fast and how long they can roll.
    - Player has a spindashSpeed and a spindashDuration that affects how fast and how long they can spindash.
    - Player has a peelOutSpeed and a peelOutDuration that affects how fast and how long they can peel out.
    - Player has a flySpeed and a flyDuration that affects how fast and how long they can fly.
    - Player has a glideSpeed and a glideDuration that affects how fast and how long they can glide.
    
    - Player input will be locked for a short time after certain actions (like getting hurt or performing a special move).
    - Player will have a controlLockTimer that plays when the player is sliding down a steep slope or falling from a height (upside down).
    - Player can run upside down on loops and special collisions.

    - Player can climb ladders and vines. (but we will not implement this yet)
    - Player can swim in water. (but we will not implement this yet)
    - Player can hang from monkey bars. (but we will not implement this yet)
    - Player can wall jump. (but we will not implement this yet)
    - Player can slide on ice. (but we will not implement this yet)

    - Player can interact with springs and bumpers.
    - Player can collect rings and powerups.
    - Player can enter special stages.
    - Player can save and load their progress, and will auto-save at checkpoints.
    - Player can pause the game and access the options menu.
    - Player can see their score, time, and rings on the HUD.
    - Player can hear sound effects and music.

    Ok, I think that is enough for now. We can implement these features step by step. This will require
    a lot of functions, but we can start with the basics and build up from there.
*/

Player Player_Init(float startX, float startY);
void PlayerDrawSensorLines(Player* player);
void Player_Update(Player* player, float dt);
void Player_Draw(Player* player);
#endif