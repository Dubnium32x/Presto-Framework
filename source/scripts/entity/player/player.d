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
import std.algorithm;

import entity.sprite_object;
import entity.player.var;
import utils.level_loader; // for LevelData and helpers
import world.tile_collision; // for TileHeightProfile and angle helper
import world.tileset_map;
import entity.player.animations;
import sprite.sprite_manager;
import sprite.animation_manager;
import utils.spritesheet_splitter;
import world.audio_manager;
import world.input_manager;

// Skid tuning constants
immutable float SKID_MIN_SPEED = 2.5f;        // minimum groundSpeed required to enter skid
immutable float SKID_DECEL_FACTOR = 0.5f;    // factor to reduce deceleration when skidding (slower decel)
// Idle impatience constants (seconds)
immutable float IDLE_IMPATIENT_DELAY = 5.0f;    // time before Sonic does the impatient look
immutable float IDLE_IMPATIENT_LOOK_TIME = 1.5f; // how long the look/animation plays before looping

enum PlayerState {
    IDLE,
    WALKING,
    CROUCHING,
    LOOKING_UP,
    SKIDDING,
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

enum IdleState {
    NORMAL,
    IMPATIENT_LOOK,
    IMPATIENT_ANIMATION
}

enum GroundCollisionMode {
    NONE,
    FLOOR,
    LEFT_WALL,
    RIGHT_WALL,
    CEILING
}

struct Player {
    // Spindash charge tracking
    int spindashCharge = 0; // Number of jump presses while crouching
    static immutable int SPINDASH_CHARGE_MAX = 6;
    static immutable float SPINDASH_MIN_SPEED = 6.0f;
    static immutable float SPINDASH_SPEED_PER_CHARGE = 1.5f;
    // Spindash SFX state
    bool spindashChargeSoundPlaying = false;
    // Previous state for sound triggers
    PlayerState previousState = PlayerState.IDLE;
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
    // Debug logging controls
    bool dbgRollSpindash = true;   // show only roll/spindash related logs
    bool dbgVerbose = false;       // gate noisy physics/collision logs
    // Debug: last ground contact info (tile/layer) for angle verification
    int dbgLastGroundTileRawId = -1;
    string dbgLastGroundLayerName = "";
    // Collision mode tracking for wall/ceiling running
    GroundCollisionMode collisionMode = GroundCollisionMode.NONE;
    // One-frame event flags to protect immediate transitions
    bool justLanded = false; // set when collision detects a new landing this frame
    bool justJumped = false; // set when a jump is initiated this frame
    bool justSpindashLaunched = false; // set for one frame after spindash launch
    
    // Push state tracking
    bool hitWallThisFrame = false;
    int pushTimer = 0; // frames spent pushing
    // Crouch height bookkeeping
    float savedHeightRadius = 0.0f;
    bool crouchHeightApplied = false;
    // Remember bottom position when crouching so we can keep feet grounded
    float savedCrouchBottom = 0.0f;
    // Camera crouch look delay
    float crouchLookTimer = 0.0f;
    static immutable float CROUCH_CAMERA_DELAY = 0.5f; // seconds before camera pans when crouching
    // Idle impatience tracking
    float idleTimer = 0.0f; // seconds spent idle
    bool isImpatient = false; // whether we've entered impatient mode
    IdleState idleSubState = IdleState.NORMAL;
    // Animation state preservation
    PlayerAnimationState lastGroundAnimationState = PlayerAnimationState.IDLE;
    // Roll permission flag - enabled after spindash, disabled when landing without down input
    bool canRoll = false;
    bool isRolling = false; // whether we're currently in a roll (separate from canRoll)
    int canRollGraceFrames = 0; // grace period after landing from roll

    // Constructor
    static Player create(float x, float y) {
        Player player;
        player.sprite = SpriteObject();
        player.state = PlayerState.IDLE;
        player.vars = PlayerVariables();
    player.vars.resetPosition(x, y + 1);
        return player;
    }

    // Attach the level so collision queries can prefer precomputed profiles
    void setLevel(LevelData* lvl) {
        this.level = lvl;
    }

    // Initialize the player
    void initialize(float x, float y) {
        vars = PlayerVariables();
    vars.resetPosition(x, y + 1);

    // Initialize sprite positioning and sizing
    sprite.x = x;
    sprite.y = y + 1;
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

    // writeln("Player initialized at position: (", x, ", ", y, ")");
    }

    // Update player input
    void updateInput() {
        // Store previous input state for edge detection
        bool prevJump = vars.keyJump;

        // Read current input
        vars.keyLeft = InputManager.getInstance().isDown(InputBit.LEFT);
        vars.keyRight = InputManager.getInstance().isDown(InputBit.RIGHT);
        vars.keyUp = InputManager.getInstance().isDown(InputBit.UP);
        vars.keyDown = InputManager.getInstance().isDown(InputBit.DOWN);
        vars.keyJump = InputManager.getInstance().isDown(InputBit.A);

        // Detect edge events
        vars.keyJumpPressed = vars.keyJump && !prevJump;
        vars.keyJumpReleased = !vars.keyJump && prevJump;
    // Toggle slope debug with P (keep keyboard-only for debug)
    if (IsKeyPressed(KeyboardKey.KEY_P)) dbgSlopeDebug = !dbgSlopeDebug;
    // Toggle verbose physics/collision logs with F9
    if (IsKeyPressed(KeyboardKey.KEY_F9)) dbgVerbose = !dbgVerbose;
    // Toggle roll/spindash logs with F10
    if (IsKeyPressed(KeyboardKey.KEY_F10)) dbgRollSpindash = !dbgRollSpindash;
    }


    // Main update function
    void update(float deltaTime) {
        updateInput();
    // Toggle collision debug drawing with O (optional)
    // Toggle collision debug with O (keep keyboard-only for debug)
    if (IsKeyPressed(KeyboardKey.KEY_O)) dbgDrawCollisions = !dbgDrawCollisions;
        // Debug: track update order for spindash states
        if (dbgVerbose && (state == PlayerState.SPINDASHING || state == PlayerState.ROLLING || justSpindashLaunched)) {
            writeln("[UPDATE DEBUG] Before physics - state: ", state, " justSpindashLaunched: ", justSpindashLaunched);
        }
        updatePhysics(deltaTime);
        if (dbgVerbose && (state == PlayerState.SPINDASHING || state == PlayerState.ROLLING || justSpindashLaunched)) {
            writeln("[UPDATE DEBUG] Before updateState - state: ", state, " justSpindashLaunched: ", justSpindashLaunched);
        }
        updateState();
        if (dbgVerbose && (state == PlayerState.SPINDASHING || state == PlayerState.ROLLING || justSpindashLaunched)) {
            writeln("[UPDATE DEBUG] After updateState - state: ", state, " justSpindashLaunched: ", justSpindashLaunched);
        }
        // Manage idle impatience timing here (use deltaTime available)
        if (state == PlayerState.IDLE) {
            idleTimer += deltaTime;
            if (!isImpatient && idleTimer >= IDLE_IMPATIENT_DELAY) {
                isImpatient = true;
                idleSubState = IdleState.IMPATIENT_LOOK;
                // start the look animation immediately
                animations.setPlayerAnimationState(PlayerAnimationState.IMPATIENT_LOOK);
            } else if (isImpatient && idleSubState == IdleState.IMPATIENT_LOOK && idleTimer >= (IDLE_IMPATIENT_DELAY + IDLE_IMPATIENT_LOOK_TIME)) {
                idleSubState = IdleState.IMPATIENT_ANIMATION;
                animations.setPlayerAnimationState(PlayerAnimationState.IMPATIENT);
            }
        } else {
            // Reset impatience when not idle
            idleTimer = 0.0f;
            isImpatient = false;
            idleSubState = IdleState.NORMAL;
        }

        // Spindash SFX logic
        if (state == PlayerState.SPINDASHING) {
            // Play charge sound if not already playing
            if (!spindashChargeSoundPlaying) {
                AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic Jam S3/120.wav", 1.0f);
                spindashChargeSoundPlaying = true;
            }
        } else {
            // If we just released spindash, play release sound
            if (spindashChargeSoundPlaying) {
                AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic Jam S3/131.wav", 1.0f);
                spindashChargeSoundPlaying = false;
            }
        }
        if (dbgVerbose && (state == PlayerState.SPINDASHING || state == PlayerState.ROLLING || justSpindashLaunched)) {
            writeln("[UPDATE DEBUG] Before updateAnimation - state: ", state, " justSpindashLaunched: ", justSpindashLaunched);
        }
        updateAnimation(deltaTime);
        if (dbgVerbose && (state == PlayerState.SPINDASHING || state == PlayerState.ROLLING || justSpindashLaunched)) {
            writeln("[UPDATE DEBUG] After updateAnimation - state: ", state, " justSpindashLaunched: ", justSpindashLaunched);
        }
        updateSpritePosition();
        // Clear one-frame event flags so they only protect the immediate frame
    justLanded = false;
    justJumped = false;
    justSpindashLaunched = false;
        if (dbgVerbose && (state == PlayerState.SPINDASHING || state == PlayerState.ROLLING)) {
            writeln("[UPDATE DEBUG] End of frame - state: ", state, " cleared justSpindashLaunched");
        }
    }

    // Update physics based on SPG
    void updatePhysics(float deltaTime) {
        // Clear wall collision flag from previous frame
        hitWallThisFrame = false;
        
        // Handle control lock timer
        if (vars.controlLockTimer > 0) {
            vars.controlLockTimer--;
        }

        // Handle canRoll grace period
        if (canRollGraceFrames > 0) {
            canRollGraceFrames--;
            if (canRollGraceFrames == 0 && !vars.keyDown && vars.isGrounded) {
                canRoll = false;
                if (dbgRollSpindash) writeln("[ROLL DEBUG] Grace period expired - disabled canRoll");
            }
        }

        if (vars.isGrounded) {
            updateGroundPhysics();
        } else {
            updateAirPhysics();
        }

        // Apply gravity if airborne OR handle collision-mode-specific gravity
        if (!vars.isGrounded) {
            vars.ySpeed += vars.GRAVITY_FORCE;
            if (vars.ySpeed > vars.TOP_Y_SPEED) {
                vars.ySpeed = vars.TOP_Y_SPEED;
            }
        } else {
            // Apply collision-mode-specific gravity/physics
            handleCollisionModePhysics();
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
            // Only detect walls for push state on flat ground - slopes should allow movement up
            if (abs(vars.groundAngle) < 5.0f) {
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
                    if (dbgVerbose) writeln("[PUSH CHECK] Wall detected while stationary on flat ground");
                }
            } else {
                if (dbgVerbose) writeln("[SLOPE DEBUG] Skipping wall check on slope, angle=", vars.groundAngle);
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
            // writeln("[PUSH STATE] Blocking vertical movement");
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
                    // writeln("[PUSH STATE] Blocking movement into wall (x only)");
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
        if (vars.isRolling && canRoll) {
            updateRollingPhysics();
            return;
        }

        // Left input
        if (vars.keyLeft && !vars.keyRight) {
            if (vars.groundSpeed > 0) {
                // Decelerate when moving right but pressing left
                // If reversing while above skid threshold, decelerate more slowly to create a skid
                float appliedDecel = (abs(vars.groundSpeed) > SKID_MIN_SPEED) ? decel * SKID_DECEL_FACTOR : decel;
                vars.groundSpeed -= appliedDecel;
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
                float appliedDecel = (abs(vars.groundSpeed) > SKID_MIN_SPEED) ? decel * SKID_DECEL_FACTOR : decel;
                vars.groundSpeed += appliedDecel;
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
        
        if (dbgVerbose && abs(vars.groundAngle) > 1.0f) {
            writeln("[SLOPE PHYSICS] angle=", vars.groundAngle, " preGS=", preSlopeGS, " postGS=", postSlopeGS, " diff=", (postSlopeGS - preSlopeGS));
        }
        
        if (dbgVerbose && abs(vars.groundAngle) > 1.0f) {
            writeln("[SLOPE PHYSICS] angle=", vars.groundAngle, " preGS=", preSlopeGS, " postGS=", postSlopeGS, " diff=", (postSlopeGS - preSlopeGS));
        }

        // Check for slipping on slopes
        if (vars.shouldSlipOnSlope()) {
            vars.isGrounded = false;
            vars.groundSpeed = 0;
            vars.controlLockTimer = 30; // 30 frames control lock
        }

        if (dbgSlopeDebug) {
            /* writeln("SlopeDbg: angle=", vars.groundAngle, " deg, angleRad=", angleRad,
                    " slopeModifier=", slopeModifier,
                    " preGS=", preSlopeGS, " postGS=", postSlopeGS,
                    " xSpeed=", vars.xSpeed, " ySpeed=", vars.ySpeed);
                    */
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

        // Handle jumping (allow jumping while rolling when grounded)
        if (vars.keyJumpPressed && vars.isGrounded && state != PlayerState.SPINDASHING) {
            writeln("[JUMP] Jump initiated from state ", state);
            canRoll = false;
            state = PlayerState.JUMPING;
            vars.isRolling = false;
            AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic Jam S3/47.wav", 1.0f);
            vars.isGrounded = false;
            vars.hasJumped = true;
            // Mark a one-frame jump so updateState doesn't overwrite in the same frame
            justJumped = true;

            // Compose jump along surface normal: angleNormal = groundAngle - 90deg
            angleRad = vars.groundAngleRadians();
            if (isNaN(angleRad)) angleRad = 0.0f;
            // Normal vector pointing out of the surface
            float nx = -sin(angleRad);
            float ny = -cos(angleRad);
            // Scale by jump speed
            float v = -vars.INITIAL_JUMP_VELOCITY; // magnitude (positive)
            // When nearly flat, keep forward momentum like classic Sonic
            if (abs(vars.groundAngle) < 8.0f) {
                vars.ySpeed = vars.INITIAL_JUMP_VELOCITY; // straight up
                vars.xSpeed = vars.groundSpeed;           // preserve forward
            } else {
                // Project jump along surface normal (outward from ground)
                vars.xSpeed = nx * v + (vars.groundSpeed * cos(angleRad));
                vars.ySpeed = ny * v + (vars.groundSpeed * -sin(angleRad));
            }

            // Important: return early so updateState() doesn't overwrite the JUMPING state this frame
            return;
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
            if (state == PlayerState.ROLLING) {
                state = PlayerState.IDLE;
                writeln("[ROLL DEBUG] Exiting roll due to low speed: ", vars.groundSpeed);
            }
        }

        // Exit rolling if jump is pressed
        if (vars.keyJumpPressed && vars.isGrounded) {
            writeln("[ROLL DEBUG] Exiting roll due to jump press");
            vars.isRolling = false;
            state = PlayerState.JUMPING;
            vars.ySpeed = vars.INITIAL_JUMP_VELOCITY;
            vars.isGrounded = false;
            vars.hasJumped = true;
            AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic Jam S3/47.wav", 1.0f);
            // Keep horizontal momentum - simple and safe
            if (abs(vars.groundAngle) < 15.0f) {
                // Nearly flat - use groundSpeed directly
                vars.xSpeed = vars.groundSpeed;
            } else {
                // Steep slope - use current xSpeed to avoid projection errors
                // vars.xSpeed stays as-is
            }
        }
        // Apply slope physics
        vars.applySlopeFactor();
        vars.updateSpeedsFromGroundSpeed();
    }

    // Handle collision-mode-specific physics (walls, ceiling, etc.)
    void handleCollisionModePhysics() {
        switch (collisionMode) {
            case GroundCollisionMode.FLOOR:
                // Normal floor physics - no special gravity adjustments
                break;
                
            case GroundCollisionMode.LEFT_WALL:
            case GroundCollisionMode.RIGHT_WALL:
                // Wall physics - apply gravity in the direction perpendicular to the wall
                // For walls, gravity should pull the player away from the wall
                float wallGravity = vars.GRAVITY_FORCE * 0.5f; // Reduced gravity on walls
                
                if (collisionMode == GroundCollisionMode.LEFT_WALL) {
                    // Left wall - gravity pulls to the right
                    vars.xSpeed += wallGravity;
                } else {
                    // Right wall - gravity pulls to the left  
                    vars.xSpeed -= wallGravity;
                }
                
                // Check if we should fall off the wall due to gravity
                if (abs(vars.groundSpeed) < 1.0f) {
                    vars.isGrounded = false;
                    collisionMode = GroundCollisionMode.NONE;
                    if (dbgVerbose) writeln("[WALL RUNNING] Falling off wall due to low speed");
                }
                break;
                
            case GroundCollisionMode.CEILING:
                // Ceiling physics - gravity pulls downward, away from ceiling
                vars.ySpeed += vars.GRAVITY_FORCE;
                
                // Fall off ceiling if moving too slowly
                if (abs(vars.groundSpeed) < 3.0f) {
                    vars.isGrounded = false;
                    collisionMode = GroundCollisionMode.NONE;
                    if (dbgVerbose) writeln("[CEILING RUNNING] Falling off ceiling due to low speed");
                }
                break;
                
            default:
                break;
        }
    }

    // Update player state
    void updateState() {
        // If we just initiated a jump this frame, keep JUMPING and skip overwriting logic
        if (justJumped) {
            // clear justJumped here (it will be reset at end of update())
            return;
        }
        // If we just landed this frame, rely on the landing decision made in checkGroundCollision()
        if (justLanded) {
            // clear justLanded later in update(); skip additional state inference this frame
            return;
        }
        // --- Classic Rolling Logic (Sonic 2/3 style) ---
        // If grounded, not already rolling, not spindashing, and moving fast enough, pressing down triggers roll
        // BUT only if canRoll is true (earned through spindash)
        static immutable float ROLL_MIN_SPEED = 2.0f;
        // Roll attempt diagnostics
        if (dbgRollSpindash && vars.keyDown && state != PlayerState.SPINDASHING) {
            string reason = "";
            canRoll = true; // TEMP: allow rolling always for testing
            if (!vars.isGrounded) reason ~= "not_grounded ";
            if (abs(vars.groundSpeed) < ROLL_MIN_SPEED) reason ~= "speed<min(" ~ to!string(ROLL_MIN_SPEED) ~ ") actual=" ~ to!string(abs(vars.groundSpeed)) ~ " ";
            if (state == PlayerState.ROLLING) reason ~= "already_rolling ";
            if (reason.length == 0) reason = "eligible";
            writeln("[ROLL DEBUG] Roll attempt: ", reason, " state=", state, " gs=", vars.groundSpeed, " canRoll=", canRoll);
        }

        // Classic rolling - allow pressing down while moving fast (no canRoll requirement)
        if (state != PlayerState.ROLLING && state != PlayerState.SPINDASHING && vars.isGrounded && abs(vars.groundSpeed) >= ROLL_MIN_SPEED && vars.keyDown && canRoll) {
            state = PlayerState.ROLLING;
            vars.isRolling = true;
            canRoll = true; // Set canRoll when manually rolling
            if (dbgRollSpindash) writeln("[ROLL DEBUG] Rolling enabled by pressing down while moving fast");
            // Optionally play roll sound here
        }
        // If rolling and become airborne, switch to FALLING_ROLLING
        if (state == PlayerState.ROLLING && !vars.isGrounded) {
            state = PlayerState.FALLING_ROLLING;
        }
        // FALLING_ROLLING landing is handled by checkGroundCollision, skip here to avoid conflicts
        // Only exit roll if speed is near zero (while grounded)
        if (state == PlayerState.ROLLING && abs(vars.groundSpeed) < 0.5f && vars.isGrounded) {
            state = PlayerState.IDLE;
            vars.isRolling = false;
            canRoll = true; // Allow rolling again after stopping
        }

        // Classic Sonic 2/3 Spindash logic
        // Enter spindash if crouching and jump is pressed
        // Only allow spindash from crouch if not rolling and not moving fast
        if (state == PlayerState.CROUCHING && !vars.isRolling && abs(vars.groundSpeed) < ROLL_MIN_SPEED && vars.keyJumpPressed) {
            state = PlayerState.SPINDASHING;
            spindashCharge = 1;
            AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic Jam S3/10.wav", 1.0f); // Spindash start
            writeln("[SPINDASH DEBUG] ENTERED SPINDASH STATE - charge: ", spindashCharge);
        }
        // While in spindash, charge up with more jump presses
        if (state == PlayerState.SPINDASHING) {
            writeln("[DEBUG] Spindashd charge: ", spindashCharge);
            if (vars.keyJumpPressed && spindashCharge < SPINDASH_CHARGE_MAX) {
                spindashCharge++;
                AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic Jam S3/120.wav", 1.0f); // Spindash charge
            }
            // Release spindash if down is released or jump is released
            if (!vars.keyDown || vars.keyJumpReleased) {
                float launchSpeed = SPINDASH_MIN_SPEED + (spindashCharge - 1) * SPINDASH_SPEED_PER_CHARGE;
                if (launchSpeed < SPINDASH_MIN_SPEED) launchSpeed = SPINDASH_MIN_SPEED;
                vars.groundSpeed = launchSpeed * vars.facing;
                vars.xSpeed = launchSpeed * vars.facing; // Forcefully blast off in facing direction
                writeln("[SPINDASH DEBUG] RELEASING - charge: ", spindashCharge, " launchSpeed: ", launchSpeed, " groundSpeed: ", vars.groundSpeed, " xSpeed: ", vars.xSpeed);
                state = PlayerState.ROLLING;
                vars.isRolling = true;
                canRoll = true; // Enable rolling after spindash
                AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic Jam S3/131.wav", 1.0f); // Spindash release
                spindashCharge = 0;
                // No manual animation set here; rely on state-driven animation
                justSpindashLaunched = true;
                writeln("[SPINDASH DEBUG] STATE CHANGED TO ROLLING - justSpindashLaunched: ", justSpindashLaunched);
            }
        }
        if (justSpindashLaunched) {
            return;
        }
        // Debug: Always print current state and inputs
         // writeln("[STATE DEBUG] Current state: ", state, " isGrounded: ", vars.isGrounded, " hasInput: ", (vars.keyLeft || vars.keyRight), " hitWall: ", hitWallThisFrame);
        
        if (vars.isGrounded) {
            // Check for push state first - but NOT on slopes
            bool hasHorizontalInput = vars.keyLeft || vars.keyRight;
            bool onSlope = abs(vars.groundAngle) > 5.0f;
            
            // Only allow push state on flat ground - slopes should allow movement
            if (!onSlope) {
                // Enter push state if we hit a wall this frame OR if we're already pushing and still trying to move
                if ((hitWallThisFrame && hasHorizontalInput) || 
                    (state == PlayerState.PUSHING && hasHorizontalInput && abs(vars.groundSpeed) < 0.1f)) {
                    state = PlayerState.PUSHING;
                    pushTimer++;
                    if (dbgVerbose) writeln("ENTERING/STAYING IN PUSH STATE - timer: ", pushTimer);
                    return;
                } else {
                    // Reset push timer when not pushing
                    if (state == PlayerState.PUSHING) {
                        if (dbgVerbose) writeln("EXITING PUSH STATE");
                    }
                    pushTimer = 0;
                }
            } else {
                // On slope - always exit push state and allow movement
                if (state == PlayerState.PUSHING) {
                    if (dbgVerbose) writeln("EXITING PUSH STATE - on slope angle=", vars.groundAngle);
                }
                pushTimer = 0;
            }
            
            // Check if we're trying to move into a wall - only check direction of movement
            bool movingIntoWall = false;
            if (hasHorizontalInput && abs(vars.groundSpeed) < 0.5f) {
                bool checkingRight = vars.keyRight;
                movingIntoWall = isNextToWallInDirection(checkingRight);
                
                // writeln("[WALL PROXIMITY DEBUG] checkingRight: ", checkingRight, " movingIntoWall: ", movingIntoWall);
                
                if (movingIntoWall) {
                    // Trying to move into wall - go to push state
                    state = PlayerState.PUSHING;
                    // writeln("[WALL PROXIMITY] Entering push state - moving into wall");
                    return;
                }
            }
            
                // Normal ground state logic - only blocked if moving INTO wall, not away from it
                // Crouch: only allow crouching when completely stationary and no horizontal input
                // Only apply crouch height if grounded and crouching
                bool shouldCrouch = vars.isGrounded && vars.keyDown && !vars.isRolling && !vars.isSpinDashing && abs(vars.groundSpeed) < 0.1f && !vars.keyLeft && !vars.keyRight;
                if (shouldCrouch) {
                    if (!crouchHeightApplied) {
                        savedHeightRadius = vars.heightRadius;
                        savedCrouchBottom = vars.yPosition + vars.heightRadius;
                        vars.heightRadius = max(8.0f, vars.heightRadius * 0.6f);
                        vars.yPosition = savedCrouchBottom - vars.heightRadius;
                        crouchHeightApplied = true;
                    }
                    state = PlayerState.CROUCHING;
                } else {
                    // Always restore height if not grounded or not crouching
                    if (crouchHeightApplied) {
                        vars.heightRadius = savedHeightRadius;
                        vars.yPosition = savedCrouchBottom - vars.heightRadius;
                        crouchHeightApplied = false;
                    }
                    if (vars.isRolling) {
                        state = PlayerState.ROLLING;
                    } else if (abs(vars.groundSpeed) < 0.1f) {
                        state = PlayerState.IDLE;
                    } else {
                        bool turningLeftIntoSkid = (vars.groundSpeed > SKID_MIN_SPEED) && vars.keyLeft && !vars.keyRight;
                        bool turningRightIntoSkid = (vars.groundSpeed < -SKID_MIN_SPEED) && vars.keyRight && !vars.keyLeft;
                        if (turningLeftIntoSkid || turningRightIntoSkid) {
                            // Play skid sound only when entering SKIDDING state from a different state
                            if (state != PlayerState.SKIDDING) {
                                AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic Jam S3/4.wav", 1.0f);
                            }
                            if (vars.groundSpeed >= 0) {
                                vars.setFacing(1);
                            } else {
                                vars.setFacing(-1);
                            }
                            state = PlayerState.SKIDDING;
                        } else if (abs(vars.groundSpeed) < 6.0f) {
                            state = PlayerState.WALKING;
                        } else {
                            state = PlayerState.RUNNING;
                        }
                    }
                }
        } else {
            // Reset push timer when airborne
            pushTimer = 0;
            // Stay in JUMPING state until grounded, unless rolling in air
            if (vars.isRolling) {
                state = PlayerState.FALLING_ROLLING;
            } else if (vars.hasJumped) {
                state = PlayerState.JUMPING;
            } else {
                state = PlayerState.FALLING;
            }
        }
        
        // Update previous state for next frame
        previousState = state;
    }

    // Update animation
    void updateAnimation(float deltaTime) {
        // First handle state-based animations (higher priority)
        switch (state) {
            case PlayerState.IDLE:
                if (vars.keyUp && vars.isGrounded) {
                    animations.setPlayerAnimationState(PlayerAnimationState.LOOKUP);
                } else if (vars.keyDown && vars.isGrounded) {
                    animations.setPlayerAnimationState(PlayerAnimationState.LOOKDOWN);
                } else if (idleSubState == IdleState.IMPATIENT_LOOK) {
                    animations.setPlayerAnimationState(PlayerAnimationState.IMPATIENT_LOOK);
                } else if (idleSubState == IdleState.IMPATIENT_ANIMATION) {
                    animations.setPlayerAnimationState(PlayerAnimationState.IMPATIENT);
                } else {
                    animations.setPlayerAnimationState(PlayerAnimationState.IDLE);
                }
                break;
            case PlayerState.WALKING:
                lastGroundAnimationState = PlayerAnimationState.WALK;
                animations.setPlayerAnimationState(PlayerAnimationState.WALK);
                break;
            case PlayerState.CROUCHING:
                animations.setPlayerAnimationState(PlayerAnimationState.LOOKDOWN);
                break;
            case PlayerState.SKIDDING:
                lastGroundAnimationState = PlayerAnimationState.SKID;
                animations.setPlayerAnimationState(PlayerAnimationState.SKID);
                break;
            case PlayerState.RUNNING:
                lastGroundAnimationState = PlayerAnimationState.RUN;
                animations.setPlayerAnimationState(PlayerAnimationState.RUN);
                break;
            case PlayerState.PUSHING:
                lastGroundAnimationState = PlayerAnimationState.PUSH;
                animations.setPlayerAnimationState(PlayerAnimationState.PUSH);
                break;
            case PlayerState.JUMPING:
                animations.setPlayerAnimationState(PlayerAnimationState.JUMP);
                break;
            case PlayerState.FALLING:
                animations.setPlayerAnimationState(lastGroundAnimationState);
                break;
            case PlayerState.ROLLING:
            case PlayerState.FALLING_ROLLING:
                writeln("[ANIMATION DEBUG] Setting ROLL animation for state: ", state);
                animations.setPlayerAnimationState(PlayerAnimationState.ROLL);
                break;
            case PlayerState.SPINDASHING:
                writeln("[ANIMATION DEBUG] Setting SPINDASH animation");
                animations.setPlayerAnimationState(PlayerAnimationState.SPINDASH);
                break;
            default:
                animations.setPlayerAnimationState(PlayerAnimationState.IDLE);
                break;
        }

        // Speed-dependent animation playback
        float playbackMul = 1.0f;
        // Use groundSpeed for grounded animations, xSpeed for air
        if (state == PlayerState.WALKING || state == PlayerState.RUNNING || state == PlayerState.PUSHING) {
            float maxSpeed = vars.isSuperSonic ? vars.SUPER_TOP_SPEED : vars.TOP_SPEED;
            float speedNorm = abs(vars.groundSpeed) / (maxSpeed > 0 ? maxSpeed : 1.0f);
            // Map speedNorm [0,1+] to multiplier [0.6, 2.0]
            playbackMul = 0.6f + min(1.4f, max(0.0f, speedNorm * 1.4f));
        } else if (state == PlayerState.JUMPING || state == PlayerState.FALLING || state == PlayerState.FALLING_ROLLING) {
            float maxSpeed = vars.isSuperSonic ? vars.SUPER_TOP_SPEED : vars.TOP_SPEED;
            float speedNorm = abs(vars.xSpeed) / (maxSpeed > 0 ? maxSpeed : 1.0f);
            playbackMul = 0.6f + min(1.4f, max(0.0f, speedNorm * 1.4f));
        }

        animations.setPlaybackMultiplier(playbackMul);

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
    float spriteVisualYOffset = 12.0f; // tweak this value if the sprite needs tuning (offset by 1px down)
    // Determine if sprite should be flipped based on facing direction
    bool shouldFlip = (vars.facing < 0); // flip when facing left
    animations.render(Vector2(vars.xPosition, desiredCenterY + spriteVisualYOffset), 1.0f, shouldFlip);
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

        // Minimal on-screen HUD for roll debugging
        if (dbgRollSpindash) {
            import std.format : format;
            auto hud = format(
                "ROLL HUD | state=%s canRoll=%s isRolling=%s gs=%.2f down=%s \n Mode=%s angle=%.1f | tile=%s layer=%s",
                state, canRoll, vars.isRolling, vars.groundSpeed, vars.keyDown,
                collisionMode, vars.groundAngle,
                dbgLastGroundTileRawId, dbgLastGroundLayerName
            );
            DrawText(hud.toStringz, cast(int)vars.xPosition - 200, cast(int)vars.yPosition + 40, 10, Colors.WHITE);
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
        
    // writeln("[WALL CHECK DEBUG] checkingRight: ", checkingRight, " checkX: ", checkX, " playerX: ", vars.xPosition);
        
        // Sample multiple points vertically (body area, not feet)
        float topY = vars.yPosition - vars.heightRadius + 4.0f;
        float bottomY = vars.yPosition + vars.heightRadius - 12.0f; // Well above feet
        
        int samples = 4;
        int solidHits = 0;
        
        for (int i = 0; i < samples; i++) {
            float sampleY = topY + (bottomY - topY) * cast(float)i / cast(float)(samples - 1);
            if (isSolidAtPosition(*level, checkX, sampleY)) {
                solidHits++;
                // writeln("[WALL CHECK] Sample ", i, " at (", checkX, ",", sampleY, ") = SOLID");
            } else {
                // writeln("[WALL CHECK] Sample ", i, " at (", checkX, ",", sampleY, ") = empty");
            }
        }
        
        bool hasWall = solidHits >= 3;
    // writeln("[WALL CHECK RESULT] solidHits: ", solidHits, "/", samples, " hasWall: ", hasWall);
        
        // Consider wall present if 3+ samples hit solid
        return hasWall;
    }

    // Debug functions
    void debugPrint() {
    // writeln("=== Player Debug ===");
    // writeln("State: ", state);
        vars.debugPrint();
    }

    // Collision detection placeholder
    bool checkGroundCollision() {
    import std.math : floor;
    import std.algorithm : max, min;

    // writeln("[GROUND CHECK] Starting at position Y=", vars.yPosition, " bottom=", vars.yPosition + vars.heightRadius);

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
                    // writeln("LANDING (fallback): xSpeed=", vars.xSpeed, " -> groundSpeed=", vars.groundSpeed);
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
            if (dbgVerbose) writeln("[GROUND FOLLOWING] Looking ahead to x=", lookAheadX, " (speed=", vars.xSpeed, ")");
        }

        // Layers to check in priority order
        struct LayerCheck { Tile[][]* layer; string name; bool isSemi; }
        LayerCheck[7] checks = [
            // Prefer real ground tiles first so we get accurate slope angles
            LayerCheck(&level.groundLayer1, "Ground_1", false),
            LayerCheck(&level.groundLayer2, "Ground_2", false),
            LayerCheck(&level.groundLayer3, "Ground_3", false),
            // Then semi-solids (platforms)
            LayerCheck(&level.semiSolidLayer1, "SemiSolid_1", true),
            LayerCheck(&level.semiSolidLayer2, "SemiSolid_2", true),
            LayerCheck(&level.semiSolidLayer3, "SemiSolid_3", true),
            // Collision fallback last (no angles)
            LayerCheck(&level.collisionLayer, "Collision", false)
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

                    // Get profile - for semi-solid layers, always use runtime collision
                    world.tile_collision.TileHeightProfile profile;
                    bool hadProfile = false;
                    
                    if (!ch.isSemi) {
                        // For solid layers, try precomputed first
                        hadProfile = utils.level_loader.getPrecomputedTileProfile(*level, tile.tileId, ch.name, profile);
                    }
                    
                    if (!hadProfile) {
                        // Use runtime collision (fallback for solid layers, always for semi-solid layers)
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
                        if (dbgVerbose) writeln("[GROUND CHECK] Found support at surfaceY=", surfaceY, " sampleTileY=", checkY, " tileId=", tile.tileId);
                        if (surfaceY < bestSurfaceY) {
                            bestSurfaceY = surfaceY;
                            float ang = world.tile_collision.TileCollision.getTileGroundAngle(tile.tileId, ch.name, level.tilesets);
                            bool usedAltAngle = false;
                            import std.math : isNaN;
                            if (isNaN(ang)) {
                                if (dbgVerbose) {
                                    writeln("[WARN] Tile ", tile.tileId, " returned NaN angle, using 0");
                                    writeln("[DEBUG] Heights for tile ", tile.tileId, ": checking tile collision system...");
                                }
                                ang = 0.0f;
                            }
                            // If we got angle 0 from Collision layer, try to source true angle from ground layers at same tile
                            if (ch.name == "Collision" && ang == 0.0f) {
                                Tile g1 = utils.level_loader.getTileAtPosition(level.groundLayer1, sampleTileX, checkY);
                                Tile g2 = utils.level_loader.getTileAtPosition(level.groundLayer2, sampleTileX, checkY);
                                Tile g3 = utils.level_loader.getTileAtPosition(level.groundLayer3, sampleTileX, checkY);
                                int altId = (g3.tileId > 0) ? g3.tileId : (g2.tileId > 0 ? g2.tileId : g1.tileId);
                                if (altId > 0) {
                                    string altLayer = (g3.tileId>0?"Ground_3":(g2.tileId>0?"Ground_2":"Ground_1"));
                                    float angAlt = world.tile_collision.TileCollision.getTileGroundAngle(altId, altLayer, level.tilesets);
                                    if (!isNaN(angAlt)) {
                                        if (dbgVerbose) writeln("[ANGLE FALLBACK] Using ground layer angle ", angAlt, " for collision tile raw=", tile.tileId, " altId=", altId);
                                        ang = angAlt;
                                        // Update debug tracking
                                        dbgLastGroundTileRawId = altId;
                                        dbgLastGroundLayerName = altLayer;
                                        usedAltAngle = true;
                                    }
                                }
                            }
                            bestAngle = ang;
                            // Track for debug: which tile/layer supported us (prefer alt if used)
                            if (!usedAltAngle) {
                                dbgLastGroundTileRawId = tile.tileId;
                                dbgLastGroundLayerName = ch.name;
                            }
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
            if (dbgVerbose) writeln("[GROUND CHECK] FOUND SUPPORT! bestSurfaceY=", bestSurfaceY, " bestAngle=", bestAngle);
            // New landing only if previously airborne
            if (!vars.isGrounded) {
                // Landing: set grounded, snap to surface, safe velocity handling
                vars.isGrounded = true;
                vars.hasJumped = false; // Reset jump state on landing
                vars.yPosition = bestSurfaceY - vars.heightRadius;
                
                // Ensure angle is safe before assigning
                if (isNaN(bestAngle)) {
                    if (dbgVerbose) writeln("[WARN] Landing bestAngle invalid: ", bestAngle, ", using 0");
                    bestAngle = 0.0f;
                }
                
                // Determine collision mode based on angle
                GroundCollisionMode newMode = GroundCollisionMode.FLOOR;
                if (abs(bestAngle) >= 45.0f && abs(bestAngle) < 135.0f) {
                    // Wall collision - determine which wall based on angle direction
                    if (bestAngle > 0) {
                        newMode = GroundCollisionMode.RIGHT_WALL; // Slope rising to right = right wall
                    } else {
                        newMode = GroundCollisionMode.LEFT_WALL;  // Slope rising to left = left wall
                    }
                } else if (abs(bestAngle) >= 135.0f) {
                    newMode = GroundCollisionMode.CEILING;
                }
                
                // Check if player has enough speed to stick to non-floor surfaces
                float minStickSpeed = 2.5f; // Minimum speed needed to stick to walls/ceiling
                if (newMode != GroundCollisionMode.FLOOR && abs(vars.groundSpeed) < minStickSpeed) {
                    // Not enough speed - fall off the surface
                    vars.isGrounded = false;
                    collisionMode = GroundCollisionMode.NONE;
                    if (dbgVerbose) writeln("[WALL RUNNING] Not enough speed to stick to surface, angle=", bestAngle, " speed=", abs(vars.groundSpeed));
                    return false;
                } else {
                    collisionMode = newMode;
                    if (dbgVerbose) writeln("[COLLISION MODE] Set to ", collisionMode, " based on angle ", bestAngle);
                }
                
                // Debug: track groundAngle assignment
                float oldGroundAngle = vars.groundAngle;
                vars.groundAngle = bestAngle;
                if (dbgVerbose) writeln("[DEBUG GROUND ANGLE] Assigned: old=", oldGroundAngle, " new=", vars.groundAngle, " bestAngle=", bestAngle);

                // Safe velocity conversion - avoid NaN and zipping
                if (isNaN(bestAngle) || abs(bestAngle) > 90.0f) {
                    if (dbgVerbose) writeln("[WARN] bestAngle invalid: ", bestAngle, ", resetting to 0");
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
                    if (dbgVerbose) writeln("[WARN] groundSpeed became NaN, resetting to 0");
                    vars.groundSpeed = 0.0f;
                }
                if (abs(vars.groundSpeed) < 0.1f) vars.groundSpeed = 0.0f;

                // Decide landing state explicitly so we don't rely on later updateState timing
                if (vars.isRolling || state == PlayerState.FALLING_ROLLING) {
                    // If we were rolling in-air, choose whether to continue rolling or stop
                    if (abs(vars.groundSpeed) < 0.5f || !vars.keyDown) {
                        // Come to rest on landing or if down is not held
                        vars.isRolling = false;
                        // Transition to a non-rolling state based on speed
                        if (abs(vars.groundSpeed) < 0.5f) {
                            state = PlayerState.IDLE;
                        } else if (abs(vars.groundSpeed) < 6.0f) {
                            state = PlayerState.WALKING;
                        } else {
                            state = PlayerState.RUNNING;
                        }
                        if (dbgRollSpindash) writeln("[ROLL DEBUG] Landing from roll/falling_roll and stopping. Reason: low speed or down not held.");
                    } else {
                        // Still moving fast and holding down - stay rolling
                        vars.isRolling = true;
                        state = PlayerState.ROLLING;
                        if (dbgRollSpindash) writeln("[ROLL DEBUG] Landing from roll/falling_roll with speed ", vars.groundSpeed, " and down held - continuing roll");
                    }
                } else {
                    // Normal landing - pick a sensible grounded state based on groundSpeed
                    if (abs(vars.groundSpeed) < 0.1f) {
                        state = PlayerState.IDLE;
                    } else if (abs(vars.groundSpeed) < 6.0f) {
                        state = PlayerState.WALKING;
                    } else {
                        state = PlayerState.RUNNING;
                    }
                }

                if (vars.isGrounded && state == PlayerState.FALLING_ROLLING) {
                    if (dbgRollSpindash) writeln("[ROLL DEBUG] Correcting state from FALLING_ROLLING to IDLE/WALKING/RUNNING/DASHING on landing");
                    if (abs(vars.groundSpeed) < 0.1f) {
                        state = PlayerState.IDLE;
                    } else if (abs(vars.groundSpeed) < 6.0f) {
                        state = PlayerState.WALKING;
                    } else if (abs(vars.groundSpeed) < 12.0f) {
                        state = PlayerState.RUNNING;
                    } else {
                        state = PlayerState.DASHING;
                    }
                }

                // Check if we should disable canRoll on landing from rolling states
                if ((vars.isRolling || state == PlayerState.FALLING_ROLLING)) {
                    if (vars.keyDown) {
                        // Holding down - keep canRoll and reset grace
                        canRollGraceFrames = 0;
                        if (dbgRollSpindash) writeln("[ROLL DEBUG] Landing from roll with down held - keeping canRoll");
                    } else {
                        // Not holding down - start grace period
                        canRollGraceFrames = 6; // 6 frames grace (0.1 seconds at 60fps)
                        if (dbgRollSpindash) writeln("[ROLL DEBUG] Landing from roll without down - starting grace period (6 frames)");
                    }
                }
                
                // Mark we've just landed so updateState() won't clobber this decision this frame
                justLanded = true;
                if (dbgVerbose || dbgRollSpindash) writeln("LANDING: angle=", vars.groundAngle, " groundSpeed=", vars.groundSpeed, " => state=", state);
                return true;

                if (vars.isRolling && vars.keyJumpPressed) {
                    // Jump out of roll on landing if jump pressed
                    canRoll = false;
                    vars.isRolling = false;
                    state = PlayerState.JUMPING;
                }
            }
            // Already grounded: update Y position to follow slope contour
            // This ensures the player follows slopes smoothly as they move horizontally
            // BUT NOT when in pushing state - stay exactly where we are
            vars.isGrounded = true;
            if (state != PlayerState.PUSHING) {
                vars.yPosition = bestSurfaceY - vars.heightRadius;
            } else {
                if (dbgVerbose) writeln("[PUSH STATE] Blocking Y position update in ground collision");
            }
            
            // Update ground angle if it has changed
            if (isNaN(bestAngle)) {
                bestAngle = 0.0f;
            }
            
            // Determine collision mode based on angle and check speed requirements
            GroundCollisionMode newMode = GroundCollisionMode.FLOOR;
            if (abs(bestAngle) >= 45.0f && abs(bestAngle) < 135.0f) {
                // Wall collision - determine which wall based on angle direction
                if (bestAngle > 0) {
                    newMode = GroundCollisionMode.RIGHT_WALL;
                } else {
                    newMode = GroundCollisionMode.LEFT_WALL;
                }
            } else if (abs(bestAngle) >= 135.0f) {
                newMode = GroundCollisionMode.CEILING;
            }
            
            // Check if player has enough speed to stick to non-floor surfaces
            float minStickSpeed = 2.5f;
            if (newMode != GroundCollisionMode.FLOOR && abs(vars.groundSpeed) < minStickSpeed) {
                // Not enough speed - fall off the surface
                vars.isGrounded = false;
                collisionMode = GroundCollisionMode.NONE;
                if (dbgVerbose) writeln("[WALL RUNNING] Lost grip on surface, angle=", bestAngle, " speed=", abs(vars.groundSpeed));
                return false;
            } else {
                collisionMode = newMode;
            }
            
            // Debug: track groundAngle assignment
            float oldGroundAngle = vars.groundAngle;
            vars.groundAngle = bestAngle;
            if (dbgVerbose) writeln("[DEBUG GROUND ANGLE] Updated during ground collision: old=", oldGroundAngle, " new=", vars.groundAngle, " bestAngle=", bestAngle);
            return false;
        }

        // No sample supported us
        vars.isGrounded = false;
    if (dbgVerbose) writeln("[GROUND CHECK] No support found - setting isGrounded = false");
        return false;
    }

    // Whether the player requests the camera to look down (crouch intent)
    bool wantsLookDown() {
        // Only trigger camera look-down when actually in CROUCHING state
        if (state == PlayerState.CROUCHING) {
            crouchLookTimer += 1.0f/60.0f; // approximate per-frame increment; camera also uses frames
            return (crouchLookTimer >= CROUCH_CAMERA_DELAY);
        }
        crouchLookTimer = 0.0f;
        return false;
    }

    // Should the camera lock to current position (idle/crouch, not moving)?
    bool shouldLockCamera() const {
        bool stationary = (abs(vars.xSpeed) < 0.05f && abs(vars.ySpeed) < 0.05f);
        return (state == PlayerState.IDLE || state == PlayerState.CROUCHING) && stationary;
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
            import utils.level_loader;
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
            
            if (dbgVerbose) {
                if (isWall) {
                    writeln("Touching wall: true");
                    writeln("[WALL DEBUG] WALL DETECTED! checkX=", checkX, " solidHits=", solidHits, "/", samples);
                } else {
                    writeln("[WALL DEBUG] No wall - checkX=", checkX, " solidHits=", solidHits, "/", samples);
                }
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
                    if (dbgVerbose) writeln("WALL HIT (grounded): stopped at x=", lastSafeX);
                } else {
                    // Airborne (JUMP/FALL): bounce away from wall
                    float bounceForce = 2.0f; // Adjust this value for bounce strength
                    if (stepDir > 0) {
                        // Moving right, hit right wall - bounce left
                        vars.xSpeed = -bounceForce;
                        if (dbgVerbose) writeln("WALL BOUNCE: hit right wall, bouncing left with force ", bounceForce);
                    } else {
                        // Moving left, hit left wall - bounce right  
                        vars.xSpeed = bounceForce;
                        if (dbgVerbose) writeln("WALL BOUNCE: hit left wall, bouncing right with force ", bounceForce);
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