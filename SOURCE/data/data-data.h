// Data for the game
#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "raylib.h"

#define MAX_PLAYERS 4
#define MAX_NAME_LENGTH 32
#define MAX_ZONES 11  // Changed from 10+1 for clarity
#define MAX_ACTS 3
#define MAX_EMERALDS 7  // Chaos Emeralds
#define MAX_LIVES 99
#define VERSION_MAJOR 1
#define VERSION_MINOR 0

typedef enum {
    SONIC,
    TAILS,
    KNUCKLES,
    AMY,
    PLAYER_TYPE_COUNT
} PlayerType;

typedef enum {
    ZONE_0,
    ZONE_1,
    ZONE_2,
    ZONE_3,
    ZONE_4,
    ZONE_5,
    ZONE_6,
    ZONE_7,
    ZONE_8,
    ZONE_9,
    ZONE_10,
    ZONE_COUNT = ZONE_10 + 1
} ZoneType;

typedef enum {
    ACT_1,
    ACT_2,
    ACT_3,
    ACT_COUNT = ACT_3 + 1
} ActType;

typedef enum {
    SLOT_1,
    SLOT_2,
    SLOT_3,
    SLOT_4,
    SLOT_5,
    SLOT_COUNT = 5
} SaveSlot;

typedef struct {
    char name[MAX_NAME_LENGTH];
    PlayerType type;
    uint32_t score;             // Changed to uint32_t for larger scores
    uint8_t lives;
    ZoneType currentZone;
    ActType currentAct;
    uint8_t emeralds;           // Bitfield: each bit represents an emerald
    uint32_t rings;             // Current ring count
    uint32_t totalRings;        // Total rings collected (for statistics)
    bool hasSuper;              // Super form availability
    bool isActive;              // Whether this player slot is in use
    uint32_t checkpointId;      // Last checkpoint reached
    Vector2 checkpointPosition; // Checkpoint spawn position
} PlayerData;

typedef struct {
    size_t playerCount;
    ZoneType currentZone;
    ActType currentAct;
    uint32_t timeElapsed;                       // in milliseconds for precision
    uint32_t* bestTime[MAX_ZONES][MAX_ACTS];    // Best completion time for each level
    bool* levelCompleted[MAX_ZONES][MAX_ACTS];  // Track completion status
    uint8_t difficulty;      // Difficulty setting (0-3)
    uint32_t totalScore;     // Combined score from all players
    uint32_t sessionRings;   // Rings collected this session
    bool timeAttack;         // Time attack mode flag
} GameData;

typedef struct {
    uint16_t versionMajor;   // File format version
    uint16_t versionMinor;
    uint32_t magic;          // Magic number for file validation (0x53415645 = "SAVE")
    uint32_t checksum;       // Simple checksum for corruption detection
    GameData slots[SLOT_COUNT];
    PlayerData players[MAX_PLAYERS];
    SaveSlot currentSlot;
    char lastPlayedLevel[64]; // Name of last level played
    uint32_t totalPlayTime;   // Total time played in seconds
    uint32_t achievementFlags; // Bitfield for unlocked achievements
    bool unlockedZones[MAX_ZONES]; // Which zones are unlocked
} SaveData;

typedef enum {
    CAMERA_GENESIS,
    CAMERA_CD,
    CAMERA_POCKET
} CameraType;

typedef struct {
    uint8_t musicVolume;     // 0-100
    uint8_t sfxVolume;       // 0-100
    bool fullscreen;         // Fullscreen mode
    size_t screenSize;       // 1-4 scale
    bool vsync;              // VSync enabled
    bool showFPS;            // Show FPS counter
    bool dropdashEnabled;    // Dropdash ability
    bool instaShieldEnabled; // Instant shield recharge
    bool peeloutEnabled;     // Peelout ability
    CameraType cameraType;   // Selected camera type
} Options;

extern SaveData g_SaveData;
extern ZoneType g_currentZone;
extern ActType g_currentAct;
extern size_t g_currentPlayerIndex;
extern Options g_Options;
extern const char *g_OptionsFilePath;

void InitGameData(size_t numPlayers);
void InitOptions(); 
bool LoadGameData(size_t numPlayers, const char *filePath);
bool LoadOptions(const char *filePath);
bool SaveGameData(size_t numPlayers, const char *filePath);
bool SaveOptions(const char *filePath);
void ResetPlayerData(PlayerData *player);
void ResetGameData(GameData *game);
void ResetOptions(Options *options);
void PrintSaveDataInfo(const SaveData *data);