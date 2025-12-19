// Screen states manager
#include "managers-screen_state.h"

static ScreenState currentScreenState = SCREEN_STATE_INIT;

void ChangeScreenState(ScreenState newState) {
    currentScreenState = newState;
}

ScreenState GetCurrentScreenState(void) {
    return currentScreenState;
}

static OptionsMenu currentOptionsMenu = OPTIONS_NONE;

void SetOptionsMenu(OptionsMenu menu) {
    currentOptionsMenu = menu;
}

OptionsMenu GetOptionsMenu(void) {
    return currentOptionsMenu;
}
