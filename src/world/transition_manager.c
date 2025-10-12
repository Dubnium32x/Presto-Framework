// Transition Manager
#include "transition_manager.h"
#include <stdio.h>
#include <stdlib.h>
#include "raylib.h"

void StartTransition(Transition* transition, TransitionType type, float duration, Color color) {
    if (transition == NULL) return;
    transition->type = type;
    transition->duration = duration;
    transition->color = color;
    transition->elapsed = 0.0f;
    transition->active = true;
}

void UpdateTransition(Transition* transition, float deltaTime) {
    if (transition == NULL || !transition->active) return;
    transition->elapsed += deltaTime;
    if (transition->elapsed >= transition->duration) {
        transition->elapsed = transition->duration;
        transition->active = false;
    }
}

void DrawTransition(const Transition* transition) {
    if (transition == NULL || !transition->active) return;
    switch (transition->type) {
        case FADE:
            DrawFadeTransition(transition);
            break;
        case SLIDE:
            DrawSlideTransition(transition);
            break;
        case WIPE:
            DrawWipeTransition(transition);
            break;
        case CUT:
            DrawCutTransition(transition);
            break;
        default:
            break;
    }
}

bool IsTransitionActive(const Transition* transition) {
    if (transition == NULL) return false;
    return transition->active;
}

void DrawFadeTransition(const Transition* transition) {
    if (transition == NULL) return;
    float alpha = transition->elapsed / transition->duration;
    if (alpha > 1.0f) alpha = 1.0f;
    Color color = transition->color;
    color.a = (unsigned char)(alpha * 255);
    DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), color);
}

void DrawSlideTransition(const Transition* transition) {
    if (transition == NULL) return;
    float progress = transition->elapsed / transition->duration;
    if (progress > 1.0f) progress = 1.0f;
    int width = GetScreenWidth();
    int height = GetScreenHeight();
    int slideX = (int)(width * progress);
    DrawRectangle(-width + slideX, 0, width, height, transition->color);
}

void DrawWipeTransition(const Transition* transition) {
    if (transition == NULL) return;
    float progress = transition->elapsed / transition->duration;
    if (progress > 1.0f) progress = 1.0f;
    int width = GetScreenWidth();
    int height = GetScreenHeight();
    int wipeWidth = (int)(width * progress);
    DrawRectangle(0, 0, wipeWidth, height, transition->color);
}

void DrawCutTransition(const Transition* transition) {
    if (transition == NULL) return;
    DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), transition->color);
}

// End of Transition Manager

