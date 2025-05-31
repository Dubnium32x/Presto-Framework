module player.player;

import raylib;

import std.stdio;
import std.string;
import std.file;
import std.algorithm;
import std.conv;
import std.array;
import std.math;


import player.var;

enum PlayerState {
    IDLE,
    RUNNING,
    JUMPING,
    FALLING,
    FALLING_ROLL,
    SHIELD_ACTION,
    WALK,
    RUN,
    DASHING,
    SPINDASHING,
    PEELING,
    ROLLING,
    HOVERING,
    CLIMBING,
    GLIDING,
    HURT,
    DEAD
}

enum IdleState {
    IDLE,
    LOOK_UP,
    LOOK_DOWN,
    IMPATIENT,
    IMPATIENT_ATTRACT,
    IM_OUTTA_HERE,
    BALANCE_FORWARD,
    BALANCE_BACKWARD
}

enum KeyDefine {
    LEFT,
    RIGHT,
    UP,
    DOWN,
    ACTION,
    ACTION2
}

enum Sensor {
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
    MIDDLE_LEFT,
    MIDDLE_RIGHT,
    TOP_LEFT,
    TOP_RIGHT,
    COUNT // Helper for array sizes
}

bool isKeyPressed(KeyDefine key) {
    switch (key) {
        case KeyDefine.LEFT:
            return IsKeyPressed(KeyboardKey.KEY_LEFT);
        case KeyDefine.RIGHT:
            return IsKeyPressed(KeyboardKey.KEY_RIGHT);
        case KeyDefine.UP:
            return IsKeyPressed(KeyboardKey.KEY_UP);
        case KeyDefine.DOWN:
            return IsKeyPressed(KeyboardKey.KEY_DOWN);
        case KeyDefine.ACTION:
            return IsKeyPressed(KeyboardKey.KEY_Z);
        case KeyDefine.ACTION2:
            return IsKeyPressed(KeyboardKey.KEY_X);
        default:
            writeln("Unknown key define: ", key);
            assert(false, "Unknown key define in isKeyPressed function");
            return false; // Fallback case
    }
    return false;
}

bool isKeyDown(KeyDefine key) {
    switch (key) {
        case KeyDefine.LEFT:
            return IsKeyDown(KeyboardKey.KEY_LEFT);
        case KeyDefine.RIGHT:
            return IsKeyDown(KeyboardKey.KEY_RIGHT);
        case KeyDefine.UP:
            return IsKeyDown(KeyboardKey.KEY_UP);
        case KeyDefine.DOWN:
            return IsKeyDown(KeyboardKey.KEY_DOWN);
        case KeyDefine.ACTION:
            return IsKeyDown(KeyboardKey.KEY_Z);
        case KeyDefine.ACTION2:
            return IsKeyDown(KeyboardKey.KEY_X);
        default:
            writeln("Unknown key define: ", key);
            assert(false, "Unknown key define in isKeyDown function");
            return false; // Fallback case
    }
    return false;
}

bool isKeyReleased(KeyDefine key) {
    switch (key) {
        case KeyDefine.LEFT:
            return IsKeyReleased(KeyboardKey.KEY_LEFT);
        case KeyDefine.RIGHT:
            return IsKeyReleased(KeyboardKey.KEY_RIGHT);
        case KeyDefine.UP:
            return IsKeyReleased(KeyboardKey.KEY_UP);
        case KeyDefine.DOWN:
            return IsKeyReleased(KeyboardKey.KEY_DOWN);
        case KeyDefine.ACTION:
            return IsKeyReleased(KeyboardKey.KEY_Z);
        case KeyDefine.ACTION2:
            return IsKeyReleased(KeyboardKey.KEY_X);
        default:
            writeln("Unknown key define: ", key);
            assert(false, "Unknown key define in isKeyReleased function");
            return false; // Fallback case
    }
    return false;
}

class Player {
    PlayerState state = PlayerState.IDLE;
    IdleState idleState = IdleState.IDLE;

    // Input state variables
    bool keyLeft;
    bool keyRight;
    bool keyUp;
    bool keyDown;
    bool keyActionPressed; // For jump, etc. (Z key)
    bool keyActionHeld;    // For held jump, etc. (Z key)
    bool keyAction2Pressed; // (X key)
    
    // Ground stability counter to prevent oscillations
    int groundStabilityCounter = 0;

    // Sensor data
    Vector2[Sensor.COUNT] sensorPositions;
    // bool[Sensor.COUNT] sensorCollisions; // Will be used later for collision logic

    // Player position and movement variables are located in var.d (Var.x, Var.y, Var.xspeed, Var.yspeed)
    // Physics constants are in var.d (GamePhysics.gravity, etc.)

    // Singletons for player state and physics
    this() {
        Var.x = 400.0f;
        Var.y = 100.0f;

        // Initialize other player variables
        Var.xspeed = 0.0f;
        Var.yspeed = 0.0f;
        Var.grounded = false;

        // Set initial state
        state = PlayerState.IDLE;

        // Initialize sensor positions array to avoid issues, though they'll be set each frame.
        foreach (ref pos; sensorPositions) {
            pos = Vector2(0,0);
        }
    }

    void processInput() {
        keyLeft = isKeyDown(KeyDefine.LEFT);
        keyRight = isKeyDown(KeyDefine.RIGHT);
        keyUp = isKeyDown(KeyDefine.UP);
        keyDown = isKeyDown(KeyDefine.DOWN);
        
        keyActionPressed = isKeyPressed(KeyDefine.ACTION); // Z key
        keyActionHeld = isKeyDown(KeyDefine.ACTION);     // Z key
        keyAction2Pressed = isKeyPressed(KeyDefine.ACTION2); // X key
    }

    void updateSensorPositions() {
        float halfWidth = Var.widthrad;
        float halfHeight = Var.heightrad;

        // Bottom sensors (like A, B in classic Sonic)
        sensorPositions[Sensor.BOTTOM_LEFT]  = Vector2(Var.x - halfWidth * 0.7f, Var.y + halfHeight); // Slightly inwards
        sensorPositions[Sensor.BOTTOM_RIGHT] = Vector2(Var.x + halfWidth * 0.7f, Var.y + halfHeight); // Slightly inwards

        // Middle side sensors (like C, D)
        sensorPositions[Sensor.MIDDLE_LEFT]  = Vector2(Var.x - halfWidth, Var.y);
        sensorPositions[Sensor.MIDDLE_RIGHT] = Vector2(Var.x + halfWidth, Var.y);
        
        // Top sensors (like E, F)
        sensorPositions[Sensor.TOP_LEFT]  = Vector2(Var.x - halfWidth * 0.7f, Var.y - halfHeight); // Slightly inwards
        sensorPositions[Sensor.TOP_RIGHT] = Vector2(Var.x + halfWidth * 0.7f, Var.y - halfHeight); // Slightly inwards
    }

    public void checkEnvironmentCollision() {
        // get references to test platforms in app.d
        import app : testPlatforms;

        bool wwasGrounded = Var.grounded; // Store previous grounded state
        
        // For movement prediction, store velocity
        float xvel = Var.xspeed;
        
        // Only for debug visualization
        bool leftCollided = false;
        bool rightCollided = false;
        
        // Create horizontal padding for side sensors based on xspeed
        // This helps catch collisions when moving fast
        float horizPadding = min(abs(Var.xspeed) * 0.5f, Var.widthrad * 0.5f);
        
        // Reset grounded state conditionally - don't reset if we're in a stability window
        if (groundStabilityCounter <= 0) {
            Var.grounded = false; // Reset grounded state for this frame
        } else {
            groundStabilityCounter--; // Decrease stability counter
        }
        
        // Temporary flag to detect if grounded this frame (for stability counter update)
        bool groundedThisFrame = false;
        
        // Always check side collisions first, regardless of grounded state
        // This prevents clipping through walls when falling or jumping
        foreach (platform; testPlatforms) {
            // Check for right wall collision (left side sensor)
            if (Var.xspeed < 0 || (abs(Var.xspeed) < 0.1f && Var.x - Var.widthrad <= platform.x + platform.width && 
                Var.x > platform.x + platform.width * 0.5f)) {
                
                // Left sensor with padding based on speed
                Vector2 leftSensor = Vector2(
                    sensorPositions[Sensor.MIDDLE_LEFT].x - horizPadding, 
                    sensorPositions[Sensor.MIDDLE_LEFT].y
                );
                
                // Additional corner check for high-speed movement
                Vector2 topLeftSensor = Vector2(
                    sensorPositions[Sensor.MIDDLE_LEFT].x - horizPadding, 
                    sensorPositions[Sensor.TOP_LEFT].y + Var.heightrad * 0.3f
                );
                
                Vector2 bottomLeftSensor = Vector2(
                    sensorPositions[Sensor.MIDDLE_LEFT].x - horizPadding, 
                    sensorPositions[Sensor.BOTTOM_LEFT].y - Var.heightrad * 0.3f
                );
                
                // Check if any of the sensors collide
                if (CheckCollisionPointRec(leftSensor, platform) || 
                    CheckCollisionPointRec(topLeftSensor, platform) || 
                    CheckCollisionPointRec(bottomLeftSensor, platform)) {
                    
                    leftCollided = true;
                    
                    // Snap to the right edge of the platform with a small buffer
                    Var.x = platform.x + platform.width + Var.widthrad + 0.1f;
                    
                    // Reflect some momentum for a bounce effect on high speed
                    if (Var.xspeed < -2.0f) {
                        Var.xspeed = abs(Var.xspeed) * 0.1f; // Small bounce
                    } else {
                        Var.xspeed = 0; // Just stop for low speed
                    }
                }
            }
            
            // Check for left wall collision (right side sensor)
            if (Var.xspeed > 0 || (abs(Var.xspeed) < 0.1f && Var.x + Var.widthrad >= platform.x && 
                Var.x < platform.x + platform.width * 0.5f)) {
                
                // Right sensor with padding based on speed
                Vector2 rightSensor = Vector2(
                    sensorPositions[Sensor.MIDDLE_RIGHT].x + horizPadding, 
                    sensorPositions[Sensor.MIDDLE_RIGHT].y
                );
                
                // Additional corner check for high-speed movement
                Vector2 topRightSensor = Vector2(
                    sensorPositions[Sensor.MIDDLE_RIGHT].x + horizPadding, 
                    sensorPositions[Sensor.TOP_RIGHT].y + Var.heightrad * 0.3f
                );
                
                Vector2 bottomRightSensor = Vector2(
                    sensorPositions[Sensor.MIDDLE_RIGHT].x + horizPadding, 
                    sensorPositions[Sensor.BOTTOM_RIGHT].y - Var.heightrad * 0.3f
                );
                
                // Check if any of the sensors collide
                if (CheckCollisionPointRec(rightSensor, platform) || 
                    CheckCollisionPointRec(topRightSensor, platform) || 
                    CheckCollisionPointRec(bottomRightSensor, platform)) {
                    
                    rightCollided = true;
                    
                    // Snap to the left edge of the platform with a small buffer
                    Var.x = platform.x - Var.widthrad - 0.1f;
                    
                    // Reflect some momentum for a bounce effect on high speed
                    if (Var.xspeed > 2.0f) {
                        Var.xspeed = -abs(Var.xspeed) * 0.1f; // Small bounce
                    } else {
                        Var.xspeed = 0; // Just stop for low speed
                    }
                }
            }
        }
        
        // Now check the bottom sensors for ground collision with improved high-speed fall detection
        foreach (platform; testPlatforms) {
            // Calculate vertical padding based on fall speed
            // The faster we're falling, the more we need to check ahead
            float fallPadding = Var.yspeed > 0 ? min(Var.yspeed * 0.6f, Var.heightrad * 0.9f) : 0;
            
            // Extended bottom sensors that reach farther down when falling fast
            Vector2 bottomLeftExt = Vector2(
                sensorPositions[Sensor.BOTTOM_LEFT].x,
                sensorPositions[Sensor.BOTTOM_LEFT].y + fallPadding
            );
            
            Vector2 bottomRightExt = Vector2(
                sensorPositions[Sensor.BOTTOM_RIGHT].x,
                sensorPositions[Sensor.BOTTOM_RIGHT].y + fallPadding
            );
            
            Vector2 bottomCenter = Vector2(
                Var.x,
                sensorPositions[Sensor.BOTTOM_LEFT].y + fallPadding
            );
            
            // Additional edge case detection for high speed falls
            // These wide sensors help catch platform edges when falling fast
            Vector2 bottomLeftWide = Vector2(
                sensorPositions[Sensor.BOTTOM_LEFT].x - Var.widthrad * 0.3f,
                sensorPositions[Sensor.BOTTOM_LEFT].y + fallPadding * 0.7f
            );
            
            Vector2 bottomRightWide = Vector2(
                sensorPositions[Sensor.BOTTOM_RIGHT].x + Var.widthrad * 0.3f,
                sensorPositions[Sensor.BOTTOM_RIGHT].y + fallPadding * 0.7f
            );
            
            // Create a sweep test for very high speeds
            bool performSweepTest = Var.yspeed > 7.0f; // Only for high fall speeds
            Rectangle sweepRect;
            
            if (performSweepTest) {
                // Create a rectangle that covers the entire sweep path with extra width
                sweepRect = Rectangle(
                    Var.x - Var.widthrad * 0.9f,                          // Left edge (wider)
                    sensorPositions[Sensor.BOTTOM_LEFT].y - fallPadding,  // Top edge (previous position)
                    Var.widthrad * 1.8f,                                  // Width (using 90% of full width)
                    fallPadding * 2                                       // Height (covers the swept area)
                );
            }
            
            // For extremely high fall speeds, use a broader detection area
            Rectangle extremeFallRect;
            bool useExtremeFallDetection = Var.yspeed > 12.0f;
            
            if (useExtremeFallDetection) {
                // Create a very wide rectangle for extreme speeds
                extremeFallRect = Rectangle(
                    Var.x - Var.widthrad * 1.5f,                          // Much wider left edge
                    sensorPositions[Sensor.BOTTOM_LEFT].y,                // Start at current position
                    Var.widthrad * 3.0f,                                  // Very wide detection area
                    fallPadding * 1.5f                                    // Shorter but focused height
                );
            }
            
            // Check for pre-collision with platform edges to prevent clipping at high speeds
            bool edgePreventionCheck = false;
            
            // Only do edge prevention at high speeds when near platform edges
            if (Var.yspeed > 9.0f) {
                // Check if we're about to clip through the edge of a platform
                // by comparing our position with the platform edges
                bool nearLeftEdge = abs(Var.x - platform.x) < Var.widthrad * 1.2f && 
                                  Var.x > platform.x && 
                                  Var.y + Var.heightrad + fallPadding * 0.8f > platform.y &&
                                  Var.y < platform.y;
                                  
                bool nearRightEdge = abs(Var.x - (platform.x + platform.width)) < Var.widthrad * 1.2f && 
                                   Var.x < platform.x + platform.width &&
                                   Var.y + Var.heightrad + fallPadding * 0.8f > platform.y &&
                                   Var.y < platform.y;
                
                // If we're near an edge and would clip through it, do edge prevention
                if (nearLeftEdge || nearRightEdge) {
                    // Create a special collision point on the platform edge
                    Vector2 edgePoint = Vector2(
                        nearLeftEdge ? platform.x + 2.0f : platform.x + platform.width - 2.0f,
                        platform.y - 1.0f
                    );
                    
                    // Check if our extended sensor would hit this edge point
                    if (CheckCollisionPointCircle(edgePoint, Vector2(Var.x, Var.y + Var.heightrad + fallPadding * 0.5f), Var.widthrad * 1.1f)) {
                        edgePreventionCheck = true;
                    }
                }
            }
            
            // Check if we're close enough to the ground to be considered grounded
            // This helps with the oscillation issue by using a more forgiving ground check
            bool isCloseToGround = false;
            float groundProximityThreshold = 0.5f; // Distance within which we're considered "on the ground"
            
            // Calculate distance from bottom of player to top of platform
            float distanceToGround = platform.y - (Var.y + Var.heightrad);
            if (distanceToGround >= -0.1f && distanceToGround <= groundProximityThreshold) {
                // Check if we're horizontally within the platform
                if (Var.x + Var.widthrad * 0.7f >= platform.x && 
                    Var.x - Var.widthrad * 0.7f <= platform.x + platform.width) {
                    isCloseToGround = true;
                }
            }
            
            // Check all bottom sensors and sweep rect
            if (CheckCollisionPointRec(sensorPositions[Sensor.BOTTOM_LEFT], platform) ||
                CheckCollisionPointRec(sensorPositions[Sensor.BOTTOM_RIGHT], platform) ||
                CheckCollisionPointRec(bottomLeftExt, platform) ||
                CheckCollisionPointRec(bottomRightExt, platform) ||
                CheckCollisionPointRec(bottomCenter, platform) ||
                CheckCollisionPointRec(bottomLeftWide, platform) ||    // New wide sensor
                CheckCollisionPointRec(bottomRightWide, platform) ||   // New wide sensor
                (performSweepTest && CheckCollisionRecs(sweepRect, platform)) ||
                (useExtremeFallDetection && CheckCollisionRecs(extremeFallRect, platform)) ||
                edgePreventionCheck ||
                isCloseToGround) {
                
                Var.grounded = true;
                groundedThisFrame = true;  // Mark that we found ground this frame
                Var.framesNotGrounded = 0;
                
                // Calculate a more precise landing position
                // For high speeds, place character slightly above platform to prevent clipping through
                float snapBuffer = Var.yspeed > 6.0f ? 0.2f : 0.1f; // Increased minimum buffer to prevent oscillation
                if (Var.yspeed > 10.0f) snapBuffer = 0.25f;  // Even more buffer at extreme speeds
                
                // Only snap if we're not already very close to the platform (to prevent jitter)
                if (!isCloseToGround || abs(distanceToGround) > 0.05f) {
                    Var.y = platform.y - Var.heightrad - snapBuffer;
                }
                
                // Apply ground friction to horizontal speed when landing at high speed
                if (Var.yspeed > 8.0f && abs(Var.xspeed) > 3.0f) {
                    Var.xspeed *= 0.9f; // Reduce horizontal speed slightly on hard landings
                }
                
                // Special handling for edge prevention cases
                if (edgePreventionCheck) {
                    // If this was an edge prevention case, we need to ensure player stays on platform
                    if (Var.x < platform.x + Var.widthrad) {
                        // Near left edge, push slightly right
                        Var.x = platform.x + Var.widthrad * 1.1f;
                    } else if (Var.x > platform.x + platform.width - Var.widthrad) {
                        // Near right edge, push slightly left
                        Var.x = platform.x + platform.width - Var.widthrad * 1.1f;
                    }
                }
                
                Var.yspeed = 0;
                break;
            }
        }

        // Update stability counter if we found ground
        if (groundedThisFrame) {
            // Set stability counter to prevent oscillation for a few frames
            groundStabilityCounter = 3; // Stay grounded for at least 3 frames to prevent oscillation
        }

        // Finally check for ceiling collisions - only when moving upward
        if (Var.yspeed < 0) {
            foreach (platform; testPlatforms) {
                // Add vertical padding for fast upward movement
                float vertPadding = min(abs(Var.yspeed) * 0.5f, Var.heightrad * 0.3f);
                
                // Adjust ceiling sensors with padding
                Vector2 topLeftSensor = Vector2(
                    sensorPositions[Sensor.TOP_LEFT].x,
                    sensorPositions[Sensor.TOP_LEFT].y - vertPadding
                );
                
                Vector2 topRightSensor = Vector2(
                    sensorPositions[Sensor.TOP_RIGHT].x,
                    sensorPositions[Sensor.TOP_RIGHT].y - vertPadding
                );
                
                // Check ceiling collision
                if (CheckCollisionPointRec(topLeftSensor, platform) || 
                    CheckCollisionPointRec(topRightSensor, platform)) {
                    
                    // Snap to the bottom of the platform with a small buffer
                    Var.y = platform.y + platform.height + Var.heightrad + 0.1f;
                    
                    // Bounce slightly off ceiling for better game feel
                    Var.yspeed = abs(Var.yspeed) * 0.1f; // Small downward bounce
                    
                    break; // Exit loop if collided
                }
            }
        }
        
        // Update player state based on grounded status
        if (Var.grounded) {
            if (state != PlayerState.IDLE && state != PlayerState.RUNNING) {
                state = PlayerState.IDLE; // Reset to idle when grounded
            }
        } else {
            if (state == PlayerState.IDLE || state == PlayerState.RUNNING) {
                state = PlayerState.JUMPING; // Transition to jumping state when not grounded
            }
        }
        
        // If the player was previously grounded but is no longer grounded, increment framesNotGrounded
        if (wwasGrounded && !Var.grounded) {
            Var.framesNotGrounded++;
        } else if (Var.grounded) {
            Var.framesNotGrounded = 0; // Reset if grounded
        }
    }

    public void update(float deltaTime) {
        // Process player input
        processInput();
        
        // Store previous position for collision
        float prevX = Var.x;
        float prevY = Var.y;
        
        // Apply variable gravity based on jump state
        if (!Var.grounded) {
            // Calculate a parabolic-like jump curve with variable gravity
            float gravityModifier = 1.0f;
            
            // When moving upward, use lighter gravity for a more gradual slowdown
            if (Var.yspeed < 0) {
                // Use lighter gravity at the beginning of the jump (when speed is high)
                // and gradually increase it as we approach the apex
                gravityModifier = 0.5f + (0.5f * (1.0f - min(abs(Var.yspeed) / Var.jumpforce, 1.0f)));
                
                // Jump height control (variable height) - apply only during first half of jump
                if (!keyActionHeld) {
                    // If player releases jump button during rise, add extra gravity
                    gravityModifier += 0.7f;  // Makes jump cut feel more responsive
                }
            }
            // When falling, use slightly lower gravity for lower descent
            else {
                gravityModifier = 0.8f;
            }
            
            // Apply adjusted gravity
            Var.yspeed += GamePhysics.gravity * gravityModifier;
            
            // Clamp maximum fall speed
            if (Var.yspeed > GamePhysics.maxFallSpeed) {
                Var.yspeed = GamePhysics.maxFallSpeed;
            }
        }
        
        // Handle jumping - modify the initial jump velocity calculation
        if (Var.grounded && keyActionPressed) {
            // Apply the full jump force instantly for responsive feel
            Var.yspeed = -Var.jumpforce;
            Var.grounded = false;
            state = PlayerState.JUMPING;
            
            // Add debug output
            writeln("Jump initiated! yspeed = ", Var.yspeed);
        }
        
        // Handle horizontal movement with improved turn-around physics
        if (Var.grounded) {
            // Ground movement
            if (keyLeft && !keyRight) {
                // If moving right but trying to go left, apply stronger deceleration (turn-around)
                if (Var.xspeed > 0) {
                    Var.xspeed -= GamePhysics.deceleration * 2.5f; // Stronger turn-around force
                } 
                // Normal acceleration to the left
                else {
                    Var.xspeed -= GamePhysics.acceleration;
                }
                
                // Cap maximum speed
                if (Var.xspeed < -GamePhysics.topspeed) {
                    Var.xspeed = -GamePhysics.topspeed;
                }
                
                // Update state
                if (state != PlayerState.JUMPING && state != PlayerState.FALLING) {
                    state = Var.xspeed > 0 ? PlayerState.RUNNING : PlayerState.WALK; // Running if still moving right
                }
            } 
            else if (keyRight && !keyLeft) {
                // If moving left but trying to go right, apply stronger deceleration (turn-around)
                if (Var.xspeed < 0) {
                    Var.xspeed += GamePhysics.deceleration * 2.5f; // Stronger turn-around force
                } 
                // Normal acceleration to the right
                else {
                    Var.xspeed += GamePhysics.acceleration;
                }
                
                // Cap maximum speed
                if (Var.xspeed > GamePhysics.topspeed) {
                    Var.xspeed = GamePhysics.topspeed;
                }
                
                // Update state
                if (state != PlayerState.JUMPING && state != PlayerState.FALLING) {
                state = Var.xspeed < 0 ? PlayerState.RUNNING : PlayerState.WALK; // Running if still moving left
                }
            } 
            else {
                // No input - apply friction based on ground mode
                // For now, just apply standard friction
                if (Var.xspeed > 0) {
                    Var.xspeed -= GamePhysics.friction;
                    if (Var.xspeed < 0) Var.xspeed = 0;
                } 
                else if (Var.xspeed < 0) {
                    Var.xspeed += GamePhysics.friction;
                    if (Var.xspeed > 0) Var.xspeed = 0;
                }
                
                // Update state if virtually stopped
                if (abs(Var.xspeed) < 0.1f && state != PlayerState.JUMPING && state != PlayerState.FALLING) {
                    state = PlayerState.IDLE;
                }
            }
        } 
        else {
            // Air movement - increased control with no friction
            float airControlFactor = 1.2f; // Tripled from 0.4f for more responsive air control
            
            // In mid-air, apply turn-around effect but softer than on ground
            if (keyLeft && !keyRight) {
                // If moving right but trying to go left in air, apply moderate turn-around
                if (Var.xspeed > 0) {
                    Var.xspeed -= GamePhysics.deceleration * 0.8f; // Slightly reduced for less heavy feel
                } 
                // Enhanced air acceleration for responsive control
                else {
                    Var.xspeed -= GamePhysics.acceleration * airControlFactor;
                }
                
                // Cap maximum speed
                if (Var.xspeed < -GamePhysics.topspeed) {
                    Var.xspeed = -GamePhysics.topspeed;
                }
            } 
            else if (keyRight && !keyLeft) {
                // If moving left but trying to go right in air, apply moderate turn-around
                if (Var.xspeed < 0) {
                    Var.xspeed += GamePhysics.deceleration * 0.5f; // Slightly reduced for less heavy feel
                } 
                // Enhanced air acceleration for responsive control
                else {
                    Var.xspeed += GamePhysics.acceleration * airControlFactor;
                }
                
                // Cap maximum speed
                if (Var.xspeed > GamePhysics.topspeed) {
                    Var.xspeed = GamePhysics.topspeed;
                }
            }
            else {
                // No input in air - apply reduced friction
                if (Var.xspeed > 0) {
                    Var.xspeed -= GamePhysics.friction * 0.5f; // Reduced friction in air
                    if (Var.xspeed < 0) Var.xspeed = 0;
                } 
                else if (Var.xspeed < 0) {
                    Var.xspeed += GamePhysics.friction * 0.5f; // Reduced friction in air
                    if (Var.xspeed > 0) Var.xspeed = 0;
                }
                
                // Update state if virtually stopped
                if (abs(Var.xspeed) < 0.1f && state != PlayerState.JUMPING && state != PlayerState.FALLING) {
                    state = PlayerState.IDLE;
                }
            }
        }
        
        // Remove the old jump height control since we're now handling it with variable gravity
        
        // Apply movement
        Var.x += Var.xspeed;
        Var.y += Var.yspeed;
        
        // Update sensor positions after movement but before collision
        updateSensorPositions();
        
        // Check for and resolve collisions
        checkEnvironmentCollision();
        
        // Update sensor positions again after collision resolution
        updateSensorPositions();
        
        // Store ground speed for reference (useful for loops and slopes later)
        Var.groundspeed = Var.xspeed;
        
        // Debug output - commented out for less console spam
        // writeln("Player pos: ", Var.x, ", ", Var.y, " | Speed: ", Var.xspeed, ", ", Var.yspeed, 
        //         " | Ground: ", Var.grounded, " | State: ", state);
    }

    void draw() {
        // Sensor debug visualization
        import app : testPlatforms;
        
        // Draw a simple representation of the player (hitbox)
        DrawRectangleLines(
            cast(int)(Var.x - Var.widthrad), 
            cast(int)(Var.y - Var.heightrad), 
            cast(int)(Var.widthrad * 2), 
            cast(int)(Var.heightrad * 2), 
            Colors.GREEN
        );

        /* Comment out detailed sensor visualization for cleaner display
        // Draw regular sensors
        foreach (int i; 0 .. cast(int)Sensor.COUNT) {
            // Check collision state for sensor color
            bool isSensorColliding = false;
            foreach (platform; testPlatforms) {
                if (CheckCollisionPointRec(sensorPositions[cast(Sensor)i], platform)) {
                    isSensorColliding = true;
                    break;
                }
            }
            
            // Choose color based on collision
            Color sensorColor = isSensorColliding ? Colors.RED : Colors.YELLOW;
            
            // Draw sensor dot
            DrawCircleV(sensorPositions[i], 3.0f, sensorColor);
            
            // Label sensors
            char label = cast(char)('A' + i);
            DrawText(&label, 
                cast(int)sensorPositions[i].x + 5, 
                cast(int)sensorPositions[i].y - 5, 
                12, 
                sensorColor
            );
        }
        
        // Draw additional collision sensors used in wall detection
        float horizPadding = min(abs(Var.xspeed) * 0.5f, Var.widthrad * 0.5f);
        
        // Left side extended sensors
        Vector2 extendedLeftSensor = Vector2(
            sensorPositions[Sensor.MIDDLE_LEFT].x - horizPadding,
            sensorPositions[Sensor.MIDDLE_LEFT].y
        );
        
        Vector2 topLeftSensor = Vector2(
            sensorPositions[Sensor.MIDDLE_LEFT].x - horizPadding, 
            sensorPositions[Sensor.TOP_LEFT].y + Var.heightrad * 0.3f
        );
        
        Vector2 bottomLeftSensor = Vector2(
            sensorPositions[Sensor.MIDDLE_LEFT].x - horizPadding, 
            sensorPositions[Sensor.BOTTOM_LEFT].y - Var.heightrad * 0.3f
        );
        
        // Right side extended sensors
        Vector2 extendedRightSensor = Vector2(
            sensorPositions[Sensor.MIDDLE_RIGHT].x + horizPadding,
            sensorPositions[Sensor.MIDDLE_RIGHT].y
        );
        
        Vector2 topRightSensor = Vector2(
            sensorPositions[Sensor.MIDDLE_RIGHT].x + horizPadding, 
            sensorPositions[Sensor.TOP_RIGHT].y + Var.heightrad * 0.3f
        );
        
        Vector2 bottomRightSensor = Vector2(
            sensorPositions[Sensor.MIDDLE_RIGHT].x + horizPadding, 
            sensorPositions[Sensor.BOTTOM_RIGHT].y - Var.heightrad * 0.3f
        );
        
        // Draw extended sensor points with dimmer color
        Color extendedSensorColor = Color(150, 150, 0, 200);
        
        DrawCircleV(extendedLeftSensor, 2.0f, extendedSensorColor);
        DrawCircleV(topLeftSensor, 2.0f, extendedSensorColor);
        DrawCircleV(bottomLeftSensor, 2.0f, extendedSensorColor);
        
        DrawCircleV(extendedRightSensor, 2.0f, extendedSensorColor);
        DrawCircleV(topRightSensor, 2.0f, extendedSensorColor);
        DrawCircleV(bottomRightSensor, 2.0f, extendedSensorColor);
        
        // Draw extended floor sensors when falling
        if (Var.yspeed > 0) {
            float fallPadding = min(Var.yspeed * 0.6f, Var.heightrad * 0.9f);
            
            Vector2 bottomLeftExt = Vector2(
                sensorPositions[Sensor.BOTTOM_LEFT].x,
                sensorPositions[Sensor.BOTTOM_LEFT].y + fallPadding
            );
            
            Vector2 bottomRightExt = Vector2(
                sensorPositions[Sensor.BOTTOM_RIGHT].x,
                sensorPositions[Sensor.BOTTOM_RIGHT].y + fallPadding
            );
            
            Vector2 bottomCenter = Vector2(
                Var.x,
                sensorPositions[Sensor.BOTTOM_LEFT].y + fallPadding
            );
            
            // Additional edge case detection
            Vector2 bottomLeftWide = Vector2(
                sensorPositions[Sensor.BOTTOM_LEFT].x - Var.widthrad * 0.3f,
                sensorPositions[Sensor.BOTTOM_LEFT].y + fallPadding * 0.7f
            );
            
            Vector2 bottomRightWide = Vector2(
                sensorPositions[Sensor.BOTTOM_RIGHT].x + Var.widthrad * 0.3f,
                sensorPositions[Sensor.BOTTOM_RIGHT].y + fallPadding * 0.7f
            );
            
            // Draw extended floor sensors
            Color fallSensorColor = Color(0, 200, 200, 200);
            DrawCircleV(bottomLeftExt, 2.0f, fallSensorColor);
            DrawCircleV(bottomRightExt, 2.0f, fallSensorColor);
            DrawCircleV(bottomCenter, 2.0f, fallSensorColor);
            
            // Draw wide sensors
            Color wideSensorColor = Color(200, 100, 200, 200);
            DrawCircleV(bottomLeftWide, 2.0f, wideSensorColor);
            DrawCircleV(bottomRightWide, 2.0f, wideSensorColor);
            
            // Draw sweep rectangle for high speeds
            if (Var.yspeed > 7.0f) {
                Rectangle sweepRect = Rectangle(
                    Var.x - Var.widthrad * 0.9f,                          
                    sensorPositions[Sensor.BOTTOM_LEFT].y - fallPadding,  
                    Var.widthrad * 1.8f,                                  
                    fallPadding * 2
                );
                
                DrawRectangleLinesEx(sweepRect, 1.0f, Color(255, 0, 255, 150));
            }
            
            // Draw extreme fall rectangle
            if (Var.yspeed > 12.0f) {
                Rectangle extremeFallRect = Rectangle(
                    Var.x - Var.widthrad * 1.5f,
                    sensorPositions[Sensor.BOTTOM_LEFT].y,
                    Var.widthrad * 3.0f,
                    fallPadding * 1.5f
                );
                
                DrawRectangleLinesEx(extremeFallRect, 1.0f, Color(255, 50, 50, 150));
            }
            
            // Ground proximity check visualization
            float groundProximityThreshold = 0.5f;
            
            // For each platform, draw the ground proximity threshold
            foreach (platform; testPlatforms) {
                // Calculate if we're within the proximity threshold
                float distanceToGround = platform.y - (Var.y + Var.heightrad);
                if (distanceToGround >= -0.1f && distanceToGround <= groundProximityThreshold) {
                    if (Var.x + Var.widthrad * 0.7f >= platform.x && 
                        Var.x - Var.widthrad * 0.7f <= platform.x + platform.width) {
                        
                        // Draw the proximity threshold zone
                        Rectangle proximityRect = Rectangle(
                            platform.x,
                            platform.y - groundProximityThreshold,
                            platform.width,
                            groundProximityThreshold
                        );
                        DrawRectangleRec(proximityRect, Color(0, 255, 0, 30));
                        DrawRectangleLinesEx(proximityRect, 1.0f, Color(0, 255, 0, 100));
                    }
                }
            }
            
            // Edge prevention visualization
            if (Var.yspeed > 9.0f) {
                DrawCircleV(
                    Vector2(Var.x, Var.y + Var.heightrad + fallPadding * 0.5f),
                    Var.widthrad * 1.1f,
                    Color(255, 165, 0, 50)
                );
            }
        }
        */
        
        // Draw a direction indicator for movement
        if (abs(Var.xspeed) > 0.1f || abs(Var.yspeed) > 0.1f) {
            Vector2 start = Vector2(Var.x, Var.y);
            Vector2 end = Vector2(
                Var.x + Var.xspeed * 3.0f,
                Var.y + Var.yspeed * 3.0f
            );
            DrawLineV(start, end, Colors.SKYBLUE);
        }
        
        // Draw fall speed indicator - keep this as it's useful even without detailed debug
        if (Var.yspeed > 0) {
            DrawText(
                TextFormat("Fall: %.1f", Var.yspeed),
                cast(int)(Var.x - 20),
                cast(int)(Var.y - Var.heightrad - 15),
                14,
                Var.yspeed > 7.0f ? Colors.RED : Colors.WHITE
            );
        }
        
        /* Comment out stability indicator
        // Draw ground stability indicator
        DrawText(
            TextFormat("Stability: %d", groundStabilityCounter),
            cast(int)(Var.x - 35),
            cast(int)(Var.y - Var.heightrad - 35),
            14,
            Var.grounded ? Colors.GREEN : Colors.RED
        );
        */
    }
}