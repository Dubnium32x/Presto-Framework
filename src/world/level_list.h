// Level list header
#ifndef LEVEL_LIST_H
#define LEVEL_LIST_H
#include <raylib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LEVELS 11
#define MAX_ACTS 4

#define TOTAL_LEVELS (MAX_LEVELS * MAX_ACTS)

typedef enum {
    LEVEL_0,
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
} LevelType;

typedef enum {
    ACT_0,
    ACT_1,
    ACT_2,
    ACT_3
} ActType;

typedef struct {
    LevelType level;
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
LevelInfo* GetLevelInfo(LevelType level, ActType act);
Level* GetLevelByIndex(int index);
#endif // LEVEL_LIST_H