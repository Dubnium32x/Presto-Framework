// Player implementation

/*

    This one is gonna take a few tries I'm sure. Especially with the data loss that has recently happened.
    We need to make sure to keep the UpdateMovement files static and private if possible.

    We also need to make sure that the player state is properly encapsulated and
    not accessible from outside the player module.

    Damnit... If only I hadn't lost the data I had. Transcribing the old code from D would have made the
    process a little bit easier. Well, at least most of it has been transcribed.

    Let's hope the rest of the code is as easy to create from scratch.
*/
//ꏥꏌ ꎦꎶꏁꏿ, here we go again... - Birb64

#include "player.h"
#include "raylib.h"
#include "var.h"
#include "../../world/tile_collision.h"
#include "../../util/level_loader.h"
#include "../../world/generated_heightmaps.h"

// Helper: Get tile at world position
static Tile GetTileAtWorldPos(float worldX, float worldY, LevelData* level) {
    int tileX = (int)(worldX / 16);
    int tileY = (int)(worldY / 16);
    
    if (tileX < 0 || tileX >= level->width || tileY < 0 || tileY >= level->height) {
        Tile empty = {0};
        return empty;
    }
    
    // Check collision layers in priority order
    if (level->groundLayer1 && level->groundLayer1[tileY][tileX].tileId != 0) {
        return level->groundLayer1[tileY][tileX];
    }
    if (level->groundLayer2 && level->groundLayer2[tileY][tileX].tileId != 0) {
        return level->groundLayer2[tileY][tileX];
    }
    if (level->groundLayer3 && level->groundLayer3[tileY][tileX].tileId != 0) {
        return level->groundLayer3[tileY][tileX];
    }
    
    Tile empty = {0};
    return empty;
}

// Helper: Get height from heightmap at specific pixel within tile
static int GetHeightAtPosition(float worldX, float worldY, LevelData* level) {
    int tileX = (int)(worldX / 16);
    int tileY = (int)(worldY / 16);
    int pixelX = ((int)worldX) % 16;
    
    if (pixelX < 0) pixelX += 16;
    if (pixelX >= 16) pixelX = 15;
    
    Tile tile = GetTileAtWorldPos(worldX, worldY, level);
    if (tile.tileId == 0) return 0;
    
    int tileId = tile.tileId - 1; // Convert to 0-based index
    if (tileId < 0 || tileId >= TILESET_TILE_COUNT) return 0;
    
    return TILESET_HEIGHTMAPS[tileId][pixelX];
}

#include "player.h"
#include "raylib.h"
#include "var.h"
#include "../../world/tile_collision.h"

// Returns -1 for negative, 1 for positive, 0 for zero
static inline int sign(float x) {
    return (x > 0) - (x < 0);
}

static void PlayerAssignSensors(Player* player);
static void PlayerUpdate(Player* player, float dt);
static void PlayerDraw(Player* player);
static void PlayerUnload(Player* player);

#define JUMP_BUTTON KEY_Z | KEY_X | KEY_C | BUTTON_A | BUTTON_B | BUTTON_X

// Local toggle for showing sensor overlay (debug aid)
static bool s_showSensors = true;

// Compute all sensor positions and hitbox from current player position/orientation
static void PlayerAssignSensors(Player* player) {
    if (!player) return;
    switch (player->groundDirection) {
        case ANGLE_DOWN: // standing on floor
            player->hitbox = (Hitbox_t){0, 0, PLAYER_WIDTH, PLAYER_HEIGHT};
            player->playerSensors.center     = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right      = (Vector2){player->position.x + PLAYER_WIDTH_RAD,  player->position.y};
            player->playerSensors.left       = (Vector2){player->position.x - PLAYER_WIDTH_RAD,  player->position.y};
            player->playerSensors.topLeft    = (Vector2){player->position.x - PLAYER_WIDTH_RAD,  player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.topRight   = (Vector2){player->position.x + PLAYER_WIDTH_RAD,  player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x - PLAYER_WIDTH_RAD,  player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomRight= (Vector2){player->position.x + PLAYER_WIDTH_RAD,  player->position.y - PLAYER_HEIGHT_RAD};
            break;

        case ANGLE_RIGHT: // on right wall
            player->hitbox = (Hitbox_t){0, 0, PLAYER_HEIGHT, PLAYER_WIDTH};
            player->playerSensors.center     = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right      = (Vector2){player->position.x,                     player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.left       = (Vector2){player->position.x,                     player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.topLeft    = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.topRight   = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.bottomRight= (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            break; // IMPORTANT: avoid fall-through

        case ANGLE_UP: // on ceiling
            player->hitbox = (Hitbox_t){0, 0, PLAYER_WIDTH, PLAYER_HEIGHT};
            player->playerSensors.center     = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right      = (Vector2){player->position.x - PLAYER_WIDTH_RAD,  player->position.y};
            player->playerSensors.left       = (Vector2){player->position.x + PLAYER_WIDTH_RAD,  player->position.y};
            player->playerSensors.topLeft    = (Vector2){player->position.x + PLAYER_WIDTH_RAD,  player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.topRight   = (Vector2){player->position.x - PLAYER_WIDTH_RAD,  player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x + PLAYER_WIDTH_RAD,  player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomRight= (Vector2){player->position.x - PLAYER_WIDTH_RAD,  player->position.y + PLAYER_HEIGHT_RAD};
            break;

        case ANGLE_LEFT: // on left wall
            player->hitbox = (Hitbox_t){0, 0, PLAYER_HEIGHT, PLAYER_WIDTH};
            player->playerSensors.center     = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right      = (Vector2){player->position.x,                     player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.left       = (Vector2){player->position.x,                     player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.topLeft    = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.topRight   = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.bottomRight= (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            break;

        default:
            // Fallback to floor orientation
            player->groundDirection = ANGLE_DOWN;
            PlayerAssignSensors(player);
            break;
    }
}



Player Player_Init(float startX, float startY) {
    Player player;
    player.position = (Vector2){startX, startY};
    player.velocity = (Vector2){0, 0};
    player.groundSpeed = 0;
    player.verticalSpeed = 0;
    player.groundAngle = 0;
    player.playerRotation = 0;
    player.isOnGround = false;
    player.isJumping = false;
    player.hasJumped = false;
    player.jumpPressed = false;
    player.isFalling = false;
    player.isRolling = false;
    player.isCrouching = false;
    player.isLookingUp = false;
    player.isSpindashing = false;
    player.isGravityApplied = true;
    player.isSuper = false;
    player.isPeelOut = false;
    player.isFlying = false;
    player.isGliding = false;
    player.isClimbing = false;
    player.isHurt = false;
    player.isDead = false;
    
    // Input tracking fields
    player.inputLeft = false;
    player.inputRight = false;
    player.inputUp = false;
    player.inputDown = false;
    
    player.facing = 1; // Default facing right
    player.state = IDLE;
    player.idleState = IDLE_NORMAL;
    player.groundDirection = NOINPUT;
    player.isImpatient = false;
    player.impatientTimer = 0;
    player.spindashCharge = 0;
    player.idleTimer = 0;
    player.idleLookTimer = 0;
    player.sprite = NULL;
    player.groundAngles.bottomLeftAngle = 0;
    player.groundAngles.bottomRightAngle = 0;
    player.animationState = ANIM_IDLE;
    player.animationManager = NULL;
    player.controlLockTimer = 0;
    player.invincibilityTimer = 0;
    player.blinkTimer = 0;
    player.blinkInterval = 0;
    player.blinkDuration = 0;
    player.jumpButtonHoldTimer = 0;
    player.slipAngleType = 0;
    player.currentTileset = NULL;
    player.hitbox = (Hitbox_t){0, 0, PLAYER_WIDTH, PLAYER_HEIGHT};

    player.playerSensors.center = (Vector2){startX, startY};
    player.playerSensors.left = (Vector2){startX - PLAYER_WIDTH / 2, startY};
    player.playerSensors.right = (Vector2){startX + PLAYER_WIDTH / 2, startY};
    player.playerSensors.topLeft = (Vector2){startX - PLAYER_WIDTH / 2, startY - PLAYER_HEIGHT / 2};
    player.playerSensors.topRight = (Vector2){startX + PLAYER_WIDTH / 2, startY - PLAYER_HEIGHT / 2};
    player.playerSensors.bottomLeft = (Vector2){startX - PLAYER_WIDTH / 2, startY + PLAYER_HEIGHT / 2};
    player.playerSensors.bottomRight = (Vector2){startX + PLAYER_WIDTH / 2, startY + PLAYER_HEIGHT / 2};
    return player;
}

void Player_Update(Player* player, float dt) {
    /*
        We will start by organizing this into categories for clarity.
        - Input handling
        - Collision detection
        - Physics and movement
        - State transitions
        - Animation updates
    */
    #pragma region input_handling
    // Input Handling
    if (IsKeyDown(KEY_LEFT)) {
        player->inputLeft = true;
    } else {
        player->inputLeft = false;
    }
    
    if (IsKeyDown(KEY_RIGHT)) {
        player->inputRight = true;
    } else {
        player->inputRight = false;
    }
    
    if (IsKeyDown(KEY_UP)) {
        player->inputUp = true;
    } else {
        player->inputUp = false;
    }
    
    if (IsKeyDown(KEY_DOWN)) {
        player->inputDown = true;
    } else {
        player->inputDown = false;
    }

    // Jump keys: Z, X, C, Space
    if (IsKeyDown(KEY_Z) || IsKeyDown(KEY_X) || IsKeyDown(KEY_C) || IsKeyDown(KEY_SPACE)) {
        player->jumpPressed = true;
    } else {
        player->jumpPressed = false;
    }

    // Debug toggle: F3 to show/hide sensor overlay
    if (IsKeyPressed(KEY_F3)) {
        s_showSensors = !s_showSensors;
    }

    bool noInput = false;
    if (!player->inputLeft && !player->inputRight && !player->inputUp && !player->inputDown) {
        noInput = true;
    }
    #pragma endregion
    #pragma region collision_detection
    // Collision detection
    /*
        First we need to gather the groundAngle for both bottom left and bottom right.
        We do this by getting the groundAngle attached to the tileID 

    */
    //player->groundAngles.bottomLeftAngle = TileCollision_GetTileGroundAngle(player->playerSensors.bottomLeft., player->playerSensors.bottomLeft);
    //player->groundAngles.bottomRightAngle = TileCollision_GetTileGroundAngle(player->playerSensors.bottomRight);

    if (player->groundAngles.bottomLeftAngle > player->groundAngles.bottomRightAngle) {
        player->groundAngle = player->groundAngles.bottomLeftAngle;
    } else if (player->groundAngles.bottomLeftAngle < player->groundAngles.bottomRightAngle){
        player->groundAngle = player->groundAngles.bottomRightAngle;
    } else { // Assume this is true when both angles are equal
        player->groundAngle = player->groundAngles.bottomLeftAngle;
    }
    
    // Next, we need to determine the groundDirection based on the player's direction.
    bool isAngleFloor = ((player->groundAngle < GetAngleFromHexDirection(ANGLE_DOWN_RIGHT)) || (player->groundAngle > GetAngleFromHexDirection(ANGLE_DOWN_LEFT)));
    bool isAngleRightWall = ((player->groundAngle > GetAngleFromHexDirection(ANGLE_UP_RIGHT)) && (player->groundAngle < GetAngleFromHexDirection(ANGLE_DOWN_RIGHT)));
    bool isAngleLeftWall = ((player->groundAngle > GetAngleFromHexDirection(ANGLE_DOWN_LEFT)) && (player->groundAngle < GetAngleFromHexDirection(ANGLE_UP_LEFT)));
    bool isAngleCeiling = ((player->groundAngle > GetAngleFromHexDirection(ANGLE_UP_LEFT)) && (player->groundAngle < GetAngleFromHexDirection(ANGLE_UP_RIGHT)));

    if (isAngleFloor) {
        player->groundDirection = ANGLE_DOWN;
    } else if (isAngleRightWall) {
        player->groundDirection = ANGLE_RIGHT;
    } else if (isAngleLeftWall) {
        player->groundDirection = ANGLE_LEFT;
    } else if (isAngleCeiling) {
        player->groundDirection = ANGLE_UP;
    }

    // Now that we have the groundDirection, compute sensors from current position
    PlayerAssignSensors(player);
    #pragma end region
    // Sensors are derived from position; no need to pre-offset by velocity

    // Physics and movement
    /*
        Heres the big one.
        We need to handle gravity, jumping, falling, and collisions here.
    */

    // First we need to determine what the velocity and speed is this frame.
    float xVel = player->velocity.x;
    float yVel = player->velocity.y;

    // Make sure to determine the player rotation based off of the groundAngle
    player->playerRotation = player->groundAngle;
    float playerRot = player->playerRotation;

    // Set Horizontal speed and Vertical speed based on groundAngle and groundDirection as well as groundSpeed.
    float xSpeed = player->groundSpeed * cosf(playerRot);
    float ySpeed = player->groundSpeed * sinf(playerRot);

    // Add thresholds to player angle when on a near flat slope
    if (noInput && ((player->groundAngle > 253) || (player->groundAngle < 3)) && (player->groundSpeed < fabsf(0.1f))) {
        playerRot = 0;
    }
    
    // Only apply ground-based velocity when actually on ground
    // In air, preserve existing momentum and let air physics handle changes
    if (player->isOnGround) {
        xVel += xSpeed;
        yVel += ySpeed;
    }
        
    // Jump initiation and hold behavior
    if (player->jumpPressed && player->isOnGround && !player->hasJumped) {
        // Start jump: set upward velocity
        yVel = INITIAL_JUMP_VELOCITY;
        player->isOnGround = false;
        player->isFalling = false;
        player->hasJumped = true;
        player->jumpButtonHoldTimer = 0.0f;
    }

    // If jump is being held while already jumped, extend upward velocity for a short window
    if (player->hasJumped && player->jumpPressed) {
        player->jumpButtonHoldTimer += dt;
        if (player->jumpButtonHoldTimer < MAX_JUMP_HOLD_TIME) {
            // Apply a small upward impulse while holding jump
            yVel += -JUMP_HOLD_VELOCITY_INCREASE;
        }
    }

    // If jump released early, clamp upward velocity to a release velocity (short hop)
    if (player->hasJumped && !player->jumpPressed && player->jumpButtonHoldTimer > 0.0f && player->jumpButtonHoldTimer < MAX_JUMP_HOLD_TIME) {
        if (yVel < RELEASE_JUMP_VELOCITY) {
            yVel = RELEASE_JUMP_VELOCITY;
        }
    }

    // Apply gravity if enabled
    if (player->isGravityApplied) {
        yVel += GRAVITY_FORCE;
        player->velocity.y = yVel;
    } else if (yVel >= TOP_Y_SPEED) {
        yVel = TOP_Y_SPEED;
    }
    
    if (groundSpeed < fabsf(PLAYER_RUN_SPEED_MIN)) {
        // If the ground speed is less than the minimum run speed, turn on gravity
        player->isGravityApplied = true;
    } else if (groundSpeed < fabsf(PLAYER_SPRINT_SPEED_MIN)) {
        // If the ground speed is less than the minimum sprint speed, turn off gravity
        player->isGravityApplied = false;
    } else if (groundSpeed < fabsf(PLAYER_SUPER_SPEED_MIN)) {
        // If the ground speed is less than the minimum super speed, turn off gravity
        player->isGravityApplied = false;
    }

    if (((player->groundAngle > SLIP_ANGLE_START) || (player->groundAngle < SLIP_ANGLE_END)) && groundSpeed < fabsf(2.5f)) {
        // If the player is on a slope and the ground speed is less than the minimum run speed, turn on gravity
        player->isGravityApplied = true;
        player->isOnGround = false; 
        player->groundSpeed = 0;
        player->controlLockTimer = 30;
        /*
            According to the SPG, when sonic is on a slope and the ground speed is less than fabsf(2.5f),
            he should be detached from the ground. GroundSpeed would then be set to 0.
        */
    }

    // We need to implement the controlLockTimer thresholds
    if (player->controlLockTimer < 0) {
        player->controlLockTimer = 0;
        // I know the SPG considers this timer to be non-zero, but I think that's a bug.
        // If the timer is non-zero, then the player would not be able to move ever, which I don't want to believe.
    } else if (player->controlLockTimer > 0 && player->isOnGround) {
        player->controlLockTimer -= dt;
        // The SPG says that the timer will count down while the player is on the ground.
        // Once the timer reaches 0, the player will be able to move again.
    }
    
    // So what's next?
    // Ground Physics
    // Check if the player is on the ground
    if (player->isOnGround) {
        // Apply friction to the player's horizontal velocity
        if (xVel > 0) {
            xVel -= FRICTION_SPEED;
            if (xVel < 0) {
                xVel = 0;
            }
        } else if (xVel < 0) {
            xVel += FRICTION_SPEED;
            if (xVel > 0) {
                xVel = 0;
            }
        } else {
            // Apply no friction if the player is not moving
            xVel = 0;
        }

        if (player->isSuper) {
            if (player->inputLeft && player->controlLockTimer == 0 && !player->isRolling) {
                player->groundSpeed -= ACCELERATION_SPEED;
            } else if (player->inputRight && player->controlLockTimer == 0 && !player->isRolling) {
                player->groundSpeed += ACCELERATION_SPEED;
            }
            // Clamp the ground speed to the maximum allowed speed
            if (player->groundSpeed > TOP_SPEED) {
                player->groundSpeed = TOP_SPEED;
            } else if (player->groundSpeed < -TOP_SPEED) {
                player->groundSpeed = -TOP_SPEED;
            }

            if (noInput && player->controlLockTimer == 0) {
                if (player->groundSpeed > 0) {
                    player->groundSpeed -= DECELERATION_SPEED;
                } else if (player->groundSpeed < 0) {
                    player->groundSpeed += DECELERATION_SPEED;
                }
            }
        }

        if (player->isRolling) {
            if (player->facing == 1) {
                if (player->inputLeft) {
                    player->groundSpeed -= ROLLING_FRICTION;
                } else if (player->inputRight) {
                    // do nothing
                }

            } else if (player->facing == -1) {
                if (player->inputRight) {
                    player->groundSpeed += ROLLING_FRICTION;
                } else if (player->inputLeft) {
                    // do nothing
                }
            }

            // Apply acceleration while rolling while downhill
            if (ySpeed > 0) {
                if (player->facing == 1) {
                    player->groundSpeed += ACCELERATION_SPEED * cosf(ySpeed);
                } else if (player->facing == -1) {
                    player->groundSpeed -= ACCELERATION_SPEED * cosf(ySpeed);
                }
            }
            // Else decelerate while rolling uphill or on a flat surface
            else {
                if (player->groundSpeed > 0) {
                    player->groundSpeed -= DECELERATION_SPEED;
                } else if (player->groundSpeed < 0) {
                    player->groundSpeed += DECELERATION_SPEED;
                }
            }

            yVel += ROLLING_GRAVITY_FORCE;
        }
        else if (player->isSuper && player->isRolling) {
            if (player->facing == 1) {
                if (player->inputLeft) {
                    player->groundSpeed -= SUPER_ROLLING_FRICTION;
                } else if (player->inputRight) {
                    // do nothing
                }

            } else if (player->facing == -1) {
                if (player->inputRight) {
                    player->groundSpeed += SUPER_ROLLING_FRICTION;
                } else if (player->inputLeft) {
                    // do nothing
                }
            }
        }

        // Slope physics based on groundAngle
        if (abs(groundAngle) >= 23 && abs(groundAngle) < 45) {
            // Sonic Slope
            groundSpeed = xSpeed + ySpeed * 0.5f * -sign(sin(groundAngle));
        } else if (abs(groundAngle) > 45 && abs(groundAngle) < 90) {
            // Sonic Steep Slope
            groundSpeed = xSpeed + ySpeed * -sign(sin(groundAngle));
        } else {
            // Sonic Flat
            groundSpeed = xSpeed - sin(groundAngle);
        }
    } else {
        // Process air physics here - preserve existing xVel for air momentum
        // Don't overwrite xVel with ground-based xSpeed when in air
        
        // Apply gravity based on launch angle
        if (player->groundAngle != 0 && player->hasJumped) {
            xVel += GRAVITY_FORCE * sinf(player->groundAngle) * dt;
            yVel += GRAVITY_FORCE * cosf(player->groundAngle) * dt;
        } else if (yVel > TOP_Y_SPEED) {
            yVel = TOP_Y_SPEED;
        } else {
            yVel += GRAVITY_FORCE;
        }

        // Apply air acceleration and drag
        if (player->inputRight && xVel < TOP_SPEED) {
            xVel += AIR_ACCELERATION_SPEED;
        } else if (player->inputLeft && xVel > -TOP_SPEED) {
            xVel -= AIR_ACCELERATION_SPEED;
        }
        
        // Apply air drag when no input or opposing input
        if (!player->inputLeft && !player->inputRight) {
            // Natural air resistance - gradual deceleration
            if (xVel > 0) {
                xVel -= AIR_DRAG_FORCE;
                if (xVel < 0) xVel = 0;  // Don't overshoot to opposite direction
            } else if (xVel < 0) {
                xVel += AIR_DRAG_FORCE;
                if (xVel > 0) xVel = 0;
            }
        }
    }

    // Commit velocity to position
    player->velocity.x = xVel;
    player->velocity.y = yVel;
    player->position.x += player->velocity.x;
    player->position.y += player->velocity.y;

    // After movement, refresh sensors so debug overlay matches final position
    PlayerAssignSensors(player);

    // Tile-based floor collision using heightmaps (SPG method)
    // Check both bottom sensors
    extern LevelData currentLevel;
    if (currentLevel.groundLayer1 != NULL) {
        // Sensor positions at player's feet
        float sensorLeftX = player->position.x - PLAYER_WIDTH_RAD;
        float sensorRightX = player->position.x + PLAYER_WIDTH_RAD;
        float sensorY = player->position.y + PLAYER_HEIGHT_RAD; // Bottom of player
        
        // Get tile Y coordinate for sensor
        int sensorTileY = (int)(sensorY / 16);
        
        // Get heights from heightmaps
        int leftHeight = GetHeightAtPosition(sensorLeftX, sensorY, &currentLevel);
        int rightHeight = GetHeightAtPosition(sensorRightX, sensorY, &currentLevel);
        
        // Take the higher of the two sensor heights (SPG: use the sensor that's more in the ground)
        int maxHeight = (leftHeight > rightHeight) ? leftHeight : rightHeight;
        
        if (maxHeight > 0) {
            // Calculate ground Y position (top of tile + height from heightmap)
            float groundY = (sensorTileY * 16.0f) + (16.0f - maxHeight);
            
            // If player's bottom is at or below ground level
            float playerBottom = player->position.y + PLAYER_HEIGHT_RAD;
            if (playerBottom >= groundY && player->velocity.y >= 0) {
                // Snap to ground
                player->position.y = groundY - PLAYER_HEIGHT_RAD;
                player->velocity.y = 0.0f;
                player->isOnGround = true;
                player->isFalling = false;
                player->hasJumped = false;
                
                // Get tile angle for ground angle
                Tile tile = GetTileAtWorldPos(sensorLeftX, sensorY, &currentLevel);
                if (tile.tileId > 0 && tile.tileId <= TILESET_TILE_COUNT) {
                    player->groundAngle = (float)TileCollision_GetAngle(tile.tileId - 1);
                }
            }
        }
    }
}

void Player_Draw(Player* player) {
    // TODO: Replace with animated sprite draw when available
    DrawCircleV(player->position, 10, RED);

    // Draw collision sensors overlay (temporarily always on to verify rendering path)
    PlayerDrawSensorLines(player);
}

static void PlayerUnload(Player* player) {
    // Unload player resources here
}

// Debug: draw player collision sensors and rays
void PlayerDrawSensorLines(Player* player) {
    if (!player) return;

    // Colors inspired by classic Sonic debugging
    const Color colVertical = YELLOW;      // Vertical sensor bars
    const Color colHorizontal = (Color){230, 230, 230, 255}; // Mid-line
    const Color colPointsTop = SKYBLUE;    // Sensor points (top)
    const Color colPointsBottom = GREEN;   // Sensor points (bottom)
    const Color colCenter = ORANGE;        // Center marker

    // Convenience aliases
    Vector2 TL = player->playerSensors.topLeft;
    Vector2 TR = player->playerSensors.topRight;
    Vector2 BL = player->playerSensors.bottomLeft;
    Vector2 BR = player->playerSensors.bottomRight;
    Vector2 L  = player->playerSensors.left;
    Vector2 R  = player->playerSensors.right;
    Vector2 C  = player->playerSensors.center;

    // Sanity cross at center
    DrawLineEx((Vector2){C.x - 12, C.y}, (Vector2){C.x + 12, C.y}, 2.0f, WHITE);
    DrawLineEx((Vector2){C.x, C.y - 12}, (Vector2){C.x, C.y + 12}, 2.0f, WHITE);

    // Vertical bars (left/right)
    DrawLineEx(TL, BL, 1.0f, colVertical);
    DrawLineEx(TR, BR, 1.0f, colVertical);

    // Center vertical bar using averaged top/bottom
    Vector2 topMid = { (TL.x + TR.x) * 0.5f, (TL.y + TR.y) * 0.5f };
    Vector2 botMid = { (BL.x + BR.x) * 0.5f, (BL.y + BR.y) * 0.5f };
    DrawLineEx(topMid, botMid, 1.0f, colVertical);

    // Mid horizontal line between left/right sensors
    DrawLineEx(L, R, 1.0f, colHorizontal);
    // Sensor points
    DrawCircleV(TL, 2.0f, colPointsTop);
    DrawCircleV(TR, 2.0f, colPointsTop);
    DrawCircleV(BL, 2.0f, colPointsBottom);
    DrawCircleV(BR, 2.0f, colPointsBottom);
    DrawCircleV(L,  2.0f, colHorizontal);
    DrawCircleV(R,  2.0f, colHorizontal);
    DrawCircleV(C,  2.0f, colCenter);
}

