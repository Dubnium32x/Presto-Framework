module player.player;

import raylib;

import std.stdio;
import std.string;
import std.file;
import std.algorithm;
import std.conv;
import std.array;
import std.math;

// Make sure we import level for CSV loading
import world.level; // Provides LevelManager and Level struct
import world.level_list; // Ensure LevelList and ActNumber are available if needed here
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
    bool prevKeyDown;     // Track previous down key state for press detection
    bool keyActionPressed; // For jump, etc. (Z key)
    bool keyActionHeld;    // For held jump, etc. (Z key)
    bool keyAction2Pressed; // (X key)
    
    // Reference to the LevelManager
    private LevelManager levelManagerInstance;

    // Ground stability counter to prevent oscillations
    int groundStabilityCounter = 0;
    
    // Rolling state variables
    bool isRolling = false;
    float rollTimer = 0.0f;     // For timing-based effects
    bool canExitRoll = false;   // Flag to control when we can exit a roll

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
        
        // Initialize hitbox dimensions if not already set
        if (GamePhysics.normalWidthrad <= 0) {
            GamePhysics.normalWidthrad = Var.widthrad;
        }
        if (GamePhysics.normalHeightrad <= 0) {
            GamePhysics.normalHeightrad = Var.heightrad;
        }

        // Set initial state
        state = PlayerState.IDLE;
        isRolling = false;
        prevKeyDown = false;

        // Initialize sensor positions array to avoid issues, though they'll be set each frame.
        foreach (ref pos; sensorPositions) {
            pos = Vector2(0,0);
        }
    }

    // Method to set the LevelManager instance
    void setLevelManager(LevelManager lm) {
        this.levelManagerInstance = lm;
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
        // get references to test platforms and CSV level platforms from app.d
        import app : testPlatforms, csvPlatforms, useCsvLevel;

        // Select which platform array to use based on mode
        Rectangle[] platformsToUse = useCsvLevel ? csvPlatforms : testPlatforms;

        bool wwasGrounded = Var.grounded; // Store previous grounded state
        
        // For movement prediction, store velocity
        float xvel = Var.xspeed;
        
        // Only for debug visualization
        bool leftCollided = false;
        bool rightCollided = false;
        
        // Create horizontal padding for side sensors based on xspeed
        // This helps catch collisions when moving fast
        float horizPadding = min(abs(Var.xspeed) * 0.5f, Var.widthrad * 0.5f);
        
        // If rolling, increase the horizontal padding slightly to represent the rolling shape
        if (isRolling && abs(Var.xspeed) > 3.0f) {
            horizPadding *= 1.2f; // 20% more padding when rolling fast
        }
        
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
        foreach (platform; platformsToUse) {
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
                
                // Check if any of the sensors are inside the platform
                if (CheckCollisionPointRec(leftSensor, platform) || 
                    CheckCollisionPointRec(topLeftSensor, platform) || 
                    CheckCollisionPointRec(bottomLeftSensor, platform)) {
                    
                    // Collision detected, stop horizontal movement and push player out
                    Var.xspeed = 0;
                    Var.x = platform.x + platform.width + Var.widthrad + 0.1f; // Small buffer
                    
                    // Flag for debug visualization
                    leftCollided = true;
                    
                    break; // Exit the loop once collision is resolved
                }
            }
            
            // Check for left wall collision (right side sensor)
            if (Var.xspeed > 0 || (abs(Var.xspeed) < 0.1f && Var.x + Var.widthrad >= platform.x && 
                Var.x < platform.x + platform.width * 0.5f)) {
                
                // Right sensor with padding
                Vector2 rightSensor = Vector2(
                    sensorPositions[Sensor.MIDDLE_RIGHT].x + horizPadding, 
                    sensorPositions[Sensor.MIDDLE_RIGHT].y
                );
                
                // Additional corner checks for high-speed movement
                Vector2 topRightSensor = Vector2(
                    sensorPositions[Sensor.MIDDLE_RIGHT].x + horizPadding, 
                    sensorPositions[Sensor.TOP_RIGHT].y + Var.heightrad * 0.3f
                );
                
                Vector2 bottomRightSensor = Vector2(
                    sensorPositions[Sensor.MIDDLE_RIGHT].x + horizPadding, 
                    sensorPositions[Sensor.BOTTOM_RIGHT].y - Var.heightrad * 0.3f
                );
                
                // Check if any of the sensors are inside the platform
                if (CheckCollisionPointRec(rightSensor, platform) || 
                    CheckCollisionPointRec(topRightSensor, platform) || 
                    CheckCollisionPointRec(bottomRightSensor, platform)) {
                    
                    // Collision detected, stop horizontal movement and push player out
                    Var.xspeed = 0;
                    Var.x = platform.x - Var.widthrad - 0.1f; // Small buffer
                    
                    // Flag for debug visualization
                    rightCollided = true;
                    
                    break; // Exit the loop once collision is resolved
                }
            }
        }
        
        // Now check the bottom sensors for ground collision with improved high-speed fall detection
        foreach (platform; platformsToUse) {
            // Calculate vertical tolerance based on falling speed
            float fallSnapTolerance = Var.yspeed > 1.0f ? 
                                    Var.HIGH_SPEED_SNAP_TOLERANCE : Var.GROUND_SNAP_TOLERANCE;
            
            // Check if we're above the platform and within a threshold for snapping to the ground
            if (Var.y + Var.heightrad <= platform.y + fallSnapTolerance && 
                Var.y < platform.y + platform.height/2 && // Make sure we're closer to top than bottom
                Var.x + Var.widthrad * 0.7f >= platform.x && 
                Var.x - Var.widthrad * 0.7f <= platform.x + platform.width) {
                
                // Check bottom sensors
                if (CheckCollisionPointRec(sensorPositions[Sensor.BOTTOM_LEFT], platform) || 
                    CheckCollisionPointRec(sensorPositions[Sensor.BOTTOM_RIGHT], platform) ||
                    // For high-speed falls, also check a bit ahead of the sensors
                    (Var.yspeed > 1.0f && 
                     (CheckCollisionPointRec(Vector2(sensorPositions[Sensor.BOTTOM_LEFT].x, 
                                                      sensorPositions[Sensor.BOTTOM_LEFT].y + Var.yspeed * 0.5f), platform) || 
                      CheckCollisionPointRec(Vector2(sensorPositions[Sensor.BOTTOM_RIGHT].x, 
                                                      sensorPositions[Sensor.BOTTOM_RIGHT].y + Var.yspeed * 0.5f), platform)))) {
                    
                    // Ground collision detected
                    Var.y = platform.y - Var.heightrad; // Snap to ground
                    Var.yspeed = 0;
                    Var.grounded = true;
                    groundedThisFrame = true;
                    
                    // Only transition out of rolling if allowed
                    if (state == PlayerState.FALLING_ROLL) {
                        canExitRoll = true; // Allow exiting roll now that we've landed
                        state = PlayerState.ROLLING;
                    }
                    
                    break; // Exit the loop once collision is resolved
                }
            }
            
            // Check ceiling collision (only when moving upward)
            if (Var.yspeed < 0) {
                if (Var.y - Var.heightrad <= platform.y + platform.height && 
                    Var.y >= platform.y + platform.height/2 && // Make sure we're closer to bottom than top
                    Var.x + Var.widthrad * 0.7f >= platform.x && 
                    Var.x - Var.widthrad * 0.7f <= platform.x + platform.width) {
                
                    // Check top sensors
                    if (CheckCollisionPointRec(sensorPositions[Sensor.TOP_LEFT], platform) || 
                        CheckCollisionPointRec(sensorPositions[Sensor.TOP_RIGHT], platform)) {
                        // Ceiling collision detected
                        Var.y = platform.y + platform.height + Var.heightrad; // Push player down
                        Var.yspeed = 0; // Stop upward movement
                    }
                }
            }
        }

        // Update stability counter if we found ground
        if (groundedThisFrame) {
            // Set grounded to true and reset the frames not grounded counter
            Var.grounded = true;
            Var.framesNotGrounded = 0;
            
            // Add stability counter to prevent oscillating between grounded/not grounded
            // when moving quickly over uneven terrain
            groundStabilityCounter = Var.GROUND_DEBOUNCE_FRAMES;
        }

        // Finally check for ceiling collisions - only when moving upward
        if (!useCsvLevel && Var.yspeed < 0) {
            foreach (platform; testPlatforms) {
                if (Var.y - Var.heightrad <= platform.y + platform.height && 
                    Var.y >= platform.y + platform.height/2 && // Make sure we're closer to bottom than top
                    Var.x + Var.widthrad * 0.7f >= platform.x && 
                    Var.x - Var.widthrad * 0.7f <= platform.x + platform.width) {
                
                    // Check top sensors
                    if (CheckCollisionPointRec(sensorPositions[Sensor.TOP_LEFT], platform) || 
                        CheckCollisionPointRec(sensorPositions[Sensor.TOP_RIGHT], platform)) {
                        // Ceiling collision detected
                        Var.y = platform.y + platform.height + Var.heightrad; // Push player down
                        Var.yspeed = 0; // Stop upward movement
                    }
                }
            }
        }
        
        // Update player state based on grounded status and rolling state
        if (Var.grounded) {
            // Additional state transitions can be added here
        } else {
            // If not on ground and not already in a jumping or falling state, transition to falling
            if (state != PlayerState.JUMPING && state != PlayerState.FALLING && 
                state != PlayerState.FALLING_ROLL) {
                // If we're rolling when we leave the ground, transition to falling roll
                if (state == PlayerState.ROLLING) {
                    state = PlayerState.FALLING_ROLL;
                } else {
                    state = PlayerState.FALLING;
                }
            }
        }
        
        // If the player was previously grounded but is no longer grounded, increment framesNotGrounded
        if (wwasGrounded && !Var.grounded) {
            Var.framesNotGrounded++;
        } else if (Var.grounded) {
            // Reset counter when grounded
            Var.framesNotGrounded = 0;
        }
    }

    // Helper method to check collision with CSV level tiles
    private void checkCollisionWithCSVLevel(ref bool groundedThisFrame) {
        if (this.levelManagerInstance is null) return; // Use the class member

        Level currentLevelInfo = this.levelManagerInstance.getCurrentLevelInfo();
        int[][][] layersData = this.levelManagerInstance.layerTileData;

        if (layersData is null || layersData.length == 0) {
            // writeln("Player: No CSV level data to check for collision.");
            return;
        }

        // writeln("Player: Checking collision with CSV level. Layers: ", layersData.length);

        // For now, iterate all layers. Later, you might want to specify which layers are collidable.
        foreach (layerIdx, int[][] singleLayerData; layersData) {
            if (singleLayerData is null || singleLayerData.length == 0) continue;
            
            // Optional: Get layer name if needed for specific collision rules
            // string layerName = (layerIdx < currentLevelInfo.layerNames.length) ? currentLevelInfo.layerNames[layerIdx] : "UnknownLayer";

            // Example: Only collide with "Ground_1" for now, similar to app.d
            // This requires knowing the exact name or a property to check.
            // For a generic fix, we'll check all tiles in all layers passed.
            // if (layerName != "Ground_1") continue; // Example filter

            for (int ty = 0; ty < singleLayerData.length; ty++) {
                if (singleLayerData[ty] is null || singleLayerData[ty].length == 0) continue;
                for (int tx = 0; tx < singleLayerData[ty].length; tx++) {
                    int rawTileId = singleLayerData[ty][tx];

                    // Constants for Tiled flags (from Tiled documentation)
                    const uint FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
                    const uint FLIPPED_VERTICALLY_FLAG   = 0x40000000;
                    // const uint FLIPPED_DIAGONALLY_FLAG = 0x20000000; // Not used here yet

                    // Clear the flags to get the actual tile ID (GID)
                    int actualTileId = cast(int)(rawTileId & ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG /* | FLIPPED_DIAGONALLY_FLAG */));

                    if (actualTileId != -1) { // Use actualTileId for collision check
                        Rectangle tileRect = { 
                            cast(float)tx * currentLevelInfo.tileWidthPx, 
                            cast(float)ty * currentLevelInfo.tileHeightPx, 
                            cast(float)currentLevelInfo.tileWidthPx, 
                            cast(float)currentLevelInfo.tileHeightPx 
                        };

                        // Basic AABB collision with player's bounding box
                        Rectangle playerRect = { 
                            Var.x - Var.widthrad, 
                            Var.y - Var.heightrad, 
                            Var.widthrad * 2, 
                            Var.heightrad * 2 
                        };

                        if (CheckCollisionRecs(playerRect, tileRect)) {
                            // writeln("Player: Collision with tileID ", tileID, " at [", tx, ",", ty, "] in layer ", layerIdx);
                            // More sophisticated collision response needed here.
                            // For now, just setting grounded if collision is below.
                            // This is a very simplistic placeholder.
                            if (playerRect.y + playerRect.height > tileRect.y && 
                                playerRect.y < tileRect.y + tileRect.height && // Player is vertically aligned
                                Var.yspeed >= 0) { // And moving downwards or stationary

                                // Check if the collision is primarily from the bottom of the player
                                float overlapY = (playerRect.y + playerRect.height) - tileRect.y;
                                float overlapX = min(playerRect.x + playerRect.width, tileRect.x + tileRect.width) - max(playerRect.x, tileRect.x);

                                if (overlapY > 0 && overlapY < Var.heightrad + 5 && overlapX > 0) { // Heuristic: overlap is small and from bottom
                                     // Snap player to top of tile
                                    Var.y = tileRect.y - Var.heightrad;
                                    Var.yspeed = 0;
                                    groundedThisFrame = true;
                                    Var.grounded = true; 
                                    this.groundStabilityCounter = Var.GROUND_DEBOUNCE_FRAMES; // Use class member
                                }
                            }
                            // Handle side collisions, etc.
                        }
                    }
                }
            }
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
            
            // Set state based on whether we're rolling or not
            if (isRolling) {
                // Jump while rolling maintains roll in the air
                state = PlayerState.FALLING_ROLL;
            } else {
                state = PlayerState.JUMPING;
            }
            
            // Add debug output
            writeln("Jump initiated! yspeed = ", Var.yspeed);
        }
        
        // Check for roll state transitions
        if (Var.grounded) {
            // Detect when down key is pressed (not just held)
            bool downPressed = keyDown && !prevKeyDown;
            prevKeyDown = keyDown;
            
            // Press down to enter rolling or to exit if already rolling
            float minRollSpeed = GamePhysics.minSpeedToStartRoll > 0 ? GamePhysics.minSpeedToStartRoll : 2.0f;
            
            if (downPressed) {
                if (!isRolling && abs(Var.xspeed) >= minRollSpeed) {
                    // Enter roll when we have enough speed
                    enterRolling();
                    
                    // Check environment after entering roll to ensure proper collision detection
                    updateSensorPositions();
                    checkEnvironmentCollision();
                } 
                else if (isRolling && canExitRoll) {
                    // Save previous state for re-checking
                    bool wasRolling = isRolling;
                    
                    // Exit roll when already rolling and down is pressed again
                    exitRolling();
                    
                    // If we were rolling but now aren't, recheck collisions to ensure proper positioning
                    if (wasRolling && !isRolling) {
                        // Update sensor positions after exiting roll
                        updateSensorPositions();
                        checkEnvironmentCollision();
                    }
                }
            }
        }
        
        // Handle physics based on rolling state
        if (isRolling) {
            // Use rolling-specific physics
            updateRollingPhysics(deltaTime);
        }
        else {
            // Standard movement physics when not rolling
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
        }
        
        // Apply movement
        Var.x += Var.xspeed;
        Var.y += Var.yspeed;
        
        // Update sensor positions after movement but before collision
        updateSensorPositions();
        
        // Check for and resolve collisions
        checkEnvironmentCollision();
        
        // Update sensor positions again after collision resolution
        updateSensorPositions();
        
        // Handle landing from an airborne roll
        if (Var.grounded && state == PlayerState.FALLING_ROLL) {
            // Landing from a rolling jump - maintain roll state
            isRolling = true;
            state = PlayerState.ROLLING;
            
            // Set hitbox size to rolling dimensions (with safety check)
            if (GamePhysics.rollingWidthrad > 0 && GamePhysics.rollingHeightrad > 0) {
                // Store current height before changing
                float currentHeight = Var.heightrad;
                
                // Change hitbox size
                Var.widthrad = GamePhysics.rollingWidthrad;
                Var.heightrad = GamePhysics.rollingHeightrad;
                
                // Update sensors after changing hitbox
                updateSensorPositions();
                
                // Recheck collisions to properly position at rolling height
                checkEnvironmentCollision();
            } else {
                // Fallback if physics constants aren't set correctly
                Var.widthrad = 9.0f; // Keep width the same
                Var.heightrad = 14.0f;
            }
        }
        
        // Store ground speed for reference (useful for loops and slopes later)
        Var.groundspeed = Var.xspeed;
    }

    void draw() {
        // Sensor debug visualization
        import app : testPlatforms;
        
        // Draw a simple representation of the player (hitbox)
        Color hitboxColor = isRolling ? Colors.ORANGE : Colors.GREEN;
        
        // Draw based on current state
        if (isRolling) {
            // Draw a shorter but still rectangular hitbox when rolling
            DrawRectangleLines(
                cast(int)(Var.x - Var.widthrad), 
                cast(int)(Var.y - Var.heightrad), 
                cast(int)(Var.widthrad * 2), 
                cast(int)(Var.heightrad * 2), 
                hitboxColor
            );
            
            // Add a small indicator for rolling state
            DrawRectangle(
                cast(int)(Var.x - 3),
                cast(int)(Var.y - 3),
                6, 6,
                Colors.ORANGE
            );
        } else {
            // Draw rectangular hitbox when not rolling
            DrawRectangleLines(
                cast(int)(Var.x - Var.widthrad), 
                cast(int)(Var.y - Var.heightrad), 
                cast(int)(Var.widthrad * 2), 
                cast(int)(Var.heightrad * 2), 
                hitboxColor
            );
        }
        
        // Draw a direction indicator for movement
        if (abs(Var.xspeed) > 0.1f || abs(Var.yspeed) > 0.1f) {
            Vector2 start = Vector2(Var.x, Var.y);
            Vector2 end = Vector2(
                Var.x + Var.xspeed * 3.0f,
                Var.y + Var.yspeed * 3.0f
            );
            DrawLineV(start, end, Colors.SKYBLUE);
        }
        
        // Get debug visualization flag from app.d
        // We need to use this import with a public variable in app.d
        import app;  // Import the entire module instead of a specific symbol
        
        // Draw sensor points for collision detection only if debug visualization is enabled
        if (debugVisualizationEnabled) {
            // Bottom sensors (floor)
            DrawCircleV(sensorPositions[Sensor.BOTTOM_LEFT], 3.0f, Colors.GREEN);
            DrawCircleV(sensorPositions[Sensor.BOTTOM_RIGHT], 3.0f, Colors.GREEN);
            
            // Middle sensors (walls)
            DrawCircleV(sensorPositions[Sensor.MIDDLE_LEFT], 3.0f, Colors.RED);
            DrawCircleV(sensorPositions[Sensor.MIDDLE_RIGHT], 3.0f, Colors.RED);
            
            // Top sensors (ceiling)
            DrawCircleV(sensorPositions[Sensor.TOP_LEFT], 3.0f, Colors.BLUE);
            DrawCircleV(sensorPositions[Sensor.TOP_RIGHT], 3.0f, Colors.BLUE);
            
            // Optional: Add sensor labels if not moving too fast
            if (abs(Var.xspeed) < 5.0f) {
                DrawText("Floor", 
                    cast(int)sensorPositions[Sensor.BOTTOM_LEFT].x - 15, 
                    cast(int)sensorPositions[Sensor.BOTTOM_LEFT].y + 5, 
                    10, Colors.GREEN);
                    
                DrawText("Wall", 
                    cast(int)sensorPositions[Sensor.MIDDLE_LEFT].x - 25, 
                    cast(int)sensorPositions[Sensor.MIDDLE_LEFT].y, 
                    10, Colors.RED);
                    
                DrawText("Wall", 
                    cast(int)sensorPositions[Sensor.MIDDLE_RIGHT].x + 5, 
                    cast(int)sensorPositions[Sensor.MIDDLE_RIGHT].y, 
                    10, Colors.RED);
                    
                DrawText("Ceiling", 
                    cast(int)sensorPositions[Sensor.TOP_LEFT].x - 15, 
                    cast(int)sensorPositions[Sensor.TOP_LEFT].y - 15, 
                    10, Colors.BLUE);
            }
        } // Close the debugVisualizationEnabled condition
        
        // Draw state text (safer implementation)
        const(char)* stateText;
        if (isRolling) {
            stateText = "ROLLING";
        } else {
            // Convert enum to int for safer formatting
            stateText = TextFormat("State: %d", cast(int)state);
        }
        
        DrawText(
            stateText,
            cast(int)(Var.x - 25),
            cast(int)(Var.y - Var.heightrad - 30),
            14,
            isRolling ? Colors.ORANGE : Colors.WHITE
        );
        
        // Draw speed indicator
        DrawText(
            TextFormat("Speed: %.1f", abs(Var.xspeed)),
            cast(int)(Var.x - 25),
            cast(int)(Var.y + Var.heightrad + 5),
            14,
            abs(Var.xspeed) > 4.0f ? Colors.YELLOW : Colors.WHITE
        );
        
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
    }

    // Helper method to enter rolling state
    void enterRolling() {
        if (!isRolling && Var.grounded) {
            // Store current position for reference
            float prevX = Var.x;
            float prevY = Var.y;
            float prevHeightrad = Var.heightrad;
            
            // Get ground platform information before changing hitbox
            import app : testPlatforms;
            Rectangle* groundPlatform = null;
            float groundY = float.max;
            
            // Find the platform Sonic is standing on
            foreach (ref platform; testPlatforms) {
                if (Var.grounded && 
                    prevX + Var.widthrad * 0.7f >= platform.x && 
                    prevX - Var.widthrad * 0.7f <= platform.x + platform.width &&
                    prevY + prevHeightrad >= platform.y - 1.0f && 
                    prevY + prevHeightrad <= platform.y + 1.0f) {
                
                    groundPlatform = &platform;
                    groundY = platform.y;
                    break; // Found the ground platform
                }
            }
            
            // Mark that we're now rolling
            isRolling = true;
            state = PlayerState.ROLLING;
            
            // Change hitbox size (with safety checks)
            if (GamePhysics.rollingWidthrad > 0 && GamePhysics.rollingHeightrad > 0) {
                Var.widthrad = GamePhysics.rollingWidthrad;
                Var.heightrad = GamePhysics.rollingHeightrad;
            } else {
                // Fallback if physics constants aren't set correctly
                Var.widthrad = 9.0f; // Keep width the same to prevent clipping
                Var.heightrad = 14.0f;
            }
            
            // Precisely position player relative to ground
            if (groundPlatform !is null) {
                // Position Sonic exactly on the ground platform with the new hitbox
                Var.y = groundY - Var.heightrad - 0.1f; // Small buffer to ensure contact
            } else {
                // If we couldn't find a specific ground platform, use the old adjustment method
                float heightDifference = prevHeightrad - Var.heightrad;
                if (heightDifference > 0) {
                    Var.y -= heightDifference * 0.5f;
                }
            }
            
            // Update sensor positions with new hitbox dimensions
            updateSensorPositions();
            
            // Immediately check for collisions to ensure proper ground contact
            checkEnvironmentCollision();
            
            // Debug output
            writeln("Entering roll state. Speed: ", abs(Var.xspeed), 
                   " Position: ", Var.x, ",", Var.y);
            
            // Always allow exit of roll for new implementation
            canExitRoll = true;
            rollTimer = 0.0f;
        }
        else if (isRolling && Var.grounded && canExitRoll) {
            // If already rolling and we press down again, exit the roll
            exitRolling();
        }
    }
    
    // Helper method to exit rolling state
    void exitRolling() {
        if (isRolling && canExitRoll) {
            // Store current position and sensor data before changing hitbox
            float currentX = Var.x;
            float currentY = Var.y;
            
            // Get current sensor distances from platforms to preserve positioning
            import app : testPlatforms;
            float minLeftDist = float.max;
            float minRightDist = float.max;
            float groundDist = float.max;
            
            // Save reference to nearest platforms for post-adjustment
            Rectangle* nearestLeftWall = null;
            Rectangle* nearestRightWall = null;
            Rectangle* groundPlatform = null;
            
            // Measure distances to nearby platforms to preserve relative positioning
            foreach (ref platform; testPlatforms) {
                // Check horizontal distance to left wall
                if (currentX > platform.x + platform.width) {
                    float dist = currentX - Var.widthrad - (platform.x + platform.width);
                    if (dist < minLeftDist) {
                        minLeftDist = dist;
                        nearestLeftWall = &platform;
                    }
                }
                
                // Check horizontal distance to right wall
                if (currentX < platform.x) {
                    float dist = platform.x - (currentX + Var.widthrad);
                    if (dist < minRightDist) {
                        minRightDist = dist;
                        nearestRightWall = &platform;
                    }
                }
                
                // Check vertical distance to ground
                if (Var.grounded && platform.y >= currentY + Var.heightrad - 1 && 
                    currentX + Var.widthrad * 0.7f >= platform.x && 
                    currentX - Var.widthrad * 0.7f <= platform.x + platform.width) {
                    float dist = platform.y - (currentY + Var.heightrad);
                    if (dist < groundDist) {
                        groundDist = dist;
                        groundPlatform = &platform;
                    }
                }
            }
            
            // Mark that we're no longer rolling
            isRolling = false;
            
            // Restore original hitbox size (with safety checks)
            if (GamePhysics.normalWidthrad > 0 && GamePhysics.normalHeightrad > 0) {
                Var.widthrad = GamePhysics.normalWidthrad;
                Var.heightrad = GamePhysics.normalHeightrad;
            } else {
                // Fallback if physics constants aren't set correctly
                Var.widthrad = 9.0f;
                Var.heightrad = 19.0f;
            }
            
            // Adjust player position for taller hitbox
            // Move player up to compensate for the height difference while maintaining ground contact
            float heightDifference = GamePhysics.normalHeightrad - GamePhysics.rollingHeightrad;
            if (heightDifference > 0 && Var.grounded) {
                // Move up by half the height difference to center the player at the same point
                Var.y -= heightDifference * 0.5f;
            }
            
            // Preserve relative distances to platforms after hitbox change
            if (nearestLeftWall !is null && minLeftDist < float.max && minLeftDist >= 0) {
                // Adjust position if too close to left wall with new hitbox
                float newLeftDist = Var.x - Var.widthrad - (nearestLeftWall.x + nearestLeftWall.width);
                if (newLeftDist < minLeftDist) {
                    Var.x += (minLeftDist - newLeftDist);
                }
            }
            
            if (nearestRightWall !is null && minRightDist < float.max && minRightDist >= 0) {
                // Adjust position if too close to right wall with new hitbox
                float newRightDist = nearestRightWall.x - (Var.x + Var.widthrad);
                if (newRightDist < minRightDist) {
                    Var.x -= (minRightDist - newRightDist);
                }
            }
            
            // Ensure we're still properly snapped to the ground
            if (groundPlatform !is null && groundDist < float.max && groundDist >= -0.1f && groundDist <= 0.5f) {
                Var.y = groundPlatform.y - Var.heightrad - 0.1f; // Small buffer to ensure we stay grounded
            }
            
            // Set state based on speed
            if (abs(Var.xspeed) < 0.1f) {
                state = PlayerState.IDLE;
            } else {
                state = PlayerState.RUNNING;
            }
            
            // Update sensors after position adjustment
            updateSensorPositions();
            
            // Immediately check for collisions to ensure proper ground contact
            checkEnvironmentCollision();
            
            // Debug output
            writeln("Exiting roll state. Speed: ", abs(Var.xspeed), 
                   " Position: ", Var.x, ",", Var.y);
        }
    }
    
    // Helper to update rolling physics
    void updateRollingPhysics(float deltaTime) {
        // Increment roll timer (used to control when player can exit roll)
        rollTimer += deltaTime;
        
        // Allow exiting roll after a certain time threshold
        if (rollTimer >= 0.25f && !canExitRoll) {
            canExitRoll = true;
        }
        
        // Get rolling friction with safety check
        float rollFriction = GamePhysics.rollingFriction > 0 ? GamePhysics.rollingFriction : GamePhysics.friction * 0.5f;
        float rollDecel = GamePhysics.rollingDeceleration > 0 ? GamePhysics.rollingDeceleration : GamePhysics.deceleration * 0.5f;
        
        // Apply rolling-specific friction
        if (Var.xspeed > 0) {
            Var.xspeed -= rollFriction;
            if (Var.xspeed < 0) Var.xspeed = 0;
        } 
        else if (Var.xspeed < 0) {
            Var.xspeed += rollFriction;
            if (Var.xspeed > 0) Var.xspeed = 0;
        }
        
        // Stop rolling if speed is very low
        if (abs(Var.xspeed) < 0.1f && canExitRoll) {
            exitRolling();
        }
        
        // Allow directional control while rolling, but with reduced effect
        float rollControlFactor = 0.2f; // 20% of normal control
        
        if (keyLeft && !keyRight) {
            if (Var.xspeed > 0) {
                // Turning around while rolling
                Var.xspeed -= rollDecel;
            } else {
                // Accelerating while rolling in same direction
                Var.xspeed -= GamePhysics.acceleration * rollControlFactor;
            }
        }
        else if (keyRight && !keyLeft) {
            if (Var.xspeed < 0) {
                // Turning around while rolling
                Var.xspeed += rollDecel;
            } else {
                // Accelerating while rolling in same direction
                Var.xspeed += GamePhysics.acceleration * rollControlFactor;
            }
        }
        
        // Cap maximum speed
        if (Var.xspeed > GamePhysics.maxspeed) {
            Var.xspeed = GamePhysics.maxspeed;
        }
        else if (Var.xspeed < -GamePhysics.maxspeed) {
            Var.xspeed = -GamePhysics.maxspeed;
        }
    }
}