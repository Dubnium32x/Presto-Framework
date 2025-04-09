module prestoframework.player_states;

import raylib;
import std.stdio : writeln;
import std.string;

enum PlayerState {
    IDLE,
    WALK,
    RUN,
    JUMP,
    ROLL,
    FALL,
    SPINDASH,
    PEELOUT,
    HURT,
    DEAD
}

enum IdleState {
    IDLE,
    LOOKUP,
    CROUCH,
    IMPATIENT,
    LEANFORWARD,
    LEANBACK
}