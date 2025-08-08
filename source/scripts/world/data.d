module data;

import std.stdio;
import std.file;
import std.string;
import std.array;
import std.conv : to;
import std.json;
import std.file;
import std.exception;

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

// Options - Below will be a set of enums that will be selections for different options
// ...such as CameraType, ColorSwapMethod, WindowSize, etc.
enum CameraType {
    GENESIS,
    CD,
    POCKET
}

enum ColorSwapMethod {
    PALLETE,
    INTERNAL
}   

enum WindowSize {
    SIZE1,
    SIZE2,
    SIZE3,
    SIZE4
}

bool isDebugMode = false; // Global debug mode flag
bool isMusicEnabled = true; // Global music toggle
bool isSoundEnabled = true; // Global sound effects toggle
bool isFullscreen = false; // Global fullscreen toggle
bool isVSyncEnabled = true; // Global VSync toggle

bool isDropDashEnabled = true; // Global drop dash toggle
bool isSuperPeelOutEnabled = true; // Global super peel out toggle
bool instaShieldEnabled = true; // Global insta-shield toggle
bool maxControlEnabled;
bool isAndKnucklesEnabled = true; // Global "and Knuckles" toggle

enum TailsAssistType {
    SONIC2,
    SONIC3,
    SONIC2_2011,
    MAX_CONTROL
}

bool timeLimitEnabled = false; // Global time limit toggle
bool spriteTrailsEnabled = true; // Global sprite trails toggle

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
    JSONValue parsed = parseJSON(jsonData);
    auto obj = parsed.object;
    playerSaveData = SaveData(
        cast(int)obj["playerScore"].integer,
        cast(int)obj["playerLevel"].integer,
        cast(byte)obj["playerEmeralds"].integer,
        obj["playerName"].str,
        cast(int)obj["playerLives"].integer,
        cast(SavedCharacter)obj["playerCharacter"].integer
    );
    currentDataSlot = slot;
    writeln("Save data loaded successfully.");
}

void saveData(DataSlot slot) {
    // Implementation for saving the current player data to a file
    auto filePath = "save_" ~ to!string(slot) ~ ".json";
    
    // Serialize SaveData manually
    JSONValue obj = JSONValue([
        "playerScore": JSONValue(playerSaveData.playerScore),
        "playerLevel": JSONValue(playerSaveData.playerLevel),
        "playerEmeralds": JSONValue(cast(int)playerSaveData.playerEmeralds),
        "playerName": JSONValue(playerSaveData.playerName),
        "playerLives": JSONValue(playerSaveData.playerLives),
        "playerCharacter": JSONValue(cast(int)playerSaveData.playerCharacter)
    ]);
    auto jsonData = obj.toString();
    std.file.write(filePath, jsonData);
    currentDataSlot = slot;
    writeln("Save data saved successfully.");
}
