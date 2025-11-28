// Input header
#ifndef INPUT_H
#define INPUT_H

#include "raylib.h"
#include <stdbool.h>
#include <stdint.h>

#define MAX_PLAYERS 4
#define MAX_BUTTONS 32

// Unified input system using bitfields
typedef uint16_t InputMask;

// Input bit positions (similar to D version)
typedef enum
{
    INPUT_UP = 0,
    INPUT_DOWN = 1,
    INPUT_LEFT = 2,
    INPUT_RIGHT = 3,
    INPUT_A = 4,
    INPUT_B = 5,
    INPUT_X = 6,
    INPUT_Y = 7,
    INPUT_RB = 8,
    INPUT_LB = 9,
    INPUT_RT = 10,
    INPUT_LT = 11,
    INPUT_START = 12,
    INPUT_MODIFIER1 = 13, // Currently for level editor stuff
    INPUT_MODIFIER2 = 14, // ditto
} InputBit;

// Helper macro to get mask for a bit
#define INPUT_MASK(bit) (1 << (bit))

// Unified input state
typedef struct
{
    InputMask prevState;
    InputMask curState;
    InputMask pressedMask;
    InputMask releasedMask;
    float holdTimers[16];
    int gamepadId;
    bool useGamepad;
} UnifiedInputState;

// Global unified input functions
void InitUnifiedInput(void);
void UpdateUnifiedInput(float deltaTime);
bool IsInputDown(InputBit bit);
bool IsInputPressed(InputBit bit);
bool IsInputReleased(InputBit bit);
bool IsModifierDown(int modifier);
bool IsModifierPressed(int modifier);
bool IsModifierReleased(int modifier);
float GetInputHoldTime(InputBit bit);
void SetInputGamepadId(int id);

// GAMEPAD INPUTS
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

// KEYBOARD INPUTS
#define KEY_UP KEY_UP
#define KEY_DOWN KEY_DOWN
#define KEY_LEFT KEY_LEFT
#define KEY_RIGHT KEY_RIGHT
#define KEY_JUMP1 KEY_Z
#define KEY_JUMP2 KEY_X
#define KEY_JUMP3 KEY_C
#define KEY_ACTION1 KEY_A
#define KEY_ACTION2 KEY_S
#define KEY_ACTION3 KEY_D
#define KEY_START KEY_ENTER
#define KEY_BACK KEY_BACKSPACE
#define KEY_MENU KEY_ESCAPE

typedef struct
{
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
void GetAnalogStickMagnitudeAndAngle(int player, float *magnitude, float *angle);

#endif // INPUT_H