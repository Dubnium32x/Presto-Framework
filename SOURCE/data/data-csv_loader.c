// CSV Loader
#include "data-csv_loader.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "raylib.h"
#include "../util/util-global.h"
#include "data-level_list.h"

// Declare external reference to g_levels and g_levelCount if not already declared in included headers
extern LevelMetaData g_levels[MAX_LEVELS];

#define MAX_LAYERS 10

int** LoadCSVInt(const char* filePath) {
    return LoadCSVIntWithDimensions(filePath, NULL, NULL);
}

int** LoadCSVIntWithDimensions(const char* filePath, int* outWidth, int* outHeight) {
    FILE* file = fopen(filePath, "r");
    if (!file) {
        printf("Error opening file %s: %s\n", filePath, strerror(errno));
        if (outWidth) *outWidth = 0;
        if (outHeight) *outHeight = 0;
        return NULL;
    }

    int** data = NULL;
    size_t rowCount = 0;
    size_t colCount = 0;
    char line[8192];  // Increased buffer size for large CSVs

    while (fgets(line, sizeof(line), file)) {
        // Strip trailing newline and carriage return
        size_t len = strlen(line);
        while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r')) {
            line[len-1] = '\0';
            len--;
        }
        
        // Skip empty lines
        if (len == 0) continue;
        
        // Count columns by counting commas + 1
        size_t currentColCount = 1; // At least one column if line isn't empty
        for (size_t i = 0; i < len; i++) {
            if (line[i] == ',') currentColCount++;
        }
        
        if (colCount == 0) {
            colCount = currentColCount;
        } else if (colCount != currentColCount) {
            printf("Inconsistent column count in file %s at line %zu (expected %zu, got %zu)\n", filePath, rowCount + 1, colCount, currentColCount);
            FreeCSVData(data, rowCount);
            fclose(file);
            if (outWidth) *outWidth = 0;
            if (outHeight) *outHeight = 0;
            return NULL;
        }

        // Allocate memory for new row
        data = realloc(data, sizeof(int*) * (rowCount + 1));
        data[rowCount] = malloc(sizeof(int) * colCount);

        // Parse integers
        char* token = strtok(line, ",");
        for (size_t col = 0; col < colCount; col++) {
            if (token) {
                data[rowCount][col] = atoi(token);
                token = strtok(NULL, ",");
            } else {
                data[rowCount][col] = 0; // Default to 0 if missing
            }
        }
        rowCount++;
    }

    fclose(file);
    
    if (outWidth) *outWidth = (int)colCount;
    if (outHeight) *outHeight = (int)rowCount;
    
    return data;
}

const char*** LoadCSVString(const char* filePath) {
    FILE* file = fopen(filePath, "r");
    if (!file) {
        printf("Error opening file %s: %s\n", filePath, strerror(errno));
        return NULL;
    }

    const char*** data = NULL;
    size_t rowCount = 0;
    size_t colCount = 0;
    char line[1024];

    while (fgets(line, sizeof(line), file)) {
        // Count columns
        size_t currentColCount = 1; // At least one column
        for (char* p = line; *p; p++) {
            if (*p == ',') currentColCount++;
        }
        if (colCount == 0) {
            colCount = currentColCount;
        } else if (colCount != currentColCount) {
            printf("Inconsistent column count in file %s\n", filePath);
            // Free previously allocated data
            for (size_t i = 0; i < rowCount; i++) {
                for (size_t j = 0; j < colCount; j++) {
                    free((void*)data[i][j]);
                }
                free(data[i]);
            }
            free(data);
            fclose(file);
            return NULL;
        }

        // Allocate memory for new row
        data = realloc(data, sizeof(char**) * (rowCount + 1));
        data[rowCount] = malloc(sizeof(char*) * colCount);

        // Parse strings
        char* token = strtok(line, ",");
        for (size_t col = 0; col < colCount; col++) {
            if (token) {
                data[rowCount][col] = strdup(token);
                token = strtok(NULL, ",");
            } else {
                data[rowCount][col] = strdup(""); // Default to empty string if missing
            }
        }
        rowCount++;
    }

    fclose(file);
    return data;
}

int*** LoadLevelLayers(const char* filePath, const char** layerNames) {
    int*** layers = NULL;

    for (int i = 0; layerNames[i] != NULL; i++) {
        char fullPath[256];
        snprintf(fullPath, sizeof(fullPath), "%s_%s.csv", filePath, layerNames[i]);
        int** layerData = LoadCSVInt(fullPath);
        if (!layerData) {
            // Free previously loaded layers
            for (int j = 0; j < i; j++) {
                FreeCSVData(layers[j], 0); // Height unknown here
                free(layers[j]);
            }
            free(layers);
            return NULL;
        }
        layers = realloc(layers, sizeof(int**) * (i + 1));
        layers[i] = layerData;
    }
    // Count layers manually to avoid sizeof-pointer-div warning
    int layerCount = 0;
    while (layerNames[layerCount] != NULL) layerCount++;
    
    layers = realloc(layers, sizeof(int**) * (layerCount + 1));
    layers[layerCount] = NULL; // Null-terminate
    return layers;
}

void FreeCSVData(int** data, int height) {
    if (data) {
        for (int i = 0; i < height; i++) {
            free(data[i]);
        }
        free(data);
    }
}

void FreeAllLevels(void) {
    // Implement if you maintain a global list of levels
}

size_t GetLevelCount(void) {
    return g_levelCount;
}

void AddLevel(LevelMetaData level) {
    (void)level; // Suppress unused parameter warning
    // Implementation needed
}

LevelMetaData GetLevelMetaData(int index) {
    if (index >= 0 && index < (int)g_levelCount) {
        return g_levels[index];
    }
    LevelMetaData empty = {0};
    return empty;
}


// Load all layers for a specific level
int*** LoadLevel(int levelIndex, const char* basePath) {
    LevelMetaData metadata = GetLevelMetaData(levelIndex);
    if (metadata.levelName == NULL || metadata.levelName[0] == '\0') {
        return NULL;
    }

    char levelPath[256];
    snprintf(levelPath, sizeof(levelPath), "%slevels/%s", basePath ? basePath : "resources/data/", metadata.levelName);

    // Build actual layer names array (null-terminated)
    const char* layerNames[MAX_LAYERS + 1];
    size_t i = 0;
    for (; i < (size_t)metadata.layerCount && i < MAX_LAYERS; i++) {
        layerNames[i] = metadata.layerNames[i];
    }
    layerNames[i] = NULL;

    return LoadLevelLayers(levelPath, layerNames);
}