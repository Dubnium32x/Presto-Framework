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

    if (state->transition.active) {
        UpdateTransition(&state->transition, deltaTime);
    }
}

void DrawScreenState(ScreenStateManager *state) {
    if (state == NULL) return;

    if (state->transition.active) {
        DrawTransition(&state->transition);
    }
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

void StartTransition(Transition *transition, TransitionType type, float duration) {
    if (transition == NULL) return;

    transition->type = type;
    transition->duration = duration;
    transition->elapsed = 0.0f;
    transition->active = true;
}

void UpdateTransition(Transition *transition, float deltaTime) {
    if (transition == NULL || !transition->active) return;

    transition->elapsed += deltaTime;
    if (transition->elapsed >= transition->duration) {
        transition->active = false;
    }
}

void DrawTransition(Transition *transition) {
    if (transition == NULL || !transition->active) return;

    float alpha = transition->elapsed / transition->duration;
    if (transition->type == TRANSITION_FADE_IN) {
        alpha = 1.0f - alpha;
    }
    DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), (Color){0, 0, 0, (unsigned char)(alpha * 255)});
}