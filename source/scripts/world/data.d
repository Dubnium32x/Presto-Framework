module data;

import std.stdio;
import std.file;
import std.string;
import std.array;

enum SavedCharacter {
    SONIC,
    TAILS,
    KNUCKLES,
    AMY,
    NONE
}

// Loads and keeps track of game data
struct SaveData {
    int playerScore;
    int playerLevel;
    byte playerEmeralds;
    string playerName;
    SavedCharacter playerCharacter;
    int playerLives;

    this(int score, int level, byte emeralds, string name, int lives, SavedCharacter character) {
        playerScore = score;
        playerLevel = level;
        playerEmeralds = emeralds;
        playerName = name;
        playerLives = lives;
        playerCharacter = character;
    }
}

enum DataSlot {
    NO_SAVE,
    SLOT_1,
    SLOT_2,
    SLOT_3,
    SLOT_4,
    SLOT_5,
    SLOT_6,
    SLOT_7,
    SLOT_8
}

auto currentDataSlot = DataSlot.NO_SAVE;
auto playerSaveData = SaveData(0, 1, 0, "Player", 3, SavedCharacter.NONE);

// Function to reset the save data
void resetSaveData() {
    playerSaveData = SaveData(0, 1, 0, "Player", 3, SavedCharacter.NONE);
    currentDataSlot = DataSlot.NO_SAVE;
    writeln("Save data has been reset.");
}

void loadSaveData(DataSlot slot) {
    // Implementation for loading save data from a file
    auto filePath = "save_" ~ to!string(slot) ~ ".json";
    if (!exists(filePath)) {
        writeln("No save data found.");
        return;
    }

    // Read the file and deserialize the JSON
    auto jsonData = readText(filePath);
    playerSaveData = fromJSON!SaveData(jsonData);
    currentDataSlot = slot;
    writeln("Save data loaded successfully.");
}

void saveData(DataSlot slot) {
    // Implementation for saving the current player data to a file
    auto filePath = "save_" ~ to!string(slot) ~ ".json";
    auto jsonData = toJSON(playerSaveData);
    writeText(filePath, jsonData);
    currentDataSlot = slot;
    writeln("Save data saved successfully.");
}
