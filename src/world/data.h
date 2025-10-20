// Data header
#ifndef DATA_H
#define DATA_H

#include <stdint.h>
#include <string.h>
#include "../util/globals.h"

typedef enum {
    SONIC,
    TAILS,
    KNUCKLES,
    AMY,
    OTHER,
    NONE
} SavedCharacter;

typedef struct {
    int playerScore;
    int playerLevel;
    uint8_t playerEmeralds;
    const char* playerName;
    SavedCharacter character;
    int playerLives;
} PlayerData;

typedef enum {
    NO_SAVE,
    SLOT_1,
    SLOT_2,
    SLOT_3,
    SLOT_4,
    SLOT_5,
    SLOT_6,
    SLOT_7,
    SLOT_8
} DataSlot;

typedef enum {
    GENESIS,
    CD,
    POCKET
} CameraType;

// Global configuration variables (extern declarations)
extern bool isDebugMode;
extern bool isMusicEnabled;
extern bool isSoundEnabled;
extern bool isFullscreen;
extern bool isVSync;
extern int windowSize; // Default 2x scale
extern CameraType cameraType;
extern DataSlot currentDataSlot;
extern PlayerData playerData[8]; // 8 save slots
extern bool isDropDashEnabled;
extern bool isSuperPeeloutEnabled;
extern bool isInstaShieldEnabled;
extern bool isMaxControlEnabled;
extern bool isAndKnucklesEnabled;

typedef enum {
    SONIC2,
    SONIC3,
    SONIC2_2011,
    MAX_CONTROL
} TailsAssistType;

extern bool isTimeLimitEnabled;
extern bool isSpriteTrailsEnabled;
extern TailsAssistType tailsAssistType;

// Player data functions
void ResetPlayerData(PlayerData* data, DataSlot slot);
bool LoadPlayerData(DataSlot slot);
bool SavePlayerData(DataSlot slot);
void DeletePlayerData(DataSlot slot);

// Configuration management functions
void LoadConfiguration(void);
void SaveConfiguration(void);
void InitializeDataSystem(void);
const char* GetConfigValueString(const char* key);
bool GetConfigValueBool(const char* key);
int GetConfigValueInt(const char* key);
void SetConfigValue(const char* key, const char* value);

#endif // DATA_H