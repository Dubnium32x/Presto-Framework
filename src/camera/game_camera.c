// Game camera
#include "game_camera.h"
#include "../util/globals.h"
#include "raylib.h"

GameCamera GameCamera_Init(int xPos, int yPos, int tX, int tY, float zoom, float rot) {
    GameCamera camera;
    float scale = (float)VIRTUAL_SCREEN_WIDTH / 400.0f; // Base scale for 400p design

    camera.position = (Vector2){xPos, yPos};
    camera.targetPos = (Vector2){tX, tY};
    camera.zoom = zoom;
    camera.rotation = rot;

    camera.borders = (Vector2){144 * scale, 160 * scale}; // Horizontal and vertical borders
    camera.verticalFocalPoint = 96.0f * (float)(VIRTUAL_SCREEN_HEIGHT / 400.0f); // Vertical focal point
    camera.horizontalFocalPoint = 144.0f * scale; // Horizontal focal point

    camera.horizontalSpeedCap = 16.0f;
    camera.verticalSpeedCap = 16.0f;
    camera.defaultVerticalSpeedCap = 16.0f;

    camera.isLookingUp = false;
    camera.isLookingDown = false;
    camera.lockTimer = 0;
    camera.verticalShift = 0.0f;

    camera.extendedHorizontalShift = 0.0f;
    camera.extendedVerticalShift = 0.0f;
    camera.extendedCameraActive = false;

    camera.screenShakeIntensity = 0.0f;
    camera.screenShakeDuration = 0.0f;
    camera.screenShakeTimer = 0.0f;

    return camera;
}

void MoveCamTo(GameCamera* cam, Vector2 newPos) {
    cam->position.x = newPos.x;
    cam->position.y = newPos.y;
}
