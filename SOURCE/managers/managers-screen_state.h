// Screen states header
#ifndef MANAGERS_SCREEN_STATE_H
#define MANAGERS_SCREEN_STATE_H
#include "raylib.h"
#include <stdio.h>

typedef enum {
    SCREEN_STATE_INIT,
    SCREEN_STATE_SPLASH,
    SCREEN_STATE_INTRO,
    SCREEN_STATE_TITLE,
    SCREEN_STATE_MENU,
    SCREEN_STATE_GAMEPLAY,
    SCREEN_STATE_PAUSE,
    SCREEN_STATE_GAMEOVER,
    SCREEN_STATE_CREDITS,
    SCREEN_STATE_EXIT,

    // Debug screen states
    SCREEN_STATE_DEBUG1,
    SCREEN_STATE_DEBUG2,
    SCREEN_STATE_DEBUG3,
    SCREEN_STATE_DEBUG4
} ScreenState;

typedef enum {
    OPTIONS_NONE,
    OPTIONS_TOP_MENU,
    OPTIONS_AUDIO,
    OPTIONS_VIDEO,
    OPTIONS_CONTROLS,
    OPTIONS_GAMEPLAY
} OptionsMenu;

void ChangeScreenState(ScreenState newState);
ScreenState GetCurrentScreenState(void);
void SetOptionsMenu(OptionsMenu menu);
OptionsMenu GetOptionsMenu(void);

#endif // MANAGERS_SCREEN_STATE_H