// Player Script - SPG-accurate Sonic physics implementation
#include "player-player.h"
#include "player-collision.h"
#include <string.h>
#include <stdio.h>

// ============================================================================
// Animation
// ============================================================================

void SetPlayerAnimation(Player* player, PlayerAnimationState newState) {
    if (player == NULL) return;
    player->animationState = newState;
}

// ============================================================================
// Initialization
// ============================================================================

void InitPlayer(Player* player, PlayerType type, Vector2 startPosition) {
    memset(player, 0, sizeof(Player));
    player->type = type;
    player->state = FALL; // Start falling to find ground
    player->idleState = IDLE_NORMAL;

    // Set up hitbox dimensions based on character
    switch (type) {
        case SONIC:
            player->widthRadius = SONIC_PLAYER_WIDTH_RAD;
            player->heightRadius = SONIC_PLAYER_HEIGHT_RAD;
            player->pushRadius = 10.0f;
            break;
        case TAILS:
            player->widthRadius = TAILS_PLAYER_WIDTH_RAD;
            player->heightRadius = TAILS_PLAYER_HEIGHT_RAD;
            player->pushRadius = 10.0f;
            break;
        default:
            player->widthRadius = SONIC_PLAYER_WIDTH_RAD;
            player->heightRadius = SONIC_PLAYER_HEIGHT_RAD;
            player->pushRadius = 10.0f;
            break;
    }

    // Store default radii for state changes
    player->defaultWidthRadius = player->widthRadius;
    player->defaultHeightRadius = player->heightRadius;

    player->groundDirection = NOINPUT;
    player->facing = 1; // Facing right by default

    // Initialize sprite and animation manager (NULL for now)
    player->sprite = NULL;
    player->animationManager = NULL;
    player->animationState = ANIM_IDLE;

    player->position = startPosition;
    player->velocity = (Vector2){0, 0};
    player->isOnGround = false;
    player->isJumping = false;
    player->hasJumped = false;
    player->jumpPressed = false;
    player->isFalling = true;
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
    player->groundAngle = 0;  // 0-255 byte angle
    player->collisionMode = MODE_FLOOR;

    player->inputLeft = false;
    player->inputRight = false;
    player->inputUp = false;
    player->inputDown = false;
    player->inputJump = false;
    player->inputJumpPressed = false;

    player->spindashCharge = 0;
    player->idleTimer = 0.0f;
    player->idleLookTimer = 0.0f;
    player->controlLockTimer = 0;
    player->invincibilityTimer = 0;
    player->jumpButtonHoldTimer = 0;
    player->blinkTimer = 0;
    player->blinkInterval = 20;
    player->blinkDuration = 255;
}

// ============================================================================
// Input Handling
// ============================================================================

void HandlePlayerInput(Player* player) {
    // Store previous jump state for edge detection
    bool prevJump = player->inputJump;

    // Read current input state
    player->inputLeft = IsKeyDown(KEY_LEFT);
    player->inputRight = IsKeyDown(KEY_RIGHT);
    player->inputUp = IsKeyDown(KEY_UP);
    player->inputDown = IsKeyDown(KEY_DOWN);
    player->inputJump = IsKeyDown(KEY_Z) || IsKeyDown(KEY_SPACE);

    // Detect jump press (rising edge)
    player->inputJumpPressed = player->inputJump && !prevJump;

    // Update ground direction for animation purposes
    if (player->inputLeft && player->inputRight) {
        player->groundDirection = NOINPUT;
    } else if (player->inputLeft) {
        player->groundDirection = LEFT;
        if (!player->controlLockTimer) player->facing = -1;
    } else if (player->inputRight) {
        player->groundDirection = RIGHT;
        if (!player->controlLockTimer) player->facing = 1;
    } else {
        player->groundDirection = NOINPUT;
    }
}

// ============================================================================
// Physics Helpers
// ============================================================================

static float GetAcceleration(Player* player) {
    if (player->isSuper) {
        return (player->type == SONIC) ? SONIC_SUPER_ACCELERATION_SPEED : TAILS_SUPER_ACCELERATION_SPEED;
    }
    return (player->type == SONIC) ? SONIC_ACCELERATION_SPEED : TAILS_ACCELERATION_SPEED;
}

static float GetDeceleration(Player* player) {
    if (player->isSuper) {
        return (player->type == SONIC) ? SONIC_SUPER_DECELERATION_SPEED : TAILS_SUPER_DECELERATION_SPEED;
    }
    return (player->type == SONIC) ? SONIC_DECELERATION_SPEED : TAILS_DECELERATION_SPEED;
}

static float GetFriction(Player* player) {
    return (player->type == SONIC) ? SONIC_FRICTION_SPEED : TAILS_FRICTION_SPEED;
}

static float GetTopSpeed(Player* player) {
    if (player->isSuper) {
        return (player->type == SONIC) ? SONIC_SUPER_TOP_SPEED : TAILS_SUPER_TOP_SPEED;
    }
    return (player->type == SONIC) ? (float)SONIC_TOP_SPEED : (float)TAILS_TOP_SPEED;
}

static float GetGravity(Player* player) {
    return (player->type == SONIC) ? SONIC_GRAVITY_FORCE : TAILS_GRAVITY_FORCE;
}

static float GetJumpForce(Player* player) {
    // SPG: Jump force is 6.5 for Sonic, 6.0 for Knuckles (Tails same as Sonic)
    return (player->type == SONIC) ? 6.5f : -TAILS_JUMP_FORCE;
}

static float GetAirAcceleration(Player* player) {
    if (player->isSuper) {
        return (player->type == SONIC) ? SONIC_SUPER_AIR_ACCELERATION_SPEED : TAILS_SUPER_AIR_ACCELERATION_SPEED;
    }
    return (player->type == SONIC) ? SONIC_AIR_ACCELERATION_SPEED : TAILS_AIR_ACCELERATION_SPEED;
}

static float GetSlopeFactor(Player* player) {
    if (player->isRolling) {
        // Different slope factors for rolling up vs down
        float angleRad = AngleByteToRadians(player->groundAngle);
        float slopeSin = sinf(angleRad);

        // If moving in direction of slope (downhill), use stronger factor
        if ((player->groundSpeed > 0 && slopeSin > 0) ||
            (player->groundSpeed < 0 && slopeSin < 0)) {
            return (player->type == SONIC) ? SONIC_SLOPE_FACTOR_ROLLDOWN : TAILS_SLOPE_FACTOR_ROLLDOWN;
        } else {
            return (player->type == SONIC) ? SONIC_SLOPE_FACTOR_ROLLUP : TAILS_SLOPE_FACTOR_ROLLUP;
        }
    }
    return (player->type == SONIC) ? SONIC_SLOPE_FACTOR_NORMAL : TAILS_SLOPE_FACTOR_NORMAL;
}

static float GetRollingFriction(Player* player) {
    if (player->isSuper) {
        return (player->type == SONIC) ? SONIC_SUPER_ROLLING_FRICTION : TAILS_SUPER_ROLLING_FRICTION;
    }
    return (player->type == SONIC) ? SONIC_ROLLING_FRICTION : TAILS_ROLLING_FRICTION;
}

static float GetRollingDeceleration(Player* player) {
    return (player->type == SONIC) ? SONIC_ROLLING_DECELERATION : TAILS_ROLLING_DECELERATION;
}

// ============================================================================
// Ground Movement (SPG: Running)
// ============================================================================

static void UpdateGroundMovement(Player* player) {
    float acc = GetAcceleration(player);
    float dec = GetDeceleration(player);
    float frc = GetFriction(player);
    float top = GetTopSpeed(player);

    // Apply slope factor to ground speed (SPG)
    float slopeFactor = GetSlopeFactor(player);
    float angleRad = AngleByteToRadians(player->groundAngle);
    player->groundSpeed -= slopeFactor * sinf(angleRad);

    // Check for control lock
    if (player->controlLockTimer > 0) {
        player->controlLockTimer--;
        // During control lock, no friction if input held (SPG quirk)
        if (!player->inputLeft && !player->inputRight) {
            if (player->groundSpeed > 0) {
                player->groundSpeed -= frc;
                if (player->groundSpeed < 0) player->groundSpeed = 0;
            } else if (player->groundSpeed < 0) {
                player->groundSpeed += frc;
                if (player->groundSpeed > 0) player->groundSpeed = 0;
            }
        }
        return;
    }

    // Handle input
    if (player->inputLeft && !player->inputRight) {
        if (player->groundSpeed > 0) {
            // Turning around - use deceleration
            player->groundSpeed -= dec;
            if (player->groundSpeed <= 0) {
                player->groundSpeed = -0.5f; // SPG: Set to -0.5 when changing direction
            }
        } else if (player->groundSpeed > -top) {
            // Accelerating left
            player->groundSpeed -= acc;
            if (player->groundSpeed < -top) {
                player->groundSpeed = -top;
            }
        }
    } else if (player->inputRight && !player->inputLeft) {
        if (player->groundSpeed < 0) {
            // Turning around - use deceleration
            player->groundSpeed += dec;
            if (player->groundSpeed >= 0) {
                player->groundSpeed = 0.5f; // SPG: Set to 0.5 when changing direction
            }
        } else if (player->groundSpeed < top) {
            // Accelerating right
            player->groundSpeed += acc;
            if (player->groundSpeed > top) {
                player->groundSpeed = top;
            }
        }
    } else {
        // No input - apply friction
        if (player->groundSpeed > 0) {
            player->groundSpeed -= frc;
            if (player->groundSpeed < 0) player->groundSpeed = 0;
        } else if (player->groundSpeed < 0) {
            player->groundSpeed += frc;
            if (player->groundSpeed > 0) player->groundSpeed = 0;
        }
    }
}

// ============================================================================
// Rolling Movement (SPG: Rolling)
// ============================================================================

static void UpdateRollingMovement(Player* player) {
    float frc = GetRollingFriction(player);
    float dec = GetRollingDeceleration(player);

    // Apply slope factor
    float slopeFactor = GetSlopeFactor(player);
    float angleRad = AngleByteToRadians(player->groundAngle);
    player->groundSpeed -= slopeFactor * sinf(angleRad);

    // Rolling: can only decelerate, not accelerate
    if (player->inputLeft && !player->inputRight && player->groundSpeed > 0) {
        player->groundSpeed -= dec;
    } else if (player->inputRight && !player->inputLeft && player->groundSpeed < 0) {
        player->groundSpeed += dec;
    }

    // Always apply friction when rolling
    if (player->groundSpeed > 0) {
        player->groundSpeed -= frc;
        if (player->groundSpeed < 0) player->groundSpeed = 0;
    } else if (player->groundSpeed < 0) {
        player->groundSpeed += frc;
        if (player->groundSpeed > 0) player->groundSpeed = 0;
    }

    // Uncurl if speed drops below threshold (Sonic 3K behavior)
    if (fabsf(player->groundSpeed) < 0.5f) {
        player->isRolling = false;
        player->widthRadius = player->defaultWidthRadius;
        player->heightRadius = player->defaultHeightRadius;
        // Pop up to account for hitbox change
        player->position.y -= (player->defaultHeightRadius - 14);
    }
}

// ============================================================================
// Jumping (SPG: Jumping)
// ============================================================================

static void HandleJump(Player* player) {
    if (!player->inputJumpPressed) return;
    if (player->isJumping) return;

    float jumpForce = GetJumpForce(player);

    // SPG: Jump velocity is applied perpendicular to ground angle
    float angleRad = AngleByteToRadians(player->groundAngle);

    player->velocity.x -= jumpForce * sinf(angleRad);
    player->velocity.y -= jumpForce * cosf(angleRad);

    player->isOnGround = false;
    player->isJumping = true;
    player->hasJumped = true;

    // Set rolling hitbox when jumping
    player->widthRadius = player->defaultWidthRadius - 2;
    player->heightRadius = 14;

    // Clear ground state
    player->groundAngle = 0;
    player->collisionMode = MODE_FLOOR;
}

// ============================================================================
// Variable Jump Height (SPG)
// ============================================================================

static void HandleVariableJump(Player* player) {
    // SPG: If jump button released and Y speed < -4, cap Y speed at -4
    if (!player->inputJump && player->isJumping && player->velocity.y < -4.0f) {
        player->velocity.y = -4.0f;
    }
}

// ============================================================================
// Air Movement (SPG: Jumping - Air Drag)
// ============================================================================

static void UpdateAirMovement(Player* player) {
    float airAcc = GetAirAcceleration(player);

    if (player->inputLeft && !player->inputRight) {
        player->velocity.x -= airAcc;
    } else if (player->inputRight && !player->inputLeft) {
        player->velocity.x += airAcc;
    }

    // SPG Air drag: If Y speed < 0 and Y speed > -4, apply air drag to X speed
    if (player->velocity.y < 0 && player->velocity.y > -4.0f) {
        if (fabsf(player->velocity.x) >= 0.125f) {
            player->velocity.x *= 0.96875f;
        }
    }

    // Cap horizontal speed
    float maxSpeed = player->isRolling ? 16.0f : GetTopSpeed(player);
    if (player->velocity.x > maxSpeed) player->velocity.x = maxSpeed;
    if (player->velocity.x < -maxSpeed) player->velocity.x = -maxSpeed;
}

// ============================================================================
// Gravity (SPG)
// ============================================================================

static void ApplyGravity(Player* player) {
    float gravity = GetGravity(player);

    player->velocity.y += gravity;

    // Cap fall speed
    float maxYSpeed = (player->type == SONIC) ? (float)SONIC_TOP_Y_SPEED : (float)TAILS_TOP_Y_SPEED;
    if (player->velocity.y > maxYSpeed) {
        player->velocity.y = maxYSpeed;
    }
}

// ============================================================================
// Position Update
// ============================================================================

static void UpdatePosition(Player* player) {
    if (player->isOnGround) {
        // Convert ground speed to X/Y velocity based on angle
        float angleRad = AngleByteToRadians(player->groundAngle);
        player->velocity.x = player->groundSpeed * cosf(angleRad);
        player->velocity.y = player->groundSpeed * -sinf(angleRad);
    }

    // Move player
    player->position.x += player->velocity.x;
    player->position.y += player->velocity.y;
}

// ============================================================================
// Collision Detection
// ============================================================================

static void HandleGroundCollision(Player* player) {
    SensorResult sensorA, sensorB;
    SensorResult ground = CheckGroundSensors(
        player->position,
        player->widthRadius,
        player->heightRadius,
        player->collisionMode,
        player->groundAngle,
        &sensorA, &sensorB
    );

    if (ground.found && ground.distance <= 14 && ground.distance >= -14) {
        // Snap to ground
        player->position.y += ground.distance;
        player->groundAngle = ground.angle;
        player->collisionMode = GetCollisionModeFromAngle(ground.angle);

        // Check for slip/fall on steep slopes
        if (!player->isJumping) {
            float angleDeg = AngleByteToDegrees(player->groundAngle);

            if (fabsf(player->groundSpeed) < 2.5f) {
                bool shouldSlip = false;

                if (angleDeg >= 46 && angleDeg <= 315) {
                    shouldSlip = true;
                }

                if (shouldSlip) {
                    player->controlLockTimer = 30;

                    if (angleDeg >= 69 && angleDeg <= 293) {
                        player->isOnGround = false;
                        player->groundAngle = 0;
                        player->collisionMode = MODE_FLOOR;
                    }
                }
            }
        }
    } else if (ground.distance > 14 || !ground.found) {
        // Lost ground - start falling
        player->isOnGround = false;
        player->groundAngle = 0;
        player->collisionMode = MODE_FLOOR;
    }
}

static void HandleAirCollision(Player* player) {
    // Ground sensors (moving mostly down)
    if (player->velocity.y >= 0) {
        SensorResult sensorA, sensorB;
        SensorResult ground = CheckGroundSensors(
            player->position,
            player->widthRadius,
            player->heightRadius,
            MODE_FLOOR,
            0,
            &sensorA, &sensorB
        );

        // SPG landing condition
        if (ground.found && ground.distance <= 0 && ground.distance >= -(player->velocity.y + 8)) {
            player->position.y += ground.distance;
            player->isOnGround = true;
            player->isJumping = false;
            player->hasJumped = false;
            player->groundAngle = ground.angle;
            player->collisionMode = GetCollisionModeFromAngle(ground.angle);

            // Convert air velocity to ground speed
            float angleDeg = AngleByteToDegrees(ground.angle);

            if (angleDeg < 22.5f || angleDeg > 337.5f) {
                player->groundSpeed = player->velocity.x;
            } else if (angleDeg < 45.0f || angleDeg > 315.0f) {
                if (fabsf(player->velocity.x) > fabsf(player->velocity.y)) {
                    player->groundSpeed = player->velocity.x;
                } else {
                    float sign = (sinf(AngleByteToRadians(ground.angle)) >= 0) ? 1.0f : -1.0f;
                    player->groundSpeed = player->velocity.y * 0.5f * sign;
                }
            } else {
                if (fabsf(player->velocity.x) > fabsf(player->velocity.y)) {
                    player->groundSpeed = player->velocity.x;
                } else {
                    float sign = (sinf(AngleByteToRadians(ground.angle)) >= 0) ? 1.0f : -1.0f;
                    player->groundSpeed = player->velocity.y * sign;
                }
            }

            // Restore standing hitbox (unless rolling)
            if (!player->isRolling) {
                float oldHeight = player->heightRadius;
                player->widthRadius = player->defaultWidthRadius;
                player->heightRadius = player->defaultHeightRadius;
                player->position.y -= (player->heightRadius - oldHeight);
            }

            return;
        }
    }

    // Ceiling sensors (moving mostly up)
    if (player->velocity.y < 0) {
        SensorResult sensorC, sensorD;
        SensorResult ceiling = CheckCeilingSensors(
            player->position,
            player->widthRadius,
            player->heightRadius,
            MODE_FLOOR,
            0,
            &sensorC, &sensorD
        );

        if (ceiling.found && ceiling.distance <= 0) {
            player->position.y -= ceiling.distance;
            player->velocity.y = 0;
        }
    }

    // Wall sensors
    SensorResult sensorE, sensorF;
    CheckWallSensors(player->position, player->pushRadius, MODE_FLOOR, &sensorE, &sensorF);

    if (sensorE.found && sensorE.distance <= 0 && player->velocity.x < 0) {
        player->position.x -= sensorE.distance;
        player->velocity.x = 0;
    }

    if (sensorF.found && sensorF.distance <= 0 && player->velocity.x > 0) {
        player->position.x += sensorF.distance;
        player->velocity.x = 0;
    }
}

static void HandleWallCollision(Player* player) {
    if (!player->isOnGround) return;

    SensorResult sensorE, sensorF;
    CheckWallSensors(player->position, player->pushRadius, player->collisionMode, &sensorE, &sensorF);

    if (sensorE.found && sensorE.distance <= 0 && player->groundSpeed < 0) {
        player->position.x -= sensorE.distance;
        player->groundSpeed = 0;
    }

    if (sensorF.found && sensorF.distance <= 0 && player->groundSpeed > 0) {
        player->position.x += sensorF.distance;
        player->groundSpeed = 0;
    }
}

// ============================================================================
// Roll Initiation
// ============================================================================

static void HandleRollInitiation(Player* player) {
    if (!player->isOnGround) return;
    if (player->isRolling) return;
    if (player->isSpindashing) return;

    // SPG: Must be pressing down and have speed >= 1.0 (S3K threshold)
    if (player->inputDown && fabsf(player->groundSpeed) >= 1.0f) {
        player->isRolling = true;
        player->widthRadius = player->defaultWidthRadius; // not altered
        player->heightRadius = 14;
        player->position.y += (player->defaultHeightRadius - 14);
    }
}

// ============================================================================
// Crouching and Looking Up
// ============================================================================

static void HandleCrouchAndLookUp(Player* player) {
    if (!player->isOnGround) {
        player->isCrouching = false;
        player->isLookingUp = false;
        return;
    }

    if (player->isRolling || player->isSpindashing) return;

    if (fabsf(player->groundSpeed) < 0.1f) {
        if (player->inputDown) {
            player->isCrouching = true;
            player->isLookingUp = false;
        } else if (player->inputUp) {
            player->isLookingUp = true;
            player->isCrouching = false;
        } else {
            player->isCrouching = false;
            player->isLookingUp = false;
        }
    } else {
        player->isCrouching = false;
        player->isLookingUp = false;
    }
}

// ============================================================================
// State Management
// ============================================================================

void UpdatePlayerState(Player* player) {
    if (player->isDead) {
        player->state = DEAD;
    } else if (player->isHurt) {
        player->state = HURT;
    } else if (!player->isOnGround) {
        if (player->isRolling || player->isJumping) {
            player->state = ROLL;
        } else {
            player->state = FALL;
        }
    } else if (player->isSpindashing) {
        player->state = SPINDASH;
    } else if (player->isRolling) {
        player->state = ROLL;
    } else if (player->isCrouching) {
        player->state = CROUCH;
    } else if (player->isLookingUp) {
        player->state = LOOK_UP;
    } else if (fabsf(player->groundSpeed) < 0.1f) {
        player->state = IDLE;
    } else if (fabsf(player->groundSpeed) < 4.0f) {
        player->state = WALK;
    } else if (fabsf(player->groundSpeed) < 6.0f) {
        player->state = RUN;
    } else {
        player->state = DASH;
    }
}

// ============================================================================
// Animation Update
// ============================================================================

void UpdatePlayerAnimation(Player* player, float deltaTime) {
    switch (player->state) {
        case IDLE:
            player->idleTimer += deltaTime;
            SetPlayerAnimation(player, ANIM_IDLE);
            break;
        case WALK:
        case RUN:
            player->idleTimer = 0;
            SetPlayerAnimation(player, (fabsf(player->groundSpeed) < 4.0f) ? ANIM_WALK : ANIM_RUN);
            break;
        case DASH:
            SetPlayerAnimation(player, ANIM_DASH);
            break;
        case CROUCH:
            SetPlayerAnimation(player, ANIM_CROUCH);
            break;
        case LOOK_UP:
            SetPlayerAnimation(player, ANIM_LOOK_UP);
            break;
        case ROLL:
            SetPlayerAnimation(player, player->isOnGround ? ANIM_ROLL : ANIM_JUMP);
            break;
        case JUMP:
        case FALL:
            SetPlayerAnimation(player, ANIM_FALL);
            break;
        case SPINDASH:
            SetPlayerAnimation(player, ANIM_SPINDASH);
            break;
        case HURT:
            SetPlayerAnimation(player, ANIM_HURT);
            break;
        case DEAD:
            SetPlayerAnimation(player, ANIM_DEAD);
            break;
        default:
            SetPlayerAnimation(player, ANIM_IDLE);
            break;
    }
}

// ============================================================================
// Main Update Loop (SPG order)
// ============================================================================

void UpdatePlayer(Player* player, float deltaTime) {
    if (player->isDead) return;

    // 1. Handle input
    HandlePlayerInput(player);

    // 2. Ground vs Air state handling
    if (player->isOnGround) {
        HandleCrouchAndLookUp(player);
        HandleRollInitiation(player);
        HandleJump(player);

        if (player->isRolling) {
            UpdateRollingMovement(player);
        } else if (!player->isCrouching && !player->isLookingUp) {
            UpdateGroundMovement(player);
        }

        UpdatePosition(player);
        HandleWallCollision(player);
        HandleGroundCollision(player);

    } else {
        HandleVariableJump(player);
        UpdateAirMovement(player);
        UpdatePosition(player);
        ApplyGravity(player);
        HandleAirCollision(player);
    }

    UpdatePlayerState(player);
    UpdatePlayerAnimation(player, deltaTime);
}

// ============================================================================
// Drawing
// ============================================================================

void DrawPlayer(const Player* player) {
    float width = player->widthRadius * 2;
    float height = player->heightRadius * 2;

    Color boxColor = player->isOnGround ? GREEN : RED;
    if (player->isRolling) boxColor = BLUE;

    Rectangle rect = {
        player->position.x - player->widthRadius,
        player->position.y - player->heightRadius,
        width,
        height
    };

    DrawRectangleRec(rect, (Color){boxColor.r, boxColor.g, boxColor.b, 128});
    DrawRectangleLinesEx(rect, 1, boxColor);
    DrawCircleV(player->position, 2, YELLOW);

    DrawLineV(
        player->position,
        (Vector2){player->position.x + player->facing * 15, player->position.y},
        YELLOW
    );

    if (player->isOnGround) {
        Vector2 sensorA = {player->position.x - player->widthRadius, player->position.y + player->heightRadius};
        Vector2 sensorB = {player->position.x + player->widthRadius, player->position.y + player->heightRadius};
        DrawCircleV(sensorA, 2, MAGENTA);
        DrawCircleV(sensorB, 2, MAGENTA);
    }
}

// ============================================================================
// Reset
// ============================================================================

void ResetPlayer(Player* player, Vector2 startPosition) {
    PlayerType type = player->type;
    InitPlayer(player, type, startPosition);
}
