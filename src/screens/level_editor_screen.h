#pragma once

typedef enum
{
    LEVEL_EDITOR_EDITING,
    LEVEL_EDITOR_CREATING,
    LEVEL_EDITOR_OPENING,
    LEVEL_EDITOR_MENU
} LevelEditorState;

typedef struct
{
    char name[128];
    int width;
    int height;
} LevelEditorLevel;

typedef struct
{
    LevelEditorLevel *levels;
    int levelCount;
    int currentLevelIndex;
    LevelEditorState state;
} LevelEditorData;

void LevelEditor_Init(void);
void LevelEditor_Update(float deltaTime);
void LevelEditor_Draw(void);
void LevelEditor_Unload(void);
void LevelEditor_SearchDirectories(const char *basePath);

void FreeEditorLayer(void);
void SaveLayerToCSV(const char *path);
void DrawEditorLayer(void);
void DrawEditorGrid(void);
void DrawMenu(void);
void DrawEditor(void);
void DrawLevelSelectionMenu(void);
void DrawCreationMenu(void);
void DrawHoverHighlight(void);
void UpdateMenu(float deltaTime);
void UpdateLevelSelectionMenu(float deltaTime);
void UpdateCreationMenu(float deltaTime);
void UpdateEditor(float deltaTime);
void LoadLevelIntoEditor(const char *levelPath);
void CreateNewLevel(const char *levelName, int width, int height);
void SearchDirectories(const char *basePath);