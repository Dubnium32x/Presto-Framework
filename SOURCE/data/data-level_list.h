// Level list header
#ifndef DATA_LEVEL_LIST_H
#define DATA_LEVEL_LIST_H
#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "data-data.h"

#define MAX_LEVELS 11
#define MAX_ACTS 4

#define TOTAL_LEVELS (MAX_LEVELS * MAX_ACTS)


typedef struct {
    ZoneType zone;
    ActType act;
    const char* name;
    const char* filePath;
} LevelInfo;

typedef struct {
    const char* name;
    const char* filePath;
    Texture2D thumbnail;
    bool isLocked;
} Level;

extern LevelInfo g_levelList[];
extern const int g_levelCount;

void InitLevelList(void);
Texture2D LoadThumbnail(const char* path);
void UnloadLevelThumbnails(void);
LevelInfo* GetLevelInfo(ZoneType zone, ActType act);
Level* GetLevelByIndex(int index);
#endif // DATA_LEVEL_LIST_H