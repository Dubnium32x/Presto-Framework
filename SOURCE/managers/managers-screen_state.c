// Screen State Implementation
#include "managers-screen_state.h"
#include <stdio.h>
#include <string.h>

void InitScreenState(ScreenStateManager *state) {
    if (state == NULL) return;

    state->currentScreen = SCREEN_STATE_INIT;
    state->previousScreen = SCREEN_STATE_INIT;
    state->currentMenu = OPTIONS;
    state->gameplayState = GAMEPLAY_PLAYING;
    state->transition.type = TRANSITION_NONE;
    state->transition.duration = 0.0f;
    state->transition.elapsed = 0.0f;
    state->transition.active = false;
    state->initialized = true;
    state->frameCounter = 0;
    state->isPaused = false;
}

void UpdateScreenState(ScreenStateManager *state, float deltaTime) {
    if (state == NULL) return;

    state->frameCounter++;
}

void DrawScreenState(ScreenStateManager *state) {
    if (state == NULL) return;
}

void UnloadScreenState(ScreenStateManager *state) {
    if (state == NULL) return;

    state->initialized = false;
}

void SetScreen(ScreenStateManager *state, ScreenState newScreen) {
    if (state == NULL) return;

    state->previousScreen = state->currentScreen;
    state->currentScreen = newScreen;
}