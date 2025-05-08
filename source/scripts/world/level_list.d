module level_list;

import raylib;
import std.stdio;
import std.string;
import std.file;


enum LevelList {
    LEVEL_0, // DEBUG
    LEVEL_1,
    LEVEL_2,
    LEVEL_3,
    LEVEL_4,
    LEVEL_5,
    LEVEL_6,
    LEVEL_7,
    LEVEL_8,
    LEVEL_9,
    LEVEL_10
}

enum ActNumber {
    ACT_1,
    ACT_2,
    ACT_3
}

string[] LayerNames = [
    "Ground_1",
    "SemiSolid_1",
    "Solid_1",
    "Objects_1",
    "Enemies_1",
    "Hazards_1",
    "Ground_2",
    "SemiSolid_2",
    "Solid_2",
    "Objects_2",
    "Enemies_2",
    "Hazards_2",
    "Ground_3",
    "SemiSolid_3",
    "Solid_3",
    "Objects_3",
    "Enemies_3",
    "Hazards_3",
    "Ground_4",
    "SemiSolid_4",
    "Solid_4",
    "Objects_4",
    "Enemies_4",
    "Hazards_4"
];
