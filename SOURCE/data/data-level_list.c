// Level list
#include "data-level_list.h"
#include "data-csv_loader.h"
#include "../managers/managers-root.h"

// #include "../util/global_constants.h" // TODO: Create this file when needed

Level levelList[MAX_LEVELS] = {0};
Level actList[MAX_ACTS] = {0};

// CSV loader compatibility
const int g_levelCount = MAX_LEVELS;
LevelMetaData g_levels[MAX_LEVELS] = {0};

#define THUMBNAIL_WIDTH 128
#define THUMBNAIL_HEIGHT 64

void InitLevelList(void) {
    for (int i = 0; i < MAX_LEVELS; i++) {
        levelList[i] = (Level){
            .name = "Level 1", // TODO: Replace with real names
            .filePath = "",
            .thumbnail = (Texture2D){0},
            .isLocked = (i != 0) // Unlock first level
        };
    }
    for (int j = 0; j < MAX_ACTS; j++) {
        actList[j] = (Level){
            .name = "Act 1", // TODO: Replace with real act names
            .filePath = "",
            .thumbnail = (Texture2D){0},
            .isLocked = (j != 0) // Unlock first act
        };
    }
}

Texture2D LoadThumbnail(const char* path) {
    Image img = LoadImage(path);
    if (!img.data) {
        TraceLog(LOG_WARNING, "Failed to load thumbnail image: %s", path);
        return (Texture2D){0};
    }
    // Resize to standard thumbnail size
    ImageResize(&img, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT);
    Texture2D tex = LoadTextureFromImage(img);
    UnloadImage(img);
    return tex;
}

void UnloadLevelThumbnails(void) {
    for (int i = 0; i < MAX_LEVELS; i++) {
        if (levelList[i].thumbnail.id > 0) {
            UnloadTexture(levelList[i].thumbnail);
            levelList[i].thumbnail = (Texture2D){0};
        }
    }
    for (int i = 0; i < MAX_ACTS; i++) {
        if (actList[i].thumbnail.id > 0) {
            UnloadTexture(actList[i].thumbnail);
            actList[i].thumbnail = (Texture2D){0};
        }
    }
}

Level* GetLevelByIndex(int index) {
    if (index < 0 || index >= MAX_LEVELS) {
        SetError(ERROR_OUT_OF_BOUNDS, "Level index out of bounds");
        return NULL;
    }
    return &levelList[index];
}
