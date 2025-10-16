// Game camera
#include "game_camera.h"
#include "../util/globals.h"
#include "../util/math_utils.h"
#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void GameCamera_Init(GameCamera* camera) {
    float scale = (float)VIRTUAL_SCREEN_WIDTH / 400.0f; // Base scale for 400p design

    camera->position = (Vector2){0, 0};
    camera->targetPos = (Vector2){0, 0};
    camera->zoom = 1.0f;
    camera->rotation = 0.0f;

    camera->borders = (Vector2){144 * scale, 160 * scale}; // Horizontal and vertical borders
    camera->verticalFocalPoint = 96.0f * (float)(VIRTUAL_SCREEN_HEIGHT / 400.0f); // Vertical focal point
    camera->horizontalFocalPoint = 144.0f * scale; // Horizontal focal point

    camera->horizontalSpeedCap = 16.0f;
    camera->verticalSpeedCap = 16.0f;
    camera->defaultVerticalSpeedCap = 16.0f;

    camera->isLookingUp = false;
    camera->isLookingDown = false;
    camera->lockTimer = 0;
    camera->verticalShift = 0.0f;

    camera->extendedHorizontalShift = 0.0f;
    camera->extendedVerticalShift = 0.0f;
    camera->extendedCameraActive = false;

    camera->screenShakeIntensity = 0.0f;
    camera->screenShakeDuration = 0.0f;
    camera->screenShakeTimer = 0.0f;
}