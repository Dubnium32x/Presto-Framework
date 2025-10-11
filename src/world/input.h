// Input header
#ifndef INPUT_H
#define INPUT_H

#include "raylib.h"
#include <stdbool.h>
#include <stdint.h>

#define MAX_PLAYERS 4
#define MAX_BUTTONS 32

#define BUTTON_A GAMEPAD_BUTTON_RIGHT_FACE_DOWN
#define BUTTON_B GAMEPAD_BUTTON_RIGHT_FACE_RIGHT
#define BUTTON_X GAMEPAD_BUTTON_RIGHT_FACE_LEFT
#define BUTTON_Y GAMEPAD_BUTTON_RIGHT_FACE_UP
#define BUTTON_LB GAMEPAD_BUTTON_LEFT_TRIGGER_1
#define BUTTON_RB GAMEPAD_BUTTON_RIGHT_TRIGGER_1
#define BUTTON_BACK GAMEPAD_BUTTON_MIDDLE_LEFT
#define BUTTON_START GAMEPAD_BUTTON_MIDDLE_RIGHT
#define DPAD_UP GAMEPAD_BUTTON_LEFT_FACE_UP
#define DPAD_DOWN GAMEPAD_BUTTON_LEFT_FACE_DOWN
#define DPAD_LEFT GAMEPAD_BUTTON_LEFT_FACE_LEFT
#define DPAD_RIGHT GAMEPAD_BUTTON_LEFT_FACE_RIGHT
#define ANALOG_LEFT_X GAMEPAD_AXIS_LEFT_X
#define ANALOG_LEFT_Y GAMEPAD_AXIS_LEFT_Y
#define ANALOG_RIGHT_X GAMEPAD_AXIS_RIGHT_X
#define ANALOG_RIGHT_Y GAMEPAD_AXIS_RIGHT_Y

typedef struct {
    Vector2 leftStick;
    bool buttons[MAX_BUTTONS];
    bool lastButtons[MAX_BUTTONS];
    float holdTimes[MAX_BUTTONS];
    int gamepadId;
} GamepadState;

void InitializeInput();
void UpdateInput(float deltaTime);
bool IsDown(int player, int button);
bool IsPressed(int player, int button);
bool IsReleased(int player, int button);
float GetAnalogX(int player);
float GetAnalogY(int player);
float HoldTime(int player, int button);
void SetGamepadId(int player, int id);
void GetAnalogStickMagnitudeAndAngle(int player, float* magnitude, float* angle);

#endif // INPUT_H