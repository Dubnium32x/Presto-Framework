// Player file!
// ... oh boy.
#include "player.h"
#include "../../util/globals.h"'
#include "../../util/math_utils.h"
#include "../../world/input.h"
#include "../../util/globals.h"
#include "../../camera/game_camera.h"
#include "var.h"
#include "../../world/tileset_map.h"
#include "../../world/tile_collision.h"
#include "../../sprite/animation_manager.h"
#include "../entity_manager.h"
#include "../sprite_object.h"
#include "animations/animations.h"
#include "../../sprite/spritesheet_splitter.h"
#include "../../sprite/sprite_manager.h"

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
    player->sprite = SpriteManager_GetSprite("res/sprite/spritesheet/character/Sonic_spritemap.png");
    if (player->sprite != NULL) {
        Sprite_SetPosition(player->sprite, (int)player->position.x, (int)player->position.y);
        Sprite_SetScale(player->sprite, 1.0f, 1.0f);
        Sprite_SetOrigin(player->sprite, PLAYER_WIDTH_RAD, PLAYER_HEIGHT_RAD);
    }
    player->animationManager = AnimationManager_Create();
    if (player->animationManager != NULL) {
        fprintf(stderr, "Error: Failed to create animation manager for player\n");
    }
}

void Player_SetLevel(Player* player, TilesetInfo* tilesetInfo) {
    if (player == NULL || tilesetInfo == NULL) return;

    player->currentTileset = tilesetInfo;
}

void Player_SetSpawnPoint(Player* player, float x, float y, bool checkpoint) {
    if (player == NULL) return;

    ResetPosition(x, y);

    if (player->sprite != NULL) {
        Sprite_SetPosition(player->sprite, (int)player->position.x, (int)player->position.y);
        Sprite_SetScale(player->sprite, 1.0f, 1.0f);
        Sprite_SetOrigin(player->sprite, PLAYER_WIDTH_RAD, PLAYER_HEIGHT_RAD);
    }
}

void Player_UpdateInput(Player* player) {
    if (player == NULL) return;

    bool prevJump = IsInputDown(BUTTON_JUMP);
    bool prevDown = IsInputDown(BUTTON_DOWN);
    bool prevLeft = IsInputDown(BUTTON_LEFT);
    bool prevRight = IsInputDown(BUTTON_RIGHT);
    bool prevUp = IsInputDown(BUTTON_UP);
    bool prevAction1 = IsInputDown(BUTTON_ACTION1);
    bool prevAction2 = IsInputDown(BUTTON_ACTION2);

    bool jumpPressed = IsInputPressed(BUTTON_JUMP);
    bool downPressed = IsInputPressed(BUTTON_DOWN);
    bool leftPressed = IsInputPressed(BUTTON_LEFT);
    bool rightPressed = IsInputPressed(BUTTON_RIGHT);
    bool upPressed = IsInputPressed(BUTTON_UP);
    bool action1Pressed = IsInputPressed(BUTTON_ACTION1);
    bool action2Pressed = IsInputPressed(BUTTON_ACTION2); 
}

void Player_Update(Player* player, float deltaTime) {
    Player_UpdateInput(player);
    if (player == NULL) return;

    Player_UpdatePhysics(player, deltaTime);
    Player_UpdateState(player, deltaTime);
    Player_UpdateAnimation(player, deltaTime);
    Player_UpdatePosition(player, deltaTime);
    Player_UpdateState(player, deltaTime);

    // Update sprite position
    if (player->sprite != NULL) {
        Sprite_SetPosition(player->sprite, (int)player->position.x, (int)player->position.y);
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