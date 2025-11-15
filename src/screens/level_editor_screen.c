#include "level_editor_screen.h"

#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>

#include "raylib.h"

#include "../util/globals.h"
#include "../util/level_loader.h"
#include "../world/input.h"
#include "../world/screen_manager.h"
#include "../world/level_list.h"

#define BASE_LEVEL_DIR "res/data/levels/"

#define MAX_LEVEL_FILES 100

Tile **editorLayer = NULL;
int editorWidth = 0;
int editorHeight = 0;
Texture2D editorTileset = {0};
Camera2D editorCamera = {0};
Vector2 cameraPos = {0};
int selectedTile = 1;
int totalTiles = 0;
bool showGrid = true;
int hoverTileX = -1;
int hoverTileY = -1;
char saveMessage[128] = {0};
float saveMessageTimer = 0.0f;

float tileChangeTimer = 0.0f;
float tileChangeInterval = 0.3f;
bool ltHeld = false;
bool rtHeld = false;

float ltTileChangeTimer = 0.0f;
float rtTileChangeTimer = 0.0f;

int menuSelectedIndex = 0;
int creationMenuSelectedIndex = 0;

char levelName[128] = "NEW_LEVEL";
int levelWidth = 64;
int levelHeight = 32;

int levelsFound = 0;
int selectedLevelIndex = 0;
char levelFileNames[MAX_LEVEL_FILES][256];

int scrollOffset = 0;

LevelEditorState editorState = LEVEL_EDITOR_MENU;

void LevelEditor_Init(void)
{
}

void LevelEditor_SearchDirectories(const char *basePath)
{
}

void LevelEditor_Update(float deltaTime)
{
    switch (editorState)
    {
    case LEVEL_EDITOR_MENU:
        UpdateMenu(deltaTime);
        break;
    case LEVEL_EDITOR_CREATING:
        UpdateCreationMenu(deltaTime);
        break;
    case LEVEL_EDITOR_EDITING:
        UpdateEditor(deltaTime);
        break;
    case LEVEL_EDITOR_OPENING:
        UpdateLevelSelectionMenu(deltaTime);
        break;
    }
}

void UpdateMenu(float deltaTime)
{
    if (IsInputPressed(INPUT_DOWN) && menuSelectedIndex < 2)
    {
        menuSelectedIndex++;
    }
    else if (IsInputPressed(INPUT_UP) && menuSelectedIndex > 0)
    {
        menuSelectedIndex--;
    }

    if (IsInputPressed(INPUT_A) || IsInputPressed(INPUT_START))
    {
        if (menuSelectedIndex == 0)
        {
            editorState = LEVEL_EDITOR_CREATING;
        }
        else if (menuSelectedIndex == 1)
        {
            SearchDirectories(BASE_LEVEL_DIR);
            editorState = LEVEL_EDITOR_OPENING;
        }
        else if (menuSelectedIndex == 2)
        {
            SetCurrentScreenGlobal(SCREEN_TITLE);
        }
    }
}

void UpdateCreationMenu(float deltaTime)
{
    (void)deltaTime;

    if ((IsKeyPressed(KEY_DOWN) || IsDown(0, DPAD_DOWN)) && creationMenuSelectedIndex < 2)
    {
        creationMenuSelectedIndex++;
    }
    else if ((IsKeyPressed(KEY_UP) || IsDown(0, DPAD_UP)) && creationMenuSelectedIndex > 0)
    {
        creationMenuSelectedIndex--;
    }

    if (creationMenuSelectedIndex == 0)
    {
        int key = GetCharPressed();
        while (key > 0)
        {
            if (key >= 32 && key <= 125 && strlen(levelName) < sizeof(levelName) - 1)
            {
                strncat(levelName, (char *)&key, 1);
            }
            key = GetCharPressed();
        }
        if (IsKeyPressed(KEY_BACKSPACE) && strlen(levelName) > 0)
        {
            levelName[strlen(levelName) - 1] = '\0';
        }
    }
    else if (creationMenuSelectedIndex == 1)
    {
        if (IsInputPressed(INPUT_LEFT) && levelWidth > 1)
            levelWidth--;
        else if (IsInputPressed(INPUT_RIGHT))
            levelWidth++;
    }
    else if (creationMenuSelectedIndex == 2)
    {
        if (IsInputPressed(INPUT_LEFT) && levelHeight > 1)
            levelHeight--;
        else if (IsInputPressed(INPUT_RIGHT))
            levelHeight++;
    }

    if (IsKeyPressed(KEY_ENTER) || IsInputPressed(INPUT_A))
    {
        CreateNewLevel(levelName, levelWidth, levelHeight);

        char path[512];
        snprintf(path, sizeof(path), "%s%s.csv", BASE_LEVEL_DIR, levelName);
        LoadLevelIntoEditor(path);

        editorState = LEVEL_EDITOR_EDITING;
    }

    if (IsInputPressed(INPUT_B))
    {
        editorState = LEVEL_EDITOR_MENU;
    }
}

void UpdateLevelSelectionMenu(float deltaTime)
{
    (void)deltaTime;

    if ((IsKeyPressed(KEY_DOWN) || IsInputPressed(INPUT_DOWN)) && selectedLevelIndex < levelsFound - 1)
    {
        selectedLevelIndex++;
    }
    else if ((IsKeyPressed(KEY_UP) || IsInputPressed(INPUT_UP)) && selectedLevelIndex > 0)
    {
        selectedLevelIndex--;
    }

    // Update scroll offset
    const int itemsPerPage = 5;
    if (selectedLevelIndex < scrollOffset)
    {
        scrollOffset = selectedLevelIndex;
    }
    if (selectedLevelIndex >= scrollOffset + itemsPerPage)
    {
        scrollOffset = selectedLevelIndex - itemsPerPage + 1;
    }

    if (IsInputPressed(INPUT_A) || IsInputPressed(INPUT_START))
    {
        if (levelsFound > 0)
        {
            // Load the selected level
            char path[512];
            snprintf(path, sizeof(path), "%s%s", BASE_LEVEL_DIR, levelFileNames[selectedLevelIndex]);
            LoadLevelIntoEditor(path);

            // Extract name without .csv
            char levelNameBuf[128];
            strcpy(levelNameBuf, levelFileNames[selectedLevelIndex]);
            char *dot = strstr(levelNameBuf, ".csv");
            if (dot)
                *dot = '\0';
            strcpy(levelName, levelNameBuf);

            editorState = LEVEL_EDITOR_EDITING;
        }
    }

    if (IsInputPressed(INPUT_B))
    {
        editorState = LEVEL_EDITOR_MENU;
    }
}

void UpdateEditor(float deltaTime)
{
    if (IsKeyPressed(KEY_ESCAPE) || IsInputPressed(INPUT_B))
    {
        FreeEditorLayer();
        if (editorTileset.id != 0)
        {
            UnloadTexture(editorTileset);
            editorTileset.id = 0;
        }
        editorWidth = 0;
        editorHeight = 0;
        cameraPos = (Vector2){0.0f, 0.0f};
        editorCamera = (Camera2D){0};
        selectedTile = 1;
        totalTiles = 0;
        showGrid = true;
        hoverTileX = -1;
        hoverTileY = -1;
        saveMessage[0] = '\0';
        saveMessageTimer = 0.0f;
        ltHeld = false;
        rtHeld = false;
        ltTileChangeTimer = 0.0f;
        rtTileChangeTimer = 0.0f;
        tileChangeInterval = 0.3f;
        editorState = LEVEL_EDITOR_MENU;
        return;
    }

    if (saveMessageTimer > 0.0f)
    {
        saveMessageTimer -= deltaTime;
        if (saveMessageTimer < 0.0f)
            saveMessageTimer = 0.0f;
    }

    const float moveSpeed = 240.0f;
    bool moveRight = IsKeyDown(KEY_RIGHT) || IsInputDown(INPUT_RIGHT);
    bool moveLeft = IsKeyDown(KEY_LEFT) || IsInputDown(INPUT_LEFT);
    bool moveDown = IsKeyDown(KEY_DOWN) || IsInputDown(INPUT_DOWN);
    bool moveUp = IsKeyDown(KEY_UP) || IsInputDown(INPUT_UP);
    bool modifierHeld = IsModifierDown(INPUT_MASK(INPUT_MODIFIER1)) ||
                        IsModifierDown(INPUT_MASK(INPUT_MODIFIER2));

    if (!modifierHeld)
    {
        if (moveRight)
            cameraPos.x += (moveSpeed / editorCamera.zoom) * deltaTime;
        if (moveLeft)
            cameraPos.x -= (moveSpeed / editorCamera.zoom) * deltaTime;
        if (moveDown)
            cameraPos.y += (moveSpeed / editorCamera.zoom) * deltaTime;
        if (moveUp)
            cameraPos.y -= (moveSpeed / editorCamera.zoom) * deltaTime;
    }

    float wheel = GetMouseWheelMove();
    if (wheel != 0.0f)
    {
        editorCamera.zoom += wheel * 0.1f;
        if (editorCamera.zoom < 0.25f)
            editorCamera.zoom = 0.25f;
        if (editorCamera.zoom > 4.0f)
            editorCamera.zoom = 4.0f;
    }

    editorCamera.target = cameraPos;

    hoverTileX = -1;
    hoverTileY = -1;
    Vector2 mouseVirtual = GetMousePositionVirtual();
    if (mouseVirtual.x >= 0.0f && mouseVirtual.x < (float)VIRTUAL_SCREEN_WIDTH &&
        mouseVirtual.y >= 0.0f && mouseVirtual.y < (float)VIRTUAL_SCREEN_HEIGHT)
    {
        Vector2 worldPos = GetScreenToWorld2D(mouseVirtual, editorCamera);
        if (worldPos.x >= 0.0f && worldPos.y >= 0.0f)
        {
            int tileX = (int)floorf(worldPos.x / TILE_SIZE);
            int tileY = (int)floorf(worldPos.y / TILE_SIZE);
            if (tileX >= 0 && tileX < editorWidth && tileY >= 0 && tileY < editorHeight)
            {
                hoverTileX = tileX;
                hoverTileY = tileY;

                if (IsMouseButtonDown(MOUSE_BUTTON_LEFT))
                {
                    if (selectedTile > 0 && totalTiles > 0)
                    {
                        editorLayer[tileY][tileX] = CreateTileFromId(selectedTile);
                    }
                }
                else if (IsMouseButtonDown(MOUSE_BUTTON_RIGHT))
                {
                    editorLayer[tileY][tileX] = CreateEmptyTile();
                }
            }
        }
    }

    if (totalTiles > 0)
    {
        // Handle initial press for tapping
        if (IsInputPressed(INPUT_LT) && selectedTile > 1)
        {
            selectedTile--;
            ltHeld = true;
            ltTileChangeTimer = 0.3f;
            tileChangeInterval = 0.3f;
        }
        if (IsInputPressed(INPUT_RT) && selectedTile < totalTiles)
        {
            selectedTile++;
            rtHeld = true;
            rtTileChangeTimer = 0.3f;
            tileChangeInterval = 0.3f;
        }

        // Handle holding for acceleration
        if (IsInputDown(INPUT_LT) && ltHeld)
        {
            ltTileChangeTimer -= deltaTime;
            if (ltTileChangeTimer <= 0.0f)
            {
                if (selectedTile > 1)
                    selectedTile--;
                tileChangeInterval *= 0.9f;
                if (tileChangeInterval < 0.05f)
                    tileChangeInterval = 0.05f;
                ltTileChangeTimer = tileChangeInterval;
            }
        }
        else if (!IsInputDown(INPUT_LT))
        {
            ltHeld = false;
        }

        if (IsInputDown(INPUT_RT) && rtHeld)
        {
            rtTileChangeTimer -= deltaTime;
            if (rtTileChangeTimer <= 0.0f)
            {
                if (selectedTile < totalTiles)
                    selectedTile++;
                tileChangeInterval *= 0.9f;
                if (tileChangeInterval < 0.05f)
                    tileChangeInterval = 0.05f;
                rtTileChangeTimer = tileChangeInterval;
            }
        }
        else if (!IsInputDown(INPUT_RT))
        {
            rtHeld = false;
        }
    }

    if (IsKeyPressed(KEY_ZERO) || IsKeyPressed(KEY_DELETE))
    {
        selectedTile = 0;
    }

    if (IsKeyPressed(KEY_G))
    {
        showGrid = !showGrid;
    }

    if ((IsKeyDown(KEY_LEFT_CONTROL) || IsKeyDown(KEY_RIGHT_CONTROL)) && IsKeyPressed(KEY_S))
    {
        const char *path = TextFormat("%s%s.csv", BASE_LEVEL_DIR, levelName);
        SaveLayerToCSV(path);
    }
}

void DrawMenu(void)
{
    ClearBackground((Color){24, 24, 32, 255});
    DrawText("LEVEL EDITOR", 12, 8, 32, WHITE);

    DrawText("New Level", 12, 100, 32, menuSelectedIndex == 0 ? WHITE : GRAY);

    DrawText("Open Existing Level", 12, 140, 32, menuSelectedIndex == 1 ? WHITE : GRAY);

    DrawText("Return To Main Menu", 12, 180, 32, menuSelectedIndex == 2 ? WHITE : GRAY);
}

void DrawCreationMenu(void)
{
    ClearBackground((Color){24, 24, 32, 255});
    DrawText("Creating a new level...", 12, 8, 32, WHITE);
    DrawText(levelName, 12, 60, 24, creationMenuSelectedIndex == 0 ? WHITE : GRAY);
    DrawText(TextFormat("Width: %d", levelWidth), 12, 100, 24, creationMenuSelectedIndex == 1 ? WHITE : GRAY);
    DrawText(TextFormat("Height: %d", levelHeight), 12, 140, 24, creationMenuSelectedIndex == 2 ? WHITE : GRAY);
    DrawText("Press ENTER to create the level", 12, 200, 20, SKYBLUE);
}

void DrawLevelSelectionMenu(void)
{
    ClearBackground((Color){24, 24, 32, 255});
    DrawText("Select a level to open", 12, 8, 32, WHITE);

    const int itemsPerPage = 10;
    int startY = 50;
    int lineHeight = 30;

    for (int i = scrollOffset; i < levelsFound && i < scrollOffset + itemsPerPage; i++)
    {
        int y = startY + (i - scrollOffset) * lineHeight;
        char displayName[256];
        strcpy(displayName, levelFileNames[i]);
        char *dot = strstr(displayName, ".csv");
        if (dot)
            *dot = '\0';

        Color color = (i == selectedLevelIndex) ? WHITE : GRAY;
        DrawText(displayName, 12, y, 24, color);
    }

    // Draw scroll indicators if needed
    if (scrollOffset > 0)
    {
        DrawText("^", VIRTUAL_SCREEN_WIDTH - 20, 20, 20, LIGHTGRAY);
    }
    if (scrollOffset + itemsPerPage < levelsFound)
    {
        DrawText("v", VIRTUAL_SCREEN_WIDTH - 20, VIRTUAL_SCREEN_HEIGHT - 40, 20, LIGHTGRAY);
    }

    DrawText(TextFormat("Levels found: %d", levelsFound), 200, VIRTUAL_SCREEN_HEIGHT - 20, 12, SKYBLUE);
}

void DrawEditor(void)
{
    ClearBackground((Color){24, 24, 32, 255});

    BeginMode2D(editorCamera);
    DrawEditorLayer();
    if (showGrid)
    {
        DrawEditorGrid();
    }
    DrawHoverHighlight();
    EndMode2D();

    DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, 44, (Color){0, 0, 0, 180});
    DrawText(TextFormat("Editing %s", levelName), 12, 6, 24, WHITE);
    DrawText(TextFormat("Tile: %d%s", selectedTile, selectedTile == 0 ? " (empty)" : ""), 12, 28, 12, LIGHTGRAY);

    if (selectedTile > 0 && editorTileset.id != 0)
    {
        int columns = editorTileset.width / TILE_SIZE;
        int rows = editorTileset.height / TILE_SIZE;
        if (columns > 0 && rows > 0)
        {
            int maxIndex = columns * rows;
            if (selectedTile > maxIndex)
            {
                selectedTile = maxIndex;
            }
            int index = selectedTile - 1;
            Rectangle src = {
                (float)((index % columns) * TILE_SIZE),
                (float)((index / columns) * TILE_SIZE),
                (float)TILE_SIZE,
                (float)TILE_SIZE};
            Rectangle dst = {
                (float)VIRTUAL_SCREEN_WIDTH - 44.0f,
                6.0f,
                32.0f,
                32.0f};
            DrawRectangleLines((int)dst.x - 4, (int)dst.y - 4, (int)dst.width + 8, (int)dst.height + 8, (Color){200, 200, 200, 200});
            DrawTexturePro(editorTileset, src, dst, (Vector2){0.0f, 0.0f}, 0.0f, WHITE);
        }
    }

    DrawRectangle(0, VIRTUAL_SCREEN_HEIGHT - 28, VIRTUAL_SCREEN_WIDTH, 28, (Color){0, 0, 0, 160});
    DrawText("WASD - MOVES, MOUSE - PLACEMENT, Q & E FOR TILES", 12, VIRTUAL_SCREEN_HEIGHT - 22, 12, LIGHTGRAY);

    if (saveMessageTimer > 0.0f)
    {
        DrawText(saveMessage, 12, VIRTUAL_SCREEN_HEIGHT - 40, 12, SKYBLUE);
    }
}

void LevelEditor_Draw(void)
{
    switch (editorState)
    {
    case LEVEL_EDITOR_MENU:
        DrawMenu();
        break;
    case LEVEL_EDITOR_EDITING:
        DrawEditor();
        break;
    case LEVEL_EDITOR_CREATING:
        DrawCreationMenu();
        break;
    case LEVEL_EDITOR_OPENING:
        DrawLevelSelectionMenu();
        break;
    }
}

void LevelEditor_Unload(void)
{
    FreeEditorLayer();
    if (editorTileset.id != 0)
    {
        UnloadTexture(editorTileset);
        editorTileset.id = 0;
    }
    totalTiles = 0;
    selectedTile = 0;
}

void DrawEditorLayer(void)
{
    if (!editorLayer)
        return;

    if (editorTileset.id != 0)
    {
        int columns = editorTileset.width / TILE_SIZE;
        int rows = editorTileset.height / TILE_SIZE;
        if (columns <= 0 || rows <= 0)
            return;
        int maxIndex = columns * rows;
        for (int y = 0; y < editorHeight; y++)
        {
            for (int x = 0; x < editorWidth; x++)
            {
                int tileId = editorLayer[y][x].tileId;
                if (tileId <= 0)
                    continue;

                int index = tileId - 1;
                if (index < 0 || index >= maxIndex)
                    continue;
                Rectangle src = {
                    (float)((index % columns) * TILE_SIZE),
                    (float)((index / columns) * TILE_SIZE),
                    (float)TILE_SIZE,
                    (float)TILE_SIZE};
                Rectangle dst = {
                    (float)(x * TILE_SIZE),
                    (float)(y * TILE_SIZE),
                    (float)TILE_SIZE,
                    (float)TILE_SIZE};
                DrawTexturePro(editorTileset, src, dst, (Vector2){0.0f, 0.0f}, 0.0f, WHITE);
            }
        }
    }
    else
    {
        for (int y = 0; y < editorHeight; y++)
        {
            for (int x = 0; x < editorWidth; x++)
            {
                Color c = editorLayer[y][x].tileId > 0 ? (Color){80, 140, 255, 255} : (Color){45, 45, 60, 255};
                DrawRectangle(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE, c);
            }
        }
    }
}

void DrawEditorGrid(void)
{
    Color lineColor = (Color){70, 70, 90, 120};
    for (int x = 0; x <= editorWidth; x++)
    {
        DrawLine(x * TILE_SIZE, 0, x * TILE_SIZE, editorHeight * TILE_SIZE, lineColor);
    }
    for (int y = 0; y <= editorHeight; y++)
    {
        DrawLine(0, y * TILE_SIZE, editorWidth * TILE_SIZE, y * TILE_SIZE, lineColor);
    }
}

void DrawHoverHighlight(void)
{
    if (hoverTileX < 0 || hoverTileY < 0)
        return;
    int px = hoverTileX * TILE_SIZE;
    int py = hoverTileY * TILE_SIZE;
    DrawRectangleLines(px, py, TILE_SIZE, TILE_SIZE, (Color){255, 255, 0, 160});
}

void SearchDirectoriesRecursive(const char *basePath, const char *currentPath)
{
    DIR *dir = opendir(currentPath);
    if (!dir)
        return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL)
    {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
            continue;

        char fullPath[512];
        snprintf(fullPath, sizeof(fullPath), "%s/%s", currentPath, entry->d_name);

        struct stat st;
        if (stat(fullPath, &st) == 0)
        {
            if (S_ISDIR(st.st_mode))
            {
                SearchDirectoriesRecursive(basePath, fullPath);
            }
            else if (S_ISREG(st.st_mode))
            {
                const char *ext = ".csv";
                size_t len = strlen(entry->d_name);
                if (len > strlen(ext) && strcmp(entry->d_name + len - strlen(ext), ext) == 0)
                {
                    char relPath[256] = {0};
                    if (strlen(currentPath) > strlen(basePath))
                    {
                        strcpy(relPath, currentPath + strlen(basePath));
                        if (relPath[0] == '/')
                            relPath[0] = '\0'; // remove leading /
                        if (strlen(relPath) > 0)
                            strcat(relPath, "/");
                        strcat(relPath, entry->d_name);
                    }
                    else
                    {
                        strcpy(relPath, entry->d_name);
                    }
                    if (levelsFound < MAX_LEVEL_FILES)
                    {
                        strcpy(levelFileNames[levelsFound], relPath);
                        levelsFound++;
                    }
                }
            }
        }
    }
    closedir(dir);
}

void SearchDirectories(const char *basePath)
{
    levelsFound = 0;
    selectedLevelIndex = 0;
    scrollOffset = 0;
    SearchDirectoriesRecursive(basePath, basePath);
}

void LoadLevelIntoEditor(const char *path)
{
    FreeEditorLayer();
    hoverTileX = -1;
    hoverTileY = -1;
    saveMessage[0] = '\0';
    saveMessageTimer = 0.0f;

    int loadedWidth = 0;
    int loadedHeight = 0;
    Tile **loadedLayer = LoadTileLayer(path, &loadedWidth, &loadedHeight);
    if (loadedLayer)
    {
        editorLayer = loadedLayer;
        editorWidth = loadedWidth;
        editorHeight = loadedHeight;
    }
    else
    {
        editorWidth = 64;
        editorHeight = 32;
        editorLayer = InitializeLayer(editorWidth, editorHeight);
    }

    if (editorTileset.id == 0)
    {
        editorTileset = LoadTexture("res/sprite/spritesheet/tileset/SPGSolidTileHeightCollision.png");
    }

    if (editorTileset.id != 0)
    {
        int columns = editorTileset.width / TILE_SIZE;
        int rows = editorTileset.height / TILE_SIZE;
        totalTiles = columns * rows;
    }
    else
    {
        totalTiles = 0;
    }

    cameraPos = (Vector2){0.0f, 0.0f};
    editorCamera.offset = (Vector2){0.0f, 0.0f};
    editorCamera.rotation = 0.0f;
    editorCamera.zoom = 1.0f;
    editorCamera.target = cameraPos;

    selectedTile = (totalTiles > 0) ? 1 : 0;
    showGrid = true;
}

void CreateNewLevel(const char *levelName, int width, int height)
{
    char path[512];
    snprintf(path, sizeof(path), "%s%s.csv", BASE_LEVEL_DIR, levelName);

    Tile **tempLayer = InitializeLayer(width, height);
    if (!tempLayer)
        return;

    FILE *file = fopen(path, "w");
    if (!file)
    {
        // Failed to create file
        for (int y = 0; y < height; y++)
            free(tempLayer[y]);
        free(tempLayer);
        return;
    }

    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            int value = tempLayer[y][x].tileId;
            fprintf(file, "%d", value);
            if (x < width - 1)
                fputc(',', file);
        }
        fputc('\n', file);
    }

    fclose(file);

    // Free temporary layer
    for (int y = 0; y < height; y++)
        free(tempLayer[y]);
    free(tempLayer);
}

void SaveLayerToCSV(const char *path)
{
    if (!editorLayer)
        return;

    FILE *file = fopen(path, "w");
    if (!file)
    {
        snprintf(saveMessage, sizeof(saveMessage), "Failed to save %s", path);
        saveMessageTimer = 3.0f;
        return;
    }

    for (int y = 0; y < editorHeight; y++)
    {
        for (int x = 0; x < editorWidth; x++)
        {
            int value = editorLayer[y][x].tileId;
            if (value < 0)
                value = -1;
            fprintf(file, "%d", value);
            if (x < editorWidth - 1)
            {
                fputc(',', file);
            }
        }
        fputc('\n', file);
    }

    fclose(file);
    snprintf(saveMessage, sizeof(saveMessage), "Saved to %s", path);
    saveMessageTimer = 3.0f;
}

void FreeEditorLayer(void)
{
    if (!editorLayer)
        return;
    for (int y = 0; y < editorHeight; y++)
    {
        free(editorLayer[y]);
    }
    free(editorLayer);
    editorLayer = NULL;
    editorWidth = 0;
    editorHeight = 0;
}
