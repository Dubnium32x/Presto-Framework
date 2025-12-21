// Screen state header

#ifndef MANAGERS_SCREEN_STATE_H
#define MANAGERS_SCREEN_STATE_H
#include "raylib.h"

typedef enum {
    SCREEN_STATE_INIT,
    SCREEN_STATE_LOADING,
    SCREEN_STATE_SPLASH,
    SCREEN_STATE_INTRO,
    SCREEN_STATE_TITLE,
    SCREEN_STATE_MENU,
    SCREEN_STATE_OPTIONS,
    SCREEN_STATE_GAMEPLAY,
    SCREEN_STATE_PAUSE,
    SCREEN_STATE_GAMEOVER,
    SCREEN_STATE_CREDITS,
    SCREEN_STATE_EXIT,

    // DEBUG SCREENS
    SCREEN_STATE_DEBUG1,
    SCREEN_STATE_DEBUG2,
    SCREEN_STATE_DEBUG3,
    SCREEN_STATE_DEBUG4,
    SCREEN_STATE_DEBUG5,
    SCREEN_STATE_DEBUG6,
    SCREEN_STATE_DEBUG7,
    SCREEN_STATE_DEBUG8,
    SCREEN_STATE_DEBUG9,
    SCREEN_STATE_DEBUG10,
    SCREEN_STATE_DEBUG11,
    SCREEN_STATE_DEBUG12,
    SCREEN_STATE_ANIM_DEMO
} ScreenState;

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

typedef struct ScreenStateManager {
    ScreenState currentScreen;
    ScreenState previousScreen;
    MenuType currentMenu;
    GameplayState gameplayState;
    Transition transition;
    bool initialized;
    int frameCounter;
    bool isPaused;
} ScreenStateManager;

void InitScreenState(ScreenStateManager *state);
void UpdateScreenState(ScreenStateManager *state, float deltaTime);
void DrawScreenState(ScreenStateManager *state);
void UnloadScreenState(ScreenStateManager *state);
void SetScreen(ScreenStateManager *state, ScreenState newScreen);
void StartTransition(Transition *transition, TransitionType type, float duration);
void UpdateTransition(Transition *transition, float deltaTime);
void DrawTransition(Transition *transition);

#endif // MANAGERS_SCREEN_STATE_H
