module world.level_list;

import raylib;

import std.stdio;

enum LevelNumber {
    LEVEL0 = 0,
    LEVEL1 = 1,
    LEVEL2 = 2,
    LEVEL3 = 3,
    LEVEL4 = 4,
    LEVEL5 = 5,
    LEVEL6 = 6,
    LEVEL7 = 7,
    LEVEL8 = 8
}

enum ActNumber {
    ACT1 = 1,
    ACT2 = 2,
    ACT3 = 3
}

int getLevelNumber(LevelNumber level) {
    return cast(int)level;
}

int getActNumber(ActNumber act) {
    return cast(int)act;
}