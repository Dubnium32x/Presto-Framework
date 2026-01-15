// Player Script
#include "player-player.h"
#include <string.h>

// Animation switching (stub implementation - to be completed later)
void SetPlayerAnimation(Player* player, PlayerAnimationState newState) {
    if (player == NULL) return;
    player->animationState = newState;
    // TODO: Implement full animation switching with sprite frames
}

// Initialize Player
void InitPlayer(Player* player, PlayerType type, Vector2 startPosition) {
    memset(player, 0, sizeof(Player));
    player->type = type;
    player->state = IDLE;
    player->idleState = IDLE_NORMAL;
    switch (type) {
        case SONIC:
            player->sensors.left = (Vector2){SONIC_PLAYER_WIDTH_RAD, 0};
            player->sensors.right = (Vector2){-SONIC_PLAYER_WIDTH_RAD, 0};
            player->sensors.topLeft = (Vector2){SONIC_PLAYER_WIDTH_RAD, -SONIC_PLAYER_HEIGHT_RAD};
            player->sensors.topRight = (Vector2){-SONIC_PLAYER_WIDTH_RAD, -SONIC_PLAYER_HEIGHT_RAD};
            player->sensors.bottomLeft = (Vector2){SONIC_PLAYER_WIDTH_RAD, SONIC_PLAYER_HEIGHT_RAD};
            player->sensors.bottomRight = (Vector2){-SONIC_PLAYER_WIDTH_RAD, SONIC_PLAYER_HEIGHT_RAD};
            break;
        case TAILS:
            player->sensors.left = (Vector2){TAILS_PLAYER_WIDTH_RAD, 0};
            player->sensors.right = (Vector2){-TAILS_PLAYER_WIDTH_RAD, 0};
            player->sensors.topLeft = (Vector2){TAILS_PLAYER_WIDTH_RAD, -TAILS_PLAYER_HEIGHT_RAD};
            player->sensors.topRight = (Vector2){-TAILS_PLAYER_WIDTH_RAD, -TAILS_PLAYER_HEIGHT_RAD};
            player->sensors.bottomLeft = (Vector2){TAILS_PLAYER_WIDTH_RAD, TAILS_PLAYER_HEIGHT_RAD};
            player->sensors.bottomRight = (Vector2){-TAILS_PLAYER_WIDTH_RAD, TAILS_PLAYER_HEIGHT_RAD};
            break;
        default:
            break;
    }
    player->groundDirection = NOINPUT;
    player->facing = 1; // Facing right by default
    player->collisionBox = (Rectangle){startPosition.x - 8.0f, startPosition.y - 16.0f, 16.0f, 32.0f};

    // Initialize sprite and animation manager (NULL for now - to be implemented)
    player->sprite = NULL;
    player->animationManager = NULL;

    // Set initial animation state
    player->animationState = ANIM_IDLE;
    SetPlayerAnimation(player, ANIM_IDLE);

    player->position = startPosition;
    player->velocity = (Vector2){0, 0};
    player->isGravityApplied = true;
    player->isOnGround = false;
    player->isJumping = false;
    player->hasJumped = false;
    player->jumpPressed = false;
    player->isFalling = false;
    player->isRolling = false;
    player->isCrouching = false;
    player->isLookingUp = false;
    player->isSpindashing = false;
    player->isSuper = false;
    player->isPeelOut = false;
    player->isFlying = false;
    player->isGliding = false;
    player->isClimbing = false;
    player->isHurt = false;
    player->isDead = false;

    player->groundSpeed = 0.0f;
    player->groundAngle = 0.0f;
    player->playerRotation = 0.0f;

    player->inputLeft = false;
    player->inputRight = false;
    player->inputUp = false;
    player->inputDown = false;

    player->spindashCharge = 0;

    player->idleTimer = 0.0f;
    player->idleLookTimer = 0.0f;

    player->controlLockTimer = 0;
    player->invincibilityTimer = 0;
    player->jumpButtonHoldTimer = 0;
    player->blinkTimer = 0;
    player->blinkInterval = 20;
    player->blinkDuration = 255;  // Blink duration (max uint8_t)
}

