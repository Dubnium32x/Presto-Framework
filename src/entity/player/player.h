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
#define PLAYER_WIDTH (PLAYER_WIDTH_RAD * 2) + 1
#define PLAYER_HEIGHT (PLAYER_HEIGHT_RAD * 2) + 1

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
    IDLE_NORMAL,
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
    bool hasJumped;
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
    int facing; // 1 = right, -1 = left
    PlayerState state;
    PlayerIdleState idleState;
    PlayerGroundDirection groundDirection;
    bool isImpatient;
    float impatientTimer;
    int spindashCharge; // 0 to SPINDASH_CHARGE_MAX
    float idleTimer; // Time spent idle
    float idleLookTimer; // Time spent looking in idle state
    SpriteObject* sprite;
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

void Player_Init(Player* player, float startX, float startY);
void Player_SetLevel(Player* player, TilesetInfo* tilesetInfo);
void Player_SetSpawnPoint(Player* player, float x, float y, bool checkpoint);
void Player_UpdateInput(Player* player);
InputBit GetPlayerInput(Player* player);
void Player_Update(Player* player, float deltaTime);
void Player_UpdatePhysics(Player* player, float deltaTime);
void Player_UpdateGroundPhysics(Player* player, float deltaTime);
void Player_UpdateAirPhysics(Player* player, float deltaTime);
void Player_UpdateRollingPhysics(Player* player, float deltaTime);
void Player_UpdateState(Player* player, float deltaTime);
void Player_UpdateAnimation(Player* player, float deltaTime);
void Player_UpdatePosition(Player* player, float deltaTime);
void Player_HandleCollisionModePhysics(Player* player, float deltaTime);
void Player_ApplySlopeFactor(Player* player);
void Player_PredictSlopePosition(Player* player, float* predictedX, float* predictedY, float deltaTime);
bool Player_IsNextToWallInDirection(Player* player, int direction);
bool Player_IsOnSteepSlope(Player* player);
bool Player_WantsToLookUp(Player* player);
bool Player_WantsToCrouch(Player* player);
bool Player_WantsToJump(Player* player);
bool Player_WantsToSpindash(Player* player);
bool Player_WantsToPeelOut(Player* player);
bool Player_WantsToRun(Player* player);
float Player_GetSlopeMovementModifier(Player* player);
void Player_ApplyFriction(Player* player, float friction);
void Player_ApplyGravity(Player* player, float gravity);
void Player_ApplyGroundDirection(Player* player);
void Player_StartJump(Player* player);
void Player_Jump(Player* player);
void Player_ReleaseJump(Player* player);
void Player_StartSpindash(Player* player);
void Player_ChargeSpindash(Player* player);
void Player_ReleaseSpindash(Player* player);
void Player_StartPeelOut(Player* player);
void Player_SpringBounce(Player* player, float bounceVelocity);
void Player_UpdateIdleState(Player* player, float deltaTime);
void Player_SetState(Player* player, PlayerState newState);
void Player_SetIdleState(Player* player, PlayerIdleState newIdleState);
void Player_FaceDirection(Player* player, bool faceRight);
void Player_TakeDamage(Player* player);
void Player_Respawn(Player* player, float startX, float startY);
void Player_Draw(Player* player);
void Player_Unload(Player* player);
void Player_ShouldLockCamera(Player *player, bool lock);
void Player_CheckHorizontalCollision(float oldX, float targetX);
void Player_CheckVerticalCollision(float oldY, float targetY);

#endif