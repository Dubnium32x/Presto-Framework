// Level list
#include "level_list.h"
#include "error_handler.h"
#include "../util/globals.h"
#include <raylib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "../util/global_constants.h"

Level levelList[MAX_LEVELS] = {0};
Level actList[MAX_ACTS] = {0};
int index[] = {0};

#define THUMBNAIL_WIDTH 128
#define THUMBNAIL_HEIGHT 64

void InitLevelList(void) {
    for (int i = 0; i < MAX_LEVELS; i++) {
        levelList[i] = (Level){
            .name = "Level " + ("%d", i),
            .filePath = "",
            .thumbnail = (Texture2D){0},
            .isLocked = true
            for (int j = 0; j < MAX_ACTS; j++) {
                actList[j] = (Level){
                    .name = "Act " + ("%d", j),
                    .filePath = "",
                    .thumbnail = (Texture2D){0},
                    .isLocked = true
                };

                levelList[i].isLocked = (i != 0 || j != 0) ? true : false; // Unlock first level and act
            }
            
            // Add to index
            index[i] = i;
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