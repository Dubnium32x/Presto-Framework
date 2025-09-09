module entity.player.player_new;

import raylib;
import std.stdio;
import std.string;
import std.file;
import std.json;
import std.traits : EnumMembers;
import std.array;
import std.conv : to;
import std.exception;
import std.math : abs, ceil, floor, cos, sin, sqrt, atan2;

import entity.sprite_object;
import entity.player.var;
import utils.level_loader;
import world.tile_collision;
import world.tileset_map;
import entity.player.animations;
import sprite.sprite_manager;
import sprite.animation_manager;
import utils.spritesheet_splitter;
import world.input_manager;

enum PlayerState {
    IDLE,
    WALKING,
    RUNNING,
    DASHING,
    JUMPING,
    FALLING,
    ROLLING,
    FALLING_ROLLING,
    SPINDASHING,
    PEELINGOUT,
    FLYING,
    GLIDING,
    CLIMBING,
    SWIMMING,
    MONKEYBARS,
    SPINNINGONFAN,
    WALLJUMPING,
    SLIDING,
    HURT,
    DEAD
}

struct PlayerNew {
    // Core components
    SpriteObject sprite;
    PlayerState state;
    PlayerVariables vars;
    PlayerAnimations animations;
    LevelData* level = null;
    
    // Debug flags
    bool dbgDrawCollisions = true;
    bool dbgSlopeDebug = false;
    
    // Debug visualization
    Vector2[] dbgGroundSamples;
    Vector2[] dbgSideSamples;
    Vector2 dbgCandidatePos;
    bool dbgCandidateValid = false;

    // Constructor
    static PlayerNew create(float x, float y) {
        PlayerNew player;
        player.sprite = SpriteObject();
        player.state = PlayerState.IDLE;
        player.vars = PlayerVariables();
        player.vars.resetPosition(x, y);
        return player;
    }

    void setLevel(LevelData* lvl) {
        this.level = lvl;
    }

    void initialize(float x, float y) {
        vars = PlayerVariables();
        vars.resetPosition(x, y);

        sprite.x = x;
        sprite.y = y;
        sprite.width = cast(int)(vars.widthRadius);
        sprite.height = cast(int)(vars.heightRadius);
        sprite.setScale(1.0f);

        animations = new PlayerAnimations();
        import std.string : toStringz;
        Texture2D playerTex = LoadTexture("resources/image/spritesheet/Sonic_spritemap.png".toStringz);
        animations.setTexture(playerTex);
        import sprite.sprite_manager;
        SpriteManager.getInstance().loadSprite("Sonic", "resources/image/spritesheet/Sonic_spritemap.png", 64, 64);
        animations.setPlayerAnimationState(PlayerAnimationState.IDLE);

        writeln("PlayerNew initialized at position: (", x, ", ", y, ")");
    }

    void updateInput() {
        bool prevJump = vars.keyJump;

        vars.keyLeft = IsKeyDown(KeyboardKey.KEY_LEFT) || IsKeyDown(KeyboardKey.KEY_A);
        vars.keyRight = IsKeyDown(KeyboardKey.KEY_RIGHT) || IsKeyDown(KeyboardKey.KEY_D);
        vars.keyUp = IsKeyDown(KeyboardKey.KEY_UP) || IsKeyDown(KeyboardKey.KEY_W);
        vars.keyDown = IsKeyDown(KeyboardKey.KEY_DOWN) || IsKeyDown(KeyboardKey.KEY_S);
        vars.keyJump = IsKeyDown(KeyboardKey.KEY_SPACE) || IsKeyDown(KeyboardKey.KEY_Z);

        vars.keyJumpPressed = vars.keyJump && !prevJump;
        vars.keyJumpReleased = !vars.keyJump && prevJump;
        
        if (IsKeyPressed(KeyboardKey.KEY_O)) dbgDrawCollisions = !dbgDrawCollisions;
        if (IsKeyPressed(KeyboardKey.KEY_P)) dbgSlopeDebug = !dbgSlopeDebug;
    }

    void update(float deltaTime) {
        updateInput();
        updatePhysics(deltaTime);
        updateState();
        updateAnimation(deltaTime);
        updateSpritePosition();
    }

    void updatePhysics(float deltaTime) {
        if (vars.controlLockTimer > 0) {
            vars.controlLockTimer--;
        }

        if (vars.isGrounded) {
            updateGroundPhysics();
        } else {
            updateAirPhysics();
        }

        // Apply gravity if airborne
        if (!vars.isGrounded) {
            vars.ySpeed += vars.GRAVITY_FORCE;
            if (vars.ySpeed > vars.TOP_Y_SPEED) {
                vars.ySpeed = vars.TOP_Y_SPEED;
            }
        }

        // Move horizontally first
        vars.xPosition += vars.xSpeed;
        
        // Then move vertically
        vars.yPosition += vars.ySpeed;

        // Check for ground collision after all movement
        checkGroundCollision();
        
        // Check for wall collision
        checkWallCollision();
    }

    void updateGroundPhysics() {
        if (vars.controlLockTimer > 0) {
            return;
        }

        float accel = vars.isSuperSonic ? vars.SUPER_ACCELERATION_SPEED : vars.ACCELERATION_SPEED;
        float decel = vars.isSuperSonic ? vars.SUPER_DECELERATION_SPEED : vars.DECELERATION_SPEED;
        float topSpeed = vars.isSuperSonic ? vars.SUPER_TOP_SPEED : vars.TOP_SPEED;
        float friction = vars.FRICTION_SPEED;

        if (vars.isRolling) {
            updateRollingPhysics();
            return;
        }

        // Handle input
        if (vars.keyLeft && !vars.keyRight) {
            if (vars.groundSpeed > 0) {
                vars.groundSpeed -= decel;
                if (vars.groundSpeed <= 0) {
                    vars.groundSpeed = -0.5f;
                }
            } else if (vars.groundSpeed > -topSpeed) {
                vars.groundSpeed -= accel;
                if (vars.groundSpeed <= -topSpeed) {
                    vars.groundSpeed = -topSpeed;
                }
            }
            vars.setFacing(-1);
        } else if (vars.keyRight && !vars.keyLeft) {
            if (vars.groundSpeed < 0) {
                vars.groundSpeed += decel;
                if (vars.groundSpeed >= 0) {
                    vars.groundSpeed = 0.5f;
                }
            } else if (vars.groundSpeed < topSpeed) {
                vars.groundSpeed += accel;
                if (vars.groundSpeed >= topSpeed) {
                    vars.groundSpeed = topSpeed;
                }
            }
            vars.setFacing(1);
        } else {
            // Apply friction
            if (vars.groundSpeed > 0) {
                vars.groundSpeed -= (vars.groundSpeed > friction) ? friction : vars.groundSpeed;
            } else if (vars.groundSpeed < 0) {
                vars.groundSpeed += (vars.groundSpeed < -friction) ? friction : -vars.groundSpeed;
            }
        }

        // Debug before slope factor
        float preGS = vars.groundSpeed;
        
        // Apply slope factor
        vars.applySlopeFactor();
        
        // Debug after slope factor
        if (dbgSlopeDebug && abs(vars.groundAngle) > 0.1f) {
            writeln("SlopeDbg: angle=", vars.groundAngle, " preGS=", preGS, " postGS=", vars.groundSpeed);
        }

        // Check for slipping
        if (vars.shouldSlipOnSlope()) {
            vars.isGrounded = false;
            vars.groundSpeed = 0;
            vars.controlLockTimer = 30;
            writeln("SLIPPING on angle ", vars.groundAngle);
        }

        // Convert ground speed to X/Y speeds
        convertGroundSpeedToXY();

        // Handle jumping
        if (vars.keyJumpPressed) {
            vars.ySpeed = vars.INITIAL_JUMP_VELOCITY;
            vars.isGrounded = false;
            // Keep current xSpeed as-is when jumping
            writeln("JUMPING: xSpeed=", vars.xSpeed, " ySpeed=", vars.ySpeed);
        }
    }

    void updateAirPhysics() {
        float airAccel = vars.isSuperSonic ? vars.SUPER_AIR_ACCELERATION : vars.AIR_ACCELERATION_SPEED;
        float topSpeed = vars.isSuperSonic ? vars.SUPER_TOP_SPEED : vars.TOP_SPEED;

        if (vars.keyLeft && !vars.keyRight) {
            vars.xSpeed -= airAccel;
            if (vars.xSpeed < -topSpeed) {
                vars.xSpeed = -topSpeed;
            }
            vars.setFacing(-1);
        } else if (vars.keyRight && !vars.keyLeft) {
            vars.xSpeed += airAccel;
            if (vars.xSpeed > topSpeed) {
                vars.xSpeed = topSpeed;
            }
            vars.setFacing(1);
        }

        if (vars.keyJumpReleased && vars.ySpeed < vars.RELEASE_JUMP_VELOCITY) {
            vars.ySpeed = vars.RELEASE_JUMP_VELOCITY;
        }

        if (vars.ySpeed < -4.0f) {
            vars.xSpeed *= 0.96875f;
        }
    }

    void updateRollingPhysics() {
        float friction = vars.ROLLING_FRICTION;

        if (vars.groundSpeed > 0) {
            vars.groundSpeed -= (vars.groundSpeed > friction) ? friction : vars.groundSpeed;
        } else if (vars.groundSpeed < 0) {
            vars.groundSpeed += (vars.groundSpeed < -friction) ? friction : -vars.groundSpeed;
        }

        if (abs(vars.groundSpeed) < 0.5f) {
            vars.isRolling = false;
        }

        vars.applySlopeFactor();
        convertGroundSpeedToXY();
    }

    // SPG-style ground collision detection
    void checkGroundCollision() {
        if (level is null) return;

        dbgGroundSamples = [];
        
        // Define sensor positions (SPG style) - more inward to avoid corners
        float leftSensorX = vars.xPosition - vars.widthRadius + 4.0f;
        float rightSensorX = vars.xPosition + vars.widthRadius - 4.0f;
        float sensorY = vars.yPosition + vars.heightRadius;

        // Check both sensors
        float leftDistance = getSensorDistance(leftSensorX, sensorY, 0, 1); // Down
        float rightDistance = getSensorDistance(rightSensorX, sensorY, 0, 1); // Down
        
        dbgGroundSamples ~= Vector2(leftSensorX, sensorY + leftDistance);
        dbgGroundSamples ~= Vector2(rightSensorX, sensorY + rightDistance);

        // Determine if we should be grounded
        float maxSensorDist = 20.0f; // Maximum sensor range
        bool leftHit = leftDistance < maxSensorDist;
        bool rightHit = rightDistance < maxSensorDist;

        if (leftHit || rightHit) {
            // Choose the closest surface (smallest distance = highest surface)
            float chosenDistance = leftHit ? leftDistance : rightDistance;
            float chosenX = leftHit ? leftSensorX : rightSensorX;
            
            // If both hit, choose the one that's closer (higher surface)
            if (leftHit && rightHit) {
                if (leftDistance < rightDistance) {
                    chosenDistance = leftDistance;
                    chosenX = leftSensorX;
                } else {
                    chosenDistance = rightDistance;
                    chosenX = rightSensorX;
                }
            }

            // Calculate new position - ensure we don't sink into ground
            float surfaceY = sensorY + chosenDistance;
            float newY = surfaceY - vars.heightRadius;
            
            // Only land if we're moving downward/stationary or already grounded
            if (vars.ySpeed >= -1.0f || vars.isGrounded) {
                if (!vars.isGrounded) {
                    // Landing
                    vars.isGrounded = true;
                    vars.yPosition = newY;
                    vars.ySpeed = 0.0f; // Stop downward movement
                    
                    // Get ground angle at landing point
                    vars.groundAngle = getGroundAngleAtPoint(chosenX, surfaceY);
                    
                    // Convert air velocity to ground velocity
                    convertXYToGroundSpeed();
                    
                    writeln("LANDING at angle ", vars.groundAngle, " groundSpeed=", vars.groundSpeed);
                } else {
                    // Already grounded, adjust position to stay on surface
                    if (newY < vars.yPosition + 4.0f) { // Don't snap down too far
                        vars.yPosition = newY;
                    }
                }
            }
        } else {
            // No ground found within sensor range
            if (vars.isGrounded) {
                vars.isGrounded = false;
                writeln("LEAVING GROUND");
            }
        }
    }

    void checkWallCollision() {
        if (level is null) return;
        
        dbgSideSamples = [];
        
        // Check left and right sensors
        float topY = vars.yPosition - vars.heightRadius + 4.0f;
        float bottomY = vars.yPosition + vars.heightRadius - 4.0f;
        float midY = (topY + bottomY) * 0.5f;
        
        if (vars.xSpeed < 0) {
            // Moving left, check left wall
            float leftX = vars.xPosition - vars.widthRadius;
            float dist = getSensorDistance(leftX, midY, -1, 0); // Left
            dbgSideSamples ~= Vector2(leftX - dist, midY);
            
            if (dist < 4.0f) {
                vars.xPosition = leftX + dist + vars.widthRadius;
                vars.xSpeed = 0;
                if (vars.isGrounded) vars.groundSpeed = 0;
            }
        } else if (vars.xSpeed > 0) {
            // Moving right, check right wall
            float rightX = vars.xPosition + vars.widthRadius;
            float dist = getSensorDistance(rightX, midY, 1, 0); // Right
            dbgSideSamples ~= Vector2(rightX + dist, midY);
            
            if (dist < 4.0f) {
                vars.xPosition = rightX - dist - vars.widthRadius;
                vars.xSpeed = 0;
                if (vars.isGrounded) vars.groundSpeed = 0;
            }
        }
    }

    // Get distance to nearest solid in given direction
    float getSensorDistance(float x, float y, int dirX, int dirY) {
        if (level is null) return 1000.0f;
        
        int tileSize = 16;
        float maxDist = 32.0f;
        
        // Check pixel by pixel for more accuracy
        for (float d = 0; d <= maxDist; d += 0.5f) {
            float checkX = x + dirX * d;
            float checkY = y + dirY * d;
            
            if (isSolidAtPosition(checkX, checkY)) {
                // Found solid, return the distance to the edge
                return d > 0 ? d - 0.5f : 0.0f;
            }
        }
        
        return maxDist;
    }

    bool isSolidAtPosition(float x, float y) {
        if (level is null) return false;
        
        int tileSize = 16;
        int tileX = cast(int)floor(x / tileSize);
        int tileY = cast(int)floor(y / tileSize);
        
        // Check collision layer first
        if (level.collisionLayer.length > 0) {
            Tile tile = utils.level_loader.getTileAtPosition(level.collisionLayer, tileX, tileY);
            if (tile.tileId > 0) {
                TileHeightProfile profile = getTileProfile(tile.tileId, "Collision");
                int localX = cast(int)(x) % tileSize;
                if (localX < 0) localX += tileSize;
                if (localX >= 16) localX = 15;
                
                int localY = cast(int)(y) % tileSize;
                if (localY < 0) localY += tileSize;
                
                int height = profile.groundHeights[localX];
                return (tileSize - localY) <= height;
            }
        }
        
        // Check ground layers
        foreach (layerPtr; [&level.groundLayer1, &level.groundLayer2, &level.groundLayer3]) {
            if (layerPtr.length > 0) {
                Tile tile = utils.level_loader.getTileAtPosition(*layerPtr, tileX, tileY);
                if (tile.tileId > 0) {
                    TileHeightProfile profile = getTileProfile(tile.tileId, "Ground_1");
                    int localX = cast(int)(x) % tileSize;
                    if (localX < 0) localX += tileSize;
                    if (localX >= 16) localX = 15;
                    
                    int localY = cast(int)(y) % tileSize;
                    if (localY < 0) localY += tileSize;
                    
                    int height = profile.groundHeights[localX];
                    return (tileSize - localY) <= height;
                }
            }
        }
        
        return false;
    }

    TileHeightProfile getTileProfile(int tileId, string layerName) {
        TileHeightProfile profile;
        bool found = utils.level_loader.getPrecomputedTileProfile(*level, tileId, layerName, profile);
        if (!found) {
            profile = TileCollision.getTileHeightProfile(tileId, layerName, level.tilesets);
        }
        return profile;
    }

    float getGroundAngleAtPoint(float x, float y) {
        if (level is null) return 0.0f;
        
        int tileSize = 16;
        int tileX = cast(int)floor(x / tileSize);
        int tileY = cast(int)floor(y / tileSize);
        
        // Try collision layer first
        if (level.collisionLayer.length > 0) {
            Tile tile = utils.level_loader.getTileAtPosition(level.collisionLayer, tileX, tileY);
            if (tile.tileId > 0) {
                return TileCollision.getTileGroundAngle(tile.tileId, "Collision", level.tilesets);
            }
        }
        
        // Try ground layers
        foreach (layerPtr; [&level.groundLayer1, &level.groundLayer2, &level.groundLayer3]) {
            if (layerPtr.length > 0) {
                Tile tile = utils.level_loader.getTileAtPosition(*layerPtr, tileX, tileY);
                if (tile.tileId > 0) {
                    return TileCollision.getTileGroundAngle(tile.tileId, "Ground_1", level.tilesets);
                }
            }
        }
        
        return 0.0f;
    }

    // SPG-style velocity conversions
    void convertGroundSpeedToXY() {
        if (!vars.isGrounded) return;
        
        float angleRad = vars.groundAngleRadians();
        vars.xSpeed = vars.groundSpeed * cos(angleRad);
        vars.ySpeed = vars.groundSpeed * -sin(angleRad); // Negative for screen coords
    }

    void convertXYToGroundSpeed() {
        if (!vars.isGrounded) return;
        
        float angleRad = vars.groundAngleRadians();
        vars.groundSpeed = vars.xSpeed * cos(angleRad) + vars.ySpeed * -sin(angleRad);
        
        // Clean up small values
        if (abs(vars.groundSpeed) < 0.1f) {
            vars.groundSpeed = 0.0f;
        }
    }

    void updateState() {
        if (vars.isGrounded) {
            if (vars.isRolling) {
                state = PlayerState.ROLLING;
            } else if (abs(vars.groundSpeed) < 0.1f) {
                state = PlayerState.IDLE;
            } else if (abs(vars.groundSpeed) < 6.0f) {
                state = PlayerState.WALKING;
            } else {
                state = PlayerState.RUNNING;
            }
        } else {
            if (vars.ySpeed < 0) {
                state = PlayerState.JUMPING;
            } else {
                state = vars.isRolling ? PlayerState.FALLING_ROLLING : PlayerState.FALLING;
            }
        }
    }

    void updateAnimation(float deltaTime) {
        switch (state) {
            case PlayerState.IDLE:
                animations.setPlayerAnimationState(PlayerAnimationState.IDLE);
                break;
            case PlayerState.WALKING:
                animations.setPlayerAnimationState(PlayerAnimationState.WALK);
                break;
            case PlayerState.RUNNING:
                animations.setPlayerAnimationState(PlayerAnimationState.RUN);
                break;
            case PlayerState.JUMPING:
                animations.setPlayerAnimationState(PlayerAnimationState.JUMP);
                break;
            case PlayerState.FALLING:
                animations.setPlayerAnimationState(PlayerAnimationState.FALL);
                break;
            case PlayerState.ROLLING:
                animations.setPlayerAnimationState(PlayerAnimationState.ROLL);
                break;
            default:
                animations.setPlayerAnimationState(PlayerAnimationState.IDLE);
                break;
        }

        animations.update(deltaTime);
    }

    void updateSpritePosition() {
        sprite.x = vars.xPosition;
        sprite.y = vars.yPosition;
    }

    void draw() {
        Rectangle frame = animations.getCurrentFrameRectangle();
        float frameH = frame.height > 0 ? frame.height : (vars.heightRadius * 2.0f);
        float desiredCenterY = (vars.yPosition + vars.heightRadius) - (frameH / 2.0f);
        float spriteVisualYOffset = 11.0f;
        animations.render(Vector2(vars.xPosition, desiredCenterY + spriteVisualYOffset), 1.0f);

        if (dbgDrawCollisions) {
            // Draw ground sensors
            foreach (p; dbgGroundSamples) {
                DrawCircleV(p, 2, Colors.LIME);
            }
            
            // Draw wall sensors
            foreach (p; dbgSideSamples) {
                DrawCircleV(p, 2, Colors.RED);
            }
            
            // Draw collision box
            float colLeft = vars.xPosition - vars.widthRadius;
            float colTop = vars.yPosition - vars.heightRadius;
            float colW = vars.widthRadius * 2.0f;
            float colH = vars.heightRadius * 2.0f;
            DrawRectangleLines(cast(int)colLeft, cast(int)colTop, cast(int)colW, cast(int)colH, Colors.YELLOW);
        }
    }
}