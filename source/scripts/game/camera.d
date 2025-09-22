module game.camera;

import raylib;

import std.stdio;
import std.math;
import std.conv : to;
import std.algorithm : clamp;
import std.array;
import std.random;

import data;
import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT;

// Camera struct to manage view following the player according to SPG specifications
struct GameCamera {
    CameraType cameraType;
    
    // Camera position and target
    Vector2 position;
    Vector2 target;
    float zoom;
    float rotation;
    
    // SPG camera system variables
    Vector2 borders; // For Genesis: left=144, right=160 (x,y used as left,right)
    float verticalFocalPoint; // Default 96, shifts for look up/down
    float horizontalFocalPoint; // For CD: default 160, shifts with extended camera
    
    // Camera movement speed caps (SPG values)
    float horizontalSpeedCap; // 16 for S1/S2/CD, 24 for S3&K
    float verticalSpeedCap; // Varies based on conditions
    float defaultVerticalSpeedCap;
    
    // Look up/down system
    bool lookingUp;
    bool lookingDown;
    int lookTimer; // Frames held
    float verticalShift; // Current shift amount
    
    // Extended camera (CD only)
    float extendedCameraShift; // Current shift amount for CD extended camera
    bool extendedCameraActive;
    
    // Screen shake
    float screenShakeIntensity;
    float screenShakeDuration;
    float screenShakeTimer;
    
    // Screen dimensions (SPG standard)
    static immutable int SCREEN_WIDTH = 320;
    static immutable int SCREEN_HEIGHT = 224;
    
    // Constructor
    this(CameraType type) {
        cameraType = type;
        position = Vector2(0, 0);
        target = Vector2(0, 0);
        zoom = 1.0f;
        rotation = 0.0f;
        
        // Initialize based on camera type
        switch (type) {
            case CameraType.GENESIS:
                // Genesis borders scaled for virtual screen (144/320*400 = 180, 160/320*400 = 200)
                float scale = cast(float)VIRTUAL_SCREEN_WIDTH / SCREEN_WIDTH;
                borders = Vector2(144 * scale, 160 * scale); // Results in 180, 200
                verticalFocalPoint = 96.0f * (cast(float)VIRTUAL_SCREEN_HEIGHT / SCREEN_HEIGHT);
                horizontalSpeedCap = 16.0f;
                defaultVerticalSpeedCap = 16.0f;
                verticalSpeedCap = defaultVerticalSpeedCap;
                break;
                
            case CameraType.CD:
                // CD uses focal points instead of borders, scaled for virtual screen
                float scale = cast(float)VIRTUAL_SCREEN_WIDTH / SCREEN_WIDTH;
                horizontalFocalPoint = 160.0f * scale; // Results in 200
                verticalFocalPoint = 96.0f * (cast(float)VIRTUAL_SCREEN_HEIGHT / SCREEN_HEIGHT);
                horizontalSpeedCap = 16.0f;
                defaultVerticalSpeedCap = 16.0f;
                verticalSpeedCap = defaultVerticalSpeedCap;
                extendedCameraShift = 0.0f;
                extendedCameraActive = false;
                break;
                
            case CameraType.POCKET:
                // Pocket Adventure style - simpler, smoother
                borders = Vector2(120, 200); // Wider borders for smoother feel
                verticalFocalPoint = 112.0f; // Slightly lower focal point
                horizontalSpeedCap = 8.0f; // Smoother movement
                defaultVerticalSpeedCap = 8.0f;
                verticalSpeedCap = defaultVerticalSpeedCap;
                break;
            default: 
                // Fallback to Genesis settings
                borders = Vector2(144, 160);
                verticalFocalPoint = 96.0f;
                horizontalSpeedCap = 16.0f;
                defaultVerticalSpeedCap = 16.0f;
                verticalSpeedCap = defaultVerticalSpeedCap;
                break;
        }
        
        lookingUp = false;
        lookingDown = false;
        lookTimer = 0;
        verticalShift = 0.0f;
        
        screenShakeIntensity = 0.0f;
        screenShakeDuration = 0.0f;
        screenShakeTimer = 0.0f;
    }
    
    // Update camera position based on player position and input
    void update(Vector2 playerPos, float playerGroundSpeed, bool playerGrounded, 
                bool inputUp, bool inputDown, float deltaTime, bool lockCamera = false) {
        
        // Handle look up/down input
        updateLookUpDown(inputUp, inputDown, playerGrounded);
        
        switch (cameraType) {
            case CameraType.GENESIS:
                processGenesisCamera(playerPos, playerGroundSpeed, playerGrounded, deltaTime, lockCamera);
                break;
            case CameraType.CD:
                processCDCamera(playerPos, playerGroundSpeed, playerGrounded, deltaTime, lockCamera);
                break;
            case CameraType.POCKET:
                processPocketCamera(playerPos, playerGroundSpeed, playerGrounded, deltaTime, lockCamera);
                break;
            default:
                processGenesisCamera(playerPos, playerGroundSpeed, playerGrounded, deltaTime, lockCamera);
                break;
        }
        
        // Apply screen shake if active
        if (screenShakeTimer > 0) {
            auto rng = Random(unpredictableSeed);
            float shake = screenShakeIntensity * (screenShakeTimer / screenShakeDuration);
            position.x += uniform(-5, 6, rng) * shake * 0.1f;
            position.y += uniform(-5, 6, rng) * shake * 0.1f;
            screenShakeTimer -= deltaTime;
            if (screenShakeTimer <= 0) {
                screenShakeTimer = 0;
                screenShakeIntensity = 0;
            }
        }
    }
    
    // Handle look up/down input timing (SPG compliant)
    void updateLookUpDown(bool inputUp, bool inputDown, bool playerGrounded) {
        if (!playerGrounded) {
            // Reset look state when airborne
            lookingUp = false;
            lookingDown = false;
            lookTimer = 0;
            // Gradually return to default focal point
            if (verticalShift != 0) {
                float returnSpeed = 2.0f;
                if (verticalShift > 0) {
                    verticalShift = fmax(0, verticalShift - returnSpeed);
                } else {
                    verticalShift = fmin(0, verticalShift + returnSpeed);
                }
            }
            return;
        }
        
        if (inputUp && !lookingDown) {
            if (!lookingUp) {
                lookingUp = true;
                lookTimer = 0;
                
                // Different timing systems per game
                if (cameraType == CameraType.CD) {
                    // CD: Start looking immediately, but can be interrupted
                    // TODO: Implement CD's double-tap and interrupt system
                } else {
                    // Genesis/Pocket: Wait 120 frames before starting (S2+ behavior)
                }
            } else {
                lookTimer++;
                
                // Start scrolling after delay (except CD)
                if (cameraType != CameraType.CD && lookTimer >= 120) {
                    // Look up: shift focal point down by 104 pixels max, 2 per frame
                    verticalShift = fmin(verticalShift + 2.0f, 104.0f);
                } else if (cameraType == CameraType.CD && lookTimer > 0) {
                    // CD starts immediately
                    verticalShift = fmin(verticalShift + 2.0f, 104.0f);
                }
            }
        } else if (inputDown && !lookingUp) {
            if (!lookingDown) {
                lookingDown = true;
                lookTimer = 0;
                
                if (cameraType == CameraType.CD) {
                    // CD: Start looking immediately
                } else {
                    // Genesis/Pocket: Wait 120 frames
                }
            } else {
                lookTimer++;
                
                // Start scrolling after delay (except CD)
                if (cameraType != CameraType.CD && lookTimer >= 120) {
                    // Look down: shift focal point down by 88 pixels max, 2 per frame (negative for down)
                    verticalShift = fmax(verticalShift - 2.0f, -88.0f);
                } else if (cameraType == CameraType.CD && lookTimer > 0) {
                    // CD starts immediately
                    verticalShift = fmax(verticalShift - 2.0f, -88.0f);
                }
            }
        } else {
            // Not pressing up or down - return to normal
            lookingUp = false;
            lookingDown = false;
            lookTimer = 0;
            
            // Return focal point to default at 2 pixels per frame
            if (verticalShift > 0) {
                verticalShift = fmax(0, verticalShift - 2.0f);
            } else if (verticalShift < 0) {
                verticalShift = fmin(0, verticalShift + 2.0f);
            }
        }
        
        // Update vertical speed cap based on focal point shift
        if (abs(verticalShift) > 0.1f) {
            verticalSpeedCap = 2.0f; // Slow camera when looking up/down
        } else {
            verticalSpeedCap = defaultVerticalSpeedCap;
        }
    }
    
    // Genesis-style camera processing (SPG borders system)
    void processGenesisCamera(Vector2 playerPos, float playerGroundSpeed, bool playerGrounded, float deltaTime, bool lockCamera) {
        float currentVerticalFocalPoint = verticalFocalPoint - verticalShift;
        
        // SPG Genesis Camera Logic:
        // The borders are screen-space positions (144 left, 160 right)
        // Camera position represents the top-left of the view
        // Player screen position = playerPos - camera position
        
        if (!lockCamera) {
            // Calculate where the player appears on screen
            float playerScreenX = playerPos.x - position.x;
            float playerScreenY = playerPos.y - position.y;
            // Horizontal movement - check if player is outside borders
            if (playerScreenX < borders.x) { // Left border (144)
                // Player is past left border, move camera left
                float diff = borders.x - playerScreenX;
                position.x -= fmin(diff, horizontalSpeedCap);
            } else if (playerScreenX > borders.y) { // Right border (160) 
                // Player is past right border, move camera right
                float diff = playerScreenX - borders.y;
                position.x += fmin(diff, horizontalSpeedCap);
            }
            // Vertical movement
            if (playerGrounded) {
                // On ground: try to keep player at vertical focal point
                float targetScreenY = currentVerticalFocalPoint;
                float diff = playerScreenY - targetScreenY;
                float speedCap = verticalSpeedCap;
                // SPG: Speed-dependent vertical camera movement
                if (abs(verticalShift) < 0.1f && abs(playerGroundSpeed) >= 8.0f) {
                    speedCap = 24.0f; // Fast movement when running fast
                } else if (abs(verticalShift) < 0.1f && abs(playerGroundSpeed) < 8.0f) {
                    speedCap = 6.0f; // Slow movement when walking
                }
                if (abs(diff) > 0.5f) {
                    position.y += diff > 0 ? fmin(diff, speedCap) : fmax(diff, -speedCap);
                }
            } else {
                // In air: use borders around focal point
                float topBorder = currentVerticalFocalPoint - 32;
                float bottomBorder = currentVerticalFocalPoint + 32;
                if (playerScreenY < topBorder) {
                    float diff = topBorder - playerScreenY;
                    position.y -= fmin(diff, verticalSpeedCap);
                } else if (playerScreenY > bottomBorder) {
                    float diff = playerScreenY - bottomBorder;
                    position.y += fmin(diff, verticalSpeedCap);
                }
            }
        }
    // Always apply verticalShift for look up/down, even if locked
    float camCenterX = position.x + VIRTUAL_SCREEN_WIDTH / 2.0f;
    float camCenterY = position.y + VIRTUAL_SCREEN_HEIGHT / 2.0f - verticalShift;
    target = Vector2(camCenterX, camCenterY);
    }
    
    // CD-style camera processing (SPG focal point system with extended camera)
    void processCDCamera(Vector2 playerPos, float playerGroundSpeed, bool playerGrounded, float deltaTime, bool lockCamera) {
        float currentVerticalFocalPoint = verticalFocalPoint - verticalShift;
        
        // Extended camera logic: shift horizontal focal point when speed >= 6
        bool shouldExtend = abs(playerGroundSpeed) >= 6.0f;
        if (shouldExtend && !extendedCameraActive) {
            extendedCameraActive = true;
        } else if (!shouldExtend && extendedCameraActive) {
            extendedCameraActive = false;
        }
        
        // Update extended camera shift
        if (extendedCameraActive) {
            // Shift 64 pixels back in opposite direction of movement
            float targetShift = playerGroundSpeed > 0 ? -64.0f : 64.0f;
            float diff = targetShift - extendedCameraShift;
            extendedCameraShift += diff > 0 ? fmin(diff, 2.0f) : fmax(diff, -2.0f);
        } else {
            // Return to center
            if (abs(extendedCameraShift) > 0.1f) {
                extendedCameraShift += extendedCameraShift > 0 ? -2.0f : 2.0f;
            } else {
                extendedCameraShift = 0.0f;
            }
        }
        
        float currentHorizontalFocalPoint = horizontalFocalPoint + extendedCameraShift;
        
        if (!lockCamera) {
            // Horizontal movement: keep player at focal point
            float hDiff = playerPos.x - (position.x + currentHorizontalFocalPoint);
            if (abs(hDiff) > 0.5f) {
                position.x += hDiff > 0 ? fmin(hDiff, horizontalSpeedCap) : fmax(hDiff, -horizontalSpeedCap);
            }
            // Vertical movement (same logic as Genesis)
            if (playerGrounded) {
                float diff = playerPos.y - (position.y + currentVerticalFocalPoint);
                float speedCap = verticalSpeedCap;
                if (abs(verticalShift) < 0.1f && abs(playerGroundSpeed) >= 8.0f) {
                    speedCap = 24.0f;
                } else if (abs(verticalShift) < 0.1f && abs(playerGroundSpeed) < 8.0f) {
                    speedCap = 6.0f;
                }
                if (abs(diff) > 0.5f) {
                    position.y += diff > 0 ? fmin(diff, speedCap) : fmax(diff, -speedCap);
                }
            } else {
                float topBorder = currentVerticalFocalPoint - 32;
                float bottomBorder = currentVerticalFocalPoint + 32;
                if (playerPos.y < position.y + topBorder) {
                    float diff = (position.y + topBorder) - playerPos.y;
                    position.y -= fmin(diff, verticalSpeedCap);
                } else if (playerPos.y > position.y + bottomBorder) {
                    float diff = playerPos.y - (position.y + bottomBorder);
                    position.y += fmin(diff, verticalSpeedCap);
                }
            }
        }
    // Always apply verticalShift for look up/down, even if locked
    float camCenterX = position.x + VIRTUAL_SCREEN_WIDTH / 2.0f;
    float camCenterY = position.y + VIRTUAL_SCREEN_HEIGHT / 2.0f - verticalShift;
    target = Vector2(camCenterX, camCenterY);
    }
    
    // Pocket Adventure style camera - smoother and more forgiving
    void processPocketCamera(Vector2 playerPos, float playerGroundSpeed, bool playerGrounded, float deltaTime, bool lockCamera) {
        // DEBUG: For now, just follow the player directly to test
        if (!lockCamera) {
            target = playerPos;
            position = playerPos;
        }
    // Always apply verticalShift for look up/down, even if locked
    float camCenterX = position.x + VIRTUAL_SCREEN_WIDTH / 2.0f;
    float camCenterY = position.y + VIRTUAL_SCREEN_HEIGHT / 2.0f - verticalShift;
    target = Vector2(camCenterX, camCenterY);
    }
    
    // Convert to raylib Camera2D for rendering
    Camera2D toCamera2D() {
        Camera2D cam;
        cam.target = target;
        cam.offset = Vector2(VIRTUAL_SCREEN_WIDTH / 2.0f, VIRTUAL_SCREEN_HEIGHT / 2.0f);
        cam.rotation = rotation;
        cam.zoom = zoom;
        return cam;
    }
    
    // Screen shake effect
    void addScreenShake(float intensity, float duration) {
        screenShakeIntensity = intensity;
        screenShakeDuration = duration;
        screenShakeTimer = duration;
    }

    // Apply screen shake if active
    private void applyScreenShake() {
        if (screenShakeTimer > 0) {
            auto rng = Random(unpredictableSeed);
            float shake = screenShakeIntensity * (screenShakeTimer / screenShakeDuration);
            position.x += uniform(-5, 6, rng) * shake * 0.1f;
            position.y += uniform(-5, 6, rng) * shake * 0.1f;
        }
    }
}
