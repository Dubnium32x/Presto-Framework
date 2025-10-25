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
//ᏥᏌ ᎦᎶᏁᏛ, here we go again... - Birb64

#include "player.h"
#include "raylib.h"
#include "var.h"
#include "../../world/tile_collision.h"

static void PlayerAssignSensors(Player* player);
static void PlayerUpdate(Player* player, float dt);
static void PlayerDraw(Player* player);
static void PlayerUnload(Player* player);

// 😄 Hey! would you look at that! Now this is useful
#define JUMP_BUTTON KEY_Z | KEY_X | KEY_C | BUTTON_A | BUTTON_B | BUTTON_X

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

    if (IsKeyDown(JUMP_BUTTON)) {
        player->jumpPressed = true;
    } else {
        player->jumpPressed = false;
    }

    bool noInput = false;
    if (!player->inputLeft && !player->inputRight && !player->inputUp && !player->inputDown) {
        noInput = true;
    }

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
    if (noInput && ((player->groundAngle > 253) || (player->groundAngle < 3)) && (player->groundSpeed < fabsf(0.1f))) {
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
        if (!player->isSuper) {
            if (player->facing == 1 && player->inputRight) {
                xVel += AIR_ACCELERATION_SPEED;
            } else if (player->facing == -1 && player->inputLeft) {
                xVel -= AIR_ACCELERATION_SPEED;
            } else if (player->facing == 1 && player->inputLeft) {
                xVel -= AIR_ACCELERATION_SPEED;
            } else if (player->facing == -1 && player->inputRight) {
                xVel += AIR_ACCELERATION_SPEED;
            }

        }
    }

}

void Player_Draw(Player* player) {
    DrawCircleV(player->position, 10, RED); // Placeholder for player drawing
}

static void PlayerUnload(Player* player) {
    // Unload player resources here
}

