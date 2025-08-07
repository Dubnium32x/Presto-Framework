module entity.player.var;

import raylib;
import std.stdio;
import std.conv : to;
import std.math;

// Player physics variables based on Sonic Physics Guide (SPG)
struct PlayerVariables {
    // Position variables
    float xPosition = 0.0f;          // X-coordinate of the player's center
    float yPosition = 0.0f;          // Y-coordinate of the player's center
    
    // Speed variables 
    float xSpeed = 0.0f;             // Horizontal speed (pixels per frame)
    float ySpeed = 0.0f;             // Vertical speed (pixels per frame)
    float groundSpeed = 0.0f;        // Speed along the ground (independent of angle)
    
    // Angle variables
    float groundAngle = 0.0f;        // Player's ground angle (0-255, where 0=right, 64=down, 128=left, 192=up)
    
    // Size variables
    float widthRadius = 9.0f;        // Width from center point (left and right)
    float heightRadius = 19.0f;      // Height from center point (up and down)
    
    // State flags
    bool isGrounded = false;         // Whether player is on the ground
    bool isRolling = false;          // Whether player is in rolling state
    bool isSpinDashing = false;      // Whether player is spin dashing
    bool isSuperSonic = false;       // Whether player is Super Sonic
    
    // Control variables
    int controlLockTimer = 0;        // Timer for control lock (when slipping on slopes)
    int facing = 1;                  // Direction player is facing (-1 = left, 1 = right)
    
    // Input state
    bool keyLeft = false;
    bool keyRight = false;
    bool keyUp = false;
    bool keyDown = false;
    bool keyJump = false;
    bool keyJumpPressed = false;     // Jump button just pressed
    bool keyJumpReleased = false;    // Jump button just released
    
    // Animation variables
    int animationFrame = 0;
    float animationTimer = 0.0f;
    string currentAnimation = "idle";
    
    // Physics constants - Running state
    static immutable float ACCELERATION_SPEED = 0.046875f;      // 12 subpixels
    static immutable float DECELERATION_SPEED = 0.5f;           // 128 subpixels
    static immutable float TOP_SPEED = 6.0f;                    // Maximum ground speed
    static immutable float FRICTION_SPEED = 0.046875f;          // 12 subpixels
    
    // Physics constants - Air state
    static immutable float AIR_ACCELERATION_SPEED = 0.09375f;   // 24 subpixels (twice ground accel)
    static immutable float GRAVITY_FORCE = 0.21875f;            // 56 subpixels
    static immutable float TOP_Y_SPEED = 16.0f;                 // Maximum falling speed
    
    // Physics constants - Jumping
    static immutable float INITIAL_JUMP_VELOCITY = -6.5f;       // Initial upward velocity when jumping
    static immutable float RELEASE_JUMP_VELOCITY = -4.0f;       // Y speed when jump is released early
    
    // Physics constants - Rolling
    static immutable float ROLLING_FRICTION = 0.046875f;        // 12 subpixels
    static immutable float ROLLING_DECELERATION = 0.125f;       // 32 subpixels
    static immutable float ROLLING_TOP_SPEED = 16.0f;           // Maximum rolling speed (via X speed cap)
    
    // Physics constants - Slopes
    static immutable float SLOPE_FACTOR_NORMAL = 0.125f;        // 32 subpixels
    static immutable float SLOPE_FACTOR_ROLLUP = 0.078125f;     // 20 subpixels
    static immutable float SLOPE_FACTOR_ROLLDOWN = 0.3125f;     // 80 subpixels
    static immutable float SLIP_THRESHOLD = 2.5f;               // Speed threshold for slipping on slopes
    
    // Physics constants - Super Sonic
    static immutable float SUPER_ACCELERATION_SPEED = 0.09375f;
    static immutable float SUPER_DECELERATION_SPEED = 0.5f;
    static immutable float SUPER_TOP_SPEED = 12.0f;
    static immutable float SUPER_AIR_ACCELERATION = 0.1875f;
    static immutable float SUPER_ROLLING_FRICTION = 0.09375f;
    
    // Angle constants (for slope detection)
    static immutable int ANGLE_RIGHT = 0;
    static immutable int ANGLE_DOWN = 64;
    static immutable int ANGLE_LEFT = 128;
    static immutable int ANGLE_UP = 192;
    
    // Slope angle ranges for slipping (Sonic 1/2/CD method)
    static immutable int SLIP_ANGLE_START = 46;     // 46 degrees
    static immutable int SLIP_ANGLE_END = 315;      // 315 degrees
    
    // Alternative slope angle ranges (Sonic 3 method)
    static immutable int SLIP_ANGLE_START_S3 = 35;  // 35 degrees  
    static immutable int SLIP_ANGLE_END_S3 = 326;   // 326 degrees
    static immutable int FALL_ANGLE_START_S3 = 75;  // 75 degrees
    static immutable int FALL_ANGLE_END_S3 = 286;   // 286 degrees
    
    enum SlipAngleType {
        Sonic1_2_CD,
        Sonic3
    }

    SlipAngleType slipAngleType = SlipAngleType.Sonic1_2_CD; // Default slip angle type

    // Utility functions
    void resetPosition(float x, float y) {
        xPosition = x;
        yPosition = y;
        xSpeed = 0.0f;
        ySpeed = 0.0f;
        groundSpeed = 0.0f;
        groundAngle = 0.0f;
        isGrounded = false;
        controlLockTimer = 0;
    }
    
    void setFacing(int direction) {
        facing = (direction < 0) ? -1 : 1;
    }
    
    // Convert ground angle to radians for trigonometric functions
    float groundAngleRadians() {
        return (groundAngle / 128.0f) * 3.14159265358979323846f; // Convert 0-255 to 0-2π
    }
    
    // Update X/Y speeds based on ground speed and angle (for grounded movement)
    void updateSpeedsFromGroundSpeed() {
        if (isGrounded) {
            float angleRad = groundAngleRadians();
            xSpeed = groundSpeed * cos(angleRad);
            ySpeed = groundSpeed * -sin(angleRad);
        }
    }
    
    // Calculate ground speed from X/Y speeds (for landing)
    void updateGroundSpeedFromSpeeds() {
        if (abs(xSpeed) > abs(ySpeed)) {
            groundSpeed = xSpeed;
        } else {
            groundSpeed = ySpeed * 0.5f * -((sin(groundAngleRadians()) >= 0) ? 1 : -1);
        }
    }
    
    // Check if player should slip on current slope
    bool shouldSlipOnSlope() {
        if (!isGrounded || controlLockTimer > 0) return false;
        
        return (abs(groundSpeed) < SLIP_THRESHOLD && 
                (groundAngle > SLIP_ANGLE_START && groundAngle < SLIP_ANGLE_END));
    }
    
    // Apply slope factor to ground speed
    void applySlopeFactor() {
        if (!isGrounded) return;
        
        float slopeFactor = SLOPE_FACTOR_NORMAL;
        
        if (isRolling) {
            // Check if rolling uphill or downhill
            float groundSpeedSign = (groundSpeed >= 0) ? 1 : -1;
            float slopeSign = (sin(groundAngleRadians()) >= 0) ? 1 : -1;
            
            if (groundSpeedSign == slopeSign) {
                slopeFactor = SLOPE_FACTOR_ROLLUP;    // Rolling uphill
            } else {
                slopeFactor = SLOPE_FACTOR_ROLLDOWN;  // Rolling downhill
            }
        }
        
        groundSpeed -= slopeFactor * sin(groundAngleRadians());
    }
    
    // Debug output
    void debugPrint() {
        writeln("=== Player Variables ===");
        writeln("Position: (", xPosition, ", ", yPosition, ")");
        writeln("Speed: (", xSpeed, ", ", ySpeed, ")");
        writeln("Ground Speed: ", groundSpeed);
        writeln("Ground Angle: ", groundAngle);
        writeln("Grounded: ", isGrounded);
        writeln("Facing: ", facing);
        writeln("========================");
    }
}