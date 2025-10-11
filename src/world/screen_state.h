// Screen state header

#ifndef SCREEN_STATE_H
#define SCREEN_STATE_H
#include <string>
#include <vector>
#include "raylib.h"
#include <stdio.h>

typedef enum {
    SCREEN_INIT,
    SCREEN_LOADING,
    SCREEN_SPLASH,
    SCREEN_INTRO,
    SCREEN_TITLE,
    SCREEN_MENU,
    SCREEN_GAMEPLAY,
    SCREEN_PAUSE,
    SCREEN_GAMEOVER,
    SCREEN_CREDITS,
    SCREEN_EXIT,

    // DEBUG SCREENS
    SCREEN_DEBUG1,
    SCREEN_DEBUG2,
    SCREEN_DEBUG3,
    SCREEN_DEBUG4,
    SCREEN_DEBUG5,
    SCREEN_DEBUG6,
    SCREEN_DEBUG7,
    SCREEN_DEBUG8,
    SCREEN_DEBUG9,
    SCREEN_DEBUG10,
    SCREEN_DEBUG11,
    SCREEN_DEBUG12
} ScreenType;

typedef enum {
    OPTIONS,
    FILE_SELECT,
    GALLERY,
    HELP,
    CREDITS
} MenuType;

typedef enum {
    GAMEPLAY_PLAYING,
    GAMEPLAY_PAUSED,
    GAMEPLAY_GAMEOVER,
    GAMEPLAY_CUTSCENE,
    GAMEPLAY_WIN
} GameplayState;

typedef enum {
    TRANSITION_NONE,
    TRANSITION_FADE_IN,
    TRANSITION_FADE_OUT
} TransitionType;

typedef struct Transition {
    TransitionType type;
    float duration;
    float elapsed;
    bool active;
} Transition;

void InitScreenState(ScreenState *state);
void UpdateScreenState(ScreenState *state, float deltaTime);
void DrawScreenState(ScreenState *state);
void UnloadScreenState(ScreenState *state);
void SetScreen(ScreenState *state, ScreenType newScreen);
void StartTransition(Transition *transition, TransitionType type, float duration);
void UpdateTransition(Transition *transition, float deltaTime);
void DrawTransition(Transition *transition);

#endif // SCREEN_STATE_H 