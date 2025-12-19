// Input handler
#include "managers-input.h"
#include <string.h>

// Unified input state
static UnifiedInputState unifiedInput = {0};

void InitUnifiedInput(void) {
    memset(&unifiedInput, 0, sizeof(unifiedInput));
    unifiedInput.gamepadId = 0;
    unifiedInput.useGamepad = false;

    unifiedInput.useGamepad = IsGamepadAvailable(0);
    printf("Unified Input initialized - Gamepad available: %s\n", unifiedInput.useGamepad ? "true" : "false");
}

void UpdateUnifiedInput(float deltaTime) {
    unifiedInput.prevState = unifiedInput.curState;
    unifiedInput.curState = 0;

    // ---- Keyboard input ----
    // Directional inputs
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

    // Trigger buttons
    if (IsKeyDown(KEY_Q)) unifiedInput.curState |= INPUT_MASK(INPUT_LT);
    if (IsKeyDown(KEY_E)) unifiedInput.curState |= INPUT_MASK(INPUT_RT);    

    // Start and Select
    if (IsKeyDown(KEY_ENTER)) unifiedInput.curState |= INPUT_MASK(INPUT_START);
    if (IsKeyDown(KEY_BACKSPACE)) unifiedInput.curState |= INPUT_MASK(INPUT_SELECT);

    // ---- Gamepad input ----
    if (unifiedInput.useGamepad) {
        // Directional inputs
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_FACE_UP) ||
            GetGamepadAxisMovement(unifiedInput.gamepadId, GAMEPAD_AXIS_LEFT_Y) < -0.5f)
            unifiedInput.curState |= INPUT_MASK(INPUT_UP);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_FACE_DOWN) ||
            GetGamepadAxisMovement(unifiedInput.gamepadId, GAMEPAD_AXIS_LEFT_Y) > 0.5f)
            unifiedInput.curState |= INPUT_MASK(INPUT_DOWN);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_FACE_LEFT) ||
            GetGamepadAxisMovement(unifiedInput.gamepadId, GAMEPAD_AXIS_LEFT_X) < -0.5f)
            unifiedInput.curState |= INPUT_MASK(INPUT_LEFT);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_FACE_RIGHT) ||
            GetGamepadAxisMovement(unifiedInput.gamepadId, GAMEPAD_AXIS_LEFT_X) > 0.5f)
            unifiedInput.curState |= INPUT_MASK(INPUT_RIGHT);
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
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_TRIGGER_1))
            unifiedInput.curState |= INPUT_MASK(INPUT_LB);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_RIGHT_TRIGGER_1))
            unifiedInput.curState |= INPUT_MASK(INPUT_RB);
        // Trigger buttons
        if (GetGamepadAxisMovement(unifiedInput.gamepadId, GAMEPAD_BUTTON_LEFT_TRIGGER_2) > 0.5f)
            unifiedInput.curState |= INPUT_MASK(INPUT_LT);
        if (GetGamepadAxisMovement(unifiedInput.gamepadId, GAMEPAD_BUTTON_RIGHT_TRIGGER_2) > 0.5f)
            unifiedInput.curState |= INPUT_MASK(INPUT_RT);
        // Start and Select
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_MIDDLE_RIGHT))
            unifiedInput.curState |= INPUT_MASK(INPUT_START);
        if (IsGamepadButtonDown(unifiedInput.gamepadId, GAMEPAD_BUTTON_MIDDLE_LEFT))
            unifiedInput.curState |= INPUT_MASK(INPUT_SELECT);
    }

    // Update pressed and released masks
    unifiedInput.pressedMask = (unifiedInput.curState) & ~(unifiedInput.prevState);
    unifiedInput.releasedMask = ~(unifiedInput.curState) & (unifiedInput.prevState);
    // Update hold timers
    for (int i = 0; i < 16; i++) {
        if (unifiedInput.curState & INPUT_MASK(i)) {
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
}