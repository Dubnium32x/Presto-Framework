// Input handler header
#ifndef MANAGERS_INPUT_H
#define MANAGERS_INPUT_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "raylib.h"

#define MAX_PLAYERS 4
#define MAX_BUTTONS 64

// Unified input system using bitfields
typedef uint64_t InputMask;

// Input bit positions
typedef enum {
    INPUT_UP = 0,
    INPUT_DOWN = 1,
    INPUT_LEFT = 2,
    INPUT_RIGHT = 3,
    INPUT_A = 4,
    INPUT_B = 5,
    INPUT_X = 6,
    INPUT_Y = 7,
    INPUT_LB = 8,
    INPUT_RB = 9,
    INPUT_LT = 10,
    INPUT_RT = 11,
    INPUT_START = 12,
    INPUT_SELECT = 13
} InputBit;


// Helper macro to get mask for a bit
#define INPUT_MASK(bit) (1 << (bit))

// Unified input state
typedef struct {
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
float GetInputHoldTime(InputBit bit);
void SetInputGamepadId(int id);

#endif // MANAGERS_INPUT_H