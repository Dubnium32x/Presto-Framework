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

void Player_Init(Player* player, float startX, float startY) {
    player->position = (Vector2){ startX, startY };
    player->velocity = (Vector2){ 0.0f, 0.0f };
    player->groundAngle = 0.0f;
    player->groundSpeed = 0.0f;
    player->verticalSpeed = 0.0f;
    player->hasJumped = false;
    player->isOnGround = true;
    player->isSpindashing = false;
    player->isRolling = false;
    player->isCrouching = false;
    player->isLookingUp = false;
    player->isFlying = false;
    player->isGliding = false;
    player->isPeelOut = false;
    player->isClimbing = false;
    player->isHurt = false;
    player->isDead = false;
    player->isSuper = false;
    player->controlLockTimer = 0;
    player->facing = 1; // Facing right
    player->state = IDLE;
    player->idleState = IDLE_NORMAL;
    player->groundDirection = NONE;
    player->isImpatient = false;
    player->impatientTimer = 0.0f;
    player->spindashCharge = 0;
    player->idleTimer = 0.0f;
    player->idleLookTimer = 0.0f;
    player->sprite = NULL;
    player->animationManager = NULL;
    player->jumpButtonHoldTimer = 0;
    player->slipAngleType = SONIC_1_2_CD;
    player->currentTileset = NULL;
    player->blinkTimer = 0;
    player->blinkInterval = 300; // Blink every 300 frames
    player->blinkDuration = 5;   // Blink lasts for 5 frames
    player->invincibilityTimer = 0;
    player->controlLockTimer = 0;
}

void Player_SetLevel(Player* player, TilesetInfo* tilesetInfo) {
    player->currentTileset = tilesetInfo;
}

void Player_SetSpawnPoint(Player* player, float x, float y, bool checkpoint) {
    Player_Init(player, x, y);
    if (checkpoint) {
        // Additional logic for checkpoint spawn can be added here
    }
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
