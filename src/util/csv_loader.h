// CSV Loader header
#ifndef CSV_LOADER_H
#define CSV_LOADER_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"

#include "../world/level_list.h"

typedef struct {
    const char** layerNames;
    const char* levelName;
    int entryId;
    const char* world;
    const char* act;
    const char* music;
    int** data; // 2D array of integers
    int width;
    int height;
    int layerCount;
} LevelMetaData;

typedef struct {
    const char* filename;
    LevelMetaData levelMetaData;
    bool isLoaded;
} CSVLoader;

typedef struct LevelManager {
    CSVLoader* levels;
    LevelInfo* levelCount;
} LevelManager;

int** LoadCSVInt(const char* filePath);
const char*** LoadCSVString(const char* filePath);
int*** LoadLevelLayers(const char* filePath, const char** layerNames);

LevelMetaData GetLevelMetaData(int index);
int*** LoadLevel(int levelIndex, const char* basePath);
size_t GetLevelCount(void);
void AddLevel(LevelMetaData level);
void FreeCSVData(int** data, int height);
void FreeAllLevels(void);
#endif // CSV_LOADER_H

