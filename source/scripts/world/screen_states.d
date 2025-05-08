module screen_states;

import raylib;
import std.stdio;

enum ScreenState {
    INIT,
    TITLE,
    GAME,
    SETTINGS,
    CREDITS,
    DEBUG,
    OTHER
}

enum GameplayState {
    INIT,
    GAMEPLAY,
    PAUSED,
    CUTSCENE,
    FINISH_ACT,
    GAME_OVER,
    OTHER
}

enum SettingsState {
    HOME,
    OPTIONS,
    FILE_SELECT,
    OTHER
}

enum Resolution {
    RES_640x360,
    RES_1280x720,
    RES_1920x1080,
    RES_2560x1440,
    RES_3840x2160
}