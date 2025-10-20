// Data system implementation
#include "data.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Define all global configuration variables
bool isDebugMode = true;
bool isMusicEnabled = true;
bool isSoundEnabled = true;
bool isFullscreen = false;
bool isVSync = true;
int windowSize = 2; // Default 2x scale
CameraType cameraType = GENESIS;
DataSlot currentDataSlot = NO_SAVE;
PlayerData playerData[8]; // 8 save slots
bool isDropDashEnabled = true;
bool isSuperPeeloutEnabled = true;
bool isInstaShieldEnabled = true;
bool isMaxControlEnabled = false;
bool isAndKnucklesEnabled = true;
bool isTimeLimitEnabled = true;
bool isSpriteTrailsEnabled = true;
TailsAssistType tailsAssistType = SONIC2;

void InitializeDataSystem(void) {
    // Initialize player data slots
    for (int i = 0; i < 8; i++) {
        ResetPlayerData(&playerData[i], (DataSlot)(i + 1));
    }
    
    // Load configuration from file
    LoadConfiguration();
    
    printf("Data system initialized\n");
}

void ResetPlayerData(PlayerData* data, DataSlot slot) {
    if (data == NULL) return;
    
    data->playerScore = 0;
    data->playerLevel = 1;
    data->playerEmeralds = 0;
    data->playerName = "SONIC";
    data->character = SONIC;
    data->playerLives = 3;
}

bool LoadPlayerData(DataSlot slot) {
    if (slot == NO_SAVE || slot < SLOT_1 || slot > SLOT_8) return false;
    
    char filename[64];
    snprintf(filename, sizeof(filename), "save_slot_%d.dat", slot);
    
    FILE* file = fopen(filename, "rb");
    if (file == NULL) return false;
    
    int slotIndex = slot - 1;
    fread(&playerData[slotIndex], sizeof(PlayerData), 1, file);
    fclose(file);
    
    return true;
}

bool SavePlayerData(DataSlot slot) {
    if (slot == NO_SAVE || slot < SLOT_1 || slot > SLOT_8) return false;
    
    char filename[64];
    snprintf(filename, sizeof(filename), "save_slot_%d.dat", slot);
    
    FILE* file = fopen(filename, "wb");
    if (file == NULL) return false;
    
    int slotIndex = slot - 1;
    fwrite(&playerData[slotIndex], sizeof(PlayerData), 1, file);
    fclose(file);
    
    return true;
}

void DeletePlayerData(DataSlot slot) {
    if (slot == NO_SAVE || slot < SLOT_1 || slot > SLOT_8) return;
    
    char filename[64];
    snprintf(filename, sizeof(filename), "save_slot_%d.dat", slot);
    
    remove(filename);
    
    int slotIndex = slot - 1;
    ResetPlayerData(&playerData[slotIndex], slot);
}

void LoadConfiguration(void) {
    FILE* file = fopen("options.ini", "r");
    if (file == NULL) {
        printf("No options.ini found, using defaults\n");
        return;
    }
    
    char line[256];
    while (fgets(line, sizeof(line), file)) {
        // Remove newline
        line[strcspn(line, "\n")] = 0;
        
        // Skip empty lines and comments
        if (strlen(line) == 0 || line[0] == '#') continue;
        
        // Find the '=' separator
        char* equals = strchr(line, '=');
        if (equals == NULL) continue;
        
        *equals = '\0';
        char* key = line;
        char* value = equals + 1;
        
        // Trim whitespace
        while (*key == ' ' || *key == '\t') key++;
        while (*value == ' ' || *value == '\t') value++;
        
        // Remove quotes if present
        if (value[0] == '"' && value[strlen(value)-1] == '"') {
            value[strlen(value)-1] = '\0';
            value++;
        }
        
        // Apply configuration values
        SetConfigValue(key, value);
    }
    
    fclose(file);
    printf("Configuration loaded from options.ini\n");
}

void SaveConfiguration(void) {
    FILE* file = fopen("options.ini", "w");
    if (file == NULL) {
        printf("Failed to save configuration\n");
        return;
    }
    
    fprintf(file, "# Presto Framework Configuration File\n");
    fprintf(file, "# Core system settings\n");
    fprintf(file, "debugMode=%s\n", isDebugMode ? "true" : "false");
    fprintf(file, "musicEnabled=%s\n", isMusicEnabled ? "true" : "false");
    fprintf(file, "sfxEnabled=%s\n", isSoundEnabled ? "true" : "false");
    fprintf(file, "fullscreen=%s\n", isFullscreen ? "true" : "false");
    fprintf(file, "windowSize=%d\n", windowSize);
    fprintf(file, "vsyncEnabled=%s\n", isVSync ? "true" : "false");
    fprintf(file, "\\n");
    
    fprintf(file, "# Gameplay settings\n");
    fprintf(file, "dropDash=%s\n", isDropDashEnabled ? "true" : "false");
    fprintf(file, "peelOut=%s\n", isSuperPeeloutEnabled ? "true" : "false");
    fprintf(file, "instaShield=%s\n", isInstaShieldEnabled ? "true" : "false");
    fprintf(file, "maxControl=%s\n", isMaxControlEnabled ? "true" : "false");
    fprintf(file, "andKnuckles=%s\n", isAndKnucklesEnabled ? "true" : "false");
    fprintf(file, "timeLimitEnabled=%s\n", isTimeLimitEnabled ? "true" : "false");
    fprintf(file, "spriteTrails=%s\n", isSpriteTrailsEnabled ? "true" : "false");
    fprintf(file, "\n");
    
    fprintf(file, "# Technical settings\n");
    const char* cameraTypeStr = (cameraType == GENESIS) ? "Genesis" : 
                               (cameraType == CD) ? "CD" : "Pocket";
    fprintf(file, "cameraType=%s\n", cameraTypeStr);
    fprintf(file, "resetSaveData=false\n");
    fprintf(file, "levelLoadType=CSV\n");
    
    fclose(file);
    printf("Configuration saved to options.ini\n");
}

const char* GetConfigValueString(const char* key) {
    if (strcmp(key, "cameraType") == 0) {
        switch (cameraType) {
            case GENESIS: return "Genesis";
            case CD: return "CD";
            case POCKET: return "Pocket";
            default: return "Genesis";
        }
    }
    return "";
}

bool GetConfigValueBool(const char* key) {
    if (strcmp(key, "debugMode") == 0) return isDebugMode;
    if (strcmp(key, "musicEnabled") == 0) return isMusicEnabled;
    if (strcmp(key, "sfxEnabled") == 0) return isSoundEnabled;
    if (strcmp(key, "fullscreen") == 0) return isFullscreen;
    if (strcmp(key, "vsyncEnabled") == 0) return isVSync;
    if (strcmp(key, "dropDash") == 0) return isDropDashEnabled;
    if (strcmp(key, "peelOut") == 0) return isSuperPeeloutEnabled;
    if (strcmp(key, "instaShield") == 0) return isInstaShieldEnabled;
    if (strcmp(key, "maxControl") == 0) return isMaxControlEnabled;
    if (strcmp(key, "andKnuckles") == 0) return isAndKnucklesEnabled;
    if (strcmp(key, "timeLimitEnabled") == 0) return isTimeLimitEnabled;
    if (strcmp(key, "spriteTrails") == 0) return isSpriteTrailsEnabled;
    return false;
}

int GetConfigValueInt(const char* key) {
    if (strcmp(key, "windowSize") == 0) return windowSize;
    return 0;
}

void SetConfigValue(const char* key, const char* value) {
    // Boolean values
    if (strcmp(key, "debugMode") == 0) {
        isDebugMode = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "musicEnabled") == 0) {
        isMusicEnabled = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "sfxEnabled") == 0) {
        isSoundEnabled = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "fullscreen") == 0) {
        isFullscreen = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "vsyncEnabled") == 0) {
        isVSync = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "dropDash") == 0) {
        isDropDashEnabled = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "peelOut") == 0) {
        isSuperPeeloutEnabled = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "instaShield") == 0) {
        isInstaShieldEnabled = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "maxControl") == 0) {
        isMaxControlEnabled = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "andKnuckles") == 0) {
        isAndKnucklesEnabled = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "timeLimitEnabled") == 0) {
        isTimeLimitEnabled = (strcmp(value, "true") == 0);
    } else if (strcmp(key, "spriteTrails") == 0) {
        isSpriteTrailsEnabled = (strcmp(value, "true") == 0);
    }
    // Integer values
    else if (strcmp(key, "windowSize") == 0) {
        windowSize = atoi(value);
        if (windowSize < 1 || windowSize > 4) windowSize = 2;
    }
    // String/enum values
    else if (strcmp(key, "cameraType") == 0) {
        if (strcmp(value, "Genesis") == 0) cameraType = GENESIS;
        else if (strcmp(value, "CD") == 0) cameraType = CD;
        else if (strcmp(value, "Pocket") == 0) cameraType = POCKET;
        else cameraType = GENESIS;
    }
}