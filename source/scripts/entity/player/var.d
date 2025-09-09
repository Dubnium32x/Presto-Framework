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
    float groundAngle = 0.0f;        // Player's ground angle in degrees (0 = flat, positive = slope rising left->right)
    
    // Size variables
    // Reduce radii to better match sprite and avoid overly large collision boxes.
    // These were previously doubled for visibility; halve them so collision extents are tighter.
    // Tighter collision radii so player can fit through narrow gaps; can be tuned further.
    float widthRadius = 6.0f;        // Width from center point (left and right)
    float heightRadius = 16.0f;      // Height from center point (up and down)
    
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
        writeln("[DEBUG GROUND ANGLE] resetPosition - groundAngle: ", groundAngle, " -> 0");
        groundAngle = 0.0f;
        isGrounded = false;
        controlLockTimer = 0;
    }
    
    void setFacing(int direction) {
        facing = (direction < 0) ? -1 : 1;
    }
    
    // Convert ground angle (degrees) to radians for trigonometric functions
    float groundAngleRadians() {
        // Safety check for bad angle values
        if (isNaN(groundAngle) || groundAngle < -180.0f || groundAngle > 180.0f) {
            writeln("[DEBUG GROUND ANGLE] Bad groundAngle detected: ", groundAngle, " - resetting to 0");
            groundAngle = 0.0f;
        }
        float radians = groundAngle * (3.14159265358979323846f / 180.0f);
        if (isNaN(radians)) {
            writeln("[DEBUG GROUND ANGLE] Radians calculation resulted in NaN! groundAngle=", groundAngle);
            radians = 0.0f;
        }
        return radians;
    }
    
    // Update X/Y speeds based on ground speed and angle (for grounded movement)
    void updateSpeedsFromGroundSpeed() {
        if (isGrounded) {
            float angleRad = groundAngleRadians();
            // Project groundSpeed onto X/Y using the ground angle.
            // Use negative sin because screen Y axis points downwards;
            // a positive groundAngle means the surface rises to the right,
            // so moving right should produce an upward (negative) ySpeed.
            xSpeed = groundSpeed * cos(angleRad);
            ySpeed = -groundSpeed * sin(angleRad);
        }
    }
    
    // Calculate ground speed from X/Y speeds (for landing)
    void updateGroundSpeedFromSpeeds() {
        // If both speeds are very small, treat as idle
        if (abs(xSpeed) < 0.1f && abs(ySpeed) < 0.1f) {
            groundSpeed = 0;
            return;
        }
        // Recompute groundSpeed by projecting the current velocity onto
        // the ground unit vector (cos, sin). This keeps sign and magnitude
        // consistent across slopes of any angle.
        float angleRad = groundAngleRadians();
    // Project the velocity vector onto the ground unit vector (cos, -sin)
    // so groundSpeed retains the correct sign when on slopes.
    groundSpeed = xSpeed * cos(angleRad) - ySpeed * sin(angleRad);

        // Clamp very small groundSpeeds to zero on (near-)flat surfaces
        if ((groundAngle == 0 || abs(sin(angleRad)) < 0.001f) && abs(groundSpeed) < 0.25f) {
            groundSpeed = 0;
        }
    }
    
    // Check if player should slip on current slope
    bool shouldSlipOnSlope() {
        if (!isGrounded || controlLockTimer > 0) return false;
        // Tile angles are computed as atan(height_slope) and thus lie in [-90,90].
        // The SPG slip ranges were expressed for 0..360 hex angles; here we
        // simply check the absolute angle magnitude to decide slipping on steep
        // slopes (equivalent to SPG's exclusion of shallow angles around 0).
        return (abs(groundSpeed) < SLIP_THRESHOLD && abs(groundAngle) > SLIP_ANGLE_START);
    }
    
    // Apply slope factor to ground speed
    void applySlopeFactor() {
        if (!isGrounded) return;
        
        // Don't apply slope factor on flat ground
        if (abs(groundAngle) < 1.0f) return;
        
        float slopeFactor = SLOPE_FACTOR_NORMAL;
        
        if (isRolling) {
            // Check if rolling uphill or downhill
            float groundSpeedSign = (groundSpeed >= 0) ? 1 : -1;
            float angleRad = groundAngleRadians();
            if (isNaN(angleRad)) {
                writeln("[WARN] groundAngleRadians returned NaN in applySlopeFactor");
                angleRad = 0.0f;
            }
            float slopeSign = (sin(angleRad) >= 0) ? 1 : -1;
            
            if (groundSpeedSign == slopeSign) {
                slopeFactor = SLOPE_FACTOR_ROLLUP;    // Rolling uphill
            } else {
                slopeFactor = SLOPE_FACTOR_ROLLDOWN;  // Rolling downhill
            }
        }
        
        float angleRad = groundAngleRadians();
        if (isNaN(angleRad)) {
            writeln("[WARN] groundAngleRadians returned NaN in slope application");
            angleRad = 0.0f;
        }
        float sinAngle = sin(angleRad);
        if (isNaN(sinAngle)) {
            writeln("[WARN] sin(angle) returned NaN, angleRad=", angleRad);
            sinAngle = 0.0f;
        }
        
        float oldGroundSpeed = groundSpeed;
        groundSpeed -= slopeFactor * sinAngle;
        
        if (isNaN(groundSpeed)) {
            writeln("[ERROR] groundSpeed became NaN! old=", oldGroundSpeed, " slopeFactor=", slopeFactor, " sinAngle=", sinAngle);
            groundSpeed = oldGroundSpeed; // Revert to old value
        }
    }
    
    // Get slope-dependent movement modifier for acceleration/deceleration/friction
    float getSlopeMovementModifier() {
        if (!isGrounded || abs(groundAngle) < 1.0f) {
            return 1.0f; // No modifier on flat ground or when airborne
        }
        
        // Determine if we're trying to move uphill or downhill
        float angleRad = groundAngleRadians();
        float slopeSign = sin(angleRad); // Positive = upward slope to the right, negative = downward slope to the right
        float movementSign = (groundSpeed >= 0) ? 1 : -1; // Direction we're moving
        
        // Calculate if we're going uphill or downhill
        // If signs are the same, we're going uphill; if different, downhill
        bool goingUphill = (slopeSign * movementSign > 0);
        
        // Base modifier ranges from 0.5 (uphill, harder) to 1.5 (downhill, easier)
        float slopeIntensity = abs(sin(angleRad)); // 0 to 1 based on slope steepness
        
        if (goingUphill) {
            // Going uphill: reduce acceleration/friction (0.5 to 1.0)
            return 1.0f - (slopeIntensity * 0.5f);
        } else {
            // Going downhill: increase acceleration/friction (1.0 to 1.5)
            return 1.0f + (slopeIntensity * 0.5f);
        }
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