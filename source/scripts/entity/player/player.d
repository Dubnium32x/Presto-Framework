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

import entity.sprite_object;
import entity.player.var;
import sprite.sprite_manager;
import sprite.animation_manager;
import utils.spritesheet_splitter;

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
    
    // Constructor
    static Player create(float x, float y) {
        Player player;
        player.sprite = SpriteObject.create();
        player.state = PlayerState.IDLE;
        player.vars = PlayerVariables();
        player.vars.resetPosition(x, y);
        return player;
    }
    
    // Initialize the player
    void initialize(float x, float y) {
        sprite.initialize();
        state = PlayerState.IDLE;
        vars = PlayerVariables();
        vars.resetPosition(x, y);
        
        // Set up sprite properties
        sprite.x = x;
        sprite.y = y;
        sprite.width = cast(int)(vars.widthRadius * 2);
        sprite.height = cast(int)(vars.heightRadius * 2);
        
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
            
            // Cap falling speed
            if (vars.ySpeed > vars.TOP_Y_SPEED) {
                vars.ySpeed = vars.TOP_Y_SPEED;
            }
        }
        
        // Update position
        vars.xPosition += vars.xSpeed;
        vars.yPosition += vars.ySpeed;
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
        vars.animationTimer += deltaTime;
        
        string newAnimation = "";
        switch (state) {
            case PlayerState.IDLE:
                newAnimation = "idle";
                break;
            case PlayerState.WALKING:
                newAnimation = "walk";
                break;
            case PlayerState.RUNNING:
                newAnimation = "run";
                break;
            case PlayerState.JUMPING:
                newAnimation = "jump";
                break;
            case PlayerState.FALLING:
                newAnimation = "fall";
                break;
            case PlayerState.ROLLING:
                newAnimation = "roll";
                break;
            default:
                newAnimation = "idle";
                break;
        }
        
        if (newAnimation != vars.currentAnimation) {
            vars.currentAnimation = newAnimation;
            vars.animationFrame = 0;
            vars.animationTimer = 0.0f;
        }
    }
    
    // Update sprite position
    void updateSpritePosition() {
        sprite.x = vars.xPosition;
        sprite.y = vars.yPosition;
    }
    
    // Draw the player
    void draw() {
        // Draw player hitbox for debugging
        DrawRectangleLines(
            cast(int)(vars.xPosition - vars.widthRadius),
            cast(int)(vars.yPosition - vars.heightRadius),
            cast(int)(vars.widthRadius * 2),
            cast(int)(vars.heightRadius * 2),
            Colors.GREEN
        );
        
        // Draw center point
        DrawCircle(cast(int)vars.xPosition, cast(int)vars.yPosition, 2, Colors.RED);
        
        // Draw facing direction
        int arrowX = cast(int)(vars.xPosition + (vars.facing * 15));
        DrawLine(cast(int)vars.xPosition, cast(int)vars.yPosition, arrowX, cast(int)vars.yPosition, Colors.BLUE);
        
        // TODO: Draw actual sprite when sprite system is ready
        sprite.draw();
    }
    
    // Debug functions
    void debugPrint() {
        writeln("=== Player Debug ===");
        writeln("State: ", state);
        vars.debugPrint();
    }
    
    // Collision detection placeholder
    bool checkGroundCollision() {
        // TODO: Implement ground collision with level data
        // For now, simple ground at y=400
        if (vars.yPosition >= 400) {
            vars.yPosition = 400;
            vars.isGrounded = true;
            vars.updateGroundSpeedFromSpeeds();
            return true;
        }
        return false;
    }
}