// Player Script
#include "player-player.h"
#include "player-physics.h"
#include "player-collision.h"
#include "../../managers/managers-input.h"
#include <string.h>
#include <stdio.h>

// Level collision reference (set by game screen)
static LevelCollision* currentLevelCollision = NULL;

// Set the level collision data for the player system
void SetPlayerLevelCollision(LevelCollision* collision) {
    currentLevelCollision = collision;
}

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

// Handle player input
void HandlePlayerInput(Player* player) {
    if (player == NULL) return;

    // Read directional input
    player->inputLeft = IsInputDown(INPUT_LEFT);
    player->inputRight = IsInputDown(INPUT_RIGHT);
    player->inputUp = IsInputDown(INPUT_UP);
    player->inputDown = IsInputDown(INPUT_DOWN);

    // Jump button (A button or Space)
    bool jumpDown = IsInputDown(INPUT_A) || IsKeyDown(KEY_SPACE);

    // Track jump press/release for variable height jumping
    if (jumpDown && !player->jumpPressed) {
        player->jumpPressed = true;
        player->hasJumped = false;  // Reset so we can jump again
    } else if (!jumpDown) {
        player->jumpPressed = false;
    }

    // Rolling - press down while moving on ground
    if (player->isOnGround && player->inputDown && fabsf(player->groundSpeed) >= 0.5f && !player->isRolling) {
        player->isRolling = true;
    }

    // Crouching - press down while stopped on ground
    if (player->isOnGround && player->inputDown && fabsf(player->groundSpeed) < 0.5f && !player->isRolling) {
        player->isCrouching = true;
    } else {
        player->isCrouching = false;
    }

    // Looking up
    if (player->isOnGround && player->inputUp && fabsf(player->groundSpeed) < 0.5f) {
        player->isLookingUp = true;
    } else {
        player->isLookingUp = false;
    }
}

// Update player state machine
void UpdatePlayerState(Player* player) {
    if (player == NULL) return;

    // Determine state based on current conditions
    if (player->isDead) {
        player->state = DEAD;
    } else if (player->isHurt) {
        player->state = HURT;
    } else if (!player->isOnGround) {
        if (player->isJumping) {
            player->state = player->isRolling ? ROLL : JUMP;
        } else {
            player->state = player->isRolling ? ROLL_FALL : FALL;
        }
    } else {
        // On ground
        if (player->isRolling) {
            player->state = ROLL;
        } else if (player->isCrouching) {
            player->state = CROUCH;
        } else if (player->isLookingUp) {
            player->state = LOOK_UP;
        } else if (player->isSpindashing) {
            player->state = SPINDASH;
        } else if (player->isPeelOut) {
            player->state = PEELOUT;
        } else if (fabsf(player->groundSpeed) < 0.1f) {
            player->state = IDLE;
        } else if (fabsf(player->groundSpeed) < 4.0f) {
            player->state = WALK;
        } else if (fabsf(player->groundSpeed) < 8.0f) {
            player->state = RUN;
        } else {
            player->state = DASH;
        }

        // Check for skidding
        if ((player->inputLeft && player->groundSpeed > 0) ||
            (player->inputRight && player->groundSpeed < 0)) {
            if (fabsf(player->groundSpeed) > 4.0f) {
                player->state = SKID;
            }
        }
    }
}

// Update player animation based on state
void UpdatePlayerAnimation(Player* player, float deltaTime) {
    if (player == NULL) return;

    PlayerAnimationState targetAnim = ANIM_IDLE;

    switch (player->state) {
        case IDLE:
            targetAnim = ANIM_IDLE;
            break;
        case WALK:
            targetAnim = ANIM_WALK;
            break;
        case RUN:
            targetAnim = ANIM_RUN;
            break;
        case DASH:
            targetAnim = ANIM_DASH;
            break;
        case CROUCH:
            targetAnim = ANIM_CROUCH;
            break;
        case LOOK_UP:
            targetAnim = ANIM_LOOK_UP;
            break;
        case SKID:
            targetAnim = ANIM_SKID;
            break;
        case JUMP:
            targetAnim = ANIM_JUMP;
            break;
        case FALL:
            targetAnim = ANIM_FALL;
            break;
        case ROLL:
            targetAnim = ANIM_ROLL;
            break;
        case ROLL_FALL:
            targetAnim = ANIM_ROLL_FALL;
            break;
        case SPINDASH:
            targetAnim = ANIM_SPINDASH;
            break;
        case PEELOUT:
            targetAnim = ANIM_PEELOUT;
            break;
        case HURT:
            targetAnim = ANIM_HURT;
            break;
        case DEAD:
            targetAnim = ANIM_DEAD;
            break;
        default:
            targetAnim = ANIM_IDLE;
            break;
    }

    if (player->animationState != targetAnim) {
        SetPlayerAnimation(player, targetAnim);
    }
}

// Main player update
void UpdatePlayer(Player* player, float deltaTime) {
    if (player == NULL) return;

    // 1. Handle input
    HandlePlayerInput(player);

    // 2. Update physics
    if (currentLevelCollision) {
        UpdatePlayerPhysics(player, currentLevelCollision);
    } else {
        // No level collision - just apply basic gravity for testing
        if (!player->isOnGround) {
            player->velocity.y += 0.21875f;  // Gravity
            if (player->velocity.y > 16.0f) player->velocity.y = 16.0f;
        }
        player->position.x += player->velocity.x;
        player->position.y += player->velocity.y;
    }

    // 3. Update state
    UpdatePlayerState(player);

    // 4. Update animation
    UpdatePlayerAnimation(player, deltaTime);

    // 5. Update collision box position
    float heightRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_HEIGHT_RAD : (float)TAILS_PLAYER_HEIGHT_RAD;
    float widthRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_WIDTH_RAD : (float)TAILS_PLAYER_WIDTH_RAD;

    if (player->isRolling || player->isJumping) {
        heightRadius = 14.0f;
        widthRadius = 7.0f;
    }

    player->collisionBox = (Rectangle){
        player->position.x - widthRadius,
        player->position.y - heightRadius,
        widthRadius * 2.0f + 1.0f,
        heightRadius * 2.0f + 1.0f
    };
}

// Draw player
void DrawPlayer(const Player* player) {
    if (player == NULL) return;

    float heightRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_HEIGHT_RAD : (float)TAILS_PLAYER_HEIGHT_RAD;
    float widthRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_WIDTH_RAD : (float)TAILS_PLAYER_WIDTH_RAD;

    if (player->isRolling || player->isJumping) {
        heightRadius = 14.0f;
        widthRadius = 7.0f;
    }

    // Draw player body (placeholder rectangle)
    Color bodyColor = (player->type == SONIC) ? BLUE : ORANGE;
    if (player->isHurt) bodyColor = RED;
    if (player->isRolling) bodyColor = DARKBLUE;

    // Draw rotated rectangle for player body
    Rectangle bodyRect = {
        player->position.x,
        player->position.y,
        widthRadius * 2.0f + 1.0f,
        heightRadius * 2.0f + 1.0f
    };

    DrawRectanglePro(bodyRect,
        (Vector2){widthRadius + 0.5f, heightRadius + 0.5f},
        -player->playerRotation,  // Negative because our angles are counter-clockwise
        bodyColor);

    // Draw facing indicator
    float indicatorX = player->position.x + (player->facing * 8.0f);
    DrawCircle((int)indicatorX, (int)player->position.y, 3.0f, WHITE);
}

// Draw player debug visualization
void DrawPlayerDebug(const Player* player, const LevelCollision* level) {
    if (player == NULL) return;

    float heightRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_HEIGHT_RAD : (float)TAILS_PLAYER_HEIGHT_RAD;
    float widthRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_WIDTH_RAD : (float)TAILS_PLAYER_WIDTH_RAD;

    if (player->isRolling || player->isJumping) {
        heightRadius = 14.0f;
        widthRadius = 7.0f;
    }

    CollisionMode mode = GetCollisionModeFromAngle(player->groundAngle);

    // Draw ground sensors (A and B) - Green
    float sensorAX, sensorAY, sensorBX, sensorBY;
    switch (mode) {
        case MODE_FLOOR:
            sensorAX = player->position.x - widthRadius;
            sensorAY = player->position.y + heightRadius;
            sensorBX = player->position.x + widthRadius;
            sensorBY = player->position.y + heightRadius;
            DrawLine((int)sensorAX, (int)sensorAY, (int)sensorAX, (int)(sensorAY + 16), GREEN);
            DrawLine((int)sensorBX, (int)sensorBY, (int)sensorBX, (int)(sensorBY + 16), GREEN);
            break;
        case MODE_RIGHT_WALL:
            sensorAX = player->position.x + heightRadius;
            sensorAY = player->position.y + widthRadius;
            sensorBX = player->position.x + heightRadius;
            sensorBY = player->position.y - widthRadius;
            DrawLine((int)sensorAX, (int)sensorAY, (int)(sensorAX + 16), (int)sensorAY, GREEN);
            DrawLine((int)sensorBX, (int)sensorBY, (int)(sensorBX + 16), (int)sensorBY, GREEN);
            break;
        case MODE_CEILING:
            sensorAX = player->position.x + widthRadius;
            sensorAY = player->position.y - heightRadius;
            sensorBX = player->position.x - widthRadius;
            sensorBY = player->position.y - heightRadius;
            DrawLine((int)sensorAX, (int)sensorAY, (int)sensorAX, (int)(sensorAY - 16), GREEN);
            DrawLine((int)sensorBX, (int)sensorBY, (int)sensorBX, (int)(sensorBY - 16), GREEN);
            break;
        case MODE_LEFT_WALL:
            sensorAX = player->position.x - heightRadius;
            sensorAY = player->position.y - widthRadius;
            sensorBX = player->position.x - heightRadius;
            sensorBY = player->position.y + widthRadius;
            DrawLine((int)sensorAX, (int)sensorAY, (int)(sensorAX - 16), (int)sensorAY, GREEN);
            DrawLine((int)sensorBX, (int)sensorBY, (int)(sensorBX - 16), (int)sensorBY, GREEN);
            break;
    }

    // Draw push sensors (E and F) - Yellow
    float pushRadius = 10.0f;
    float sensorEX = player->position.x - pushRadius;
    float sensorFX = player->position.x + pushRadius;
    float sensorY = (player->groundAngle == 0.0f && player->isOnGround) ?
                    player->position.y + 8.0f : player->position.y;

    DrawLine((int)sensorEX, (int)sensorY, (int)(sensorEX - 16), (int)sensorY, YELLOW);
    DrawLine((int)sensorFX, (int)sensorY, (int)(sensorFX + 16), (int)sensorY, YELLOW);

    // Draw ceiling sensors (C and D) - Cyan (only when in air)
    if (!player->isOnGround) {
        float sensorCX = player->position.x - widthRadius;
        float sensorCY = player->position.y - heightRadius;
        float sensorDX = player->position.x + widthRadius;
        float sensorDY = player->position.y - heightRadius;
        DrawLine((int)sensorCX, (int)sensorCY, (int)sensorCX, (int)(sensorCY - 16), SKYBLUE);
        DrawLine((int)sensorDX, (int)sensorDY, (int)sensorDX, (int)(sensorDY - 16), SKYBLUE);
    }

    // Draw center point
    DrawCircle((int)player->position.x, (int)player->position.y, 2, MAGENTA);

    // Draw ground angle indicator
    float angleRad = player->groundAngle * PI / 180.0f;
    float indicatorLen = 20.0f;
    float endX = player->position.x + cosf(angleRad) * indicatorLen;
    float endY = player->position.y - sinf(angleRad) * indicatorLen;
    DrawLine((int)player->position.x, (int)player->position.y, (int)endX, (int)endY, RED);
}

// Draw player HUD info
void DrawPlayerHUD(const Player* player) {
    if (player == NULL) return;

    // Draw debug info in top-left corner
    char buffer[256];

    snprintf(buffer, sizeof(buffer), "Pos: %.1f, %.1f", player->position.x, player->position.y);
    DrawText(buffer, 10, 50, 8, WHITE);

    snprintf(buffer, sizeof(buffer), "Vel: %.2f, %.2f", player->velocity.x, player->velocity.y);
    DrawText(buffer, 10, 60, 8, WHITE);

    snprintf(buffer, sizeof(buffer), "GndSpd: %.2f", player->groundSpeed);
    DrawText(buffer, 10, 70, 8, WHITE);

    snprintf(buffer, sizeof(buffer), "Angle: %.1f", player->groundAngle);
    DrawText(buffer, 10, 80, 8, WHITE);

    snprintf(buffer, sizeof(buffer), "Ground: %s", player->isOnGround ? "YES" : "NO");
    DrawText(buffer, 10, 90, 8, player->isOnGround ? GREEN : RED);

    CollisionMode mode = GetCollisionModeFromAngle(player->groundAngle);
    const char* modeStr = "FLOOR";
    switch (mode) {
        case MODE_FLOOR: modeStr = "FLOOR"; break;
        case MODE_RIGHT_WALL: modeStr = "R_WALL"; break;
        case MODE_CEILING: modeStr = "CEILING"; break;
        case MODE_LEFT_WALL: modeStr = "L_WALL"; break;
    }
    snprintf(buffer, sizeof(buffer), "Mode: %s", modeStr);
    DrawText(buffer, 10, 100, 8, WHITE);

    snprintf(buffer, sizeof(buffer), "State: %d", player->state);
    DrawText(buffer, 10, 110, 8, WHITE);
}

// Reset player to a position
void ResetPlayer(Player* player, Vector2 startPosition) {
    if (player == NULL) return;

    player->position = startPosition;
    player->velocity = (Vector2){0, 0};
    player->groundSpeed = 0.0f;
    player->groundAngle = 0.0f;
    player->playerRotation = 0.0f;
    player->isOnGround = false;
    player->isJumping = false;
    player->hasJumped = false;
    player->jumpPressed = false;
    player->isFalling = false;
    player->isRolling = false;
    player->isCrouching = false;
    player->isLookingUp = false;
    player->isSpindashing = false;
    player->isHurt = false;
    player->isDead = false;
    player->controlLockTimer = 0;
    player->state = IDLE;
}

// Apply gravity (legacy function - now handled by physics system)
void ApplyPlayerGravity(Player* player, float deltaTime) {
    // This is now handled by UpdatePlayerPhysics
    // Kept for backwards compatibility
}
