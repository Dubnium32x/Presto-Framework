// Transition Manager header
#ifndef MANAGERS_TRANSITION_H
#define MANAGERS_TRANSITION_H

#include "raylib.h"
#include <stddef.h>
#include <stdint.h>

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

#endif // MANAGERS_TRANSITION_H
