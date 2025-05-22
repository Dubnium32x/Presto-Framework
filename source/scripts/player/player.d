module player.player;

import std.stdio;
import std.algorithm;
import std.range;
import std.array;
import std.string;
import std.conv;
import std.math;
import raylib;

import player.var;

enum PlayerState {
    IDLE,
    WALK,
    RUN,
    DASHING,
    JUMPING,
    FALLING,
    ROLLING,
    SPINDASHING,
    PEELING,
    SPINNING,
    CLIMBING,
    HURT,
    DEAD
}

enum IdleState {
    IDLE,
    LOOKING_UP,
    LOOKING_DOWN,
    IMPATIENT,
    IMPATIENT_ATTRACT,
    BALANCING_FORWARD,
    BALANCING_BACKWARD,
    IM_OUTTA_HERE
}

// Constants for sensor collision detection
enum {
    SENSOR_A = 0, // Bottom left
    SENSOR_B = 1, // Bottom right
    SENSOR_C = 2, // Middle left
    SENSOR_D = 3, // Middle right
    SENSOR_E = 4, // Top left
    SENSOR_F = 5, // Top right
    
    TILE_SIZE = 16, // Size of a tile in pixels
    SENSOR_HEIGHT_NORMAL = 19, // Normal height radius
    SENSOR_HEIGHT_ROLLING = 10, // Height radius when rolling
}

class Player {
    // Player animation and rendering
    Texture2D spritesheet;
    Rectangle[] animations;
    int currentFrame = 0;
    float frameTimer = 0;
    float frameDuration = 1.0f / 12.0f; // 12 FPS animation by default
    
    // Player state
    PlayerState state = PlayerState.IDLE;
    IdleState idleState = IdleState.IDLE;
    int direction = 1; // 1 = right, -1 = left
    float idleTimer = 0;
    float hurtTimer = 0;
    
    // Input tracking
    bool inputLeft = false;
    bool inputRight = false;
    bool inputUp = false;
    bool inputDown = false;
    bool inputJump = false;
    bool inputJumpHeld = false;
    bool inputAction = false;
    
    // Jump buffer for more responsive controls
    int jumpBufferCounter = 0;
    
    // Collision detection
    Rectangle hitbox;
    
    // Sensor collision data
    bool[6] sensorCollisions;  // True if sensor is colliding
    int[6] sensorAngles;      // Angle at each sensor point
    
    // The sensor positions
    Vector2[6] sensors;
    
    // Internal timers and counters
    int airTime = 0;           // Frames spent in the air
    int groundTime = 0;        // Frames spent on the ground
    float spinDashCharge = 0;  // Spin dash charge amount
    bool wasGrounded = false;  // Track if we were grounded last frame
    
    // Constructor
    this() {
        // Set default position
        Var.x = 100;
        Var.y = 100;
        
        // Load the Sonic spritesheet
        spritesheet = LoadTexture("resources/image/spritesheet/Sonic_spritemap.png");
        
        // Initialize hitbox
        updateHitbox();
        
        // Initialize sensors
        updateSensorPositions();
    }
    
    ~this() {
        // Clean up resources
        UnloadTexture(spritesheet);
    }
    
    // Main update function - called every frame
    void update(float deltaTime) {
        // Save previous grounded state and position
        wasGrounded = Var.grounded;
        float prevX = Var.x;
        float prevY = Var.y;
        
        // CRITICAL FIX: Ensure the player is in a valid state
        // If somehow we got in an invalid state, reset to a sensible default
        if (state == PlayerState.IDLE && (abs(Var.groundspeed) > 0.5f || abs(Var.xspeed) > 0.5f)) {
            state = PlayerState.WALK;
            writeln("STATE CORRECTION: Player had speed but was IDLE, setting to WALK");
        }
        
        // Debug player state at start of frame with extended input info
        writeln("Frame start - State: ", state, ", Grounded: ", Var.grounded, 
            ", Position: ", Var.x, ",", Var.y, 
            ", Speeds: ", Var.xspeed, ",", Var.yspeed, ", GrndSpeed: ", Var.groundspeed,
            ", Z key: ", IsKeyDown(KeyboardKey.KEY_Z));
        
        // Read input
        processInput();
        
        // EMERGENCY JUMP: Direct jump code that bypasses the normal physics logic
        // This should work regardless of other issues in the code
        if (IsKeyPressed(KeyboardKey.KEY_SPACE) && Var.grounded) {
            writeln("!!! EMERGENCY JUMP ACTIVATED !!!");
            
            // FIXED JUMP SEQUENCE with more gradual jumping:
            // Step 1: Apply a moderate vertical boost for gradual jump
            Var.yspeed = -8.5f; // Reduced jump velocity for more gradual ascent
            
            // Step 2: Give a slight horizontal boost based on direction facing
            Var.xspeed += direction * 0.8f; // Reduced from 1.5f for more natural jump arc
            
            // Step 3: Physically move player up slightly to escape ground collision
            Var.y -= 2.0f; // Reduced from 5.0f for less teleportation effect
            
            // Step 4: Force ungrounded state after movement established
            Var.grounded = false;
            framesNotGrounded = 8; // Reduced from 15 for more natural transitions
            state = PlayerState.JUMPING;
            
            writeln("EMERGENCY JUMP FINAL: y=", Var.y, ", yspeed=", Var.yspeed);
        }
        
        // ENFORCED SPEED CAP: Hard limit on maximum speed
        if (abs(Var.groundspeed) > GamePhysics.maxspeed) {
            Var.groundspeed = GamePhysics.maxspeed * (Var.groundspeed > 0 ? 1 : -1);
            writeln("Speed capped at maximum: ", GamePhysics.maxspeed);
        }
        
        // Direct jump debug check at the start of every frame
        if (inputJump && Var.grounded) {
            writeln("JUMP CONDITION MET: Should jump this frame!");
        }
        
        // Handle physics based on current state
        // The switch statement should handle all valid states
        switch(state) {
            case PlayerState.IDLE, PlayerState.WALK, PlayerState.RUN:
                handleGroundMovement();
                break;
                
            case PlayerState.JUMPING, PlayerState.FALLING:
                handleAirMovement();
                break;
                
            case PlayerState.ROLLING:
                handleRolling();
                break;
                
            case PlayerState.SPINDASHING:
                handleSpinDash();
                break;
                
            case PlayerState.HURT:
                handleHurt();
                break;
                
            default:
                break;
        }
        
        // Apply velocity with smoothing to prevent jittering
        // DEBUG: Add more info about velocity application
        writeln("Applying velocity: X=", Var.xspeed, " Y=", Var.yspeed);
        
        // IMPORTANT FIX: Only set speeds to 0 if truly minimal, otherwise let movement happen
        if (abs(Var.xspeed) >= 0.005f) { // Lower threshold to ensure movement happens
            Var.x += Var.xspeed;
            writeln("Moving X by ", Var.xspeed);
        } else {
            Var.xspeed = 0;
        }
        
        if (abs(Var.yspeed) >= 0.005f) { // Lower threshold to ensure movement happens
            Var.y += Var.yspeed;
            writeln("Moving Y by ", Var.yspeed);
        } else {
            Var.yspeed = 0;
        }
        
        // Update hitbox and sensor positions
        updateHitbox();
        updateSensorPositions();
        
        // Check for collision with ground
        checkEnvironmentCollision();
        
        // Handle landing and falling
        if (Var.grounded) {
            airTime = 0;
            groundTime++;
            
            // Just landed
            if (!wasGrounded) {
                onLand();
                
                // Add landing effect here if needed (particles, sound, etc.)
                
                // Small camera shake for hard landings
                if (Var.yspeed > 8.0f) {
                    // Here you could implement camera shake
                }
            }
        } else {
            groundTime = 0;
            airTime++;
            
            // Just left the ground
            if (wasGrounded) {
                onLeaveGround();
            }
        }
        
        // Update timers
        updateTimers(deltaTime);
        
        // Update animation
        updateAnimation(deltaTime);
        
        // Ultimate safety check - never allow player to be stuck in an invalid state
        // This serves as a last-resort fix if all else fails
        if (Var.grounded && (state == PlayerState.JUMPING || state == PlayerState.FALLING)) {
            writeln("EMERGENCY FIX: Player was grounded but in air state! Fixing...");
            state = PlayerState.IDLE;
            if (inputLeft || inputRight) {
                state = PlayerState.WALK;
            }
        }
        
        if (!Var.grounded && (state == PlayerState.IDLE || state == PlayerState.WALK || state == PlayerState.RUN)) {
            writeln("EMERGENCY FIX: Player was in air but had ground state! Fixing...");
            state = PlayerState.FALLING;
        }
    }
    
    // Process keyboard input
    void processInput() {
        // Save previous input state for edge detection
        bool wasJumpPressed = inputJump;
        
        // Movement
        inputLeft = IsKeyDown(KeyboardKey.KEY_LEFT);
        inputRight = IsKeyDown(KeyboardKey.KEY_RIGHT);
        inputUp = IsKeyDown(KeyboardKey.KEY_UP);
        inputDown = IsKeyDown(KeyboardKey.KEY_DOWN);
        
        // Debug input state
        if (inputLeft || inputRight) {
            writeln("INPUT STATE: Left=", inputLeft, ", Right=", inputRight, 
                ", State=", state, ", Grounded=", Var.grounded,
                ", Speed=", Var.groundspeed);
        }
        
        // Jump input handling (Z key) - ENHANCED for maximum reliability
        bool jumpKeyDown = IsKeyDown(KeyboardKey.KEY_Z);
        bool isZKeyPressed = IsKeyPressed(KeyboardKey.KEY_Z);
        
        // Debug jump presses with more detailed info
        if (isZKeyPressed) {
            writeln("Z key pressed, grounded state: ", Var.grounded, ", state: ", state, 
                ", framesNotGrounded: ", framesNotGrounded, ", jumpBufferCounter: ", jumpBufferCounter);
        }
        
        // Make jump controls MUCH more responsive with an increased jump buffer
        if (isZKeyPressed) {
            // Set jump buffer when key is pressed - significantly increased for maximum reliability
            jumpBufferCounter = 12; // Allow jumping for up to 12 frames after pressing Z (was 8)
            // Debugging - track jump presses more clearly
            writeln("JUMP PRESSED! Setting jump buffer to 12");
        } else if (jumpBufferCounter > 0) {
            jumpBufferCounter--;
            
            // Additional debugging to track jump buffer
            if (jumpBufferCounter % 4 == 0) {
                writeln("Jump buffer active: ", jumpBufferCounter, " frames remaining");
            }
        }
        
        // Set input flags - CRITICAL FIX: Force a more direct jump check for immediate response
        // This bypasses any potential issues with the jump buffer
        inputJump = jumpKeyDown; // Use direct KEY_DOWN instead of KEY_PRESSED
        inputJumpHeld = jumpKeyDown;
        
        // Extra debugging for jump input
        if (jumpKeyDown) {
            writeln("DIRECT JUMP DEBUG: Z key is held down, grounded=", Var.grounded);
        }
        
        // Action (X key) - Roll, spindash, etc.
        inputAction = IsKeyPressed(KeyboardKey.KEY_X);
    }
    
    // Handle ground movement physics
    void handleGroundMovement() {
        float acc = GamePhysics.acceleration;
        float dec = GamePhysics.deceleration;
        float frc = GamePhysics.friction;
        float topSpeed = GamePhysics.topspeed;
        
        // Apply slope factor to ground movement
        float slopeFactorX = cos(Var.groundangle * (std.math.PI / 128.0f));
        float slopeFactorY = sin(Var.groundangle * (std.math.PI / 128.0f));
        
        // Add a slope resistance factor to prevent jittering on slopes
        float slopeResistance = 0.0f;
        
        // Add resistance when going uphill, assistance when going downhill
        if (abs(Var.groundangle) > 10 && abs(Var.groundangle) < 90) {
            slopeResistance = sin(Var.groundangle * (std.math.PI / 128.0f)) * 0.05f;
        }
        
        // Handle left/right movement on ground
        if (inputLeft && !inputRight) {
            // Moving left
            if (Var.groundspeed > 0) 
                Var.groundspeed -= dec * 1.5f; // Increased deceleration when turning to feel more responsive
            else
                Var.groundspeed -= acc * 2.5f; // Increased acceleration for more responsive feel
                
            // Set direction for animation
            direction = -1;
            
            // CRITICAL FIX: FORCE player state to match movement (fixes stuck in IDLE state)
            state = PlayerState.WALK; // Always force WALK state first to ensure movement
            if (abs(Var.groundspeed) >= 6.0f) {
                state = PlayerState.RUN;
            }
            
            // Force a minimum speed to prevent getting stuck
            if (abs(Var.groundspeed) < 0.2f) {
                Var.groundspeed = -0.2f;
            }
            
            // Debug movement
            writeln("LEFT: Applying speed ", Var.groundspeed, " acc=", acc, " dec=", dec);
                
        } else if (inputRight && !inputLeft) {
            // Moving right
            if (Var.groundspeed < 0) 
                Var.groundspeed += dec * 1.5f; // Increased deceleration when turning to feel more responsive
            else
                Var.groundspeed += acc * 2.5f; // Increased acceleration for more responsive feel
                
            // Set direction for animation
            direction = 1;
            
            // CRITICAL FIX: FORCE player state to match movement (fixes stuck in IDLE state)
            state = PlayerState.WALK; // Always force WALK state first to ensure movement
            if (abs(Var.groundspeed) >= 6.0f) {
                state = PlayerState.RUN;
            }
            
            // Force a minimum speed to prevent getting stuck
            if (abs(Var.groundspeed) < 0.2f) {
                Var.groundspeed = 0.2f;
            }
            
            // Debug movement
            writeln("RIGHT: Applying speed ", Var.groundspeed, " acc=", acc, " dec=", dec);
                
        } else {
            // No horizontal input - use MUCH more gradual stopping logic
            
            // Use different friction strategies based on speed
            if (abs(Var.groundspeed) > 6.0f) {
                // At very high speeds, use extremely gentle percentage-based deceleration
                Var.groundspeed *= 0.97f; // Only 3% speed reduction per frame
            }
            else if (abs(Var.groundspeed) > 4.0f) {
                // At high speeds, use very gentle percentage-based deceleration
                Var.groundspeed *= 0.96f; // Only 4% speed reduction per frame
            }
            else if (abs(Var.groundspeed) > 2.0f) {
                // At medium speeds, use gentle percentage-based deceleration
                Var.groundspeed *= 0.95f; // Only 5% speed reduction per frame
            }
            else if (abs(Var.groundspeed) > 0.3f) {
                // At low speeds, use mild deceleration
                Var.groundspeed *= 0.92f; // Only 8% speed reduction per frame
            }
            else {
                // At very low speeds, stop completely to prevent micro-sliding
                Var.groundspeed = 0;
                if (state != PlayerState.IDLE && Var.grounded)
                    state = PlayerState.IDLE;
            }
            
            // Hard stop threshold significantly lowered to allow much more natural sliding to a stop
            if (abs(Var.groundspeed) < 0.1f) {
                writeln("Stopping completely from low speed: ", Var.groundspeed);
                Var.groundspeed = 0;
                Var.xspeed = 0; // Also zero out xspeed to ensure complete stopping
            }
        }
        
        // COMPLETELY REBUILT jump handling - multiple detection methods with gradual jumping
        bool jumpTriggered = false;
        
        // Method 1: Direct key state check (most direct method)
        if ((IsKeyPressed(KeyboardKey.KEY_Z) || IsKeyDown(KeyboardKey.KEY_Z)) && Var.grounded) {
            jumpTriggered = true;
            writeln("JUMP METHOD 1: Direct key press detection");
        }
        
        // Method 2: Jump buffer system (useful for timing grace period)
        if (jumpBufferCounter > 0 && Var.grounded) {
            jumpTriggered = true;
            writeln("JUMP METHOD 2: Jump buffer activation");
        }
        
        // Method 3: Backup poll on the key raw state
        if (IsKeyPressed(KeyboardKey.KEY_Z) && Var.grounded) {
            jumpTriggered = true;
            writeln("JUMP METHOD 3: KeyPressed backup poll");
        }
        
        // EXECUTE JUMP when any method triggers
        if (jumpTriggered) {
            // Force a clear debug message to track jump execution
            writeln("!!! JUMP EXECUTION CONFIRMED !!! Ground angle: ", Var.groundangle, 
                  ", Speed: ", Var.groundspeed);
            
            // Calculate jump force with more natural impulse for gradual jumping
            float jumpImpulse = -Var.jumpforce * 1.05f; // Only 5% boost for more natural jumps
            
            // Small speed boost for fast-moving jumps
            if (abs(Var.groundspeed) > 5.0f) {
                jumpImpulse *= 1.08f; // Only 8% boost at high speeds for more control
                writeln("HIGH SPEED JUMP BOOST: ", jumpImpulse);
            }
            
            // CRUCIAL FIX: Apply jump speed BEFORE setting grounded=false
            // This prevents any race condition in the physics system
            Var.xspeed = Var.groundspeed * cos(Var.groundangle * (std.math.PI / 128.0f));
            Var.yspeed = jumpImpulse; 
            
            // Gentler slope adjustment
            if (abs(Var.groundangle) > 5) {
                Var.xspeed += sin(Var.groundangle * (std.math.PI / 128.0f)) * 1.5f; // Reduced from 2.5f
            }
            
            // Smaller directional boost
            Var.xspeed += direction * 0.6f; // Reduced from 1.0f for more controlled horizontal movement
            
            // CRITICAL ORDER: Only AFTER speeds are applied, change state and flags
            state = PlayerState.JUMPING;
            
            // Less aggressive ungrounding to allow natural transitions
            Var.grounded = false;
            framesNotGrounded = GROUND_DEBOUNCE_FRAMES + 3; // Reduced from 5 frames
            
            // Reset jump buffer after successful jump
            jumpBufferCounter = 0;
            
            // Debug the final jump values
            writeln("FINAL JUMP VALUES - yspeed: ", Var.yspeed, ", xspeed: ", Var.xspeed);
        }
        
        // Handle spindash input
        if (inputDown && Var.grounded && abs(Var.groundspeed) < 1.0f) {
            if (inputAction) {
                // Initiate spindash
                state = PlayerState.SPINDASHING;
                spinDashCharge = 0;
                Var.groundspeed = 0;
            }
        }
        // Handle rolling input
        else if (inputDown && Var.grounded && abs(Var.groundspeed) >= 1.0f) {
            // Initiate roll
            state = PlayerState.ROLLING;
        }
        
        // Apply an extremely low minimum speed threshold to allow very natural slow movement
        if (abs(Var.groundspeed) < 0.02f) {
            Var.groundspeed = 0;
        }
        
        // Apply additional slope resistance/assistance based on direction
        if (Var.groundspeed != 0) {
            // If going uphill (positive groundspeed + positive angle or negative groundspeed + negative angle)
            if ((Var.groundspeed > 0 && sin(Var.groundangle * (std.math.PI / 128.0f)) > 0) || 
                (Var.groundspeed < 0 && sin(Var.groundangle * (std.math.PI / 128.0f)) < 0)) {
                // More resistance when going uphill (less slippery)
                Var.groundspeed -= slopeResistance * 1.5 * (Var.groundspeed > 0 ? 1 : -1);
            } else {
                // Speed up when going downhill
                Var.groundspeed += slopeResistance * (Var.groundspeed > 0 ? 1 : -1);
                
                // Add a slight curve to downhill acceleration so it doesn't get out of control
                if (abs(Var.groundspeed) > GamePhysics.topspeed) {
                    // Apply a stronger resistance at higher speeds
                    Var.groundspeed -= 0.02 * (Var.groundspeed > 0 ? 1 : -1);
                }
            }
        }
        
        // Apply mild ground traction when trying to move against current direction
        // This makes the character feel responsive but not too snappy
        if ((inputLeft && Var.groundspeed > 0) || (inputRight && Var.groundspeed < 0)) {
            // Gentle traction when trying to turn around
            Var.groundspeed *= 0.95f;
        }
        
        // Convert ground speed to x/y components based on ground angle
        Var.xspeed = Var.groundspeed * cos(Var.groundangle * (std.math.PI / 128.0f));
        Var.yspeed = Var.groundspeed * sin(Var.groundangle * (std.math.PI / 128.0f));
        
        // Add gravity component on slopes (natural acceleration downhill)
        float slopeGravity = GamePhysics.gravity * sin(Var.groundangle * (std.math.PI / 128.0f));
        
        // Apply slope gravity with a small deadzone to prevent jitter on nearly-flat surfaces
        if (abs(slopeGravity) > 0.01f) {
            Var.groundspeed += slopeGravity;
        }
    }
    
    // Handle air movement physics
    void handleAirMovement() {
        // Debug air movement
        writeln("Air movement - yspeed: ", Var.yspeed, ", state: ", state);
        
        float airAcc = GamePhysics.acceleration * 0.8f;  // Increased from 0.7f for even better air control
        
        // Air control - improved but still more limited than ground control
        if (inputLeft && !inputRight) {
            // More responsive air control, especially when changing directions
            if (Var.xspeed > 0) {
                Var.xspeed -= airAcc * 1.8f; // Increased responsiveness when changing direction
            } else if (Var.xspeed > -GamePhysics.topspeed) {
                Var.xspeed -= airAcc;
            }
            direction = -1;
        }
        else if (inputRight && !inputLeft) {
            // More responsive air control, especially when changing directions
            if (Var.xspeed < 0) {
                Var.xspeed += airAcc * 1.8f; // Increased responsiveness when changing direction
            } else if (Var.xspeed < GamePhysics.topspeed) {
                Var.xspeed += airAcc;
            }
            direction = 1;
        }
        else {
            // IMPROVED: Only apply minimal air drag to perfectly preserve momentum
            Var.xspeed *= 0.995f; // Very minimal drag (0.5% reduction) for natural feel
        }
        
        // STRICT AIR SPEED CAP: Hard limit on maximum air speed
        if (abs(Var.xspeed) > GamePhysics.maxspeed) {
            Var.xspeed = GamePhysics.maxspeed * (Var.xspeed > 0 ? 1 : -1);
            writeln("Air speed capped at maximum: ", GamePhysics.maxspeed);
        }
        
        // Apply gravity with a speed cap to prevent excessive falling speeds
        if (Var.yspeed < 10.0f) { // Lower falling speed cap for more control
            // More gradual and natural jump arc
            if (state == PlayerState.JUMPING && Var.yspeed < 0) {
                if (airTime < 2) {
                    // Very short initial boost phase - gentle initial rise
                    Var.yspeed += GamePhysics.gravity * 0.5f; // More gravity influence
                    writeln("Initial jump phase - moderate gravity");
                }
                else if (airTime < 5) {
                    // Shorter boost phase for more gradual height gain
                    Var.yspeed += GamePhysics.gravity * 0.75f; // More gravity for less extreme height
                    writeln("Mid jump phase - increased gravity");
                }
                else {
                    // Faster transition to peak
                    Var.yspeed += GamePhysics.gravity * 0.95f;
                }
            } else {
                // Normal falling gravity for consistent descents
                Var.yspeed += GamePhysics.gravity * 1.0f; // Neutral gravity multiplier
            }
        }
        
        // Variable jump height with more predictable, less extreme control
        if (Var.yspeed < 0 && !inputJumpHeld) {
            // More consistent jump height control for better predictability
            float jumpCutFactor;
            
            if (airTime < 2) {
                jumpCutFactor = 0.85f; // Gentler early cut for more reliable short jumps
            }
            else if (airTime < 4) {
                jumpCutFactor = 0.92f; // Gentler mid-jump cut for medium height jumps
            }
            else {
                jumpCutFactor = 0.97f; // Very minimal late cut for reliable jump heights
            }
            
            Var.yspeed *= jumpCutFactor;
            writeln("Jump cut applied: factor=", jumpCutFactor, ", airTime=", airTime);
        }
        
        // Enhanced state transitions for better jump visuals and control
        if (Var.yspeed > 0) {
            // Only transition to falling state if we're not already falling
            // This prevents state flickering and ensures animations play correctly
            if (state != PlayerState.FALLING) {
                writeln("Reached jump apex! Transitioning to FALLING state");
                state = PlayerState.FALLING;
            }
        } else if (state == PlayerState.FALLING && Var.yspeed < -1.0f) {
            // Fix for when we're boosted upward while falling (e.g., springs, launchers)
            state = PlayerState.JUMPING;
            writeln("Vertical boost detected! Switching back to JUMPING state");
        }
        
        // Add a more substantial directional boost when pressing in a direction
        // Makes air control feel dramatically more responsive and satisfying
        if ((inputLeft && Var.xspeed > -GamePhysics.topspeed) || (inputRight && Var.xspeed < GamePhysics.topspeed)) {
            // Calculate boost amount based on current speed - stronger boost at low speeds
            float baseBoost = 0.2f; // Doubled from 0.1f
            
            // Boost is stronger in the first few frames of the jump for better initial control
            if (airTime < 5 && state == PlayerState.JUMPING) {
                baseBoost *= 1.5f; // 50% stronger air control at the start of jumps
            }
            
            // Apply the direction-based boost
            float boost = baseBoost * (inputLeft ? -1 : 1);
            Var.xspeed += boost;
            
            if (abs(boost) > 0.1f) {
                writeln("Air control boost applied: ", boost);
            }
        }
    }
    
    // Handle rolling physics
    void handleRolling() {
        float rollFriction = GamePhysics.friction * 0.5f; // Less friction while rolling
        
        // Apply friction
        if (abs(Var.groundspeed) > rollFriction)
            Var.groundspeed -= rollFriction * (Var.groundspeed > 0 ? 1 : -1);
        else {
            Var.groundspeed = 0;
            // Stop rolling if too slow
            if (abs(Var.groundspeed) < 0.5f) {
                state = PlayerState.IDLE;
            }
        }
        
        // Jump while rolling
        if (inputJump) {
            // Jump with current speed and direction
            Var.xspeed = Var.groundspeed * cos(Var.groundangle * (std.math.PI / 128.0f));
            Var.yspeed = Var.groundspeed * -sin(Var.groundangle * (std.math.PI / 128.0f)) - Var.jumpforce;
            
            Var.grounded = false;
            state = PlayerState.JUMPING;
        }
        
        // Apply gravity component on slopes
        Var.groundspeed += GamePhysics.gravity * sin(Var.groundangle * (std.math.PI / 128.0f)) * 1.2f; // Stronger gravity effect while rolling
        
        // Convert ground speed to x/y components based on ground angle
        Var.xspeed = Var.groundspeed * cos(Var.groundangle * (std.math.PI / 128.0f));
        Var.yspeed = Var.groundspeed * sin(Var.groundangle * (std.math.PI / 128.0f));
    }
    
    // Handle spindash physics
    void handleSpinDash() {
        const float SPINDASH_MAX_CHARGE = 8.0f;
        const float SPINDASH_BASE_SPEED = 8.0f;
        
        // Charging up
        if (inputDown) {
            // Rev up with action button presses
            if (inputAction) {
                spinDashCharge = min(SPINDASH_MAX_CHARGE, spinDashCharge + 2.0f);
            }
            
            // Natural charge decay
            spinDashCharge *= 0.94f;
            
            // Release with jump button
            if (inputJump) {
                // Calculate launch speed based on charge
                Var.groundspeed = SPINDASH_BASE_SPEED + spinDashCharge;
                if (direction < 0) Var.groundspeed *= -1;
                
                // Convert to components
                Var.xspeed = Var.groundspeed * cos(Var.groundangle * (std.math.PI / 128.0f));
                Var.yspeed = Var.groundspeed * sin(Var.groundangle * (std.math.PI / 128.0f));
                
                // Transition to rolling state
                state = PlayerState.ROLLING;
            }
        } else {
            // Exited spindash without launching
            state = PlayerState.IDLE;
        }
    }
    
    // Handle hurt state
    void handleHurt() {
        // Simple bouncing back when hurt
        Var.yspeed += GamePhysics.gravity;
        
        // Recover from hurt state after a short time
        if (hurtTimer <= 0) {
            if (Var.grounded) {
                state = PlayerState.IDLE;
            } else {
                state = Var.yspeed < 0 ? PlayerState.JUMPING : PlayerState.FALLING;
            }
        }
    }
    
    // Called when player lands on the ground
    void onLand() {
        // Always update the state when landing, regardless of previous state
        // This fixes the "locking up" issue when landing
        
        writeln("LANDING ON GROUND! Previous state: ", state, 
                ", xspeed: ", Var.xspeed, 
                ", yspeed: ", Var.yspeed, 
                ", position: ", Var.x, ",", Var.y);
        
        // CRITICAL FIX: Reset jump inputs to ensure we don't get stuck in a state
        inputJump = false;
        jumpBufferCounter = 0;
        
        // Reset air time counters
        airTime = 0;
        
        // Convert air momentum to ground momentum with improved precision
        float angleRad = Var.groundangle * (std.math.PI / 128.0f);
        
        // Calculate ground speed from X speed with improved angle handling
        if (abs(cos(angleRad)) > 0.01f) { // Avoid division by very small numbers
            Var.groundspeed = Var.xspeed / cos(angleRad);
        } else {
            // Better handling for near-vertical surfaces
            Var.groundspeed = Var.xspeed > 0 ? 0.5f : -0.5f; // Small default momentum
        }
        
        // ENHANCED: Add a more powerful momentum boost when landing for better game feel
        // Scale the boost based on the current speed for a more natural feel
        if (abs(Var.groundspeed) > 6.0f) {
            Var.groundspeed *= 1.15f; // 15% boost at high speeds (was 12%)
            writeln("HIGH SPEED LANDING BOOST: ", Var.groundspeed);
        } else if (abs(Var.groundspeed) > 4.0f) {
            Var.groundspeed *= 1.12f; // 12% boost at medium speeds (was 10%)
            writeln("MEDIUM SPEED LANDING BOOST: ", Var.groundspeed);
        } else if (abs(Var.groundspeed) > 2.0f) {
            Var.groundspeed *= 1.08f; // 8% boost at low speeds (was 5%)
        }
        
        // Add sound effects and visual feedback for landing (commented as placeholders)
        // playSound("land_sound.wav", abs(Var.yspeed) / 12.0f); // Volume based on falling speed
        // spawnParticles(5); // Dust particles on landing
        
        // ULTIMATE FIX: Force proper state transition based on immediate input and speed
        // This is absolutely critical to prevent the character from locking up on landing
        if (inputLeft || inputRight) {
            // If directional input is being held, immediately respond to it
            if (abs(Var.groundspeed) >= 6.0f) {
                state = PlayerState.RUN;
                writeln("LANDING WITH INPUT: Setting RUN state");
            } else {
                state = PlayerState.WALK;
                writeln("LANDING WITH INPUT: Setting WALK state");
            }
        } else {
            // No input - set state based purely on momentum
            if (abs(Var.groundspeed) >= 6.0f) {
                state = PlayerState.RUN;
                writeln("LANDING NO INPUT: Setting RUN state (momentum)");
            }
            else if (abs(Var.groundspeed) > 0.3f) {  // Lowered this threshold to prevent immediate stopping
                state = PlayerState.WALK;
                writeln("LANDING NO INPUT: Setting WALK state (momentum)");
            }
            else {
                state = PlayerState.IDLE;
                writeln("LANDING NO INPUT: Setting IDLE state");
            }
        }
        
        // Only stop if truly minimal speed to avoid abrupt stops
        if (abs(Var.groundspeed) < 0.05f) {  // Lowered from 0.05f to allow more natural sliding
            Var.groundspeed = 0;
        }
        
        // Ensure we can immediately jump again after landing
        jumpBufferCounter = 0;
    }
    
    // Called when player leaves the ground
    void onLeaveGround() {
        // If we weren't already jumping, then we're falling
        if (state != PlayerState.JUMPING) {
            state = PlayerState.FALLING;
        }
        
        // Convert ground momentum to air momentum
        Var.xspeed = Var.groundspeed * cos(Var.groundangle * (std.math.PI / 128.0f));
        Var.yspeed = Var.groundspeed * sin(Var.groundangle * (std.math.PI / 128.0f));
    }
    
    // Update timer-based mechanics
    void updateTimers(float deltaTime) {
        // Decrease hurt timer if active
        if (hurtTimer > 0)
            hurtTimer -= deltaTime;
            
        // Idle timer for idle animations
        if (state == PlayerState.IDLE) {
            idleTimer += deltaTime;
            
            // Progress through idle states
            if (idleTimer > 3.0f && idleState == IdleState.IDLE)
                idleState = IdleState.IMPATIENT;
            else if (idleTimer > 10.0f && idleState == IdleState.IMPATIENT)
                idleState = IdleState.IMPATIENT_ATTRACT;
        } else {
            // Reset idle timer and state when not idle
            idleTimer = 0;
            idleState = IdleState.IDLE;
        }
    }
    
    // Update animation frame
    void updateAnimation(float deltaTime) {
        // Increment frame timer
        frameTimer += deltaTime;
        
        // Change animation speed based on player speed
        if (state == PlayerState.RUN) {
            // Faster animation for running
            frameDuration = 1.0f / 15.0f;
        } else {
            // Default animation speed
            frameDuration = 1.0f / 12.0f;
        }
        
        // Update frame when timer exceeds duration
        if (frameTimer >= frameDuration) {
            frameTimer = 0;
            currentFrame++;
            
            // Loop animation (assuming animations array is populated correctly)
            if (animations.length > 0) {
                currentFrame %= animations.length;
            } else {
                // Default to first frame if animations not set up
                currentFrame = 0;
            }
        }
    }
    
    // Update the player's hitbox
    void updateHitbox() {
        float width = Var.widthrad;
        float height = state == PlayerState.ROLLING ? Var.widthrad : Var.heightrad;
        
        // Update hitbox to follow the player's position
        hitbox = Rectangle(
            Var.x - width,
            Var.y - height,
            width * 2,
            height * 2
        );
    }
    
    // Update sensor positions for collision detection
    void updateSensorPositions() {
        // Get appropriate width and height based on state
        float width = Var.widthrad;
        float height = state == PlayerState.ROLLING ? Var.widthrad : Var.heightrad;
        
        // Position sensors based on Sonic Physics Guide documentation
        // A and B - Bottom sensors (for ground detection)
        sensors[SENSOR_A] = Vector2(Var.x - width, Var.y + height);  // A - Bottom Left
        sensors[SENSOR_B] = Vector2(Var.x + width, Var.y + height);  // B - Bottom Right
        
        // C and D - Side sensors (for wall detection)
        sensors[SENSOR_C] = Vector2(Var.x - width, Var.y);           // C - Middle Left
        sensors[SENSOR_D] = Vector2(Var.x + width, Var.y);           // D - Middle Right
        
        // E and F - Top sensors (for ceiling detection)
        sensors[SENSOR_E] = Vector2(Var.x - width, Var.y - height);  // E - Top Left
        sensors[SENSOR_F] = Vector2(Var.x + width, Var.y - height);  // F - Top Right
    }
    
    // Check if a point is inside a platform
    bool pointInPlatform(Vector2 point, Rectangle platform) {
        return (point.x >= platform.x && 
                point.x <= platform.x + platform.width &&
                point.y >= platform.y && 
                point.y <= platform.y + platform.height);
    }
    
    // Get the nearest platform for ground detection
    Rectangle* getNearestPlatformBelow() {
        import app : testPlatforms;
        Rectangle* nearest = null;
        float nearestDist = float.infinity;
        
        foreach(ref platform; testPlatforms) {
            // Check if player is horizontally within this platform
            if (Var.x + Var.widthrad >= platform.x && Var.x - Var.widthrad <= platform.x + platform.width) {
                // Check that platform is below the player
                if (platform.y > Var.y) {
                    float dist = platform.y - Var.y;
                    if (dist < nearestDist) {
                        nearestDist = dist;
                        nearest = &platform;
                    }
                }
            }
        }
        
        return nearest;
    }
    
    // Calculate slope angle between two sensors on a platform
    int calculateSlopeAngle(Vector2 sensorA, Vector2 sensorB) {
        // If sensors are at same height, flat ground
        if (abs(sensorA.y - sensorB.y) < 0.5f) {
            return 0; // Flat
        }
        
        // Calculate angle based on height difference
        float dx = sensorB.x - sensorA.x;
        float dy = sensorB.y - sensorA.y;
        
        // Avoid division by zero
        if (abs(dx) < 0.01f) {
            return dy > 0 ? 64 : 192; // Vertical slope (90 or 270 degrees in hex)
        }
        
        // Get slope angle in radians
        float angleRad = atan2(dy, dx);
        
        // Convert to hex angle format (0-255)
        int hexAngle = cast(int)(angleRad * (128.0f / std.math.PI)) & 0xFF;
        
        return hexAngle;
    }
    
    // Check for collisions with the environment
    // Constants for ground detection
    enum float GROUND_SNAP_TOLERANCE = 4.0f;  // Further reduced to prevent interfering with jumps
    enum int GROUND_DEBOUNCE_FRAMES = 2;      // Reduced to 2 frames for more responsive ungrounding
    enum float MIN_SLOPE_HEIGHT = 0.5f;       // Minimum height difference to consider a slope
    enum float COYOTE_TIME_FRAMES = 5;        // Allow jumping this many frames after leaving ground
    
    // Track frames since we lost ground contact
    int framesNotGrounded = 0;
    
    void checkEnvironmentCollision() {
        // Reset collision flags
        for (int i = 0; i < 6; i++) {
            sensorCollisions[i] = false;
            sensorAngles[i] = 0;
        }
        
        // Ground detection with sensors A and B
        bool wasGroundedThisFrame = false;
        bool sensorAHit = false;
        bool sensorBHit = false;
        float snapYA = 0;
        float snapYB = 0;
        float bestDistA = GROUND_SNAP_TOLERANCE;
        float bestDistB = GROUND_SNAP_TOLERANCE;
        Rectangle* platformA = null;
        Rectangle* platformB = null;
        
        // Test against all platforms in app.d
        import app : testPlatforms;
        
        // First check if we're close to any platform
        foreach(ref platform; testPlatforms) {
            // Check if player's sensors are horizontally within this platform
            bool aInRange = sensors[SENSOR_A].x >= platform.x && sensors[SENSOR_A].x <= platform.x + platform.width;
            bool bInRange = sensors[SENSOR_B].x >= platform.x && sensors[SENSOR_B].x <= platform.x + platform.width;
            
            // Check ground sensor A
            if (aInRange) {
                // Only check platforms below or at the sensor
                if (sensors[SENSOR_A].y <= platform.y + GROUND_SNAP_TOLERANCE) {
                    float distance = platform.y - sensors[SENSOR_A].y;
                    
                    // If this is a better match than what we have so far
                    if (distance >= -GROUND_SNAP_TOLERANCE && distance < bestDistA) {
                        bestDistA = distance;
                        snapYA = platform.y;
                        sensorAHit = true;
                        platformA = &platform;
                    }
                }
            }
            
            // Check ground sensor B
            if (bInRange) {
                // Only check platforms below or at the sensor
                if (sensors[SENSOR_B].y <= platform.y + GROUND_SNAP_TOLERANCE) {
                    float distance = platform.y - sensors[SENSOR_B].y;
                    
                    // If this is a better match than what we have so far
                    if (distance >= -GROUND_SNAP_TOLERANCE && distance < bestDistB) {
                        bestDistB = distance;
                        snapYB = platform.y;
                        sensorBHit = true;
                        platformB = &platform;
                    }
                }
            }
        }
        
        // If we detected ground contact, snap to it and set grounded state
        if (sensorAHit || sensorBHit) {
            // Update sensor collision status
            sensorCollisions[SENSOR_A] = sensorAHit;
            sensorCollisions[SENSOR_B] = sensorBHit;
            
            // Calculate ground angle based on the difference in height between sensors
            if (sensorAHit && sensorBHit) {
                // Both sensors hit - calculate slope angle
                if (snapYA != snapYB && abs(snapYA - snapYB) >= MIN_SLOPE_HEIGHT) {
                    // We have an angled platform
                    if (snapYA < snapYB) {
                        // Going downhill to the right
                        Var.groundangle = 240; // -22.5 degrees
                    } else {
                        // Going uphill to the right
                        Var.groundangle = 16; // +22.5 degrees
                    }
                } else {
                    // Effectively flat
                    Var.groundangle = 0;
                }
                
                // For proper platform detection, in a more complete implementation,
                // we would get the real angle between platform points
                
                // Position player on top of ground (average position)
                float avgSnapY = (snapYA + snapYB) / 2;
                
                // CRITICAL FIX: Don't snap if player is intentionally jumping with significant upward velocity
                // This check prevents the ground from "catching" the player at the start of a jump
                if (Var.yspeed < -2.0f && state == PlayerState.JUMPING) {
                    writeln("JUMP PROTECTION: Preventing ground snap during active jump");
                } 
                // Only snap if falling or already grounded (prevents snapping through platforms)
                else if (Var.yspeed >= 0 || Var.grounded || bestDistA <= 0.1f || bestDistB <= 0.1f) {
                    Var.y = avgSnapY - Var.heightrad;
                    
                    // Set grounded and clear y velocity with a potential slight bounce
                    if (!Var.grounded && Var.yspeed > 4.0) {
                        // Small bounce for high-speed landing
                        Var.yspeed = -Var.yspeed * 0.15f; // 15% bounce
                    } else {
                        Var.yspeed = 0;
                    }
                    
                    Var.grounded = true;
                    framesNotGrounded = 0;
                    wasGroundedThisFrame = true;
                    writeln("SENSOR COLLISION: Player is now grounded!");
                }
            }
            // If only one sensor hit - sloped ground
            else if (sensorAHit) {
                Var.groundangle = 16; // Slight upward slope 
                
                // Position player on platform
                if (Var.yspeed >= 0 || Var.grounded || bestDistA <= 0.1f) {
                    Var.y = snapYA - Var.heightrad + (sensorAHit ? 0 : 2);
                    
                    Var.grounded = true;
                    Var.yspeed = 0;
                    framesNotGrounded = 0;
                    wasGroundedThisFrame = true;
                }
            }
            // If only sensor B hit - sloped ground
            else if (sensorBHit) {
                Var.groundangle = 240; // Slight downward slope
                
                // Position player on platform
                if (Var.yspeed >= 0 || Var.grounded || bestDistB <= 0.1f) {
                    Var.y = snapYB - Var.heightrad + (sensorBHit ? 0 : 2);
                    
                    Var.grounded = true;
                    Var.yspeed = 0;
                    framesNotGrounded = 0;
                    wasGroundedThisFrame = true;
                }
            }
        }
        
        // Handle losing ground contact with debounce
        if (!wasGroundedThisFrame && Var.grounded) {
            framesNotGrounded++;
            
            // Only unground after a few frames to prevent jitter
            if (framesNotGrounded > GROUND_DEBOUNCE_FRAMES) {
                Var.grounded = false;
            }
        }
        
        // Wall collision with sensors C and D
        // First check against global bounds
        if (sensors[SENSOR_C].x < 0) {
            sensorCollisions[SENSOR_C] = true;
            Var.x = Var.widthrad;
            Var.xspeed = 0;
        }
        
        // Right global wall
        if (sensors[SENSOR_D].x > 1500) { // Extending the boundary for more test area
            sensorCollisions[SENSOR_D] = true;
            Var.x = 1500 - Var.widthrad;
            Var.xspeed = 0;
        }
        
        // Now check platforms for side collisions
        import app : testPlatforms;
        
        foreach(platform; testPlatforms) {
            // Check if player is vertically within this platform
            if (Var.y + Var.heightrad > platform.y && 
                Var.y - Var.heightrad < platform.y + platform.height) {
                
                // Left side collision
                if (sensors[SENSOR_C].x <= platform.x + platform.width && 
                    sensors[SENSOR_C].x >= platform.x + platform.width - 5 && 
                    Var.xspeed < 0) {
                    
                    sensorCollisions[SENSOR_C] = true;
                    Var.x = platform.x + platform.width + Var.widthrad;
                    Var.xspeed = 0;
                }
                
                // Right side collision
                if (sensors[SENSOR_D].x >= platform.x && 
                    sensors[SENSOR_D].x <= platform.x + 5 && 
                    Var.xspeed > 0) {
                    
                    sensorCollisions[SENSOR_D] = true;
                    Var.x = platform.x - Var.widthrad;
                    Var.xspeed = 0;
                }
            }
        }
        
        // Ceiling collision with sensors E and F
        bool ceilingHit = false;
        
        // Check global ceiling
        if ((sensors[SENSOR_E].y < 0 || sensors[SENSOR_F].y < 0) && Var.yspeed < 0) {
            sensorCollisions[SENSOR_E] = sensors[SENSOR_E].y < 0;
            sensorCollisions[SENSOR_F] = sensors[SENSOR_F].y < 0;
            
            Var.y = Var.heightrad;
            Var.yspeed = 0;
            ceilingHit = true;
        }
        
        // Check platform ceilings
        if (!ceilingHit && Var.yspeed < 0) {
            foreach(platform; testPlatforms) {
                // Check if player is horizontally within this platform
                if (Var.x + Var.widthrad >= platform.x && 
                    Var.x - Var.widthrad <= platform.x + platform.width) {
                    
                    // Check if touching the bottom of the platform
                    if ((sensors[SENSOR_E].y <= platform.y + platform.height && 
                        sensors[SENSOR_E].y >= platform.y + platform.height - 5) ||
                        (sensors[SENSOR_F].y <= platform.y + platform.height && 
                        sensors[SENSOR_F].y >= platform.y + platform.height - 5)) {
                        
                        sensorCollisions[SENSOR_E] = sensors[SENSOR_E].y <= platform.y + platform.height;
                        sensorCollisions[SENSOR_F] = sensors[SENSOR_F].y <= platform.y + platform.height;
                        
                        Var.y = platform.y + platform.height + Var.heightrad;
                        Var.yspeed = 0;
                        break;
                    }
                }
            }
        }
    }
    
    // Draw the player and debug info
    void draw() {
        // Draw the player hitbox (placeholder)
        DrawRectangleRec(hitbox, Color(255, 255, 255, 128)); // Semi-transparent white rectangle
        
        // In a full implementation, we would draw the appropriate sprite from the spritesheet
        // For now, draw a colored rectangle based on state
        Color playerColor;
        
        switch (state) {
            case PlayerState.IDLE:
                playerColor = Color(0, 255, 255, 255); // Cyan
                break;
            case PlayerState.WALK:
                playerColor = Color(0, 255, 0, 255); // Green
                break;
            case PlayerState.RUN:
                playerColor = Color(0, 0, 255, 255); // Blue
                break;
            case PlayerState.JUMPING:
                playerColor = Color(255, 255, 0, 255); // Yellow
                break;
            case PlayerState.FALLING:
                playerColor = Color(255, 165, 0, 255); // Orange
                break;
            case PlayerState.ROLLING:
                playerColor = Color(255, 0, 255, 255); // Purple
                break;
            case PlayerState.SPINDASHING:
                playerColor = Color(255, 0, 0, 255); // Red
                break;
            default:
                playerColor = Color(255, 255, 255, 255); // White
                break;
        }
        
        // Draw the player as a simple rectangle with the color indicating state
        DrawRectangle(
            cast(int)(Var.x - Var.widthrad),
            cast(int)(Var.y - (state == PlayerState.ROLLING ? Var.widthrad : Var.heightrad)),
            cast(int)(Var.widthrad * 2),
            cast(int)((state == PlayerState.ROLLING ? Var.widthrad : Var.heightrad) * 2),
            playerColor
        );
        
        // Draw sensor points for debugging
        for (int i = 0; i < 6; i++) {
            Color sensorColor = sensorCollisions[i] ? 
                Color(255, 0, 0, 255) :     // Red if colliding
                Color(255, 255, 0, 255);    // Yellow otherwise
                
            DrawCircle(
                cast(int)sensors[i].x, 
                cast(int)sensors[i].y, 
                3, 
                sensorColor
            );
        }
        
        // Draw velocity vector for debugging
        DrawLine(
            cast(int)Var.x, 
            cast(int)Var.y,
            cast(int)(Var.x + Var.xspeed * 5), 
            cast(int)(Var.y + Var.yspeed * 5),
            Color(0, 255, 0, 255)
        );
        
        // Draw ground angle for debugging
        if (Var.grounded) {
            float angle = Var.groundangle * (std.math.PI / 128.0f);
            Vector2 start = Vector2(Var.x, Var.y + Var.heightrad);
            Vector2 end = Vector2(
                Var.x + cos(angle) * 30,
                Var.y + Var.heightrad + sin(angle) * 30
            );
            
            DrawLineV(start, end, Color(0, 255, 255, 255));
        }
    }
}
