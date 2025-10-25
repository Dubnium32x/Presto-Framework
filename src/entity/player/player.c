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

#include "player.h"
#include "raylib.h"
#include "var.h"
#include "../../util/level_loader.h" // For IsSolidAtPosition and LevelData

// Ground angle detection using the level collision system
float GetGroundAngleForTile(Vector2 position) {
    // For now, return 0 until we properly connect the level system
    // TODO: Connect to level collision system
    (void)position; // Suppress unused parameter warning
    return 0.0f;
}

// --- Local helpers for tile-based collision ---
static inline int ClampInt(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }

static inline int GetRawTileIdAt(LevelData* lvl, int tx, int ty, Tile*** outWhichLayer) {
    if (!lvl || tx < 0 || ty < 0 || tx >= lvl->width || ty >= lvl->height) return 0;
    // Prefer collision layer if present, else fall back to ground layer 1
    Tile** layer = lvl->collisionLayer ? lvl->collisionLayer : lvl->groundLayer1;
    if (outWhichLayer) *outWhichLayer = layer;
    return layer ? layer[ty][tx].tileId : 0;
}

static inline TileHeightProfile GetProfileAt(LevelData* lvl, int tx, int ty, const char* layerName) {
    int raw = GetRawTileIdAt(lvl, tx, ty, NULL);
    return TileCollision_GetTileHeightProfile(raw, layerName, lvl->tilesets, lvl->tilesetCount);
}

// Compute the world-space ground Y at the given world X inside tile row ty using the tile's height profile
static inline float GroundYAt(LevelData* lvl, int tx, int ty, float worldX, const char* layerName) {
    TileHeightProfile prof = GetProfileAt(lvl, tx, ty, layerName);
    int localX = (int)fmodf(worldX, (float)TILE_SIZE);
    if (localX < 0) localX += TILE_SIZE;
    localX = ClampInt(localX, 0, 15);
    int h = ClampInt(prof.groundHeights[localX], 0, 16);
    float tileTop = (float)(ty * TILE_SIZE);
    // heights are solid pixels from bottom; surface Y = tileTop + (TILE_SIZE - h)
    return tileTop + (float)(TILE_SIZE - h);
}

#define JUMP_BUTTON_Z KEY_Z
#define JUMP_BUTTON_X KEY_X
#define JUMP_BUTTON_C KEY_C

Player PlayerInit(float startX, float startY) {
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

void PlayerUpdate(Player* player, float dt) {
    if (!player) return;
    // Access current level (declared in level_demo_screen.c)
    extern LevelData level;
    
    /*
        We will start by organizing this into categories for clarity.
        - Input handling
        - Collision detection
        - Physics and movement
        - State transitions
        - Animation updates
    */

    // Input Handling
    bool jumpPressed = IsKeyDown(JUMP_BUTTON_Z) || IsKeyDown(JUMP_BUTTON_X) || IsKeyDown(JUMP_BUTTON_C);
    
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

    if (jumpPressed) {
        player->jumpPressed = true;
    } else {
        player->jumpPressed = false;
    }

    bool noInput = false;
    if (!player->inputLeft && !player->inputRight && !player->inputUp && !player->inputDown) {
        noInput = true;
    }

    // TEMP: Minimal physically-plausible movement (with gravity & decel)
    // Scales per-frame constants by 60*dt to operate in seconds
    const float f = 60.0f * dt;
    // Using tile collisions instead of a hardcoded ground plane

    // Facing
    if (player->inputLeft)  player->facing = -1;
    if (player->inputRight) player->facing =  1;

    // Horizontal acceleration
    if (player->inputLeft) {
        player->velocity.x -= ACCELERATION_SPEED * f;
    } else if (player->inputRight) {
        player->velocity.x += ACCELERATION_SPEED * f;
    } else if (player->isOnGround) {
        // Friction/deceleration when no input
        if (player->velocity.x > MIN_SPEED_THRESHOLD) {
            player->velocity.x -= FRICTION_SPEED * f;
            if (player->velocity.x < 0) player->velocity.x = 0;
        } else if (player->velocity.x < -MIN_SPEED_THRESHOLD) {
            player->velocity.x += FRICTION_SPEED * f;
            if (player->velocity.x > 0) player->velocity.x = 0;
        } else {
            player->velocity.x = 0;
        }
    }

    // Clamp horizontal speed
    if (player->velocity.x > TOP_SPEED)  player->velocity.x = TOP_SPEED;
    if (player->velocity.x < -TOP_SPEED) player->velocity.x = -TOP_SPEED;

    // Jump
    if (player->isOnGround && player->jumpPressed) {
        player->velocity.y = INITIAL_JUMP_VELOCITY; // negative goes up
        player->isOnGround = false;
    }

    // Gravity (apply when not grounded)
    if (!player->isOnGround) {
        player->velocity.y += GRAVITY_FORCE * f;
        if (player->velocity.y > TOP_Y_SPEED) player->velocity.y = TOP_Y_SPEED;
    }

    // Integrate
    player->position.x += player->velocity.x * f; // keep per-frame scale for now
    player->position.y += player->velocity.y * f;

    // Resolve against tiles (slope-aware using height profiles)
    float feetX = player->position.x;
    float feetY = player->position.y + PLAYER_HEIGHT_RAD + 0.1f;
    int feetTileX = (int)floorf(feetX / (float)TILE_SIZE);
    int feetTileY = (int)floorf(feetY / (float)TILE_SIZE);

    if (feetTileX >= 0 && feetTileY >= 0 && feetTileX < level.width && feetTileY < level.height) {
        // Only snap when moving downward or standing
        float surfaceY = GroundYAt(&level, feetTileX, feetTileY, feetX, "Collision");
        if (feetY >= surfaceY && player->velocity.y >= 0.0f) {
            player->position.y = surfaceY - PLAYER_HEIGHT_RAD;
            player->velocity.y = 0.0f;
            player->isOnGround = true;
        } else {
            player->isOnGround = false;
        }
    } else {
        player->isOnGround = false;
    }

    // Horizontal wall collision (simple AABB vs tile cells at center and feet)
    if (player->velocity.x != 0.0f) {
        float sideSign = (player->velocity.x > 0.0f) ? 1.0f : -1.0f;
        float probeX = player->position.x + sideSign * (PLAYER_WIDTH_RAD + 0.5f);
        float probeYCenter = player->position.y;
        float probeYFeet   = player->position.y + PLAYER_HEIGHT_RAD - 1.0f;

        bool hit = false;
        if (IsSolidAtPosition(&level, probeX, probeYCenter, TILE_SIZE)) hit = true;
        if (!hit && IsSolidAtPosition(&level, probeX, probeYFeet, TILE_SIZE)) hit = true;
        if (hit) {
            int tileX = (int)floorf(probeX / (float)TILE_SIZE);
            float boundary = (sideSign > 0.0f)
                ? (float)(tileX * TILE_SIZE) - (PLAYER_WIDTH_RAD + 0.5f)
                : (float)((tileX + 1) * TILE_SIZE) + (PLAYER_WIDTH_RAD + 0.5f);
            player->position.x = boundary;
            player->velocity.x = 0.0f;
        }
    }

    // Early exit: skip legacy complex block while we validate basics
    return;

    // Collision detection
    /*
        First we need to gather the groundAngle for both bottom left and bottom right.
        We do this by getting the groundAngle attached to the tileID 

    */
    player->groundAngles.bottomLeftAngle = GetGroundAngleForTile(player->playerSensors.bottomLeft);
    player->groundAngles.bottomRightAngle = GetGroundAngleForTile(player->playerSensors.bottomRight);

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

    // Now that we have the groundDirection, we can apply the hitbox accordingly.
    switch (player->groundDirection) {
        case ANGLE_DOWN:
            player->hitbox = (Hitbox_t){0, 0, PLAYER_WIDTH, PLAYER_HEIGHT};
            player->playerSensors.center = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.left = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.topLeft = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.topRight = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomRight = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            break;
        case ANGLE_RIGHT:
            player->hitbox = (Hitbox_t){0, 0, PLAYER_HEIGHT, PLAYER_WIDTH};
            player->playerSensors.center = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right = (Vector2){player->position.x, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.left = (Vector2){player->position.x, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.topLeft = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.topRight = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.bottomRight = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            break;
        case ANGLE_UP: 
            player->hitbox = (Hitbox_t){0, 0, PLAYER_WIDTH, PLAYER_HEIGHT};
            player->playerSensors.center = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.left = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.topLeft = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.topRight = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomRight = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            break;
        case ANGLE_LEFT:
            player->hitbox = (Hitbox_t){0, 0, PLAYER_HEIGHT, PLAYER_WIDTH};
            player->playerSensors.center = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right = (Vector2){player->position.x, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.left = (Vector2){player->position.x, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.topLeft = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.topRight = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.bottomRight = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            break;
    }

    // Update player sensors based on new position and angle
    player->playerSensors.center.x += player->velocity.x;
    player->playerSensors.center.y += player->velocity.y;
    player->playerSensors.right.x += player->velocity.x;
    player->playerSensors.right.y += player->velocity.y;
    player->playerSensors.left.x += player->velocity.x;
    player->playerSensors.left.y += player->velocity.y;
    player->playerSensors.topLeft.x += player->velocity.x;
    player->playerSensors.topLeft.y += player->velocity.y;
    player->playerSensors.topRight.x += player->velocity.x;
    player->playerSensors.topRight.y += player->velocity.y;
    player->playerSensors.bottomLeft.x += player->velocity.x;
    player->playerSensors.bottomLeft.y += player->velocity.y;
    player->playerSensors.bottomRight.x += player->velocity.x;
    player->playerSensors.bottomRight.y += player->velocity.y;

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
    if (noInput && ((player->groundAngle > 253) || (player->groundAngle < 3)) && (fabsf(player->groundSpeed) < PLAYER_WALK_SPEED_MIN)) {
        playerRot = 0;
    }
    
    // Update player velocity
    xVel = xSpeed;
    yVel = ySpeed;
        
    // Apply gravity if enabled
    if (player->isGravityApplied) {

        yVel += GRAVITY_FORCE * dt;
        player->velocity.y = yVel;
    } else if (yVel >= TOP_Y_SPEED) {
        yVel = TOP_Y_SPEED;
    }
    
    if (fabsf(player->groundSpeed) < PLAYER_RUN_SPEED_MIN) {
        // If the ground speed is less than the minimum run speed, turn on gravity
        player->isGravityApplied = true;
    } else if (fabsf(player->groundSpeed) < PLAYER_SPRINT_SPEED_MIN) {
        // If the ground speed is less than the minimum sprint speed, turn off gravity
        player->isGravityApplied = false;
    } else if (fabsf(player->groundSpeed) < PLAYER_SUPER_SPEED_MIN) {
        // If the ground speed is less than the minimum super speed, turn off gravity
        player->isGravityApplied = false;
    }

    if (((player->groundAngle > SLIP_ANGLE_START) || (player->groundAngle < SLIP_ANGLE_END)) && fabsf(player->groundSpeed) < SLIP_THRESHOLD) {
        // If the player is on a slope and the ground speed is less than the minimum run speed, turn on gravity
        player->isGravityApplied = true;
        player->isOnGround = false; 
        player->groundSpeed = 0;
        player->controlLockTimer = SECONDS_TO_FRAMES(0.5f);
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
        player->controlLockTimer--;
        // The SPG says that the timer will count down while the player is on the ground.
        // Once the timer reaches 0, the player will be able to move again.
    }

    // So what's next?
    // Ground Physics
    // Check if the player is on the ground
    if (player->isOnGround) {
        // Apply friction to the player's horizontal velocity
        if (xVel > MIN_SPEED_THRESHOLD) {
            xVel -= FRICTION_SPEED;
            if (xVel < 0) {
                xVel = 0;
            }
        } else if (xVel < -MIN_SPEED_THRESHOLD) {
            xVel += FRICTION_SPEED;
            if (xVel > 0) {
                xVel = 0;
            }
        }

        if (player->isSuper) {
            if (player->inputLeft && player->controlLockTimer == 0 && !player->isRolling) {
                player->groundSpeed -= SUPER_ACCELERATION_SPEED;
            } else if (player->inputRight && player->controlLockTimer == 0 && !player->isRolling) {
                player->groundSpeed += SUPER_ACCELERATION_SPEED;
            }
            // Clamp the ground speed to the maximum allowed speed
            if (player->groundSpeed > SUPER_TOP_SPEED) {
                player->groundSpeed = SUPER_TOP_SPEED;
            } else if (player->groundSpeed < -SUPER_TOP_SPEED) {
                player->groundSpeed = -SUPER_TOP_SPEED;
            }

            if (noInput && player->controlLockTimer == 0) {
                if (player->groundSpeed > 0) {
                    player->groundSpeed -= SUPER_DECELERATION_SPEED;
                } else if (player->groundSpeed < 0) {
                    player->groundSpeed += SUPER_DECELERATION_SPEED;
                }
            }
        } else {
            // Normal (non-Super) physics
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
                if (player->groundSpeed > MIN_SPEED_THRESHOLD) {
                    player->groundSpeed -= DECELERATION_SPEED;
                    if (player->groundSpeed < 0) player->groundSpeed = 0;
                } else if (player->groundSpeed < -MIN_SPEED_THRESHOLD) {
                    player->groundSpeed += DECELERATION_SPEED;
                    if (player->groundSpeed > 0) player->groundSpeed = 0;
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
    } else {
        // Process air physics here
        // Update velocity based on ground angle when jumping
        if (player->groundAngle != 0 && player->hasJumped) {
            xSpeed += GRAVITY_FORCE * sinf(player->groundAngle);
            yVel += GRAVITY_FORCE * cosf(player->groundAngle);
        } else if (player->hasJumped && player->groundAngle == 0) {
            yVel += GRAVITY_FORCE;
        }

        // Apply air acceleration, deceleration, and friction here now that we are in the air
        float airAccel = player->isSuper ? SUPER_AIR_ACCELERATION_SPEED : AIR_ACCELERATION_SPEED;
        
        if (player->inputRight && player->controlLockTimer == 0) {
            xVel += airAccel;
        } else if (player->inputLeft && player->controlLockTimer == 0) {
            xVel -= airAccel;
        }
        
        // Clamp air velocity
        float maxAirSpeed = player->isSuper ? SUPER_TOP_SPEED : TOP_SPEED;
        if (xVel > maxAirSpeed) {
            xVel = maxAirSpeed;
        } else if (xVel < -maxAirSpeed) {
            xVel = -maxAirSpeed;
        }
    }
    
    // Spindash mechanics
    static bool jumpButtonWasPressed = false;
    static float spindashChargeDecayTimer = 0.0f;
    
    // Start spindash when player is stationary, crouching, and presses jump
    if (fabsf(player->groundSpeed) < MIN_SPEED_THRESHOLD && player->inputDown && player->jumpPressed && !jumpButtonWasPressed && player->isOnGround) {
        player->isSpindashing = true;
        player->isRolling = false; // Stop rolling when starting spindash
    }

    if (player->isSpindashing) {
        // Increment charge on new jump button presses
        if (player->jumpPressed && !jumpButtonWasPressed) {
            if (player->spindashCharge < SPINDASH_MAX_CHARGE) {
                player->spindashCharge++;
            }
            spindashChargeDecayTimer = 0.0f; // Reset decay timer on button press
        }
        
        // Decay charge over time if no button presses
        spindashChargeDecayTimer += dt;
        if (spindashChargeDecayTimer > SPINDASH_CHARGE_DECAY_RATE && player->spindashCharge > 0) {
            player->spindashCharge--;
            spindashChargeDecayTimer = 0.0f;
        }
        
        // Calculate spindash speed based on charge
        float spindashSpeed = SPINDASH_BASE_SPEED + (player->spindashCharge * SPINDASH_SPEED_PER_CHARGE);
        
        // Release spindash when player stops holding down or lets go of crouch
        if (!player->inputDown) {
            player->isRolling = true;
            player->groundSpeed = (player->facing > 0) ? spindashSpeed : -spindashSpeed;
            player->controlLockTimer = SECONDS_TO_FRAMES(SPINDASH_CONTROL_LOCK_TIME);
            player->spindashCharge = 0; // Reset charge after release
            player->isSpindashing = false; // Have this happen last so that the state change is fully processed and that the speed is applied correctly
        }
    } else {
        // Reset spindash charge when not spindashing
        if (player->spindashCharge > 0) {
            player->spindashCharge = 0;
        }
    }
    
    // Update jump button state for next frame
    jumpButtonWasPressed = player->jumpPressed;

    // Update final velocity
    player->velocity.x = xVel;
    player->velocity.y = yVel;
    
    // Update position
    player->position.x += player->velocity.x * dt;
    player->position.y += player->velocity.y * dt;
    
    // State transitions and animation updates would go here
    // TODO: Implement state machine and animation system

}

void PlayerDraw(Player* player) {
    if (!player) return;
    
    // Choose color based on player state
    Color playerColor = BLUE;
    if (player->isSpindashing) {
        playerColor = YELLOW;
    } else if (player->isRolling) {
        playerColor = ORANGE;
    } else if (player->isSuper) {
        playerColor = GOLD;
    } else if (player->isHurt) {
        playerColor = RED;
    }
    
    // Draw player as a circle (placeholder for sprite)
    // Camera2D handles the transformation automatically
    // Make it very visible for now
    Color visColor = (Color){255, 0, 255, 255}; // MAGENTA for high contrast
    DrawCircle((int)player->position.x, (int)player->position.y, 12, visColor);
    
    // Draw hitbox outline for debug
    extern bool isDebugMode;
    if (isDebugMode) {
        DrawRectangleLines(
            (int)(player->position.x - PLAYER_WIDTH_RAD),
            (int)(player->position.y - PLAYER_HEIGHT_RAD),
            PLAYER_WIDTH,
            PLAYER_HEIGHT,
            GREEN
        );
        
        // Draw ground sensors
        DrawCircle((int)player->playerSensors.bottomLeft.x, (int)player->playerSensors.bottomLeft.y, 2, RED);
        DrawCircle((int)player->playerSensors.bottomRight.x, (int)player->playerSensors.bottomRight.y, 2, RED);
    }
}

void PlayerUnload(Player* player) {
    (void)player; // Unused parameter for now
}

void PlayerAssignSensors(Player* player) {
    // Assign sensors based on ground direction
    switch (player->groundDirection) {
        case ANGLE_DOWN:
            player->hitbox = (Hitbox_t){0, 0, PLAYER_WIDTH, PLAYER_HEIGHT};
            player->playerSensors.center = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.left = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.topLeft = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.topRight = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomRight = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            break;
        case ANGLE_RIGHT:
            player->hitbox = (Hitbox_t){0, 0, PLAYER_HEIGHT, PLAYER_WIDTH};
            player->playerSensors.center = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right = (Vector2){player->position.x, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.left = (Vector2){player->position.x, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.topLeft = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.topRight = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.bottomRight = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            break;
        case ANGLE_UP: 
            player->hitbox = (Hitbox_t){0, 0, PLAYER_WIDTH, PLAYER_HEIGHT};
            player->playerSensors.center = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.left = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.topLeft = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.topRight = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomRight = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            break;
        case ANGLE_LEFT:
            player->hitbox = (Hitbox_t){0, 0, PLAYER_HEIGHT, PLAYER_WIDTH};
            player->playerSensors.center = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right = (Vector2){player->position.x, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.left = (Vector2){player->position.x, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.topLeft = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.topRight = (Vector2){player->position.x + PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y + PLAYER_WIDTH_RAD};
            player->playerSensors.bottomRight = (Vector2){player->position.x - PLAYER_HEIGHT_RAD, player->position.y - PLAYER_WIDTH_RAD};
            break;
        default:
            // Default to ANGLE_DOWN if no valid direction
            player->hitbox = (Hitbox_t){0, 0, PLAYER_WIDTH, PLAYER_HEIGHT};
            player->playerSensors.center = (Vector2){player->position.x, player->position.y};
            player->playerSensors.right = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.left = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y};
            player->playerSensors.topLeft = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.topRight = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y + PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomLeft = (Vector2){player->position.x - PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            player->playerSensors.bottomRight = (Vector2){player->position.x + PLAYER_WIDTH_RAD, player->position.y - PLAYER_HEIGHT_RAD};
            break;
    }
}
