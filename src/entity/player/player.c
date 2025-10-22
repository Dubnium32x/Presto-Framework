// Player script
// ... oh boy...
// This is going to be a long one...

#include "player.h"
#include "raylib.h"
#include "var.h"
#include "../sprite_object.h"
#include "../../util/globals.h"
#include "../../util/math_utils.h"
#include "../../world/input.h"
#include "../../util/level_loader.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define BUTTON_JUMP KEY_SPACE
#define BUTTON_DOWN KEY_DOWN
#define BUTTON_UP KEY_UP
#define INPUT_DOWN KEY_DOWN
#define INPUT_UP KEY_UP
#define INPUT_LEFT KEY_LEFT
#define INPUT_RIGHT KEY_RIGHT

// Missing constants
#define STEEP_SLOPE_ANGLE 45.0f
#define SKID_CONTROL_LOCK_TIME 0.1f
#define SKID_SPEED_REDUCTION_FACTOR 0.5f
#define BUTTON_JUMP_ KEY_SPACE
#define MAX_SPINDASH_CHARGE 8
#define SPINDASH_SPEED_INCREMENT 0.5f
#define PEEL_OUT_SPEED 8.0f
#define PEEL_OUT_CONTROL_LOCK_TIME 0.2f
#define PEEL_OUT_HOLD_TIME 1.0f
#define PEEL_OUT_TOP_SPEED 12.0f
#define INVINCIBILITY_DURATION 2.0f
#define HURT_CONTROL_LOCK_TIME 0.3f

// Stub function for checking if key is held - replace with actual implementation
bool IsKeyHeld(int key) {
    return IsKeyDown(key); // Simple implementation
}

// Stub function for collision detection - replace with actual implementation
// Hook into the currently-loaded level from level_demo_screen.c
extern LevelData level;

bool IsTileSolidAtPosition(float x, float y) {
    // Use the level loader's collision helper on the collision layers
    if (!level.width || !level.height) return false;
    return IsSolidAtPosition(&level, x, y, TILE_SIZE);
}

// Stub function for sprite drawing - replace with actual implementation
void DrawSprite(void* sprite, float x, float y, int facing) {
    (void)sprite; (void)x; (void)y; (void)facing; // Suppress unused parameter warnings
    // Temporary stub
}

Player Player_Init(float startX, float startY, Hitbox_t box) {
    Player player = {0};

    player.position = (Vector2){ startX, startY };
    player.velocity = (Vector2){ 0.0f, 0.0f };
    player.groundAngle = 0.0f;
    player.groundSpeed = 0.0f;
    player.verticalSpeed = 0.0f;
    player.hasJumped = false;
    player.jumpPressed = false;
    // Start in the air; we'll resolve ground on the first update
    player.isOnGround = false;
    player.isSpindashing = false;
    player.isRolling = false;
    player.isCrouching = false;
    player.isLookingUp = false;
    player.isFlying = false;
    player.isGliding = false;
    player.isPeelOut = false;
    player.isClimbing = false;
    player.isHurt = false;
    player.isDead = false;
    player.isSuper = false;
    
    // Initialize input tracking
    player.inputLeft = false;
    player.inputRight = false;
    player.inputUp = false;
    player.inputDown = false;
    player.controlLockTimer = 0;
    player.facing = 1; // Facing right
    player.state = IDLE;
    player.idleState = IDLE_NORMAL;
    player.groundDirection = NOINPUT;
    player.isImpatient = false;
    player.impatientTimer = 0.0f;
    player.spindashCharge = 0;
    player.playerRotation = 0;
    player.idleTimer = 0.0f;
    player.idleLookTimer = 0.0f;
    player.sprite = NULL;
    player.animationManager = NULL;
    player.jumpButtonHoldTimer = 0;
    player.slipAngleType = SONIC_1_2_CD;
    player.currentTileset = NULL;
    player.animationState = IDLE;
    player.blinkTimer = 0;
    player.blinkInterval = 300; // Blink every 300 frames
    player.blinkDuration = 5;   // Blink lasts for 5 frames
    player.invincibilityTimer = 0;
    player.controlLockTimer = 0;

    player.hitbox = box;

    printf("Player Loaded! \n");

    return player;
}

void Player_SetLevel(Player* player, TilesetInfo* tilesetInfo) {
    player->currentTileset = tilesetInfo;
}

InputBit GetPlayerInput(Player* player) {
    (void)player; // Suppress unused parameter warning
    InputBit input = 0;
    if (IsKeyDown(INPUT_UP)) input |= 1;
    if (IsKeyDown(INPUT_DOWN)) input |= 2;
    if (IsKeyDown(INPUT_LEFT)) input |= 4;
    if (IsKeyDown(INPUT_RIGHT)) input |= 8;
    if (IsKeyDown(BUTTON_JUMP)) input |= 16;
    return input;
}

void Player_UpdateInput(Player* player) {
    bool prevJump = player->isJumping;

    // Read input
    player->isJumping = IsKeyDown(BUTTON_JUMP);
    player->jumpPressed = player->isJumping && !prevJump;
    
    // Store input state for physics
    player->inputLeft = IsKeyDown(INPUT_LEFT);
    player->inputRight = IsKeyDown(INPUT_RIGHT);
    player->inputDown = IsKeyDown(INPUT_DOWN);
    player->inputUp = IsKeyDown(INPUT_UP);
}

// Implementation of the physics update function
void Player_UpdatePhysics(Player* player, float deltaTime) {
    (void)deltaTime; // Physics runs in pixel-per-frame units (SPG-style)
    if (player->isOnGround) {
        // Ground movement (per-frame units)
        if (IsKeyDown(INPUT_LEFT)) {
            player->groundSpeed = fmaxf(player->groundSpeed - ACCELERATION, -TOP_SPEED);
        } else if (IsKeyDown(INPUT_RIGHT)) {
            player->groundSpeed = fminf(player->groundSpeed + ACCELERATION, TOP_SPEED);
        } else if (player->groundSpeed != 0) {
            // Natural deceleration when no input
            float friction = FRICTION;
            if (player->groundSpeed > 0) player->groundSpeed = fmaxf(0, player->groundSpeed - friction);
            else                         player->groundSpeed = fminf(0, player->groundSpeed + friction);
        }
    } else {
        // Air control (per-frame units)
        if (IsKeyDown(INPUT_LEFT)) {
            player->velocity.x = fmaxf(player->velocity.x - AIR_ACCELERATION, -AIR_TOP_SPEED);
        } else if (IsKeyDown(INPUT_RIGHT)) {
            player->velocity.x = fminf(player->velocity.x + AIR_ACCELERATION, AIR_TOP_SPEED);
        }
        // Gravity per frame
        player->velocity.y += GRAVITY;
    }
}

// Implementation of the animation update function
void Player_UpdateAnimation(Player* player, float deltaTime) {
    // TODO: Implement full animation system
    // For now, just update basic state
    if (player->isOnGround) {
        if (fabsf(player->groundSpeed) > 0.1f) {
            player->animationState = ANIM_WALK;
            player->facing = (player->groundSpeed > 0) ? 1 : -1;
        } else {
            player->animationState = ANIM_IDLE;
        }
    } else {
        player->animationState = ANIM_JUMP;
    }
}

// Implementation of the position update function
void Player_UpdatePosition(Player* player, float deltaTime) {
    // TODO: Implement full position update with collision
    if (player->isOnGround) {
        float angleRad = player->groundAngle * DEG2RAD;
        player->velocity.x = player->groundSpeed * cosf(angleRad);
        player->velocity.y = player->groundSpeed * -sinf(angleRad);
    }
    
    // Update position based on velocity
    (void)deltaTime; // pixel-per-frame integration
    player->position.x += player->velocity.x;
    player->position.y += player->velocity.y;

    // Simple ground probe using Genesis-style two-foot sensors (A/B)
    float centerX = player->position.x + player->hitbox.x + player->hitbox.w*0.5f;
    float feetY   = player->position.y + player->hitbox.y + player->hitbox.h;
    float footOffset = player->hitbox.w * 0.25f;

    bool groundA = IsTileSolidAtPosition(centerX - footOffset, feetY + 1);
    bool groundB = IsTileSolidAtPosition(centerX + footOffset, feetY + 1);

    bool wasGrounded = player->isOnGround;
    player->isOnGround = (groundA || groundB);

    if (player->isOnGround) {
        // Snap up slightly when landing to avoid sinking
        if (!wasGrounded && player->velocity.y > 0) {
            player->velocity.y = 0;
        }
    }
}

void Player_Update(Player* player, float deltaTime) {
    // Manage idle impatience timing here (use deltaTime available)
    if (player->state == IDLE) {
        player->idleTimer += deltaTime;
        if (!player->isImpatient && player->idleTimer >= IDLE_IMPATIENCE_LOOK_TIME) {
            player->isImpatient = true;
            player->idleState = IMPATIENT_LOOK;
            player->animationState = ANIM_IMPATIENT_LOOK;
        } else if (player->isImpatient && player->idleState == IMPATIENT_LOOK && player->idleTimer >= (IDLE_IMPATIENCE_TIME + IDLE_IMPATIENCE_LOOK_TIME)) {
            player->idleState = IMPATIENT_ANIMATION;
            player->animationState = ANIM_IMPATIENT;
        }
    } else {
        // Reset impatience when not idle
        player->idleTimer = 0.0f;
        player->isImpatient = false;
        player->idleState = IDLE_NORMAL;
    }

    Player_UpdateInput(player);
    Player_UpdatePhysics(player, deltaTime);
    Player_UpdateAnimation(player, deltaTime);
    Player_UpdatePosition(player, deltaTime);
}

void Player_UpdateGroundPhysics(Player* player, float deltaTime) {
    // Update ground speed based on input and friction
    Player_ApplySlopeFactor(player);
    Player_UpdateSpeedsFromGroundSpeed(player);
    Player_ApplyRotationBasedOnGroundAngle(player);
    Player_ApplySlopeFactor(player);
    Player_ApplyFriction(player, FRICTION_SPEED);
    Player_ApplyGroundDirection(player);
}

void Player_ApplyGroundDirection(Player* player) {
    /*
        Apply ground direction to modify ground speed.
        Ground direction is determined by player input and facing direction.
    */

    switch (player->groundDirection) {
        case DOWN:
            player->playerRotation = ANGLE_DOWN;
            break;
        case DOWN_LEFT:
            player->playerRotation = ANGLE_DOWN_LEFT;
            break;
        case LEFT:
            player->playerRotation = ANGLE_LEFT;
            break;
        case UP_LEFT:
            player->playerRotation = ANGLE_UP_LEFT;
            break;
        case UP:
            player->playerRotation = ANGLE_UP;
            break;
        case UP_RIGHT:
            player->playerRotation = ANGLE_UP_RIGHT;
            break;
        case RIGHT:
            player->playerRotation = ANGLE_RIGHT;
            break;
        case DOWN_RIGHT:
            player->playerRotation = ANGLE_DOWN_RIGHT;
            break;
        default:
            break;
    }

    if (player->groundAngle == 0.0f) return; // No slope, no adjustment needed
    if (player->isOnGround == false) return; // Only apply on ground
    if (player->groundDirection == NOINPUT) return; // No input, no adjustment needed

    float angleRad = player->groundAngle * (PI / 180.0f);

    float hexAngle = GetHexDirectionFromAngle(player->groundAngle);

    // Additional logic can be added here to handle hexagonal ground directions
    // and their effects on player movement and physics.
}

void Player_UpdateSpeedsFromGroundSpeed(Player* player) {
    if (player->isOnGround) {
        float angleRad = player->groundAngle * (PI / 180.0f);
        player->velocity.x = player->groundSpeed * cosf(angleRad);
        player->velocity.y = player->groundSpeed * -sinf(angleRad);
    } else {
        player->velocity.x = 0;
        player->velocity.y = 0;
    }
}

void Player_ApplySlopeFactor(Player* player) {
    if (!player->isOnGround) return;

    if (fabsf(player->groundAngle) < 1.0f) return;

    float slopeFactor = SLOPE_FACTOR_NORMAL;

    float angleRad = player->groundAngle * (PI / 180.0f);
    if (isnan(angleRad)) { angleRad = 0.0f;}
    float speedAdjustment = slopeFactor * sinf(angleRad);

    player->groundSpeed -= speedAdjustment;
}

void Player_ApplyRotationBasedOnGroundAngle(Player* player) {
    if (!player->isOnGround) return;

    // Rotate player sprite based on ground angle
    switch (player->groundDirection) {
        case RIGHT:
            player->playerRotation = GetAngleFromHexDirection(ANGLE_RIGHT);
            break;
        case LEFT:
            player->playerRotation = GetAngleFromHexDirection(ANGLE_LEFT);
            break;
        case UP_RIGHT:
            player->playerRotation = GetAngleFromHexDirection(ANGLE_UP_RIGHT);
            break;
        case UP_LEFT:
            player->playerRotation = GetAngleFromHexDirection(ANGLE_UP_LEFT);
            break;
        case DOWN_RIGHT:
            player->playerRotation = GetAngleFromHexDirection(ANGLE_DOWN_RIGHT);
            break;
        case DOWN_LEFT:
            player->playerRotation = GetAngleFromHexDirection(ANGLE_DOWN_LEFT);
            break;
        case UP:
            player->playerRotation = GetAngleFromHexDirection(ANGLE_UP);
            break;
        case DOWN:
            player->playerRotation = GetAngleFromHexDirection(ANGLE_DOWN);
            break;
        default:
            break;
    }
}

void Player_UpdateRollingPhysics(Player* player, float deltaTime) {
    // Additional rolling physics can be implemented here
    float slopeFactor = SLOPE_FACTOR_NORMAL;

    if (player->isRolling) {
        float groundSpeedSign  = (player->groundSpeed >= 0) ? 1.0f : -1.0f;
        float angleRad = player->groundAngle * (PI / 180.0f);
        float slopeSign = (sinf(angleRad) >= 0) ? 1.0f : -1.0f;

        if (groundSpeedSign == slopeSign) {
            slopeFactor = SLOPE_FACTOR_ROLLUP;
        } else {
            slopeFactor = SLOPE_FACTOR_ROLLDOWN;
        }
    }
}

void Player_ApplyFriction(Player* player, float friction) {
    // Make sure to apply friction based off x speed and y speed!
    // For example if you're speeding towards a wall at an angle, friction should slow you down in both x and y directions
    if (player->isOnGround) {
        if (player->groundSpeed > 0) {
            player->groundSpeed = fmaxf(0, player->groundSpeed - friction);
        } else {
            player->groundSpeed = fminf(0, player->groundSpeed + friction);
        }
    
    } else {
        if (player->velocity.x > 0) {
            player->velocity.x = fmaxf(0, player->velocity.x - friction);
        } else {
            player->velocity.x = fminf(0, player->velocity.x + friction);
        }
    }
}



void Player_PredictSlopePosition(Player* player, float* predictedX, float* predictedY, float deltaTime) {
    if (!player->isOnGround) {
        *predictedX = player->position.x + player->velocity.x * deltaTime;
        *predictedY = player->position.y + player->velocity.y * deltaTime;
        return;
    }

    float angleRad = player->groundAngle * (PI / 180.0f);
    float predictedGroundSpeed = player->groundSpeed;

    float predictedVelocityX = predictedGroundSpeed * cosf(angleRad);
    float predictedVelocityY = predictedGroundSpeed * -sinf(angleRad);

    *predictedX = player->position.x + predictedVelocityX * deltaTime;
    *predictedY = player->position.y + predictedVelocityY * deltaTime;
}

bool Player_IsNextToWallInDirection(Player* player, int direction) {
    if (player->isOnGround && direction == DOWN) {
        // Check if the player is next to a wall in the downward direction
        if (IsTileSolidAtPosition(player->position.x, player->position.y + 1)) {
            return true;
        }
    }
    return false;
}

void Player_UpdateAirPhysics(Player* player, float deltaTime) {
    // Basic air movement
    (void)deltaTime;
    if (IsKeyDown(INPUT_LEFT)) {
        player->velocity.x = fmaxf(player->velocity.x - AIR_ACCELERATION, -AIR_TOP_SPEED);
    } else if (IsKeyDown(INPUT_RIGHT)) {
        player->velocity.x = fminf(player->velocity.x + AIR_ACCELERATION, AIR_TOP_SPEED);
    }
    // Apply gravity (per frame)
    player->velocity.y += GRAVITY;

    Player_ApplyFriction(player, FRICTION);
}

void Player_UpdateState(Player* player, float deltaTime) {
    // Update player state based on conditions
    if (player->isOnGround) {
        if (4.0f < fabsf(player->groundSpeed) && fabsf(player->groundSpeed) > 0.05f) {
            player->state = WALK;
        } else if (fabsf(player->groundSpeed) >= 4.0f) {
            player->state = RUN;
        } else if (Player_WantsToBeIdle(player)) {
            player->state = IDLE;
        }
    }

    if (!player->isOnGround && player->jumpPressed && !player->hasJumped) {
        if (player->velocity.y < 0) {
            player->state = JUMP;
            player->hasJumped = true;
        } else {
            player->state = FALL;
            player->hasJumped = true; // Prevent double jumps
        }
    }
    if ((IsKeyDown(INPUT_LEFT) || IsKeyDown(INPUT_RIGHT)) && player->isOnGround) {
        if (player->facing == 1 && IsKeyDown(INPUT_LEFT) && fabsf(player->groundSpeed) > 3.0f) {
            player->state = SKID;
        } else if (player->facing == -1 && IsKeyDown(INPUT_RIGHT) && fabsf(player->groundSpeed) > 3.0f) {
            player->state = SKID;
        }
    }
    if (Player_CheckVerticalCollision(player->position.y, player->position.y + player->velocity.y) && player->isOnGround && (player->groundDirection == DOWN)) {
        if (player->facing == -1 && IsKeyDown(INPUT_LEFT)) {
            player->state = PUSH;
        } else if (player->facing == 1 && IsKeyDown(INPUT_RIGHT)) {
            player->state = PUSH;
        }
    }
    if (player->groundSpeed > TOP_SPEED / 2 && player->isOnGround && (IsKeyDown(BUTTON_DOWN))) {
        player->state = ROLL;
        player->isRolling = true;
    }
    if (player->isRolling && !player->isOnGround) {
        player->state = ROLL_FALL;
        player->isRolling = true;
    }
    if (IsKeyDown(BUTTON_DOWN) && player->isOnGround && fabsf(player->groundSpeed) < 0.1f) {
        player->isCrouching = true;
        player->state = CROUCH;
    } else {
        player->isCrouching = false;
    }
    if (player->isCrouching && IsKeyPressed(BUTTON_JUMP)) {
        player->state = SPINDASH;
        player->isSpindashing = true;
    }
    if (player->isOnGround && IsKeyPressed(BUTTON_UP) && fabsf(player->groundSpeed) < 0.1f) {
        player->isLookingUp = true;
        player->state = LOOK_UP;
    } else {
        player->isLookingUp = false;
    }
    if (player->isLookingUp && !IsKeyDown(BUTTON_JUMP)) {
        player->isPeelOut = true;
        player->state = PEELOUT;
    }
    if (player->isOnGround && fabsf(player->groundSpeed) > TOP_SPEED + 2.0f) {
        player->state = DASH;
    }

    if (player->isFlying) {
        player->state = FLY;
    }
    if (player->isGliding) {
        player->state = GLIDE;
    }
    if (player->isClimbing) {
        player->state = CLIMB;
    }
    if (player->isHurt) {
        player->state = HURT;
    }
    if (player->isDead) {
        player->state = DEAD;
    }
}

float Player_GetSlopeMovementModifier(Player* player) {
    if (!player->isOnGround || fabsf(player->groundAngle) < 1.0f) {
        return 1.0f;
    }

    float angleRad = player->groundAngle * (PI / 180.0f);
    float slopeSign = (sinf(angleRad));
    float movementSign = (player->groundSpeed >= 0) ? 1.0f : -1.0f;

    bool goingUpHill = (slopeSign > 0 && movementSign > 0) || (slopeSign < 0 && movementSign < 0);

    float slopeIntensity = fabsf(sinf(angleRad));

    if (goingUpHill) {
        return 1.0f - (slopeIntensity * 0.25f);
    } else {
        return 1.0f + (slopeIntensity * 0.5f);
    }
}

bool Player_CheckHorizontalCollision(float oldX, float targetX) {
    // Simple horizontal collision detection
    if (IsTileSolidAtPosition(targetX, 200)) { // Use a reasonable Y position
        return true;
    }
    return false;
}

bool Player_CheckVerticalCollision(float oldY, float targetY) {
    // Simple vertical collision detection
    if (IsTileSolidAtPosition(200, targetY)) { // Use a reasonable X position
        return true;
    }
    return false;
}

bool Player_WantsToRun(Player* player) {
    if (!player->isOnGround || player->controlLockTimer > 0) return false;

    if (fabsf(player->groundAngle) < SLIP_THRESHOLD && fabsf(player->groundAngle) > SLIP_ANGLE_START) {
        // Normal slip condition
        return false;
    }

    if (player->slipAngleType == SONIC_1_2_CD && (player->groundAngle > SLIP_ANGLE_START || player->groundAngle < SLIP_ANGLE_END)) {
        // Sonic 1/2 CD slip condition
        return false;
    }

    if (player->slipAngleType == SONIC_3K && ((player->groundAngle > SLIP_ANGLE_START_S3 && player->groundAngle < FALL_ANGLE_START_S3) || 
                                             (player->groundAngle < SLIP_ANGLE_END_S3 && player->groundAngle > FALL_ANGLE_END_S3))) {
        // Sonic 3K slip condition
        return false;
    }

    // If none of the slip conditions are met, the player can run
    return true;
}

bool Player_IsOnSteepSlope(Player* player) {
    return fabsf(player->groundAngle) > STEEP_SLOPE_ANGLE;
}

bool Player_WantsToLookUp(Player* player) {
    if (!player->isOnGround || player->controlLockTimer > 0) return false;

    return IsKeyDown(INPUT_UP);
}

bool Player_WantsToCrouch(Player* player) {
    if (!player->isOnGround || player->controlLockTimer > 0) return false;

    return IsKeyDown(INPUT_DOWN);
}

void Player_StartSkid(Player* player) {
    if (!player->isOnGround || player->controlLockTimer > 0) return;

    if ((player->facing == 1 && IsKeyDown(INPUT_LEFT)) || (player->facing == -1 && IsKeyDown(INPUT_RIGHT))) {
        player->state = SKID;
        player->controlLockTimer = SKID_CONTROL_LOCK_TIME;
        // Optionally reduce ground speed when starting skid
        player->groundSpeed *= SKID_SPEED_REDUCTION_FACTOR;
    } else {
        // Not skidding, reset state if necessary
        if (player->state == SKID) {
            player->state = IDLE;
        }
    }
}   

bool Player_WantsToSpindash(Player* player) {
    if (!player->isOnGround || player->controlLockTimer > 0) return false;
    if (player->state == SPINDASH && IsKeyDown(BUTTON_JUMP_)) {
        Player_ChargeSpindash(player);
        return true;
    }
    if (!IsKeyDown(BUTTON_DOWN) && player->state == SPINDASH && fabsf(player->groundSpeed) < 0.1f) {
        Player_ReleaseSpindash(player);
        return false;
    }
    return IsKeyDown(BUTTON_DOWN) && fabsf(player->groundSpeed) < 0.1f;
}

void Player_ChargeSpindash(Player* player) {
    if (player->spindashCharge < MAX_SPINDASH_CHARGE) {
        player->spindashCharge++;
    }
}

void Player_ReleaseSpindash(Player* player) {
    if (player->spindashCharge > 0) {
        float spindashSpeed = SPINDASH_BASE_SPEED + (player->spindashCharge * SPINDASH_SPEED_INCREMENT);
        player->groundSpeed = spindashSpeed * player->facing;
        player->spindashCharge = 0;
        player->isSpindashing = false;
        player->controlLockTimer = SPINDASH_CONTROL_LOCK_TIME;
    }
}

void Player_StartPeelOut(Player* player) {
    if (!player->isOnGround || player->controlLockTimer > 0) return;

    float peeloutTimer = 0.0f;

    if (player->isLookingUp && IsKeyDown(BUTTON_JUMP)) {
        player->isPeelOut = true;
        player->state = PEELOUT;
        peeloutTimer += GetFrameTime();
        player->groundSpeed = PEEL_OUT_SPEED * player->facing;
        player->controlLockTimer = PEEL_OUT_CONTROL_LOCK_TIME;
        if (IsKeyDown(BUTTON_JUMP) && peeloutTimer < PEEL_OUT_HOLD_TIME) {
            Player_ReleasePeelout(player);
        }
    }
}

void Player_ReleasePeelout(Player* player) {
    if (player->isPeelOut) {
        player->isPeelOut = false;
        player->groundSpeed = PEEL_OUT_TOP_SPEED * player->facing;
        player->state = DASH;
        player->controlLockTimer = 0.0f;
    }
}

void Player_StartJump(Player* player) {
    if (player->isOnGround && player->controlLockTimer <= 0) {
        if (IsKeyPressed(BUTTON_JUMP) && (player->state == IDLE || player->state == WALK || player->state == RUN || player->state == DASH || player->state == ROLL)) {
        // Can go between RELEASE_JUMP_VELOCITY and INITIAL_JUMP_VELOCITY based on how long the jump button is held
            player->velocity.y = INITIAL_JUMP_VELOCITY;
            player->isOnGround = false;
            player->hasJumped = true;
            player->state = JUMP;
        }
    }
}

void Player_ReleaseJump(Player* player) {
    if (player->hasJumped && IsKeyReleased(BUTTON_JUMP)) {
        if (player->velocity.y < RELEASE_JUMP_VELOCITY) {
            player->velocity.y = RELEASE_JUMP_VELOCITY;
        }
    }
}

void Player_Jump(Player* player) {
    if (Player_WantsToJump(player)) {
        Player_StartJump(player);
    }
    if (player->velocity.y < 0 && player->hasJumped && 
        !(player->state == ROLL_FALL || player->state == FALL)) {
        Player_ReleaseJump(player);
    }

}

void Player_SpringBounce(Player* player, float bounceVelocity) {
    player->velocity.y = bounceVelocity;
    player->isOnGround = false;
    player->hasJumped = true;
    player->state = SPRING_RISE;
}

void Player_UpdateIdleState(Player* player, float deltaTime) {
    if (player->state == IDLE) {
        player->idleTimer += deltaTime;
        if (!player->isImpatient && player->idleTimer >= IDLE_IMPATIENCE_LOOK_TIME) {
            player->isImpatient = true;
            player->idleState = IMPATIENT_LOOK;
            player->animationState = ANIM_IMPATIENT_LOOK;
        } else if (player->isImpatient && player->idleState == IMPATIENT_LOOK && player->idleTimer >= (IDLE_IMPATIENCE_TIME + IDLE_IMPATIENCE_LOOK_TIME)) {
            player->idleState = IMPATIENT_ANIMATION;
            player->animationState = ANIM_IMPATIENT;
        }
    } else {
        // Reset impatience when not idle
        player->idleTimer = 0.0f;
        player->isImpatient = false;
        player->idleState = IDLE_NORMAL;
    }
}

void Player_FaceDirection(Player* player, bool faceRight) {
    if (faceRight) {
        player->facing = 1;
    } else {
        player->facing = -1;
    }
}

void Player_TakeDamage(Player* player) {
    if (player->invincibilityTimer <= 0) {
        player->isHurt = true;
        player->invincibilityTimer = INVINCIBILITY_DURATION;
        player->controlLockTimer = HURT_CONTROL_LOCK_TIME;
        // TODO: Add rings or lives system
        // Additional logic for reducing rings or lives can be added here
    }
}

bool Player_WantsToBeIdle(Player* player) {
    // If Ground angle is too steep, don't go to idle
    if (Player_IsOnSteepSlope(player)) {
        return false;
    }
    return true;
}

bool Player_WantsToJump(Player* player) {
    if (!player->isOnGround || player->controlLockTimer > 0) return false;

    return IsKeyPressed(BUTTON_JUMP);
}

void Player_Draw(Player* player) {
    if (player == NULL) return;
    
    // For now, draw a simple colored rectangle to represent the player
    Color playerColor = WHITE;
    
    // Change color based on player state for visual feedback
    if (player->isJumping) {
        playerColor = YELLOW;
    } else if (player->isRolling) {
        playerColor = ORANGE;
    } else if (player->isOnGround) {
        playerColor = GREEN;
    } else {
        playerColor = RED; // Falling
    }
    
    // Draw the player rectangle
    DrawRectangle(
        (int)(player->position.x + player->hitbox.x),
        (int)(player->position.y + player->hitbox.y),
        player->hitbox.w,
        player->hitbox.h,
        playerColor
    );
    
    // Draw a facing indicator (small triangle)
    Vector2 triPos = {
        player->position.x + player->hitbox.x + player->hitbox.w/2 + (player->facing * 5),
        player->position.y + player->hitbox.y + player->hitbox.h/2
    };
    
    if (player->facing > 0) { // Facing right
        DrawTriangle(
            (Vector2){triPos.x, triPos.y - 3},
            (Vector2){triPos.x, triPos.y + 3},
            (Vector2){triPos.x + 6, triPos.y},
            BLACK
        );
    } else { // Facing left
        DrawTriangle(
            (Vector2){triPos.x, triPos.y - 3},
            (Vector2){triPos.x, triPos.y + 3},
            (Vector2){triPos.x - 6, triPos.y},
            BLACK
        );
    }
    
    // Draw six-point collision sensors (Genesis-style)
    float centerX = player->position.x + player->hitbox.x + player->hitbox.w/2;
    float centerY = player->position.y + player->hitbox.y + player->hitbox.h/2;
    float width = player->hitbox.w;
    float height = player->hitbox.h;
    
    // Ground sensors (A and B) - bottom of player
    float sensorOffset = width * 0.25f; // Offset from center
    Vector2 groundA = {centerX - sensorOffset, player->position.y + player->hitbox.y + height};
    Vector2 groundB = {centerX + sensorOffset, player->position.y + player->hitbox.y + height};
    
    // Wall sensors (C and D) - sides of player
    float wallSensorY = centerY;
    Vector2 wallLeft = {player->position.x + player->hitbox.x, wallSensorY};
    Vector2 wallRight = {player->position.x + player->hitbox.x + width, wallSensorY};
    
    // Ceiling sensors (E and F) - top of player
    Vector2 ceilingE = {centerX - sensorOffset, player->position.y + player->hitbox.y};
    Vector2 ceilingF = {centerX + sensorOffset, player->position.y + player->hitbox.y};
    
    // Draw sensor points
    DrawCircle((int)groundA.x, (int)groundA.y, 2, RED);      // Ground A
    DrawCircle((int)groundB.x, (int)groundB.y, 2, RED);      // Ground B
    DrawCircle((int)wallLeft.x, (int)wallLeft.y, 2, BLUE);   // Wall Left
    DrawCircle((int)wallRight.x, (int)wallRight.y, 2, BLUE); // Wall Right
    DrawCircle((int)ceilingE.x, (int)ceilingE.y, 2, GREEN);  // Ceiling E
    DrawCircle((int)ceilingF.x, (int)ceilingF.y, 2, GREEN);  // Ceiling F
    
    // Draw sensor labels
    DrawText("A", (int)groundA.x - 3, (int)groundA.y + 3, 8, WHITE);
    DrawText("B", (int)groundB.x - 3, (int)groundB.y + 3, 8, WHITE);
    DrawText("C", (int)wallLeft.x - 8, (int)wallLeft.y - 4, 8, WHITE);
    DrawText("D", (int)wallRight.x + 3, (int)wallRight.y - 4, 8, WHITE);
    DrawText("E", (int)ceilingE.x - 3, (int)ceilingE.y - 12, 8, WHITE);
    DrawText("F", (int)ceilingF.x - 3, (int)ceilingF.y - 12, 8, WHITE);
}

void Player_Unload(Player* player) {
    if (player == NULL) return;
    
    // Clean up any allocated resources
    if (player->sprite != NULL) {
        // Free sprite resources if needed
        player->sprite = NULL;
    }
    
    if (player->animationManager != NULL) {
        // Free animation manager if needed
        player->animationManager = NULL;
    }
    
    // Reset player to default state
    memset(player, 0, sizeof(Player));
}