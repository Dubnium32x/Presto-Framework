// screen_states.d
module prestoframework.screen_states;

import std.variant;

enum ScreenState {
    TITLE,
    DEBUG,
    MENU,
    GAME,
    CREDITS,
    EXIT
}
enum GameplayState {
    START,
    PLAYING,
    PAUSED,
    GAME_OVER
}