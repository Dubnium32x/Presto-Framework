// Input handling

#include "input.h"
#include "error_handler.h"
#include <string.h>
#include <stdio.h>
#include <math.h>

// Global array to hold gamepad states for each player
static GamepadState gamepads[MAX_PLAYERS];

// Unified input state
static UnifiedInputState unifiedInput = {0};

void InitializeInput() {
    memset(gamepads, 0, sizeof(gamepads));
    for (int i = 0; i < MAX_PLAYERS; i++) {
        gamepads[i].gamepadId = -1; // No gamepad assigned
    }
}

void UpdateInput(float deltaTime) {
    for (int i = 0; i < MAX_PLAYERS; i++) {
        GamepadState* gp = &gamepads[i];
        if (gp->gamepadId == -1 || !IsGamepadAvailable(gp->gamepadId)) {
            continue; // Skip if no gamepad assigned or not available
        }

        // Update last button states
        memcpy(gp->lastButtons, gp->buttons, sizeof(gp->buttons));

        // Update button states and hold times
        for (int b = 0; b < MAX_BUTTONS; b++) {
            gp->buttons[b] = IsGamepadButtonDown(gp->gamepadId, b);
            if (gp->buttons[b]) {
                gp->holdTimes[b] += deltaTime;
            } else {
                gp->holdTimes[b] = 0.0f;
            }
        }

        // Update left stick position
        gp->leftStick.x = GetGamepadAxisMovement(gp->gamepadId, ANALOG_LEFT_X);
        gp->leftStick.y = GetGamepadAxisMovement(gp->gamepadId, ANALOG_LEFT_Y);
    }
}

bool IsDown(int player, int button) {
    if (player < 0 || player >= MAX_PLAYERS) return false;
    return gamepads[player].buttons[button];
}

bool IsPressed(int player, int button) {
    if (player < 0 || player >= MAX_PLAYERS) return false;
    return gamepads[player].buttons[button] && !gamepads[player].lastButtons[button];
}

bool IsReleased(int player, int button) {
    if (player < 0 || player >= MAX_PLAYERS) return false;
    return !gamepads[player].buttons[button] && gamepads[player].lastButtons[button];
}

float GetAnalogX(int player) {
    if (player < 0 || player >= MAX_PLAYERS) return 0.0f;
    return gamepads[player].leftStick.x;
}

float GetAnalogY(int player) {
    if (player < 0 || player >= MAX_PLAYERS) return 0.0f;
    return gamepads[player].leftStick.y;
}

float HoldTime(int player, int button) {
    if (player < 0 || player >= MAX_PLAYERS) return 0.0f;
    return gamepads[player].holdTimes[button];
}

void SetGamepadId(int player, int id) {
    if (player < 0 || player >= MAX_PLAYERS) return;
    gamepads[player].gamepadId = id;
}

void GetAnalogStickMagnitudeAndAngle(int player, float* magnitude, float* angle) {
    if (player < 0 || player >= MAX_PLAYERS || magnitude == NULL || angle == NULL) return;

    Vector2 stick = gamepads[player].leftStick;
    *magnitude = sqrtf(stick.x * stick.x + stick.y * stick.y);
    *angle = atan2f(stick.y, stick.x) * (180.0f / PI); // Convert to degrees
    if (*angle < 0) *angle += 360.0f; // Normalize angle to [0, 360)
}

// Unified input system implementation
void InitUnifiedInput(void) {
    memset(&unifiedInput, 0, sizeof(unifiedInput));
    unifiedInput.gamepadId = 0;
    unifiedInput.useGamepad = IsGamepadAvailable(0);
    printf("Unified Input initialized - Gamepad available: %s\n", unifiedInput.useGamepad ? "true" : "false");
}

void UpdateUnifiedInput(float deltaTime) {
    unifiedInput.prevState = unifiedInput.curState;
    unifiedInput.curState = 0;
    
    // Keyboard input
    if (IsKeyDown(KEY_UP) || IsKeyDown(KEY_W)) unifiedInput.curState |= INPUT_MASK(INPUT_UP);
    if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S)) unifiedInput.curState |= INPUT_MASK(INPUT_DOWN);
    if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A)) unifiedInput.curState |= INPUT_MASK(INPUT_LEFT);
    if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D)) unifiedInput.curState |= INPUT_MASK(INPUT_RIGHT);
    
    // Face buttons
    if (IsKeyDown(KEY_Z) || IsKeyDown(KEY_SPACE)) unifiedInput.curState |= INPUT_MASK(INPUT_A);
    if (IsKeyDown(KEY_X) || IsKeyDown(KEY_ESCAPE)) unifiedInput.curState |= INPUT_MASK(INPUT_B);
    if (IsKeyDown(KEY_C)) unifiedInput.curState |= INPUT_MASK(INPUT_X);
    if (IsKeyDown(KEY_V)) unifiedInput.curState |= INPUT_MASK(INPUT_Y);
    
    // Shoulder buttons
    if (IsKeyDown(KEY_RIGHT_SHIFT)) unifiedInput.curState |= INPUT_MASK(INPUT_RB);
    if (IsKeyDown(KEY_LEFT_SHIFT)) unifiedInput.curState |= INPUT_MASK(INPUT_LB);
    
    // Triggers
    if (IsKeyDown(KEY_Q)) unifiedInput.curState |= INPUT_MASK(INPUT_LT);
    if (IsKeyDown(KEY_E)) unifiedInput.curState |= INPUT_MASK(INPUT_RT);
    
    // Start
    if (IsKeyDown(KEY_ENTER)) unifiedInput.curState |= INPUT_MASK(INPUT_START);
    
    // Gamepad input (if available)
    if (IsGamepadAvailable(unifiedInput.gamepadId)) {
        // D-pad
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_FACE_UP)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_UP);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_FACE_DOWN)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_DOWN);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_FACE_LEFT)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_LEFT);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_RIGHT);
        
        // Left stick with deadzone
        float lx = GetGamepadAxisMovement(unifiedInput.gamepadId, GAMEPAD_AXIS_LEFT_X);
        float ly = GetGamepadAxisMovement(unifiedInput.gamepadId, GAMEPAD_AXIS_LEFT_Y);
        const float deadzone = 0.4f;
        if (lx < -deadzone) unifiedInput.curState |= INPUT_MASK(INPUT_LEFT);
        if (lx > deadzone) unifiedInput.curState |= INPUT_MASK(INPUT_RIGHT);
        if (ly < -deadzone) unifiedInput.curState |= INPUT_MASK(INPUT_UP);
        if (ly > deadzone) unifiedInput.curState |= INPUT_MASK(INPUT_DOWN);
        
        // Face buttons
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_RIGHT_FACE_DOWN)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_A);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_RIGHT_FACE_RIGHT)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_B);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_RIGHT_FACE_LEFT)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_X);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_RIGHT_FACE_UP)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_Y);
        
        // Shoulder buttons
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_RIGHT_TRIGGER_1)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_RB);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_TRIGGER_1)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_LB);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_RIGHT_TRIGGER_2)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_RT);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_TRIGGER_2)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_LT);
        
        // Start
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_MIDDLE_RIGHT)) 
            unifiedInput.curState |= INPUT_MASK(INPUT_START);
    }
    
    // Calculate edge detection
    unifiedInput.pressedMask = unifiedInput.curState & ~unifiedInput.prevState;
    unifiedInput.releasedMask = unifiedInput.prevState & ~unifiedInput.curState;
    
    // Update hold timers
    for (int i = 0; i < 16; i++) {
        InputMask mask = 1 << i;
        if (unifiedInput.curState & mask) {
            unifiedInput.holdTimers[i] += deltaTime;
        } else {
            unifiedInput.holdTimers[i] = 0.0f;
        }
    }
}

bool IsInputDown(InputBit bit) {
    return (unifiedInput.curState & INPUT_MASK(bit)) != 0;
}

bool IsInputPressed(InputBit bit) {
    return (unifiedInput.pressedMask & INPUT_MASK(bit)) != 0;
}

bool IsInputReleased(InputBit bit) {
    return (unifiedInput.releasedMask & INPUT_MASK(bit)) != 0;
}

float GetInputHoldTime(InputBit bit) {
    return unifiedInput.holdTimers[bit];
}

void SetInputGamepadId(int id) {
    unifiedInput.gamepadId = id;
    unifiedInput.useGamepad = IsGamepadAvailable(id);
}

