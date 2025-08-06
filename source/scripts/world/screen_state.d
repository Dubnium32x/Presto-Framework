module world.screen_state;

// ---- ENUMS ----
enum ScreenState {
    INIT,
    TITLE,
    GAMEPLAY,
    GAMEOVER,
    SETTINGS,
    CREDITS
}

enum GameplayState {
    IN_MENU,
    PLAYING,
    NO_INPUT,
    PAUSED,
    GAMEOVER
}

enum SettingsState {
    VIDEO,
    AUDIO,
    CONTROLS,
    GAMEPLAY
}

enum Resolution {
    RES_1X,
    RES_2X,
    RES_3X,
    RES_4X,
    FULLSCREEN
}