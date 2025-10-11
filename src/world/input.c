// Input handling

#include "input.h"
#include "error_handler.h"
#include <string.h>
#include <stdio.h>
#include <math.h>

// Global array to hold gamepad states for each player
static GamepadState gamepads[MAX_PLAYERS];

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
        float lx = GetGamepadAxisMovement(gp->gamepadId, ANALOG_LEFT_X);
        float ly = GetGamepadAxisMovement(gp->gamepadId, ANALOG_LEFT_Y);
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

