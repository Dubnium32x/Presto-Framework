// Game camera header
#ifndef GAME_CAMERA_H
#define GAME_CAMERA_H

#include "raylib.h"

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

GameCamera GameCamera_Init(int xPos, int yPos, int tX, int tY, float zoom, float rot);
void MoveCamTo(GameCamera* cam, Vector2 newPos);

#endif // GAME_CAMERA_H
