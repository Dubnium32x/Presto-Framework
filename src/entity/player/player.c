// Player script
// ... oh boy...
// This is going to be a long one...

#include "player.h"
#include "raylib.h"
#include "var.h"
#include "../sprite_object.h"
#include "../../util/globals.h"
#include "../../util/math_utils.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

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
