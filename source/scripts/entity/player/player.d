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
import std.math : abs, ceil, floor;

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

struct Player {
    // Core components
    SpriteObject sprite;
    PlayerState state;
    PlayerVariables vars;  // All the physics variables from var.d
    PlayerAnimations animations;
    // Optional pointer to the loaded level so player can query precomputed tile profiles
    LevelData* level = null;
    // Debug visualization for collision samples
    Vector2[] dbgGroundSamples;
    Vector2[] dbgSideSamples;
    Vector2 dbgCandidatePos;
    bool dbgCandidateValid = false;
    bool dbgDrawCollisions = true; // toggleable while tuning

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
    // Resolve horizontal movement along the path from oldX -> targetX
    checkHorizontalCollision(oldX, targetX);

    // After horizontal movement (possibly adjusted), apply vertical movement
    vars.yPosition += vars.ySpeed;

    // Always check ground collision after movement so we can land or fall off edges.
    checkGroundCollision();
    }

    // Ground movement physics
    void updateGroundPhysics() {
        // Skip input if control is locked
        if (vars.controlLockTimer > 0) {
            return;
        }

        // Get current movement constants
        float accel = vars.isSuperSonic ? vars.SUPER_ACCELERATION_SPEED : vars.ACCELERATION_SPEED;
        float decel = vars.isSuperSonic ? vars.SUPER_DECELERATION_SPEED : vars.DECELERATION_SPEED;
        float topSpeed = vars.isSuperSonic ? vars.SUPER_TOP_SPEED : vars.TOP_SPEED;
        float friction = vars.FRICTION_SPEED;

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
        vars.applySlopeFactor();

        // Check for slipping on slopes
        if (vars.shouldSlipOnSlope()) {
            vars.isGrounded = false;
            vars.groundSpeed = 0;
            vars.controlLockTimer = 30; // 30 frames control lock
        }

        // Update X/Y speeds from ground speed
        vars.updateSpeedsFromGroundSpeed();

        // Handle jumping
        if (vars.keyJumpPressed) {
            vars.ySpeed = vars.INITIAL_JUMP_VELOCITY;
            vars.isGrounded = false;
            // Transfer groundSpeed to xSpeed when taking off
            vars.xSpeed = vars.groundSpeed;
            writeln("JUMPING: groundSpeed ", vars.groundSpeed, " transferred to xSpeed ", vars.xSpeed);
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
    float[3] sampleXs = [leftX, centerX, rightX];

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

            foreach (sx; sampleXs) {
                int sampleTileX = cast(int)floor(sx / tileSize);
                int sampleTileY = cast(int)floor(bottom / tileSize);

                Tile tile = utils.level_loader.getTileAtPosition(layer, sampleTileX, sampleTileY);
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

                float tileTopY = cast(float)(sampleTileY * tileSize);
                float surfaceY = tileTopY + (tileSize - cast(float)h);

                // If the bottom is at/under surface and moving downward or stationary, this sample supports the player
                if (vars.ySpeed >= 0 && (bottom >= surfaceY)) {
                    anySupport = true;
                    if (surfaceY < bestSurfaceY) {
                        bestSurfaceY = surfaceY;
                        float ang = world.tile_collision.TileCollision.getTileGroundAngle(tile.tileId, ch.name, level.tilesets);
                        import std.math : isNaN;
                        if (!isNaN(ang)) bestAngle = ang; else bestAngle = 0.0f;
                    }
                    // push debug sample (world position of sample point at surface)
                    float sampleWorldX = cast(float)(sampleTileX * tileSize + localX) + 0.5f;
                    float sampleWorldY = surfaceY;
                    dbgGroundSamples ~= Vector2(sampleWorldX, sampleWorldY);
                }
            }
            // If we've already found support in a higher-priority layer, stop searching lower layers
            if (anySupport) break;
        }

    if (anySupport) {
            // New landing only if previously airborne
            if (!vars.isGrounded) {
                vars.isGrounded = true;
                if (abs(vars.xSpeed) < 1.0f) {
                    vars.groundSpeed = 0;
                } else {
                    vars.groundSpeed = vars.xSpeed;
                }

                // Snap to the best supporting surface
                vars.yPosition = bestSurfaceY - vars.heightRadius;
                vars.groundAngle = bestAngle;
                // Diagnostic: Print the raw tile under each ground sample and try to resolve tileset/localIndex
                import std.math : floor;
                foreach (s; dbgGroundSamples) {
                    int tx = cast(int)floor(s.x / tileSize);
                    int ty = cast(int)floor(s.y / tileSize);
                    // Look up tile in the main ground layers
                    Tile t1 = utils.level_loader.getTileAtPosition(level.groundLayer1, tx, ty);
                    if (t1.tileId > 0) {
                        world.tileset_map.TilesetInfo chosen; int localIdx;
                        if (world.tileset_map.resolveGlobalGid(t1.tileId, level.tilesets, chosen, localIdx)) {
                            writeln("LANDING_DBG: raw=", t1.tileId, " resolved to localIndex=", localIdx, " candidates=", chosen.nameCandidates);
                        } else {
                            writeln("LANDING_DBG: raw=", t1.tileId, " could not resolve tileset");
                        }
                        float a = world.tile_collision.TileCollision.getTileGroundAngle(t1.tileId, "Ground_1", level.tilesets);
                        writeln("LANDING_DBG: tile angle returned=", a);
                    }
                }
                writeln("LANDING (multi-sample) surfaceY=", bestSurfaceY, " -> yPosition=", vars.yPosition, " angle=", bestAngle);
                return true;
            }
            // Already grounded: keep grounded
            vars.isGrounded = true;
            return false;
        }

        // No sample supported us
        vars.isGrounded = false;
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
        if (steps == 0) {
            // No horizontal movement; still run side sample debug at current position
            dbgSideSamples = [];
            float leftEdgeX = oldX - vars.widthRadius + 1.0f;
            float rightEdgeX = oldX + vars.widthRadius - 1.0f;
            // Don't sample the bottom-most pixels (feet area) since they will hit the ground
            float sideSampleInset = 6.0f;
            float topY = vars.yPosition - vars.heightRadius + 1.0f;
            float bottomY = vars.yPosition + vars.heightRadius - 1.0f - sideSampleInset;
            int samples = 5;
            float dy = (bottomY - topY) / cast(float)(samples - 1);
            bool overlapAt(float x, float y) { return isSolidAtPosition(*level, x, y); }
            for (int i = 0; i < samples; ++i) {
                float sy = topY + dy * i;
                dbgSideSamples ~= Vector2(leftEdgeX, sy);
                dbgSideSamples ~= Vector2(rightEdgeX, sy);
            }
            return;
        }

        float stepDir = dx > 0 ? 1.0f : -1.0f;
        float lastSafeX = oldX;
        dbgSideSamples = [];

        // Helper to test overlap at a candidate centerX and sample vertically.
        // Additionally consults the tile height profile beneath candidateX and allows
        // small step-ups (within stepHeight) so the player can traverse low ledges.
        bool overlapsAtCenter(float centerX) {
            float leftEdgeX = centerX - vars.widthRadius + 1.0f;
            float rightEdgeX = centerX + vars.widthRadius - 1.0f;
            // Don't sample the bottom-most pixels (feet area) since those will be in contact with ground
            float sideSampleInset = 6.0f;
            float topY = vars.yPosition - vars.heightRadius + 1.0f;
            float bottomY = vars.yPosition + vars.heightRadius - 1.0f - sideSampleInset;
            int samples = 5;
            float dy = (bottomY - topY) / cast(float)(samples - 1);
            // Allow small step-ups when moving horizontally (e.g., stepHeight in pixels)
            float maxStepUp = 6.0f;

            // Helper to get surface Y at an X world coordinate (using precomputed profiles if available)
            float getSurfaceYAtX(float worldX) {
                if (level is null) return 1e9;
                int tileSize = 16;
                int tx = cast(int)floor(worldX / tileSize);
                // Choose the tile row that is currently under the player's bottom
                int sampleTileY = cast(int)floor((vars.yPosition + vars.heightRadius) / tileSize);

                // Layers to check in priority order (SOLID layers only - exclude semisolids for horizontal collision)
                struct LayerCheck { Tile[][]* layer; string name; }
                LayerCheck[3] checks = [
                    LayerCheck(&level.collisionLayer, "Collision"),
                    LayerCheck(&level.groundLayer1, "Ground_1"),
                    LayerCheck(&level.groundLayer2, "Ground_2")
                ];

                foreach (ch; checks) {
                    Tile[][] layer = *ch.layer;
                    if (layer.length == 0) continue;
                    Tile tile = utils.level_loader.getTileAtPosition(layer, tx, sampleTileY);
                    if (tile.tileId <= 0) continue;

                    world.tile_collision.TileHeightProfile profile;
                    bool hadProfile = utils.level_loader.getPrecomputedTileProfile(*level, tile.tileId, ch.name, profile);
                    if (!hadProfile) {
                        profile = world.tile_collision.TileCollision.getTileHeightProfile(tile.tileId, ch.name, level.tilesets);
                    }

                    int localX = cast(int)floor(worldX) - tx * tileSize;
                    if (localX < 0) localX = 0;
                    if (localX > 15) localX = 15;
                    int h = profile.groundHeights[localX];

                    float tileTopY = cast(float)(sampleTileY * tileSize);
                    return tileTopY + (tileSize - cast(float)h);
                }

                return 1e9; // no tile found
            }

            // Compute the surface at the forward edge and compare against player's bottom
            float forwardX = centerX + (vars.groundSpeed >= 0 ? vars.widthRadius : -vars.widthRadius);
            float surfaceY = getSurfaceYAtX(forwardX);
            float playerBottom = vars.yPosition + vars.heightRadius;
            if (surfaceY < 1e8) {
                // stepUp: positive when the forward surface is higher (smaller Y)
                float stepUp = playerBottom - surfaceY;
                if (stepUp > 0.0f) {
                    // If the forward surface is higher than current bottom
                    if (stepUp <= maxStepUp) {
                        // Allow stepping up: snap candidate centerY to surface
                        // We'll not treat this as a blocking overlap
                        // But also update dbgGroundSamples for visualization
                        dbgGroundSamples ~= Vector2(forwardX, surfaceY);
                        return false; // not overlapping because we can step up
                    } else {
                        // Too high to step up -> blocking
                        return true;
                    }
                }
                // If stepUp <= 0, forward surface is below or equal to bottom -> no block
            }

            for (int i = 0; i < samples; ++i) {
                float sy = topY + dy * i;
                dbgSideSamples ~= Vector2(leftEdgeX, sy);
                dbgSideSamples ~= Vector2(rightEdgeX, sy);
                if (isSolidAtPosition(*level, leftEdgeX, sy) || isSolidAtPosition(*level, rightEdgeX, sy)) return true;
            }
            return false;
        }

        // Step along the path and record the last safe X
        for (int i = 1; i <= steps; ++i) {
            float candidateX = oldX + stepDir * cast(float)i;
            if (overlapsAtCenter(candidateX)) {
                // Hit a wall - gentle push to prevent sticking while allowing slope climbing
                float pushDirection = (stepDir > 0) ? -1.0f : 1.0f; // Push away from wall
                float pushAmount = 4.0f; // Gentle push to prevent sticking but allow slope movement

                vars.xPosition = candidateX + (pushDirection * pushAmount);

                // Context-aware bounce: gentler for grounded movement, stronger for high-speed impacts
                float currentSpeed = vars.isGrounded ? abs(vars.groundSpeed) : abs(vars.xSpeed);
                float bounceMultiplier = 0.4f; // Reduced from 0.3f for gentler bounce

                // Minimum bounce speed to prevent complete sticking
                float minBounceSpeed = 0.5f;

                if (vars.isGrounded) {
                    // Grounded: consider ground angle for slope-aware response
                    float angleRad = vars.groundAngle * (3.14159f / 180.0f);
                    float slopeFactor = abs(angleRad) > 0.1f ? 0.7f : 1.0f; // Reduce bounce on slopes

                    if (abs(vars.groundSpeed) < minBounceSpeed) {
                        vars.groundSpeed = pushDirection * minBounceSpeed;
                    } else {
                        vars.groundSpeed = -vars.groundSpeed * bounceMultiplier * slopeFactor;
                    }
                    vars.xSpeed = vars.groundSpeed;
                } else {
                    // Air: standard bounce
                    if (abs(vars.xSpeed) < minBounceSpeed) {
                        vars.xSpeed = pushDirection * minBounceSpeed;
                    } else {
                        vars.xSpeed = -vars.xSpeed * bounceMultiplier;
                    }
                }

                // Shorter cooldown to allow responsive slope climbing
                wallCollisionCooldown = 2; // Reduced from 5 frames

                writeln("WALL PUSH: direction=", pushDirection, " pushAmount=", pushAmount, " newX=", vars.xPosition, " xSpeed=", vars.xSpeed, " groundAngle=", vars.groundAngle);

                dbgCandidateValid = false;
                return;
            } else {
                // If we detected a step-up at this candidate (dbgGroundSamples appended),
                // snap yPosition to that surface so movement continues seamlessly.
                if (dbgGroundSamples.length > 0) {
                    auto last = dbgGroundSamples[$ - 1];
                    float newSurfaceY = last.y;
                    vars.yPosition = newSurfaceY - vars.heightRadius;
                    // Update ground angle from tile under forwardX
                    float ang = world.tile_collision.TileCollision.getTileGroundAngle(0, "", level.tilesets);
                    // Try to compute a real angle by fetching tile under forwardX
                    int tileSize = 16;
                    int tx = cast(int)floor((candidateX + (vars.groundSpeed >= 0 ? vars.widthRadius : -vars.widthRadius)) / tileSize);
                    int ty = cast(int)floor((vars.yPosition + vars.heightRadius) / tileSize);
                    struct LayerCheck2 { Tile[][]* layer; string name; }
                    LayerCheck2[3] layerChecks = [
                        LayerCheck2(&level.groundLayer1, "Ground_1"), 
                        LayerCheck2(&level.groundLayer2, "Ground_2"), 
                        LayerCheck2(&level.collisionLayer, "Collision")
                    ];
                    foreach (lc; layerChecks) {
                        Tile[][] layer = *lc.layer;
                        if (layer.length == 0) continue;
                        Tile t = utils.level_loader.getTileAtPosition(layer, tx, ty);
                        if (t.tileId <= 0) continue;
                        float a = world.tile_collision.TileCollision.getTileGroundAngle(t.tileId, lc.name, level.tilesets);
                        import std.math : isNaN;
                        if (!isNaN(a)) {
                            vars.groundAngle = a;
                            break;
                        }
                    }

                }
                lastSafeX = candidateX;
            }
        }

        // If we reached here, targetX is safe
        vars.xPosition = targetX;
        dbgCandidatePos = Vector2(vars.xPosition, vars.yPosition);
        dbgCandidateValid = true;
    }
}