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
import std.math : abs;

import entity.sprite_object;
import entity.player.var;
import utils.level_loader; // for LevelData and helpers
import world.tile_collision; // for TileHeightProfile and angle helper
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
    sprite.width = cast(int)(vars.widthRadius * 2);
    sprite.height = cast(int)(vars.heightRadius * 2);
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

        // Update position
        vars.xPosition += vars.xSpeed;
        vars.yPosition += vars.ySpeed;

        // Check for landing after moving
        if (!vars.isGrounded) {
            if (checkGroundCollision()) {
                // Landed this frame, groundSpeed is now set from x/y speed
            }
        }
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
        // Render at player position using native 1:1 scale; SpriteObject.scale is preserved for legacy draws
        animations.render(Vector2(vars.xPosition, vars.yPosition), 1.0f);
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

        // Compute bottom point in world coordinates
        float bottom = vars.yPosition + vars.heightRadius;
        int tileSize = 16;
        int tileX = cast(int)floor(vars.xPosition / tileSize);
        int tileY = cast(int)floor(bottom / tileSize);

        // Helper to compute local X inside tile (0..15)
        int localXInTile(float worldX, int tx) {
            int lx = cast(int)floor(worldX) - tx * tileSize;
            if (lx < 0) lx = 0;
            if (lx > 15) lx = 15;
            return lx;
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

        foreach (ch; checks) {
            Tile[][] layer = *ch.layer;
            if (layer.length == 0) continue;

            // Get tile at candidate position
            Tile tile = utils.level_loader.getTileAtPosition(layer, tileX, tileY);
            if (tile.tileId <= 0) continue;

            // Attempt to use precomputed profile (preferred)
            world.tile_collision.TileHeightProfile profile;
            bool hadProfile = utils.level_loader.getPrecomputedTileProfile(*level, tile.tileId, ch.name, profile);

            if (!hadProfile) {
                // Fallback: ask runtime TileCollision for a profile (this will consult generated tables as available)
                profile = world.tile_collision.TileCollision.getTileHeightProfile(tile.tileId, ch.name, level.tilesets);
            }

            // Determine local column within tile from player's X
            int localX = localXInTile(vars.xPosition, tileX);
            int h = profile.groundHeights[localX]; // 0..16

            // Calculate surface Y (top of solid pixels in tile). If h==0 => surface is tile bottom
            float tileTopY = cast(float)(tileY * tileSize);
            float surfaceY = tileTopY + (tileSize - cast(float)h);

            // We allow landing only when moving downward (or stationary) to avoid catching upward movement
            if (vars.ySpeed >= 0 && (bottom >= surfaceY)) {
                // New landing only if previously airborne
                if (!vars.isGrounded) {
                    vars.isGrounded = true;
                    // Transfer horizontal speed into groundSpeed on landing similarly to previous simple rule
                    if (abs(vars.xSpeed) < 1.0f) {
                        vars.groundSpeed = 0;
                    } else {
                        vars.groundSpeed = vars.xSpeed;
                    }

                    // Snap player to surface
                    vars.yPosition = surfaceY - vars.heightRadius;

                    // Update ground angle from generated tables when available
                    float ang = world.tile_collision.TileCollision.getTileGroundAngle(tile.tileId, ch.name, level.tilesets);
                    // Only assign if the angle is a finite number; some tiles may not have a defined angle
                    import std.math : isNaN;
                    if (!isNaN(ang)) {
                        vars.groundAngle = ang;
                    } else {
                        // Fallback to flat ground if angle is undefined
                        vars.groundAngle = 0.0f;
                    }

                    writeln("LANDING: tile(", ch.name, ") raw=", tile.tileId, " at (", tileX, ",", tileY, ") localX=", localX, " surfaceY=", surfaceY, " -> yPosition=", vars.yPosition);
                    return true;
                }
                // Already grounded: keep grounded
                vars.isGrounded = true;
                return false;
            }
        }

        // No tile surface detected beneath us
        vars.isGrounded = false;
        return false;
    }
}