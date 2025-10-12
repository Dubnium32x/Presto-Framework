// Transition Manager header
#ifndef TRANSITION_H
#define TRANSITION_H

#include "raylib.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

typedef enum {
    FADE,
    SLIDE,
    WIPE,
    CUT
} TransitionType;

typedef struct {
    TransitionType type;
    float duration;
    Color color;
    float elapsed;
    bool active;
} Transition;

void StartTransition(Transition* transition, TransitionType type, float duration, Color color);
void UpdateTransition(Transition* transition, float deltaTime);
void DrawTransition(const Transition* transition);
bool IsTransitionActive(const Transition* transition);
void DrawFadeTransition(const Transition* transition);
void DrawSlideTransition(const Transition* transition);
void DrawWipeTransition(const Transition* transition);
void DrawCutTransition(const Transition* transition);

#endif // TRANSITION_H