module world.input_manager;

import raylib;
import std.stdio;
import std.algorithm;
import std.math;

/**
 * Input Manager for Presto Framework
 * 
 * Handles input mapping, buffering, and game-specific input logic.
 * This is particularly important for Sonic games which require precise timing and input buffering.
 */
class InputManager {
    // Singleton instance
    private __gshared InputManager _instance;
    
    // Input states for common game actions
    private bool jumpPressed = false;
    private bool jumpHeld = false;
    private bool jumpReleased = false;
    
    private bool leftPressed = false;
    private bool leftHeld = false;
    private bool rightPressed = false;
    private bool rightHeld = false;
    
    private bool upPressed = false;
    private bool upHeld = false;
    private bool downPressed = false;
    private bool downHeld = false;
    
    private bool actionPressed = false;
    private bool actionHeld = false;
    
    private bool pausePressed = false;
    
    // Input buffering for precise timing (important for Sonic physics)
    private float jumpBufferTime = 0.0f;
    private float jumpBufferWindow = 0.1f; // 100ms buffer window
    
    private float groundBufferTime = 0.0f;
    private float groundBufferWindow = 0.1f; // Coyote time
    
    // Key mappings (can be customized later)
    private KeyboardKey jumpKey1 = KeyboardKey.KEY_SPACE;
    private KeyboardKey jumpKey2 = KeyboardKey.KEY_Z;
    private KeyboardKey actionKey1 = KeyboardKey.KEY_X;
    private KeyboardKey actionKey2 = KeyboardKey.KEY_C;
    private KeyboardKey pauseKey = KeyboardKey.KEY_ESCAPE;
    
    // Gamepad support
    private bool useGamepad = false;
    private int gamepadId = 0;
    
    this() {
        writeln("InputManager initialized for Presto Framework");
    }
    
    // Get singleton instance
    static InputManager getInstance() {
        if (_instance is null) {
            synchronized {
                if (_instance is null) {
                    _instance = new InputManager();
                }
            }
        }
        return _instance;
    }
    
    /**
     * Initialize input manager
     */
    void initialize() {
        // Check for gamepad
        updateGamepadStatus();
        writeln("InputManager initialized - Gamepad available: ", useGamepad);
    }
    
    /**
     * Update input states - call this every frame
     */
    void update(float deltaTime) {
        // Update gamepad status
        updateGamepadStatus();
        
        // Update input buffers
        updateBuffers(deltaTime);
        
        // Read and process inputs
        updateInputStates();
    }
    
    /**
     * Update gamepad availability
     */
    private void updateGamepadStatus() {
        useGamepad = IsGamepadAvailable(gamepadId);
    }
    
    /**
     * Update input buffers for precise timing
     */
    private void updateBuffers(float deltaTime) {
        // Update jump buffer
        if (jumpBufferTime > 0.0f) {
            jumpBufferTime -= deltaTime;
            if (jumpBufferTime < 0.0f) {
                jumpBufferTime = 0.0f;
            }
        }
        
        // Update ground buffer (coyote time)
        if (groundBufferTime > 0.0f) {
            groundBufferTime -= deltaTime;
            if (groundBufferTime < 0.0f) {
                groundBufferTime = 0.0f;
            }
        }
    }
    
    /**
     * Update all input states
     */
    private void updateInputStates() {
        // Jump input
        bool jumpInput = isKeyPressed(jumpKey1) || isKeyPressed(jumpKey2);
        if (useGamepad) {
            jumpInput = jumpInput || IsGamepadButtonPressed(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN);
        }
        
        jumpPressed = jumpInput;
        if (jumpPressed) {
            jumpBufferTime = jumpBufferWindow;
        }
        
        jumpHeld = isKeyDown(jumpKey1) || isKeyDown(jumpKey2);
        if (useGamepad) {
            jumpHeld = jumpHeld || IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN);
        }
        
        jumpReleased = isKeyReleased(jumpKey1) || isKeyReleased(jumpKey2);
        if (useGamepad) {
            jumpReleased = jumpReleased || IsGamepadButtonReleased(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN);
        }
        
        // Action input
        actionPressed = isKeyPressed(actionKey1) || isKeyPressed(actionKey2);
        if (useGamepad) {
            actionPressed = actionPressed || IsGamepadButtonPressed(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT);
        }
        
        actionHeld = isKeyDown(actionKey1) || isKeyDown(actionKey2);
        if (useGamepad) {
            actionHeld = actionHeld || IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT);
        }
        
        // Directional input
        leftPressed = IsKeyPressed(KeyboardKey.KEY_LEFT) || IsKeyPressed(KeyboardKey.KEY_A);
        leftHeld = IsKeyDown(KeyboardKey.KEY_LEFT) || IsKeyDown(KeyboardKey.KEY_A);
        
        rightPressed = IsKeyPressed(KeyboardKey.KEY_RIGHT) || IsKeyPressed(KeyboardKey.KEY_D);
        rightHeld = IsKeyDown(KeyboardKey.KEY_RIGHT) || IsKeyDown(KeyboardKey.KEY_D);
        
        upPressed = IsKeyPressed(KeyboardKey.KEY_UP) || IsKeyPressed(KeyboardKey.KEY_W);
        upHeld = IsKeyDown(KeyboardKey.KEY_UP) || IsKeyDown(KeyboardKey.KEY_W);
        
        downPressed = IsKeyPressed(KeyboardKey.KEY_DOWN) || IsKeyPressed(KeyboardKey.KEY_S);
        downHeld = IsKeyDown(KeyboardKey.KEY_DOWN) || IsKeyDown(KeyboardKey.KEY_S);
        
        // Add gamepad directional input
        if (useGamepad) {
            float leftStickX = GetGamepadAxisMovement(gamepadId, GamepadAxis.GAMEPAD_AXIS_LEFT_X);
            float leftStickY = GetGamepadAxisMovement(gamepadId, GamepadAxis.GAMEPAD_AXIS_LEFT_Y);
            
            if (leftStickX < -0.3f) leftHeld = true;
            if (leftStickX > 0.3f) rightHeld = true;
            if (leftStickY < -0.3f) upHeld = true;
            if (leftStickY > 0.3f) downHeld = true;
            
            // D-pad
            if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_LEFT)) leftHeld = true;
            if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) rightHeld = true;
            if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_UP)) upHeld = true;
            if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_DOWN)) downHeld = true;
            
            if (IsGamepadButtonPressed(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_LEFT)) leftPressed = true;
            if (IsGamepadButtonPressed(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) rightPressed = true;
            if (IsGamepadButtonPressed(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_UP)) upPressed = true;
            if (IsGamepadButtonPressed(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_DOWN)) downPressed = true;
        }
        
        // Pause input
        pausePressed = IsKeyPressed(pauseKey);
        if (useGamepad) {
            pausePressed = pausePressed || IsGamepadButtonPressed(gamepadId, GamepadButton.GAMEPAD_BUTTON_MIDDLE_RIGHT);
        }
    }
    
    // Helper methods for key states
    private bool isKeyPressed(KeyboardKey key) {
        return IsKeyPressed(key);
    }
    
    private bool isKeyDown(KeyboardKey key) {
        return IsKeyDown(key);
    }
    
    private bool isKeyReleased(KeyboardKey key) {
        return IsKeyReleased(key);
    }
    
    // Public getters for input states
    bool isJumpPressed() { return jumpPressed; }
    bool isJumpHeld() { return jumpHeld; }
    bool isJumpReleased() { return jumpReleased; }
    bool isJumpBuffered() { return jumpBufferTime > 0.0f; }
    
    bool isActionPressed() { return actionPressed; }
    bool isActionHeld() { return actionHeld; }
    
    bool isLeftPressed() { return leftPressed; }
    bool isLeftHeld() { return leftHeld; }
    bool isRightPressed() { return rightPressed; }
    bool isRightHeld() { return rightHeld; }
    
    bool isUpPressed() { return upPressed; }
    bool isUpHeld() { return upHeld; }
    bool isDownPressed() { return downPressed; }
    bool isDownHeld() { return downHeld; }
    
    bool isPausePressed() { return pausePressed; }
    
    // Get horizontal input as a float (-1.0 to 1.0)
    float getHorizontalInput() {
        float input = 0.0f;
        if (leftHeld) input -= 1.0f;
        if (rightHeld) input += 1.0f;
        
        // Add gamepad analog input
        if (useGamepad) {
            float stickX = GetGamepadAxisMovement(gamepadId, GamepadAxis.GAMEPAD_AXIS_LEFT_X);
            if (abs(stickX) > abs(input)) {
                input = stickX;
            }
        }
        
        return input;
    }
    
    // Get vertical input as a float (-1.0 to 1.0)
    float getVerticalInput() {
        float input = 0.0f;
        if (upHeld) input -= 1.0f;
        if (downHeld) input += 1.0f;
        
        // Add gamepad analog input
        if (useGamepad) {
            float stickY = GetGamepadAxisMovement(gamepadId, GamepadAxis.GAMEPAD_AXIS_LEFT_Y);
            if (abs(stickY) > abs(input)) {
                input = stickY;
            }
        }
        
        return input;
    }
    
    // Ground buffer management (for coyote time)
    void setGroundBuffer() {
        groundBufferTime = groundBufferWindow;
    }
    
    bool isGroundBuffered() {
        return groundBufferTime > 0.0f;
    }
    
    void clearJumpBuffer() {
        jumpBufferTime = 0.0f;
    }
    
    void clearGroundBuffer() {
        groundBufferTime = 0.0f;
    }
    
    // Configuration methods
    void setJumpKeys(KeyboardKey key1, KeyboardKey key2) {
        jumpKey1 = key1;
        jumpKey2 = key2;
    }
    
    void setActionKeys(KeyboardKey key1, KeyboardKey key2) {
        actionKey1 = key1;
        actionKey2 = key2;
    }
    
    void setPauseKey(KeyboardKey key) {
        pauseKey = key;
    }
    
    bool isGamepadConnected() {
        return useGamepad;
    }
}
