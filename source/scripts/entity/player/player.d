module entity.player.player;

import raylib;

import std.stdio;
import std.string;
import std.file;
import std.json;
import std.traits : EnumMembers;
import std.array;
import std.conv : to;
import std.exception;
import std.math;

import entity.sprite_object;
import entity.player.var;
import utils.level_loader; // for LevelData and helpers
import world.tile_collision; // for TileHeightProfile and angle helper
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
    PUSHING,
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

enum GroundCollisionMode {
    NONE,
    FLOOR,
    LEFT_WALL,
    RIGHT_WALL,
    CEILING
}

struct Player {
    // Core components
    SpriteObject sprite;
    PlayerState state;
    PlayerVariables vars;  // All the physics variables from var.d
    PlayerAnimations animations;
    // Optional pointer to the loaded level so player can query precomputed tile profiles
    LevelData* level = null;
    bool dbgSlopeDebug = false; // toggleable runtime slope debug
    // Debug visualization for collision samples
    Vector2[] dbgGroundSamples;
    Vector2[] dbgSideSamples;
    Vector2 dbgCandidatePos;
    bool dbgCandidateValid = false;
    bool dbgDrawCollisions = true; // toggleable while tuning
    
    // Push state tracking
    bool hitWallThisFrame = false;
    int pushTimer = 0; // frames spent pushing

    // Constructor
    static Player create(float x, float y) {
        Player player;
        player.sprite = SpriteObject();
        player.state = PlayerState.IDLE;
        player.vars = PlayerVariables();
        player.vars.resetPosition(x, y);
        return player;
    }

    // Attach the level so collision queries can prefer precomputed profiles
    void setLevel(LevelData* lvl) {
        this.level = lvl;
    }

    // Initialize the player
    void initialize(float x, float y) {
        vars = PlayerVariables();
        vars.resetPosition(x, y);

        // Initialize sprite positioning and sizing
        sprite.x = x;
        sprite.y = y;
    // Use half-size box so the debug collision box matches the player's visual size better.
    // Previously set to diameter (radius*2). Reduce to radius to make the box half the previous size.
    sprite.width = cast(int)(vars.widthRadius);
    sprite.height = cast(int)(vars.heightRadius);
    sprite.setScale(1.0f); // Use native scale; animation rendering will scale explicitly

    // Initialize animations
    animations = new PlayerAnimations();
    // Load the default player sprite sheet and provide it to the animations
    import std.string : toStringz;
    // Use the multi-frame sprite atlas so AnimationManager can map frame indices correctly
    Texture2D playerTex = LoadTexture("resources/image/spritesheet/Sonic_spritemap.png".toStringz);
    animations.setTexture(playerTex);
    // Also register a SpriteObject in SpriteManager so fallback lookups work
    import sprite.sprite_manager;
    SpriteManager.getInstance().loadSprite("Sonic", "resources/image/spritesheet/Sonic_spritemap.png", 64, 64);
    animations.setPlayerAnimationState(PlayerAnimationState.IDLE);

        writeln("Player initialized at position: (", x, ", ", y, ")");
    }

    // Update player input
    void updateInput() {
        // Store previous input state for edge detection
        bool prevJump = vars.keyJump;

        // Read current input
        vars.keyLeft = IsKeyDown(KeyboardKey.KEY_LEFT) || IsKeyDown(KeyboardKey.KEY_A);
        vars.keyRight = IsKeyDown(KeyboardKey.KEY_RIGHT) || IsKeyDown(KeyboardKey.KEY_D);
        vars.keyUp = IsKeyDown(KeyboardKey.KEY_UP) || IsKeyDown(KeyboardKey.KEY_W);
        vars.keyDown = IsKeyDown(KeyboardKey.KEY_DOWN) || IsKeyDown(KeyboardKey.KEY_S);
        vars.keyJump = IsKeyDown(KeyboardKey.KEY_SPACE) || IsKeyDown(KeyboardKey.KEY_Z);

        // Detect edge events
        vars.keyJumpPressed = vars.keyJump && !prevJump;
        vars.keyJumpReleased = !vars.keyJump && prevJump;
        // Toggle slope debug with P
        if (IsKeyPressed(KeyboardKey.KEY_P)) dbgSlopeDebug = !dbgSlopeDebug;
    }

    // Main update function
    void update(float deltaTime) {
        updateInput();
    // Toggle collision debug drawing with O (optional)
    if (IsKeyPressed(KeyboardKey.KEY_O)) dbgDrawCollisions = !dbgDrawCollisions;
        updatePhysics(deltaTime);
        updateState();
        updateAnimation(deltaTime);
        updateSpritePosition();
    }

    // Update physics based on SPG
    void updatePhysics(float deltaTime) {
        // Clear wall collision flag from previous frame
        hitWallThisFrame = false;
        
        // Handle control lock timer
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

        // Update position (horizontal then vertical) using a swept horizontal resolver.
        // This prevents high-speed tunneling and reduces aggressive overshoot corrections.
        float oldX = vars.xPosition;
        float targetX = oldX + vars.xSpeed;
        
        // Safety check for NaN values
        if (isNaN(oldX) || isNaN(targetX) || isNaN(vars.xSpeed)) {
            writeln("[ERROR] NaN detected in horizontal movement! Resetting position.");
            vars.xPosition = 100.0f; // Safe fallback position
            vars.xSpeed = 0.0f;
            oldX = vars.xPosition;
            targetX = vars.xPosition;
        }
        
        // Always check wall collision first as per SPG - wall checks happen before floor checks
        checkHorizontalCollision(oldX, targetX);
        if (vars.isGrounded && abs(vars.xSpeed) < 0.2f && (vars.keyLeft || vars.keyRight)) {
            import utils.level_loader : isSolidAtPosition;
            // Check if there's a wall in the direction we're trying to move
            // Use extended range to detect walls before foot sensors reach them
            float checkDirection = vars.keyRight ? 1.0f : -1.0f;
            float checkX = vars.xPosition + checkDirection * (vars.widthRadius + 4.0f); // Extended range
            
            // Sample for wall in movement direction
            float playerTop = vars.yPosition - vars.heightRadius + 4.0f;
            float playerBottom = vars.yPosition + vars.heightRadius - 10.0f; // Above feet
            int samples = 4;
            int solidHits = 0;
            
            for (int i = 0; i < samples; i++) {
                float sampleY = playerTop + (playerBottom - playerTop) * cast(float)i / cast(float)(samples - 1);
                if (isSolidAtPosition(*level, checkX, sampleY)) {
                    solidHits++;
                }
            }
            
            if (solidHits >= 3) {
                hitWallThisFrame = true;
                writeln("[PUSH CHECK] Wall detected while stationary - enabling push state");
            }
        }
        
        // After horizontal movement, check if we're stuck in a wall and escape if needed
        // ONLY when grounded - airborne players should just fall naturally
        if (vars.isGrounded) {
            escapeFromWalls();
        }

        // After horizontal movement (possibly adjusted), apply vertical movement
        if (isNaN(vars.ySpeed) || isNaN(vars.yPosition)) {
            writeln("[ERROR] NaN detected in vertical movement! Resetting.");
            vars.yPosition = 100.0f;
            vars.ySpeed = 0.0f;
        }
        
        // If we're grounded and moving horizontally on a slope, predict slope following
        // BEFORE applying vertical movement to avoid temporary airborne states
        // BUT NOT if we just hit a wall - walls should block movement
        // AND NOT if we're in pushing state - no movement allowed
        if (vars.isGrounded && abs(vars.xSpeed) > 0.1f && abs(vars.groundAngle) > 0.5f && !hitWallThisFrame && state != PlayerState.PUSHING) {
            // Try to predict where we should be on the slope
            predictSlopePosition();
        }
        
        // Block vertical movement when in pushing state - BUT ONLY when grounded
        // Airborne players should fall normally regardless of push state
        if (state == PlayerState.PUSHING && state != PlayerState.JUMPING && vars.isGrounded) {
            vars.ySpeed = 0;
            writeln("[PUSH STATE] Blocking vertical movement");
        } else {
            vars.yPosition += vars.ySpeed;
        }
        
        // Always check ground collision after movement so we can land or fall off edges.
    checkGroundCollision();
    }

    // Ground movement physics
    void updateGroundPhysics() {
        // Skip input if control is locked
        if (vars.controlLockTimer > 0) {
            return;
        }
        
        // If we're in pushing state, only block movement into the wall, but always allow jumping
        if (state == PlayerState.PUSHING) {
            // Allow jumping even in push state
            if (vars.keyJumpPressed) {
                // Let the jump logic below handle it
            } else {
                // Determine which direction the wall is in
                bool wallOnRight = isNextToWallInDirection(true);
                bool wallOnLeft = isNextToWallInDirection(false);
                // If pressing into the wall, block movement
                if ((vars.keyRight && wallOnRight && !vars.keyLeft) || (vars.keyLeft && wallOnLeft && !vars.keyRight)) {
                    vars.groundSpeed = 0;
                    vars.xSpeed = 0;
                    // Do NOT touch ySpeed so jumping and gravity work
                    writeln("[PUSH STATE] Blocking movement into wall (x only)");
                    return;
                }
                // If pressing away from the wall, allow normal movement (fall through)
            }
        }

        // Get base movement constants
        float baseAccel = vars.isSuperSonic ? vars.SUPER_ACCELERATION_SPEED : vars.ACCELERATION_SPEED;
        float baseDecel = vars.isSuperSonic ? vars.SUPER_DECELERATION_SPEED : vars.DECELERATION_SPEED;
        float topSpeed = vars.isSuperSonic ? vars.SUPER_TOP_SPEED : vars.TOP_SPEED;
        float baseFriction = vars.FRICTION_SPEED;
        
        // Apply slope-dependent modifiers
        float slopeModifier = vars.getSlopeMovementModifier();
        float accel = baseAccel * slopeModifier;
        float decel = baseDecel * slopeModifier;
        float friction = baseFriction * slopeModifier;

        // Handle rolling physics differently
        if (vars.isRolling) {
            updateRollingPhysics();
            return;
        }

        // Left input
        if (vars.keyLeft && !vars.keyRight) {
            if (vars.groundSpeed > 0) {
                // Decelerate when moving right but pressing left
                vars.groundSpeed -= decel;
                if (vars.groundSpeed <= 0) {
                    vars.groundSpeed = -0.5f; // SPG deceleration quirk
                }
            } else if (vars.groundSpeed > -topSpeed) {
                // Accelerate left
                vars.groundSpeed -= accel;
                if (vars.groundSpeed <= -topSpeed) {
                    vars.groundSpeed = -topSpeed;
                }
            }
            vars.setFacing(-1);
        }
        // Right input
        else if (vars.keyRight && !vars.keyLeft) {
            if (vars.groundSpeed < 0) {
                // Decelerate when moving left but pressing right
                vars.groundSpeed += decel;
                if (vars.groundSpeed >= 0) {
                    vars.groundSpeed = 0.5f; // SPG deceleration quirk
                }
            } else if (vars.groundSpeed < topSpeed) {
                // Accelerate right
                vars.groundSpeed += accel;
                if (vars.groundSpeed >= topSpeed) {
                    vars.groundSpeed = topSpeed;
                }
            }
            vars.setFacing(1);
        }
        // No horizontal input - apply friction
        else {
            if (vars.groundSpeed > 0) {
                vars.groundSpeed -= (vars.groundSpeed > friction) ? friction : vars.groundSpeed;
            } else if (vars.groundSpeed < 0) {
                vars.groundSpeed += (vars.groundSpeed < -friction) ? friction : -vars.groundSpeed;
            }
        }

        // Apply slope physics
    // Debug: capture before/after for slope factor
    float preSlopeGS = vars.groundSpeed;
    float angleRad = vars.groundAngle * (3.14159265358979323846f / 180.0f);
    vars.applySlopeFactor();
    float postSlopeGS = vars.groundSpeed;

        // Check for slipping on slopes
        if (vars.shouldSlipOnSlope()) {
            vars.isGrounded = false;
            vars.groundSpeed = 0;
            vars.controlLockTimer = 30; // 30 frames control lock
        }

        if (dbgSlopeDebug) {
            writeln("SlopeDbg: angle=", vars.groundAngle, " deg, angleRad=", angleRad,
                    " slopeModifier=", slopeModifier,
                    " preGS=", preSlopeGS, " postGS=", postSlopeGS,
                    " xSpeed=", vars.xSpeed, " ySpeed=", vars.ySpeed);
        }
        
        // Convert ground speed to X/Y speeds - simplified and safe
        if (vars.isGrounded) {
            float groundAngleRad = vars.groundAngleRadians();
            if (isNaN(groundAngleRad) || abs(groundAngleRad) > 6.28f) {
                groundAngleRad = 0.0f;
                vars.groundAngle = 0.0f;
            }
            
            if (abs(vars.groundAngle) < 1.0f) {
                // Nearly flat - direct assignment
                vars.xSpeed = vars.groundSpeed;
                vars.ySpeed = 0.0f;
            } else {
                // Sloped - project groundSpeed
                vars.xSpeed = vars.groundSpeed * cos(groundAngleRad);
                vars.ySpeed = vars.groundSpeed * -sin(groundAngleRad);
            }
            
            // Safety checks
            if (isNaN(vars.xSpeed)) vars.xSpeed = 0.0f;
            if (isNaN(vars.ySpeed)) vars.ySpeed = 0.0f;
        }

        // Handle jumping
        if (vars.keyJumpPressed) {
            vars.ySpeed = vars.INITIAL_JUMP_VELOCITY;
            vars.isGrounded = false;
            // Keep horizontal momentum - simple and safe
            if (abs(vars.groundAngle) < 15.0f) {
                // Nearly flat - use groundSpeed directly
                vars.xSpeed = vars.groundSpeed;
            } else {
                // Steep slope - use current xSpeed to avoid projection errors
                // vars.xSpeed stays as-is
            }
            writeln("JUMPING: xSpeed=", vars.xSpeed, " ySpeed=", vars.ySpeed);
        }
    }

    // Air movement physics
    void updateAirPhysics() {
        float airAccel = vars.isSuperSonic ? vars.SUPER_AIR_ACCELERATION : vars.AIR_ACCELERATION_SPEED;
        float topSpeed = vars.isSuperSonic ? vars.SUPER_TOP_SPEED : vars.TOP_SPEED;

        // Horizontal air movement
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

        // Variable jump height
        if (vars.keyJumpReleased && vars.ySpeed < vars.RELEASE_JUMP_VELOCITY) {
            vars.ySpeed = vars.RELEASE_JUMP_VELOCITY;
        }

        // Air drag (simplified version)
        if (vars.ySpeed < -4.0f) {
            vars.xSpeed *= 0.96875f; // Air drag factor
        }

        // DO NOT UPDATE GROUNDSPEED WHILE AIRBORNE - this is key!
        // groundSpeed should remain frozen until landing
    }

    // Rolling physics
    void updateRollingPhysics() {
        // Rolling can only decelerate, not accelerate
        float friction = vars.ROLLING_FRICTION;

        if (vars.groundSpeed > 0) {
            vars.groundSpeed -= (vars.groundSpeed > friction) ? friction : vars.groundSpeed;
        } else if (vars.groundSpeed < 0) {
            vars.groundSpeed += (vars.groundSpeed < -friction) ? friction : -vars.groundSpeed;
        }

        // Exit rolling if speed is too low
        if (abs(vars.groundSpeed) < 0.5f) {
            vars.isRolling = false;
        }

        // Apply slope physics
        vars.applySlopeFactor();
        vars.updateSpeedsFromGroundSpeed();
    }

    // Update player state
    void updateState() {
        // Debug: Always print current state and inputs
        writeln("[STATE DEBUG] Current state: ", state, " isGrounded: ", vars.isGrounded, " hasInput: ", (vars.keyLeft || vars.keyRight), " hitWall: ", hitWallThisFrame);
        
        if (vars.isGrounded) {
            // Check for push state first - overrides normal movement states
            bool hasHorizontalInput = vars.keyLeft || vars.keyRight;
            
            // Enter push state if we hit a wall this frame OR if we're already pushing and still trying to move
            if ((hitWallThisFrame && hasHorizontalInput) || 
                (state == PlayerState.PUSHING && hasHorizontalInput && abs(vars.groundSpeed) < 0.1f)) {
                state = PlayerState.PUSHING;
                pushTimer++;
                writeln("ENTERING/STAYING IN PUSH STATE - timer: ", pushTimer);
                return;
            } else {
                // Reset push timer when not pushing
                if (state == PlayerState.PUSHING) {
                    writeln("EXITING PUSH STATE");
                }
                pushTimer = 0;
            }
            
            // Check if we're trying to move into a wall - only check direction of movement
            bool movingIntoWall = false;
            if (hasHorizontalInput && abs(vars.groundSpeed) < 0.5f) {
                bool checkingRight = vars.keyRight;
                movingIntoWall = isNextToWallInDirection(checkingRight);
                
                writeln("[WALL PROXIMITY DEBUG] checkingRight: ", checkingRight, " movingIntoWall: ", movingIntoWall);
                
                if (movingIntoWall) {
                    // Trying to move into wall - go to push state
                    state = PlayerState.PUSHING;
                    writeln("[WALL PROXIMITY] Entering push state - moving into wall");
                    return;
                }
            }
            
            // Normal ground state logic - only blocked if moving INTO wall, not away from it
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
            // Reset push timer when airborne
            pushTimer = 0;
            
            if (vars.ySpeed < 0) {
                state = PlayerState.JUMPING;
            } else {
                state = vars.isRolling ? PlayerState.FALLING_ROLLING : PlayerState.FALLING;
            }
        }
    }

    // Update animation
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
            case PlayerState.PUSHING:
                animations.setPlayerAnimationState(PlayerAnimationState.WALK); // Use walk animation for pushing
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

    // Update sprite position
    void updateSpritePosition() {
        sprite.x = vars.xPosition;
        sprite.y = vars.yPosition;
    }

    // Draw the player
    void draw() {
    // Render at player position using native 1:1 scale; adjust vertical offset so feet align with physics bottom.
    // animations.render expects the position to be the sprite center. Our physics `yPosition` is the player's center,
    // but sprite frames may have different heights; compute the required offset so the bottom of the sprite sits at
    // (yPosition + heightRadius).
    Rectangle frame = animations.getCurrentFrameRectangle();
    float frameH = frame.height > 0 ? frame.height : (vars.heightRadius * 2.0f);
    // Desired sprite center Y such that bottom aligns with physics bottom:
    float desiredCenterY = (vars.yPosition + vars.heightRadius) - (frameH / 2.0f);
    // Small visual adjustment: move sprite down so feet sit nicely on the surface.
    // Positive Y is downward in screen space, so add to move down.
    float spriteVisualYOffset = 11.0f; // tweak this value if the sprite needs tuning
    animations.render(Vector2(vars.xPosition, desiredCenterY + spriteVisualYOffset), 1.0f);
        // Debug: draw collision sample points if enabled
        if (dbgDrawCollisions) {
            foreach (p; dbgGroundSamples) {
                DrawCircleV(p, 2, Colors.LIME);
            }
            foreach (p; dbgSideSamples) {
                DrawCircleV(p, 2, Colors.RED);
            }
            if (dbgCandidateValid) {
                DrawCircleV(dbgCandidatePos, 3, Colors.SKYBLUE);
            }
            // Draw the player's collision rectangle (world space) as an outline so we can tune radii
            float colLeft = vars.xPosition - vars.widthRadius;
            float colTop = vars.yPosition - vars.heightRadius;
            float colW = vars.widthRadius * 2.0f;
            float colH = vars.heightRadius * 2.0f;
            DrawRectangleLines(cast(int)colLeft, cast(int)colTop, cast(int)colW, cast(int)colH, Colors.YELLOW);
        }
    }

    // Predict slope position to prevent temporary airborne states
    void predictSlopePosition() {
        if (level is null) return;
        import std.math : floor;
        
        // Sample the ground directly below the player's current position
        float bottom = vars.yPosition + vars.heightRadius;
        int tileSize = 16;
        
        int sampleTileX = cast(int)floor(vars.xPosition / tileSize);
        int sampleTileY = cast(int)floor(bottom / tileSize);
        
        // Check the main ground layer
        Tile tile = utils.level_loader.getTileAtPosition(level.groundLayer1, sampleTileX, sampleTileY);
        if (tile.tileId <= 0) return;
        
        // Get the height profile for this tile
        world.tile_collision.TileHeightProfile profile;
        bool hadProfile = utils.level_loader.getPrecomputedTileProfile(*level, tile.tileId, "Ground_1", profile);
        if (!hadProfile) {
            profile = world.tile_collision.TileCollision.getTileHeightProfile(tile.tileId, "Ground_1", level.tilesets);
        }
        
        // Find the local column within the tile
        int localX = cast(int)floor(vars.xPosition) - sampleTileX * tileSize;
        if (localX < 0) localX = 0;
        if (localX > 15) localX = 15;
        
        int h = profile.groundHeights[localX];
        float tileTopY = cast(float)(sampleTileY * tileSize);
        float predictedSurfaceY = tileTopY + (tileSize - cast(float)h);
        
        // If the predicted surface is close to where we should be, snap to it
        float predictedPlayerY = predictedSurfaceY - vars.heightRadius;
        float yDiff = abs(vars.yPosition - predictedPlayerY);
        
        if (yDiff <= 3.0f) { // Within 3 pixels is close enough
            vars.yPosition = predictedPlayerY;
            // Keep the current ground angle since we're just adjusting position
        }
    }

    // Check if there's a wall in the direction of movement (for preventing movement states)
    bool isNextToWallInDirection(bool checkingRight) {
        if (level is null) return false;
        import utils.level_loader : isSolidAtPosition;
        
        // Check only the direction we're moving
        float wallCheckDistance = vars.widthRadius + 6.0f; // Further out than foot sensors
        float checkX = vars.xPosition + (checkingRight ? wallCheckDistance : -wallCheckDistance);
        
        writeln("[WALL CHECK DEBUG] checkingRight: ", checkingRight, " checkX: ", checkX, " playerX: ", vars.xPosition);
        
        // Sample multiple points vertically (body area, not feet)
        float topY = vars.yPosition - vars.heightRadius + 4.0f;
        float bottomY = vars.yPosition + vars.heightRadius - 12.0f; // Well above feet
        
        int samples = 4;
        int solidHits = 0;
        
        for (int i = 0; i < samples; i++) {
            float sampleY = topY + (bottomY - topY) * cast(float)i / cast(float)(samples - 1);
            if (isSolidAtPosition(*level, checkX, sampleY)) {
                solidHits++;
                writeln("[WALL CHECK] Sample ", i, " at (", checkX, ",", sampleY, ") = SOLID");
            } else {
                writeln("[WALL CHECK] Sample ", i, " at (", checkX, ",", sampleY, ") = empty");
            }
        }
        
        bool hasWall = solidHits >= 3;
        writeln("[WALL CHECK RESULT] solidHits: ", solidHits, "/", samples, " hasWall: ", hasWall);
        
        // Consider wall present if 3+ samples hit solid
        return hasWall;
    }

    // Debug functions
    void debugPrint() {
        writeln("=== Player Debug ===");
        writeln("State: ", state);
        vars.debugPrint();
    }

    // Collision detection placeholder
    bool checkGroundCollision() {
    import std.math : floor;
    import std.algorithm : max, min;

        writeln("[GROUND CHECK] Starting at position Y=", vars.yPosition, " bottom=", vars.yPosition + vars.heightRadius);

        // If we don't have level data, fall back to previous simple ground at y=400
        if (level is null) {
            if (vars.yPosition >= 400) {
                vars.yPosition = 400;
                if (!vars.isGrounded) {
                    vars.isGrounded = true;
                    if (abs(vars.xSpeed) < 1.0f) {
                        vars.groundSpeed = 0;
                    } else {
                        vars.groundSpeed = vars.xSpeed;
                    }
                    writeln("LANDING (fallback): xSpeed=", vars.xSpeed, " -> groundSpeed=", vars.groundSpeed);
                    return true;
                }
                vars.isGrounded = true;
                return false;
            } else {
                vars.isGrounded = false;
                return false;
            }
        }

        // Compute bottom point in world coordinates and sample columns across player's width
        float bottom = vars.yPosition + vars.heightRadius;
        int tileSize = 16;

        // Sample three x positions: left edge, center, right edge (in world coords)
        float leftX = vars.xPosition - (vars.widthRadius - 1.0f);
        float centerX = vars.xPosition;
        float rightX = vars.xPosition + (vars.widthRadius - 1.0f);
        
        // If already grounded and moving horizontally, also look ahead for ground following
        float[5] sampleXs;
        int numSamples = 3;
        sampleXs[0] = leftX;
        sampleXs[1] = centerX; 
        sampleXs[2] = rightX;
        
        if (vars.isGrounded && abs(vars.xSpeed) > 1.0f) {
            // Look ahead in movement direction for better ground following
            float lookaheadDistance = 4.0f; // pixels to look ahead
            float lookAheadX = vars.xPosition + (vars.xSpeed > 0 ? lookaheadDistance : -lookaheadDistance);
            sampleXs[3] = lookAheadX;
            numSamples = 4;
            writeln("[GROUND FOLLOWING] Looking ahead to x=", lookAheadX, " (speed=", vars.xSpeed, ")");
        }

        // Layers to check in priority order
        struct LayerCheck { Tile[][]* layer; string name; bool isSemi; }
        LayerCheck[7] checks = [
            LayerCheck(&level.collisionLayer, "Collision", false),
            LayerCheck(&level.groundLayer1, "Ground_1", false),
            LayerCheck(&level.groundLayer2, "Ground_2", false),
            LayerCheck(&level.groundLayer3, "Ground_3", false),
            LayerCheck(&level.semiSolidLayer1, "SemiSolid_1", true),
            LayerCheck(&level.semiSolidLayer2, "SemiSolid_2", true),
            LayerCheck(&level.semiSolidLayer3, "SemiSolid_3", true)
        ];

    // Track whether any sample supported us and record the best (highest) surfaceY and its angle
    bool anySupport = false;
    float bestSurfaceY = cast(float)1e9;
    float bestAngle = 0.0f;
    // debug
    dbgGroundSamples = [];

        foreach (ch; checks) {
            Tile[][] layer = *ch.layer;
            if (layer.length == 0) continue;

            foreach (sx; sampleXs[0..numSamples]) {
                int sampleTileX = cast(int)floor(sx / tileSize);
                int baseSampleTileY = cast(int)floor(bottom / tileSize);
                
                // Check current tile row AND tile above for slope climbing
                // BUT NOT if we just hit a wall - don't climb walls!
                // AND NOT if we're in pushing state - no movement allowed
                // AND NOT if we're airborne - no climbing while jumping/falling
                int[] checkTileYs;
                bool isAirborne = (state == PlayerState.JUMPING || state == PlayerState.FALLING || state == PlayerState.FALLING_ROLLING);
                
                if (hitWallThisFrame || state == PlayerState.PUSHING || isAirborne) {
                    // Only check current row when hitting wall, pushing, or airborne
                    checkTileYs = [baseSampleTileY];
                    if (state == PlayerState.PUSHING) {
                        // Only check current row when pushing - no climbing
                    } else if (isAirborne) {
                    }
                } else {
                    // Normal slope climbing - check current and above
                    checkTileYs = [baseSampleTileY, baseSampleTileY - 1];
                }
                
                foreach (sampleTileY; checkTileYs) {
                    // Skip if checking above ground level
                    if (sampleTileY < 0) continue;
                    
                    // For grounded players, also check one tile below for small drops/gaps
                    int[] tilesToCheck = [sampleTileY];
                    if (vars.isGrounded && abs(vars.xSpeed) > 0.5f) {
                        tilesToCheck ~= sampleTileY + 1; // Check tile below too
                    }
                    
                    foreach (checkY; tilesToCheck) {
                        if (checkY < 0) continue;

                    Tile tile = utils.level_loader.getTileAtPosition(layer, sampleTileX, checkY);
                    if (tile.tileId <= 0) continue;

                    // Get profile
                    world.tile_collision.TileHeightProfile profile;
                    bool hadProfile = utils.level_loader.getPrecomputedTileProfile(*level, tile.tileId, ch.name, profile);
                    if (!hadProfile) {
                        profile = world.tile_collision.TileCollision.getTileHeightProfile(tile.tileId, ch.name, level.tilesets);
                    }

                    // Compute local column for this sample within the tile
                    int localX = cast(int)floor(sx) - sampleTileX * tileSize;
                    if (localX < 0) localX = 0;
                    if (localX > 15) localX = 15;
                    int h = profile.groundHeights[localX]; // 0..16

                    float tileTopY = cast(float)(checkY * tileSize);
                    float surfaceY = tileTopY + (tileSize - cast(float)h);

                    // Support logic: must be moving down/stationary and at/under surface
                    // For tiles above current row, be more lenient with the proximity check
                    // For grounded players, be more lenient with small drops (up to 6 pixels)
                    bool isAboveTile = (checkY < baseSampleTileY);
                    float proximityTolerance = isAboveTile ? 8.0f : 0.0f;
                    if (vars.isGrounded && abs(vars.xSpeed) > 0.5f) {
                        proximityTolerance += 6.0f; // Extra tolerance for ground following
                    }
                    
                    if (vars.ySpeed >= 0 && (bottom + proximityTolerance >= surfaceY)) {
                        anySupport = true;
                        writeln("[GROUND CHECK] Found support at surfaceY=", surfaceY, " sampleTileY=", checkY, " tileId=", tile.tileId);
                        if (surfaceY < bestSurfaceY) {
                            bestSurfaceY = surfaceY;
                            float ang = world.tile_collision.TileCollision.getTileGroundAngle(tile.tileId, ch.name, level.tilesets);
                            import std.math : isNaN;
                            if (isNaN(ang)) {
                                writeln("[WARN] Tile ", tile.tileId, " returned NaN angle, using 0");
                                writeln("[DEBUG] Heights for tile ", tile.tileId, ": checking tile collision system...");
                                ang = 0.0f;
                            }
                            bestAngle = ang;
                        }
                        // push debug sample (world position of sample point at surface)
                        float sampleWorldX = cast(float)(sampleTileX * tileSize + localX) + 0.5f;
                        float sampleWorldY = surfaceY;
                        dbgGroundSamples ~= Vector2(sampleWorldX, sampleWorldY);
                    }
                    }
                }
            }
            // If we've already found support in a higher-priority layer, stop searching lower layers
            if (anySupport) break;
        }

    if (anySupport) {
            writeln("[GROUND CHECK] FOUND SUPPORT! bestSurfaceY=", bestSurfaceY, " bestAngle=", bestAngle);
            // New landing only if previously airborne
            if (!vars.isGrounded) {
                // Landing: set grounded, snap to surface, safe velocity handling
                vars.isGrounded = true;
                vars.yPosition = bestSurfaceY - vars.heightRadius;
                
                // Ensure angle is safe before assigning
                if (isNaN(bestAngle) || abs(bestAngle) > 89.0f) {
                    writeln("[WARN] Landing bestAngle invalid: ", bestAngle, ", using 0");
                    bestAngle = 0.0f;
                }
                
                // Debug: track groundAngle assignment
                float oldGroundAngle = vars.groundAngle;
                vars.groundAngle = bestAngle;
                writeln("[DEBUG GROUND ANGLE] Assigned: old=", oldGroundAngle, " new=", vars.groundAngle, " bestAngle=", bestAngle);

                // Safe velocity conversion - avoid NaN and zipping
                if (isNaN(bestAngle) || abs(bestAngle) > 90.0f) {
                    writeln("[WARN] bestAngle invalid: ", bestAngle, ", resetting to 0");
                    bestAngle = 0.0f;
                    vars.groundAngle = 0.0f;
                }
                
                // Simple ground speed calculation with extra safety
                if (abs(bestAngle) < 5.0f) {
                    // Nearly flat surface - use horizontal speed
                    vars.groundSpeed = vars.xSpeed;
                } else {
                    // Sloped surface - blend with angle consideration
                    float factor = abs(bestAngle) / 45.0f;
                    if (factor > 1.0f) factor = 1.0f;
                    vars.groundSpeed = vars.xSpeed * (1.0f - factor * 0.3f);
                }

                // Safety checks
                if (isNaN(vars.groundSpeed)) {
                    writeln("[WARN] groundSpeed became NaN, resetting to 0");
                    vars.groundSpeed = 0.0f;
                }
                if (abs(vars.groundSpeed) < 0.1f) vars.groundSpeed = 0.0f;
                
                writeln("LANDING: angle=", vars.groundAngle, " groundSpeed=", vars.groundSpeed);
                return true;
            }
            // Already grounded: update Y position to follow slope contour
            // This ensures the player follows slopes smoothly as they move horizontally
            // BUT NOT when in pushing state - stay exactly where we are
            vars.isGrounded = true;
            if (state != PlayerState.PUSHING) {
                vars.yPosition = bestSurfaceY - vars.heightRadius;
            } else {
                writeln("[PUSH STATE] Blocking Y position update in ground collision");
            }
            
            // Update ground angle if it has changed
            if (isNaN(bestAngle) || abs(bestAngle) > 89.0f) {
                bestAngle = 0.0f;
            }
            
            // Debug: track groundAngle assignment
            float oldGroundAngle = vars.groundAngle;
            vars.groundAngle = bestAngle;
            writeln("[DEBUG GROUND ANGLE] Updated during ground collision: old=", oldGroundAngle, " new=", vars.groundAngle, " bestAngle=", bestAngle);
            return false;
        }

        // No sample supported us
        vars.isGrounded = false;
        writeln("[GROUND CHECK] No support found - setting isGrounded = false");
        return false;
    }

    // Simple horizontal collision resolver: if player's center is inside a solid tile,
    // nudge the player out along the X axis based on facing direction. This is a
    // pragmatic, low-risk fix to avoid clipping into walls. For more accurate
    // continuous collision, replace with swept tests.
    // Swept horizontal collision resolver: move from oldX toward targetX incrementally
    // and stop at the last safe position. This avoids tunneling and aggressive corrections.
    void checkHorizontalCollision(float oldX, float targetX) {
        if (level is null) return;
        import utils.level_loader : isSolidAtPosition;

        // Prevent rapid consecutive wall collisions
        static int wallCollisionCooldown = 0;
        if (wallCollisionCooldown > 0) {
            wallCollisionCooldown--;
            // Allow near-normal movement during cooldown to support slope climbing
            vars.xPosition = oldX + (targetX - oldX) * 0.8f; // Increased from 0.3f to 0.8f
            return;
        }

        // Number of steps equals distance in pixels (ceiled). We'll step 1px at a time.
        float dx = targetX - oldX;
        int steps = cast(int)ceil(abs(dx));
        
        // Skip collision detection for very small movements to prevent jittering
        if (abs(dx) < 0.5f) {
            vars.xPosition = targetX;
            return;
        }
        
        if (steps == 0) {
            // No horizontal movement; run side sample debug at the side Sonic is facing
            dbgSideSamples = [];
            float margin = 2.0f;
            float sideX = vars.xPosition + ((vars.facing > 0) ? (vars.widthRadius + margin) : -(vars.widthRadius + margin));
            // Sample at vertical center and feet
            dbgSideSamples ~= Vector2(sideX, vars.yPosition); // center
            dbgSideSamples ~= Vector2(sideX, vars.yPosition + vars.heightRadius - 2.0f); // near feet
            return;
        }

        float stepDir = dx > 0 ? 1.0f : -1.0f;
        float lastSafeX = oldX;
        dbgSideSamples = [];

        // Helper to test overlap at a candidate centerX and sample vertically.
        // Simplified approach: if there's any solid tile in movement direction, it's a wall
        bool overlapsAtCenter(float centerX) {
            import utils.level_loader : isSolidAtPosition;
            import std.math : floor;
            
            // Check multiple points in the direction of movement
            float checkDistance = vars.widthRadius + 2.0f;
            float checkX = centerX + (stepDir > 0 ? checkDistance : -checkDistance);
            
            // Sample vertically at multiple points to detect solid tiles
            float playerTop = vars.yPosition - vars.heightRadius + 4.0f;
            float playerBottom = vars.yPosition + vars.heightRadius - 8.0f; // Above feet
            
            int samples = 6;
            int solidHits = 0;
            
            dbgSideSamples = []; // Reset debug samples
            
            for (int i = 0; i < samples; i++) {
                float sampleY = playerTop + (playerBottom - playerTop) * cast(float)i / cast(float)(samples - 1);
                dbgSideSamples ~= Vector2(checkX, sampleY);
                
                if (isSolidAtPosition(*level, checkX, sampleY)) {
                    solidHits++;
                }
            }
            
            // If most samples hit solid, it's a wall
            bool isWall = solidHits >= 4;
            
            if (isWall) {
                writeln("Touching wall: true");
                writeln("[WALL DEBUG] WALL DETECTED! checkX=", checkX, " solidHits=", solidHits, "/", samples);
            } else {
                writeln("[WALL DEBUG] No wall - checkX=", checkX, " solidHits=", solidHits, "/", samples);
            }
            
            return isWall;
        }

        // Step along the path and stop at the first wall collision
        for (int i = 1; i <= steps; ++i) {
            float candidateX = oldX + stepDir * cast(float)i;
            if (overlapsAtCenter(candidateX)) {
                // Hit a wall - stop at last safe position
                vars.xPosition = lastSafeX;
                
                // Handle wall collision based on state
                if (vars.isGrounded) {
                    // Grounded: normal wall collision - stop movement and set push flag
                    vars.groundSpeed = 0;
                    vars.xSpeed = 0;
                    hitWallThisFrame = true;
                    writeln("WALL HIT (grounded): stopped at x=", lastSafeX);
                } else {
                    // Airborne (JUMP/FALL): bounce away from wall
                    float bounceForce = 2.0f; // Adjust this value for bounce strength
                    if (stepDir > 0) {
                        // Moving right, hit right wall - bounce left
                        vars.xSpeed = -bounceForce;
                        writeln("WALL BOUNCE: hit right wall, bouncing left with force ", bounceForce);
                    } else {
                        // Moving left, hit left wall - bounce right  
                        vars.xSpeed = bounceForce;
                        writeln("WALL BOUNCE: hit left wall, bouncing right with force ", bounceForce);
                    }
                    // Don't set hitWallThisFrame for airborne - no push state
                }
                
                return;
            }
            lastSafeX = candidateX;
        }

        // If we reached here, targetX is safe
        vars.xPosition = targetX;
        dbgCandidatePos = Vector2(vars.xPosition, vars.yPosition);
        dbgCandidateValid = true;
    }

    // Continuous wall escape system - checks if player is stuck in a wall and pushes them out
    void escapeFromWalls() {
        if (level is null) return;
        import utils.level_loader : isSolidAtPosition;

        // Check if we're currently overlapping with any solid tiles
        bool isStuckInWall() {
            float leftEdgeX = vars.xPosition - vars.widthRadius + 1.0f;
            float rightEdgeX = vars.xPosition + vars.widthRadius - 1.0f;
            float sideSampleInset = 6.0f;
            float topY = vars.yPosition - vars.heightRadius + 1.0f;
            float bottomY = vars.yPosition + vars.heightRadius - 1.0f - sideSampleInset;
            
            int samples = 7; // More samples for better detection
            float dy = (bottomY - topY) / cast(float)(samples - 1);
            
            int solidCount = 0;
            for (int i = 0; i < samples; ++i) {
                float sy = topY + dy * i;
                if (isSolidAtPosition(*level, leftEdgeX, sy) || 
                    isSolidAtPosition(*level, rightEdgeX, sy) ||
                    isSolidAtPosition(*level, vars.xPosition, sy)) { // Also check center
                    solidCount++;
                }
            }
            
            // Only consider "stuck" if multiple samples are overlapping (not just touching)
            // This prevents interference with normal wall sliding in air
            return solidCount >= 3;
        }

        // Additional check: only escape if movement is severely restricted
        // This prevents escape system from activating during normal movement
        bool isMovementBlocked() {
            if (vars.isGrounded) {
                // On ground: escape if stuck for fewer frames, especially if embedded in wall
                static int stuckFrames = 0;
                bool hasHorizontalInput = vars.keyLeft || vars.keyRight;
                bool hasMinimalSpeed = abs(vars.groundSpeed) < 0.05f && abs(vars.xSpeed) < 0.05f;
                
                if (hasHorizontalInput && hasMinimalSpeed) {
                    stuckFrames++;
                    // If deeply embedded (high solid count), escape faster
                    bool deeplyEmbedded = isStuckInWall(); // Check current embedding
                    int escapeThreshold = deeplyEmbedded ? 5 : 20; // Much faster escape if embedded
                    return stuckFrames > escapeThreshold;
                } else {
                    stuckFrames = 0;
                    return false;
                }
            } else {
                // In air: only escape if completely stuck (no movement at all)
                return abs(vars.ySpeed) < 0.5f && abs(vars.xSpeed) < 0.5f;
            }
        }

        if (!isStuckInWall() || !isMovementBlocked()) return;

        // We're truly stuck - find the best escape direction
        float[] escapeDirections = [-1.0f, 1.0f]; // Try both directions
        float maxEscapeDistance = 48.0f; // Increased escape range for severe embedding
        bool escaped = false;

        // Try horizontal escape first - check both directions
        foreach (direction; escapeDirections) {
            for (float distance = 2.0f; distance <= maxEscapeDistance; distance += 2.0f) {
                float testX = vars.xPosition + (direction * distance);
                
                // Temporarily move to test position and check if we're clear
                float originalX = vars.xPosition;
                vars.xPosition = testX;
                
                if (!isStuckInWall()) {
                    // Found a safe position - stop horizontal movement to prevent re-collision
                    if (vars.isGrounded) {
                        vars.groundSpeed = 0;
                        vars.xSpeed = 0;
                    } else {
                        vars.xSpeed = 0;
                    }
                    
                    writeln("WALL ESCAPE (horizontal): moved from ", originalX, " to ", testX, " (distance: ", distance, ")");
                    escaped = true;
                    break;
                } else {
                    // Restore position for next test
                    vars.xPosition = originalX;
                }
            }
            if (escaped) break;
        }

        // If we couldn't escape horizontally, try moving up slightly
        if (!escaped) {
            for (float upDistance = 1.0f; upDistance <= 16.0f; upDistance += 1.0f) {
                float originalY = vars.yPosition;
                vars.yPosition = originalY - upDistance;
                
                if (!isStuckInWall()) {
                    // Stop movement and escape upward
                    if (vars.isGrounded) {
                        vars.groundSpeed = 0;
                        vars.xSpeed = 0;
                    } else {
                        vars.xSpeed = 0;
                    }
                    vars.ySpeed = -2.0f; // Small upward velocity to help escape
                    
                    writeln("WALL ESCAPE: moved up by ", upDistance, " pixels");
                    escaped = true;
                    break;
                } else {
                    vars.yPosition = originalY;
                }
            }
        }

        if (!escaped) {
            writeln("WALL ESCAPE: Failed to find escape route - player may be deeply embedded");
        }
    }
}