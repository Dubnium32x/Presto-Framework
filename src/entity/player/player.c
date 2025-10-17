// Player file!
// ... oh boy.
#include "player.h"
#include "../../util/globals.h"
#include "../../util/math_utils.h"
#include "../../world/input.h"
#include "../../camera/game_camera.h"
#include "var.h"
#include "../../world/tileset_map.h"
#include "../../world/tile_collision.h"
#include "../../sprite/sprite_manager.h"
#include "../../sprite/animation_manager.h"
#include "../entity_manager.h"
#include "../sprite_object.h"
#include "animations/animations.h"
#include "../../sprite/spritesheet_splitter.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"

#define BUTTON_JUMP KEY_JUMP1 | BUTTON_A | KEY_JUMP2 | BUTTON_B | KEY_JUMP3 | BUTTON_X
#define BUTTON_DOWN KEY_DOWN | DPAD_DOWN
#define BUTTON_UP KEY_UP | DPAD_UP
#define BUTTON_LEFT KEY_LEFT | DPAD_LEFT
#define BUTTON_RIGHT KEY_RIGHT | DPAD_RIGHT
#define BUTTON_ACTION1 KEY_A | BUTTON_LB
#define BUTTON_ACTION2 KEY_S | BUTTON_RB

void Player_Init(Player* player, float startX, float startY) {
    if (player == NULL) return;
    
    // Initialize player position and variables
    player->position.x = startX;
    player->position.y = startY;
    player->velocity.x = 0.0f;
    player->velocity.y = 0.0f;
    player->groundSpeed = 0.0f;
    player->verticalSpeed = 0.0f;
    player->groundAngle = 0.0f;
    player->isOnGround = true;
    player->isJumping = false;
    player->isFalling = false;
    player->isRolling = false;
    player->isCrouching = false;
    player->isLookingUp = false;
    player->isSpindashing = false;
    player->isPeelOut = false;
    player->isFlying = false;
    player->isGliding = false;
    player->isClimbing = false;
    player->isHurt = false;
    player->isDead = false;
    player->facingRight = true;
    player->state = IDLE;
    player->idleState = IDLE_NORMAL;
    player->groundDirection = RIGHT;
    player->spindashCharge = 0;
    player->idleTimer = 0.0f;
    player->idleLookTimer = 0.0f;
    player->controlLockTimer = 0;
    player->invincibilityTimer = 0;
    player->blinkTimer = 0;
    player->blinkInterval = 300; // Blink every 300 frames
    player->blinkDuration = 5;   // Blink lasts for 5 frames
    player->jumpButtonHoldTimer = 0;
    player->slipAngleType = SONIC_1_2_CD; // Default slip angle type
    player->currentTileset = NULL;
    player->isImpatient = false;
    player->impatientTimer = 0.0f;

    // Load and set up sprite and animations
    player->sprite = malloc(sizeof(SpriteObject));
    if (player->sprite != NULL) {
        Texture2D playerTexture = LoadTexture("res/sprite/spritesheet/character/Sonic_spritemap.png");
        InitSpriteObject(player->sprite, 1, "Sonic", playerTexture, 
                        (Vector2){player->position.x, player->position.y}, 
                        (Vector2){1.0f, 1.0f}, WHITE, 0.0f, PLAYER);
        player->sprite->origin = (Vector2){PLAYER_WIDTH_RAD, PLAYER_HEIGHT_RAD};
    }
    
    player->animationManager = malloc(sizeof(AnimationManager));
    if (player->animationManager != NULL) {
        InitAnimationManager(player->animationManager);
    } else {
        fprintf(stderr, "Error: Failed to create animation manager for player\n");
    }
}

void Player_SetLevel(Player* player, TilesetInfo* tilesetInfo) {
    if (player == NULL || tilesetInfo == NULL) return;

    player->currentTileset = &tilesetInfo;
}

void Player_SetSpawnPoint(Player* player, float x, float y, bool checkpoint) {
    if (player == NULL) return;

    player->position.x = x;
    player->position.y = y;

    if (player->sprite != NULL) {
        SetPosition(player->sprite, (Vector2){player->position.x, player->position.y});
        SetScale(player->sprite, (Vector2){1.0f, 1.0f});
        player->sprite->origin = (Vector2){PLAYER_WIDTH_RAD, PLAYER_HEIGHT_RAD};
    }
    
    (void)checkpoint; // Suppress unused parameter warning
}

void Player_Update_Input(Player* player) {
    if (player == NULL) return;

    // TODO: Implement input handling logic
    // For now, this function is a stub to prevent compilation errors
}

void Player_Update(Player* player, float deltaTime) {
    Player_Update_Input(player);
    if (player == NULL) return;

    Player_UpdatePhysics(player, deltaTime);
    Player_UpdateState(player, deltaTime);
    Player_UpdateAnimation(player, deltaTime);
    Player_UpdatePosition(player, deltaTime);
    Player_UpdateState(player, deltaTime);

    // Update sprite position
    if (player->sprite != NULL) {
        SetPosition(player->sprite, (Vector2){player->position.x, player->position.y});
    }

    if (player->state == IDLE) {
        float idleTimer = 0.0f;
        idleTimer += deltaTime;
        if (player->isImpatient && idleTimer >= IDLE_IMPATIENCE_TIME) {
            // Trigger impatient look animation
            player->idleState = IMPATIENT_LOOK;
            player->isImpatient = true;
            player->impatientTimer = 0.0f;
        }
    }
}

// Stub implementations for missing functions
void Player_UpdatePhysics(Player* player, float deltaTime) {
    if (player == NULL) return;
    // TODO: Implement player physics
    (void)deltaTime; // Suppress unused parameter warning
}

void Player_UpdateState(Player* player, float deltaTime) {
    if (player == NULL) return;
    // TODO: Implement player state updates
    (void)deltaTime; // Suppress unused parameter warning
}

void Player_UpdateAnimation(Player* player, float deltaTime) {
    if (player == NULL) return;
    // TODO: Implement player animation updates
    (void)deltaTime; // Suppress unused parameter warning
}

void Player_UpdatePosition(Player* player, float deltaTime) {
    if (player == NULL) return;
    // TODO: Implement player position updates
    (void)deltaTime; // Suppress unused parameter warning
}