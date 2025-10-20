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
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define BUTTON_JUMP (KEY_JUMP1 | KEY_JUMP2 | KEY_JUMP3 | BUTTON_A | BUTTON_B | BUTTON_X)
#define INPUT_DOWN (KEY_DOWN | DPAD_DOWN)
#define INPUT_UP (KEY_UP | DPAD_UP)
#define INPUT_LEFT (KEY_LEFT | DPAD_LEFT)
#define INPUT_RIGHT (KEY_RIGHT | DPAD_RIGHT)

Player Player_Init(float startX, float startY, Hitbox_t box) {
    Player player = {0};

    player.position = (Vector2){ startX, startY };
    player.velocity = (Vector2){ 0.0f, 0.0f };
    player.groundAngle = 0.0f;
    player.groundSpeed = 0.0f;
    player.verticalSpeed = 0.0f;
    player.hasJumped = false;
    player.isOnGround = true;
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
    player.controlLockTimer = 0;
    player.facing = 1; // Facing right
    player.state = IDLE;
    player.idleState = IDLE_NORMAL;
    player.groundDirection = NOINPUT;
    player.isImpatient = false;
    player.impatientTimer = 0.0f;
    player.spindashCharge = 0;
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
    InputBit input = 0;
    if (IsKeyDown(INPUT_UP)) input |= INPUT_MASK(INPUT_UP);
    if (IsKeyDown(INPUT_DOWN)) input |= INPUT_MASK(INPUT_DOWN);
    if (IsKeyDown(INPUT_LEFT)) input |= INPUT_MASK(INPUT_LEFT);
    if (IsKeyDown(INPUT_RIGHT)) input |= INPUT_MASK(INPUT_RIGHT);
    if (IsKeyDown(BUTTON_JUMP)) input |= INPUT_MASK(INPUT_A | INPUT_B | INPUT_X); // Assuming jump is mapped to A
    return input;
}

void Player_UpdateInput(Player* player) {
    bool prevJump = player->isJumping;

    // Read input
    player->isJumping = IsKeyDown(BUTTON_JUMP);
    bool keyLeft = IsKeyDown(INPUT_LEFT);
    bool keyRight = IsKeyDown(INPUT_RIGHT);
    bool keyDown = IsKeyDown(INPUT_DOWN);
    bool keyUp = IsKeyDown(INPUT_UP);

    // Additional input handling logic can be added here
    bool jumpPressed = player->isJumping && !prevJump;
    bool jumpReleased = !player->isJumping && prevJump;
}

// Implementation of the physics update function
void Player_UpdatePhysics(Player* player, float deltaTime) {
    // TODO: Implement full physics
    if (player->isOnGround) {
        // Basic ground movement
        if (IsKeyDown(INPUT_LEFT)) {
            player->groundSpeed = fmaxf(player->groundSpeed - (ACCELERATION * deltaTime), -TOP_SPEED);
        } else if (IsKeyDown(INPUT_RIGHT)) {
            player->groundSpeed = fminf(player->groundSpeed + (ACCELERATION * deltaTime), TOP_SPEED);
        }
        // Apply friction
        else if (player->groundSpeed != 0) {
            float friction = FRICTION * deltaTime;
            if (player->groundSpeed > 0) {
                player->groundSpeed = fmaxf(0, player->groundSpeed - friction);
            } else {
                player->groundSpeed = fminf(0, player->groundSpeed + friction);
            }
        }
    } else {
        // Basic air movement
        if (IsKeyDown(INPUT_LEFT)) {
            player->velocity.x = fmaxf(player->velocity.x - (AIR_ACCELERATION * deltaTime), -AIR_TOP_SPEED);
        } else if (IsKeyDown(INPUT_RIGHT)) {
            player->velocity.x = fminf(player->velocity.x + (AIR_ACCELERATION * deltaTime), AIR_TOP_SPEED);
        }
        // Apply gravity
        player->velocity.y += GRAVITY * deltaTime;
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
    player->position.x += player->velocity.x * deltaTime;
    player->position.y += player->velocity.y * deltaTime;
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