// Game camera header
#ifndef GAME_CAMERA_H
#define GAME_CAMERA_H

#include "raylib.h"
#include "../util/globals.h"
#include "../entity/player/player.h"
#include "../world/tileset_map.h"
#include "../util/math_utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    Vector2 position;
    Vector2 targetPos;
    float zoom;
    float rotation;

    // SPG camera properties
    Vector2 borders;
    float verticalFocalPoint;
    float horizontalFocalPoint;

    // Camera movement speedcaps
    float horizontalSpeedCap;
    float verticalSpeedCap;
    float defaultVerticalSpeedCap;

    // Look up/down properties
    bool isLookingUp;
    bool isLookingDown;
    int lockTimer;
    float verticalShift;

    // Extended camera (CD only)
    float extendedHorizontalShift;
    float extendedVerticalShift;
    bool extendedCameraActive;

    // Screen shake
    float screenShakeIntensity;
    float screenShakeDuration;
    float screenShakeTimer;
} GameCamera;

void GameCamera_Init(GameCamera* camera);
void GameCamera_Update(GameCamera* camera, Player* player, float deltaTime);
void GameCamera_BeginMode(GameCamera* camera);
void GameCamera_EndMode(void);
void GameCamera_Shake(GameCamera* camera, float intensity, float duration);
void GameCamera_UpdateLookUpDown(GameCamera* camera, Player* player, bool inputUp, bool inputDown, float deltaTime);
void GameCamera_ProcessGenesisCamera(GameCamera* camera, Player* player, float deltaTime);
void GameCamera_ProcessCDCamera(GameCamera* camera, Player* player, float deltaTime);
void GameCamera_ProcessPocketCamera(GameCamera* camera, Player* player, float deltaTime);
Camera2D GetCamera2D(GameCamera* camera);

#endif // GAME_CAMERA_H