// Player Physics System Implementation
// SPG-accurate Sonic physics

#include "player-physics.h"
#include "player-player.h"
#include <stdio.h>
#include <stdlib.h>

// Use raylib's PI constant
#ifndef PI
#define PI 3.14159265358979323846f
#endif

// Convert degrees to radians
#define DEG_TO_RAD(deg) ((deg) * PI / 180.0f)

// Sign function
static inline float signf(float x) {
    return (x > 0.0f) ? 1.0f : ((x < 0.0f) ? -1.0f : 0.0f);
}

// ========== Character-Specific Physics Getters ==========

float GetAcceleration(Player* player) {
    if (player->isSuper) {
        return (player->type == SONIC) ? SONIC_SUPER_ACCELERATION_SPEED : TAILS_SUPER_ACCELERATION_SPEED;
    }
    return (player->type == SONIC) ? SONIC_ACCELERATION_SPEED : TAILS_ACCELERATION_SPEED;
}

float GetDeceleration(Player* player) {
    if (player->isSuper) {
        return (player->type == SONIC) ? SONIC_SUPER_DECELERATION_SPEED : TAILS_SUPER_DECELERATION_SPEED;
    }
    return (player->type == SONIC) ? SONIC_DECELERATION_SPEED : TAILS_DECELERATION_SPEED;
}

float GetFriction(Player* player) {
    if (player->isRolling) {
        return (player->type == SONIC) ? SONIC_ROLLING_FRICTION : TAILS_ROLLING_FRICTION;
    }
    return (player->type == SONIC) ? SONIC_FRICTION_SPEED : TAILS_FRICTION_SPEED;
}

float GetTopSpeed(Player* player) {
    if (player->isSuper) {
        return (player->type == SONIC) ? SONIC_SUPER_TOP_SPEED : TAILS_SUPER_TOP_SPEED;
    }
    return (player->type == SONIC) ? (float)SONIC_TOP_SPEED : (float)TAILS_TOP_SPEED;
}

float GetGravity(Player* player) {
    if (player->isRolling && player->isOnGround) {
        return (player->type == SONIC) ? SONIC_ROLLING_GRAVITY_FORCE : TAILS_ROLLING_GRAVITY_FORCE;
    }
    return (player->type == SONIC) ? SONIC_GRAVITY_FORCE : TAILS_GRAVITY_FORCE;
}

float GetJumpForce(Player* player) {
    return (player->type == SONIC) ? SONIC_INITIAL_JUMP_VELOCITY : TAILS_JUMP_FORCE;
}

float GetAirAcceleration(Player* player) {
    if (player->isSuper) {
        return (player->type == SONIC) ? SONIC_SUPER_AIR_ACCELERATION_SPEED : TAILS_SUPER_AIR_ACCELERATION_SPEED;
    }
    return (player->type == SONIC) ? SONIC_AIR_ACCELERATION_SPEED : TAILS_AIR_ACCELERATION_SPEED;
}

float GetSlopeFactorForState(Player* player) {
    if (!player->isRolling) {
        return (player->type == SONIC) ? SONIC_SLOPE_FACTOR_NORMAL : TAILS_SLOPE_FACTOR_NORMAL;
    }

    // Rolling - check if going uphill or downhill
    float sinAngle = sinf(DEG_TO_RAD(player->groundAngle));

    // If sign of groundSpeed equals sign of sin(angle), going uphill
    if (signf(player->groundSpeed) == signf(sinAngle)) {
        return (player->type == SONIC) ? SONIC_SLOPE_FACTOR_ROLLUP : TAILS_SLOPE_FACTOR_ROLLUP;
    } else {
        return (player->type == SONIC) ? SONIC_SLOPE_FACTOR_ROLLDOWN : TAILS_SLOPE_FACTOR_ROLLDOWN;
    }
}

// ========== Air Direction ==========

AirDirection GetAirDirection(float xSpeed, float ySpeed) {
    // Determine primary movement direction
    float absX = fabsf(xSpeed);
    float absY = fabsf(ySpeed);

    if (absX >= absY) {
        return (xSpeed >= 0) ? AIR_MOSTLY_RIGHT : AIR_MOSTLY_LEFT;
    } else {
        return (ySpeed >= 0) ? AIR_MOSTLY_DOWN : AIR_MOSTLY_UP;
    }
}

bool IsPushSensorActive(Player* player, bool isRightSensor) {
    // Push sensors only active in certain angle ranges when grounded
    if (player->isOnGround) {
        float angle = player->groundAngle;
        // Normalize
        while (angle < 0) angle += 360.0f;
        while (angle >= 360) angle -= 360.0f;

        // Only active in floor-ish ranges (-90 to 90 degrees)
        if (!(angle <= 90.0f || angle >= 270.0f)) {
            return false;
        }

        // Only active when moving in that direction
        if (isRightSensor) {
            return player->groundSpeed > 0;
        } else {
            return player->groundSpeed < 0;
        }
    }

    // In air - active based on movement direction
    AirDirection airDir = GetAirDirection(player->velocity.x, player->velocity.y);

    if (isRightSensor) {
        return (airDir == AIR_MOSTLY_RIGHT || airDir == AIR_MOSTLY_UP || airDir == AIR_MOSTLY_DOWN);
    } else {
        return (airDir == AIR_MOSTLY_LEFT || airDir == AIR_MOSTLY_UP || airDir == AIR_MOSTLY_DOWN);
    }
}

// ========== Slope Factor ==========

void ApplySlopeFactor(Player* player) {
    // Only apply slope factor when grounded and not in ceiling mode
    if (!player->isOnGround) return;

    CollisionMode mode = GetCollisionModeFromAngle(player->groundAngle);
    if (mode == MODE_CEILING) return;

    // Sonic 3 behavior: don't apply if stopped and slope factor is small
    float slopeFactor = GetSlopeFactorForState(player);
    if (player->groundSpeed == 0.0f && slopeFactor < 0.05078125f) {
        return;
    }

    // Apply: groundSpeed -= slopeFactor * sin(groundAngle)
    float sinAngle = sinf(DEG_TO_RAD(player->groundAngle));
    player->groundSpeed -= slopeFactor * sinAngle;
}

// ========== Ground Movement ==========

void UpdateGroundMovement(Player* player) {
    if (!player->isOnGround) return;

    // Skip if control locked
    if (player->controlLockTimer > 0) {
        player->controlLockTimer--;
        // Still apply friction
        float friction = GetFriction(player);
        if (player->groundSpeed > 0) {
            player->groundSpeed -= friction;
            if (player->groundSpeed < 0) player->groundSpeed = 0;
        } else if (player->groundSpeed < 0) {
            player->groundSpeed += friction;
            if (player->groundSpeed > 0) player->groundSpeed = 0;
        }
        return;
    }

    float accel = GetAcceleration(player);
    float decel = GetDeceleration(player);
    float friction = GetFriction(player);
    float topSpeed = GetTopSpeed(player);

    // Handle rolling differently
    if (player->isRolling) {
        // Rolling - only deceleration applies, no acceleration
        if (player->inputRight && player->groundSpeed < 0) {
            player->groundSpeed += decel;
            if (player->groundSpeed > 0) player->groundSpeed = 0;
        } else if (player->inputLeft && player->groundSpeed > 0) {
            player->groundSpeed -= decel;
            if (player->groundSpeed < 0) player->groundSpeed = 0;
        }

        // Rolling friction
        if (player->groundSpeed > 0) {
            player->groundSpeed -= friction;
            if (player->groundSpeed < 0) player->groundSpeed = 0;
        } else if (player->groundSpeed < 0) {
            player->groundSpeed += friction;
            if (player->groundSpeed > 0) player->groundSpeed = 0;
        }

        // Unroll if too slow
        if (fabsf(player->groundSpeed) < 0.5f) {
            player->isRolling = false;
        }
        return;
    }

    // Normal ground movement
    if (player->inputLeft) {
        if (player->groundSpeed > 0) {
            // Skidding
            player->groundSpeed -= decel;
            if (player->groundSpeed <= 0) {
                player->groundSpeed = -0.5f;  // Small push in new direction
            }
        } else if (player->groundSpeed > -topSpeed) {
            // Accelerating left
            player->groundSpeed -= accel;
            if (player->groundSpeed < -topSpeed) {
                player->groundSpeed = -topSpeed;
            }
        }
        player->facing = -1;
    } else if (player->inputRight) {
        if (player->groundSpeed < 0) {
            // Skidding
            player->groundSpeed += decel;
            if (player->groundSpeed >= 0) {
                player->groundSpeed = 0.5f;
            }
        } else if (player->groundSpeed < topSpeed) {
            // Accelerating right
            player->groundSpeed += accel;
            if (player->groundSpeed > topSpeed) {
                player->groundSpeed = topSpeed;
            }
        }
        player->facing = 1;
    } else {
        // No input - apply friction
        if (player->groundSpeed > 0) {
            player->groundSpeed -= friction;
            if (player->groundSpeed < 0) player->groundSpeed = 0;
        } else if (player->groundSpeed < 0) {
            player->groundSpeed += friction;
            if (player->groundSpeed > 0) player->groundSpeed = 0;
        }
    }
}

// ========== Slip/Fall Check (Sonic 3 Method) ==========

void CheckSlipFall(Player* player) {
    if (!player->isOnGround) return;
    if (player->controlLockTimer > 0) return;

    float angle = player->groundAngle;
    // Normalize
    while (angle < 0) angle += 360.0f;
    while (angle >= 360) angle -= 360.0f;

    // Check if on a slope steep enough to slip
    bool inSlipRange = (angle >= SLIP_ANGLE_START_DEG && angle <= SLIP_ANGLE_END_DEG);
    if (!inSlipRange) return;

    // Check if moving slow enough to slip
    if (fabsf(player->groundSpeed) >= SLIP_SPEED_THRESHOLD) return;

    // We should slip!
    player->controlLockTimer = CONTROL_LOCK_FRAMES;

    // Check if steep enough to fall off completely
    bool inFallRange = (angle >= FALL_ANGLE_START_DEG && angle <= FALL_ANGLE_END_DEG);

    if (inFallRange) {
        // Fall off the surface
        player->isOnGround = false;
    } else {
        // Just slip down - add 0.5 to groundSpeed in direction of slope
        if (angle < 180.0f) {
            player->groundSpeed -= 0.5f;
        } else {
            player->groundSpeed += 0.5f;
        }
    }
}

// ========== Velocity Conversion ==========

void ConvertGroundSpeedToVelocity(Player* player) {
    // Convert groundSpeed to xSpeed and ySpeed based on groundAngle
    float radAngle = DEG_TO_RAD(player->groundAngle);

    player->velocity.x = player->groundSpeed * cosf(radAngle);
    player->velocity.y = player->groundSpeed * -sinf(radAngle);
}

// ========== Air Movement ==========

void UpdateAirMovement(Player* player) {
    if (player->isOnGround) return;

    float airAccel = GetAirAcceleration(player);
    float topSpeed = GetTopSpeed(player);

    // Air control
    if (player->inputLeft) {
        if (player->velocity.x > -topSpeed) {
            player->velocity.x -= airAccel;
        }
        player->facing = -1;
    } else if (player->inputRight) {
        if (player->velocity.x < topSpeed) {
            player->velocity.x += airAccel;
        }
        player->facing = 1;
    }
}

void ApplyGravity(Player* player) {
    if (player->isOnGround) return;

    float gravity = GetGravity(player);
    player->velocity.y += gravity;

    // Cap falling speed
    float topYSpeed = (player->type == SONIC) ? (float)SONIC_TOP_Y_SPEED : (float)TAILS_TOP_Y_SPEED;
    if (player->velocity.y > topYSpeed) {
        player->velocity.y = topYSpeed;
    }
}

void ApplyAirDrag(Player* player) {
    if (player->isOnGround) return;

    // Air drag only applies when moving upward and fast horizontally
    if (player->velocity.y < 0 && player->velocity.y > -4.0f) {
        float drag = (player->type == SONIC) ? SONIC_AIR_DRAG_FORCE : TAILS_AIR_DRAG_FORCE;

        // Only apply if moving fast enough horizontally
        if (fabsf(player->velocity.x) >= 0.125f) {
            player->velocity.x -= (player->velocity.x * drag) / 256.0f;
        }
    }
}

// ========== Jump ==========

void PlayerJump(Player* player) {
    if (!player->isOnGround) return;

    // Check for low ceiling before jumping
    // (We skip this check for now - can add later)

    player->isOnGround = false;
    player->isJumping = true;
    player->hasJumped = true;

    // Jump velocity is added perpendicular to current ground angle
    float jumpForce = GetJumpForce(player);
    float radAngle = DEG_TO_RAD(player->groundAngle);

    // First convert current ground speed to velocity
    ConvertGroundSpeedToVelocity(player);

    // Then add jump force perpendicular to ground
    player->velocity.x -= jumpForce * sinf(radAngle);
    player->velocity.y += jumpForce * cosf(radAngle);  // Note: positive because jump force is negative
}

// ========== Landing ==========

float CalculateLandingGroundSpeed(Player* player, float landAngle) {
    // Normalize angle
    while (landAngle < 0) landAngle += 360.0f;
    while (landAngle >= 360) landAngle -= 360.0f;

    float xSpeed = player->velocity.x;
    float ySpeed = player->velocity.y;

    // Determine air direction
    AirDirection airDir = GetAirDirection(xSpeed, ySpeed);
    bool movingHorizontal = (airDir == AIR_MOSTLY_LEFT || airDir == AIR_MOSTLY_RIGHT);

    // Flat range: 0-23 and 339-360
    if ((landAngle >= 0 && landAngle <= 23) || (landAngle >= 339 && landAngle < 360)) {
        return xSpeed;
    }

    // Slope range: 0-45 and 316-360
    if ((landAngle >= 0 && landAngle <= 45) || (landAngle >= 316 && landAngle < 360)) {
        if (movingHorizontal) {
            return xSpeed;
        } else {
            float sinAngle = sinf(DEG_TO_RAD(landAngle));
            return ySpeed * 0.5f * -signf(sinAngle);
        }
    }

    // Steep range: 45-75 (and mirrored 285-315)
    if ((landAngle > 45 && landAngle <= 75) || (landAngle >= 285 && landAngle < 316)) {
        if (movingHorizontal) {
            return xSpeed;
        } else {
            float sinAngle = sinf(DEG_TO_RAD(landAngle));
            return ySpeed * -signf(sinAngle);
        }
    }

    // Very steep (wall-like) - just use ySpeed
    float sinAngle = sinf(DEG_TO_RAD(landAngle));
    return ySpeed * -signf(sinAngle);
}

void PlayerLand(Player* player, float landAngle) {
    player->isOnGround = true;
    player->isJumping = false;
    player->isFalling = false;
    player->groundAngle = landAngle;

    // Calculate new ground speed from velocity
    player->groundSpeed = CalculateLandingGroundSpeed(player, landAngle);
}

// ========== Collision Handling ==========

void HandleGroundCollision(Player* player, const LevelCollision* level) {
    CollisionMode mode = GetCollisionModeFromAngle(player->groundAngle);

    float widthRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_WIDTH_RAD : (float)TAILS_PLAYER_WIDTH_RAD;
    float heightRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_HEIGHT_RAD : (float)TAILS_PLAYER_HEIGHT_RAD;

    // Smaller when rolling/jumping
    if (player->isRolling || player->isJumping) {
        widthRadius = 7.0f;
        heightRadius = 14.0f;
    }

    SensorResult sensorA, sensorB;
    SensorResult winner = CastGroundSensors(
        player->position.x, player->position.y,
        widthRadius, heightRadius,
        mode, level,
        &sensorA, &sensorB
    );

    if (!winner.found) {
        // No ground found - become airborne
        if (!sensorA.found && !sensorB.found) {
            player->isOnGround = false;
        }
        return;
    }

    // Check distance limits
    // Dynamic limit based on speed (Sonic 2+ behavior)
    float speedFactor = fabsf(player->groundSpeed);
    float maxDistance = fminf(speedFactor + 4.0f, GROUND_SENSOR_MAX_DISTANCE);

    if (winner.distance > maxDistance || winner.distance < GROUND_SENSOR_MIN_DISTANCE) {
        // Too far - don't snap
        if (winner.distance < GROUND_SENSOR_MIN_DISTANCE) {
            // Inside ground too far - push out anyway
            // This handles being pushed into ground
        } else {
            return;
        }
    }

    // Snap to ground based on mode
    switch (mode) {
        case MODE_FLOOR:
            player->position.y += winner.distance;
            break;
        case MODE_RIGHT_WALL:
            player->position.x += winner.distance;
            break;
        case MODE_CEILING:
            player->position.y -= winner.distance;
            break;
        case MODE_LEFT_WALL:
            player->position.x -= winner.distance;
            break;
    }

    // Update ground angle
    if (winner.flagged) {
        // Flagged tile - snap angle to nearest 90
        player->groundAngle = SnapAngleToCardinal(player->groundAngle);
    } else {
        // Check for large angle difference (Sonic 2+ behavior)
        float angleDiff = fabsf(player->groundAngle - winner.angle);
        if (angleDiff > 180.0f) angleDiff = 360.0f - angleDiff;

        if (angleDiff > 45.0f) {
            // Large difference - snap to cardinal
            player->groundAngle = SnapAngleToCardinal(player->groundAngle);
        } else {
            player->groundAngle = winner.angle;
        }
    }
}

void HandleAirCollision(Player* player, const LevelCollision* level) {
    float widthRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_WIDTH_RAD : (float)TAILS_PLAYER_WIDTH_RAD;
    float heightRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_HEIGHT_RAD : (float)TAILS_PLAYER_HEIGHT_RAD;

    // Smaller when rolling/jumping
    if (player->isRolling || player->isJumping) {
        widthRadius = 7.0f;
        heightRadius = 14.0f;
    }

    AirDirection airDir = GetAirDirection(player->velocity.x, player->velocity.y);

    // Ground sensors (when moving down or horizontal)
    if (airDir == AIR_MOSTLY_DOWN || airDir == AIR_MOSTLY_LEFT || airDir == AIR_MOSTLY_RIGHT) {
        SensorResult sensorA, sensorB;
        SensorResult groundWinner = CastGroundSensors(
            player->position.x, player->position.y,
            widthRadius, heightRadius,
            MODE_FLOOR, level,  // Air collision always uses floor mode for ground sensors
            &sensorA, &sensorB
        );

        if (groundWinner.found && groundWinner.distance <= 0) {
            // Check landing conditions
            bool canLand = false;

            if (airDir == AIR_MOSTLY_DOWN) {
                // Must be within ySpeed + 8 distance
                if (groundWinner.distance >= -(player->velocity.y + 8.0f)) {
                    canLand = true;
                }
            } else {
                // Moving horizontally - can land if ySpeed >= 0
                if (player->velocity.y >= 0) {
                    canLand = true;
                }
            }

            if (canLand) {
                // Snap to ground and land
                player->position.y += groundWinner.distance;
                PlayerLand(player, groundWinner.angle);
                return;
            }
        }
    }

    // Ceiling sensors (when moving up)
    if (airDir == AIR_MOSTLY_UP || airDir == AIR_MOSTLY_LEFT || airDir == AIR_MOSTLY_RIGHT) {
        SensorResult sensorC, sensorD;
        SensorResult ceilingWinner = CastCeilingSensors(
            player->position.x, player->position.y,
            widthRadius, heightRadius,
            MODE_FLOOR, level,
            &sensorC, &sensorD
        );

        if (ceilingWinner.found && ceilingWinner.distance <= 0) {
            // Hit ceiling
            player->position.y -= ceilingWinner.distance;

            // Check if we can land on it (steep enough)
            float angle = ceilingWinner.angle;
            while (angle < 0) angle += 360.0f;
            while (angle >= 360) angle -= 360.0f;

            // Flat ceiling range: 91-225 degrees - can't land
            bool isFlatCeiling = (angle >= 91 && angle <= 225);

            if (!isFlatCeiling && airDir == AIR_MOSTLY_UP) {
                // Can land on steep ceiling
                float sinAngle = sinf(DEG_TO_RAD(angle));
                player->groundSpeed = player->velocity.y * -signf(sinAngle);
                player->groundAngle = angle;
                player->isOnGround = true;
                player->isJumping = false;
            } else {
                // Just bump head
                player->velocity.y = 0;
            }
        }
    }
}

void HandleWallCollision(Player* player, const LevelCollision* level) {
    float heightRadius = (player->type == SONIC) ? (float)SONIC_PLAYER_HEIGHT_RAD : (float)TAILS_PLAYER_HEIGHT_RAD;

    if (player->isRolling || player->isJumping) {
        heightRadius = 14.0f;
    }

    CollisionMode mode = player->isOnGround ?
        GetPushSensorModeFromAngle(player->groundAngle) : MODE_FLOOR;

    // Right push sensor (F)
    if (IsPushSensorActive(player, true)) {
        SensorResult sensorF = CastPushSensorF(
            player->position.x, player->position.y,
            PUSH_RADIUS, heightRadius,
            mode, player->groundAngle, level
        );

        if (sensorF.found && sensorF.distance < 0) {
            // Inside wall - push out
            if (player->isOnGround) {
                // Grounded - adjust speed to stop at wall
                player->velocity.x += sensorF.distance;
                if (player->groundSpeed > 0) {
                    player->groundSpeed = 0;
                }
            } else {
                // Airborne - directly adjust position
                player->position.x += sensorF.distance;
                if (player->velocity.x > 0) {
                    player->velocity.x = 0;
                }
            }
        }
    }

    // Left push sensor (E)
    if (IsPushSensorActive(player, false)) {
        SensorResult sensorE = CastPushSensorE(
            player->position.x, player->position.y,
            PUSH_RADIUS, heightRadius,
            mode, player->groundAngle, level
        );

        if (sensorE.found && sensorE.distance < 0) {
            // Inside wall - push out
            if (player->isOnGround) {
                player->velocity.x -= sensorE.distance;
                if (player->groundSpeed < 0) {
                    player->groundSpeed = 0;
                }
            } else {
                player->position.x -= sensorE.distance;
                if (player->velocity.x < 0) {
                    player->velocity.x = 0;
                }
            }
        }
    }
}

// ========== Main Physics Update ==========

void UpdatePlayerPhysics(Player* player, const LevelCollision* level) {
    if (player->isOnGround) {
        // === GROUNDED PHYSICS ===

        // 1. Apply slope factor
        ApplySlopeFactor(player);

        // 2. Handle input / update ground speed
        UpdateGroundMovement(player);

        // 3. Check for slip/fall
        CheckSlipFall(player);

        // 4. Handle jump input
        if (player->jumpPressed && !player->hasJumped) {
            PlayerJump(player);
        }

        // 5. Convert ground speed to velocity
        if (player->isOnGround) {  // May have changed from jump
            ConvertGroundSpeedToVelocity(player);
        }

        // 6. Wall collision (before movement, per SPG)
        HandleWallCollision(player, level);

        // 7. Move
        player->position.x += player->velocity.x;
        player->position.y += player->velocity.y;

        // 8. Ground collision (after movement)
        HandleGroundCollision(player, level);

    } else {
        // === AIRBORNE PHYSICS ===

        // 1. Air movement (horizontal control)
        UpdateAirMovement(player);

        // 2. Apply gravity
        ApplyGravity(player);

        // 3. Apply air drag
        ApplyAirDrag(player);

        // 4. Variable jump height (release jump button early)
        if (player->isJumping && !player->jumpPressed && player->velocity.y < -4.0f) {
            player->velocity.y = -4.0f;
        }

        // 5. Move
        player->position.x += player->velocity.x;
        player->position.y += player->velocity.y;

        // 6. Collision detection
        HandleWallCollision(player, level);
        HandleAirCollision(player, level);
    }

    // Update player rotation for visual
    // Smoothly interpolate towards ground angle when grounded
    if (player->isOnGround) {
        float targetRotation = player->groundAngle;
        float diff = targetRotation - player->playerRotation;

        // Normalize difference
        while (diff > 180.0f) diff -= 360.0f;
        while (diff < -180.0f) diff += 360.0f;

        // Smooth interpolation
        player->playerRotation += diff * 0.25f;
    } else {
        // In air, slowly rotate back to 0
        player->playerRotation *= 0.9f;
    }

    // Normalize rotation
    while (player->playerRotation < 0) player->playerRotation += 360.0f;
    while (player->playerRotation >= 360) player->playerRotation -= 360.0f;
}
