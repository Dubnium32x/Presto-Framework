// Data for the game
#include "data-data.h"

static PlayerData players[MAX_PLAYERS];
static size_t playerCount = 0;
static GameData gameData;

void InitGameData(size_t numPlayers) {
    playerCount = (numPlayers > MAX_PLAYERS) ? MAX_PLAYERS : numPlayers;
    gameData.playerCount = playerCount;
    gameData.currentZone = ZONE_0;
    gameData.currentAct = ACT_1;
    gameData.timeElapsed = 0;
    gameData.difficulty = 0;
    gameData.totalScore = 0;
    gameData.sessionRings = 0;
    gameData.timeAttack = false;

    for (size_t i = 0; i < MAX_ZONES; i++) {
        for (size_t j = 0; j < MAX_ACTS; j++) {
            gameData.bestTime[i][j] = NULL;
            gameData.levelCompleted[i][j] = NULL;
        }
    }

    for (size_t i = 0; i < playerCount; i++) {
        players[i].isActive = true;
        players[i].lives = 3;
        players[i].score = 0;
        players[i].rings = 0;
        players[i].totalRings = 0;
        players[i].emeralds = 0;
        players[i].hasSuper = false;
        players[i].currentZone = ZONE_0;
        players[i].currentAct = ACT_1;
        players[i].checkpointId = 0;
        players[i].checkpointPosition = (Vector2){0, 0};
    }
}

bool LoadGameData(size_t numPlayers, const char *filePath) {
    // Implementation for loading game data from a file
    /*
        This will be implemented later.
    */
    return true;
}

bool SaveGameData(size_t numPlayers, const char *filePath) {
    // Implementation for saving game data to a file
    /*
        This will be implemented later.
    */
    return true;
}

void InitOptions() {
    ResetOptions(&g_Options);

    if (g_OptionsFilePath != NULL) {
        LoadOptions(g_OptionsFilePath);
    }
}

void ResetOptions(Options *options) {
    options->musicVolume = 100;
    options->sfxVolume = 100;
    options->fullscreen = false;
    options->screenSize = 2; // Default scale
    options->vsync = true;
    options->showFPS = false;
    options->dropdashEnabled = true;
    options->instaShieldEnabled = false;
    options->peeloutEnabled = true;
    options->cameraType = CAMERA_GENESIS;
}

bool LoadOptions(const char *filePath) {
    // Implementation for loading options from a file
    FILE *file = fopen(filePath, "r");
    if (file == NULL) {
        return false;
    }

    fscanf(file, "musicVolume=%hhu\n", &g_Options.musicVolume);
    fscanf(file, "sfxVolume=%hhu\n", &g_Options.sfxVolume);
    fscanf(file, "fullscreen=%d\n", (int*)&g_Options.fullscreen);
    fscanf(file, "screenSize=%zu\n", &g_Options.screenSize);
    fscanf(file, "vsync=%d\n", (int*)&g_Options.vsync);
    fscanf(file, "showFPS=%d\n", (int*)&g_Options.showFPS);
    fscanf(file, "dropdashEnabled=%d\n", (int*)&g_Options.dropdashEnabled);
    fscanf(file, "instaShieldEnabled=%d\n", (int*)&g_Options.instaShieldEnabled);
    fscanf(file, "peeloutEnabled=%d\n", (int*)&g_Options.peeloutEnabled);
    int cameraTypeInt;
    fscanf(file, "cameraType=%d\n", &cameraTypeInt);
    g_Options.cameraType = (CameraType)cameraTypeInt;
    fclose(file);

    return true;
}

bool SaveOptions(const char *filePath) {
    // Implementation for saving options to a file
    FILE *file = fopen(filePath, "w");
    if (file == NULL) {
        return false;
    }

    fprintf(file, "musicVolume=%hhu\n", g_Options.musicVolume);
    fprintf(file, "sfxVolume=%hhu\n", g_Options.sfxVolume);
    fprintf(file, "fullscreen=%d\n", g_Options.fullscreen);
    fprintf(file, "screenSize=%zu\n", g_Options.screenSize);
    fprintf(file, "vsync=%d\n", g_Options.vsync);
    fprintf(file, "showFPS=%d\n", g_Options.showFPS);
    fprintf(file, "dropdashEnabled=%d\n", g_Options.dropdashEnabled);
    fprintf(file, "instaShieldEnabled=%d\n", g_Options.instaShieldEnabled);
    fprintf(file, "peeloutEnabled=%d\n", g_Options.peeloutEnabled);
    fprintf(file, "cameraType=%d\n", (int)g_Options.cameraType);
    fclose(file);

    return true;
}