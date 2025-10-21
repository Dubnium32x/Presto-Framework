// Title card C file
#include "title_card.h"
#include "../util/globals.h"
#include "../util/math_utils.h"
#include "raylib.h"
#include "game_camera.h"
#include "hud.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SPINNING_RECT_SPEED 720.0f // Degrees per second
#define SIDE_GRAPHIC_ROTATION_ANGLE 45.0f // Degrees - 45 degree angle for better visual impact
#define SPIKE_SCROLL_SPEED 100.0f // Pixels per second
#define ACT_TEXT_SCALE 0.5
#define ACT_NUMBER_SCALE 0.75f

// Fade rectangle constants
#define FRONT_FADE_DURATION 1.0f // Immediate fade duration
#define BACK_FADE_DELAY 1.5f // Delay before back fade starts
#define BACK_FADE_DURATION 0.5f // Back fade duration (smoother)

// Texture definitions
Texture2D actText = {0};
Texture2D act1Text = {0};
Texture2D act2Text = {0};
Texture2D act3Text = {0};
Texture2D sideGraphicSpike = {0};
Texture2D redSquareTexture = {0};
Rectangle sideGraphicRect = {0, 0, 512, 128};
Rectangle zoneRect = {0, 0, 64, 64};
Rectangle blackFadeRect1 = { 0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT};
Rectangle blackFadeRect2 = { 0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT};

// Layout positioning based on sketch
const Vector2 sideGraphicStartPos = { -350.0f, VIRTUAL_SCREEN_HEIGHT - 120.0f }; // Start off-screen left, bottom area
const Vector2 spinningSquareStartPos = { VIRTUAL_SCREEN_WIDTH + 100.0f, VIRTUAL_SCREEN_HEIGHT / 2 - 32.0f };
const Vector2 zoneNameStartPos = { VIRTUAL_SCREEN_WIDTH / 2, 30.0f }; // Zone name at top center
const Vector2 zoneTextStartPos = { VIRTUAL_SCREEN_WIDTH / 2, VIRTUAL_SCREEN_HEIGHT / 2 - 10.0f }; // Main zone text center
const Vector2 actTextStartPos = { VIRTUAL_SCREEN_WIDTH - 150.0f, VIRTUAL_SCREEN_HEIGHT - 80.0f }; // ACT text bottom right
const Vector2 actNumberStartPos = { VIRTUAL_SCREEN_WIDTH - 80.0f, VIRTUAL_SCREEN_HEIGHT - 80.0f }; // Act number bottom right
const Vector2 spikeStartPos = { -350.0f, VIRTUAL_SCREEN_HEIGHT - 125.0f }; // Spikes on top of side graphic
float sideGraphicRotation = SIDE_GRAPHIC_ROTATION_ANGLE;
float spikeRotation = SIDE_GRAPHIC_ROTATION_ANGLE;
float spinningRectRotation = 0.0f;

Vector2 sideGraphicCurrentPos;
Vector2 spikeCurrentPos;
Vector2 spinningSquareCurrentPos;
Vector2 zoneNameCurrentPos;
Vector2 zoneTextCurrentPos;
Vector2 actTextCurrentPos;
Vector2 actNumberCurrentPos;

Vector2 sideGraphicTargetPos;
Vector2 spikeTargetPos;
Vector2 spinningSquareTargetPos;
Vector2 zoneNameTargetPos;
Vector2 zoneTextTargetPos;
Vector2 actTextTargetPos;
Vector2 actNumberTargetPos;

bool isTitleCardActive = false;
TitleCardState titleCardState = TITLE_CARD_STATE_INACTIVE;
static float timer = 0.0f;

// Fade rectangle variables
static float frontFadeAlpha = 255.0f; // Starts fully opaque
static float backFadeAlpha = 255.0f;  // Starts fully opaque

void TitleCardCamera_Init(void) {
    isTitleCardActive = true;
    titleCardState = TITLE_CARD_STATE_ENTERING;
    sideGraphicRotation = SIDE_GRAPHIC_ROTATION_ANGLE;
    spikeRotation = SIDE_GRAPHIC_ROTATION_ANGLE;
    spinningRectRotation = 0.0f;
    
    // Initialize fade rectangles
    frontFadeAlpha = 255.0f; // Start fully opaque
    backFadeAlpha = 255.0f;  // Start fully opaque

    // Load textures (try to load from files, fallback to placeholders)
    actText = LoadTexture("res/image/title_card/ACT.png");
    if (actText.id == 0) {
        Image actImg = GenImageColor(64, 32, WHITE);
        actText = LoadTextureFromImage(actImg);
        UnloadImage(actImg);
    }

    act1Text = LoadTexture("res/image/title_card/1.png");
    if (act1Text.id == 0) {
        Image act1Img = GenImageColor(32, 32, WHITE);
        act1Text = LoadTextureFromImage(act1Img);
        UnloadImage(act1Img);
    }

    act2Text = LoadTexture("res/image/title_card/2.png");
    if (act2Text.id == 0) {
        Image act2Img = GenImageColor(32, 32, WHITE);
        act2Text = LoadTextureFromImage(act2Img);
        UnloadImage(act2Img);
    }

    act3Text = LoadTexture("res/image/title_card/3.png");
    if (act3Text.id == 0) {
        Image act3Img = GenImageColor(32, 32, WHITE);
        act3Text = LoadTextureFromImage(act3Img);
        UnloadImage(act3Img);
    }

    // Load actual spike texture (12x36), fallback to generated if not found
    sideGraphicSpike = LoadTexture("res/image/title_card/side_graphic_spike.png");
    if (sideGraphicSpike.id == 0) {
        // Fallback: generate 12x36 red spike texture
        Image spikeImg = GenImageColor(12, 36, WHITE);
        sideGraphicSpike = LoadTextureFromImage(spikeImg);
        UnloadImage(spikeImg);
    }
    
    // Create red rectangle texture for background (wider to ensure both corners are off-screen)
    Image redSquareImg = GenImageColor(300, 120, (Color){ 255, 0, 0, 255 });
    redSquareTexture = LoadTextureFromImage(redSquareImg);
    UnloadImage(redSquareImg);

    sideGraphicCurrentPos = sideGraphicStartPos;
    spikeCurrentPos = spikeStartPos;
    spinningSquareCurrentPos = spinningSquareStartPos;
    zoneNameCurrentPos = zoneNameStartPos;
    zoneTextCurrentPos = zoneTextStartPos;
    actTextCurrentPos = actTextStartPos;
    actNumberCurrentPos = actNumberStartPos;

    // Final positions based on sketch layout
    sideGraphicTargetPos = (Vector2){ -0.0f, VIRTUAL_SCREEN_HEIGHT - 120.0f }; // Extend beyond both edges to hide corners
    spikeTargetPos = (Vector2){ -12.0f, VIRTUAL_SCREEN_HEIGHT - 125.0f }; // Spikes on top of side graphic
    spinningSquareTargetPos = (Vector2){ VIRTUAL_SCREEN_WIDTH - 120.0f, VIRTUAL_SCREEN_HEIGHT / 2 - 32.0f }; // Right side spinning square
    zoneNameTargetPos = (Vector2){ VIRTUAL_SCREEN_WIDTH / 2, 30.0f }; // Zone name at top
    zoneTextTargetPos = (Vector2){ VIRTUAL_SCREEN_WIDTH / 2, VIRTUAL_SCREEN_HEIGHT / 2 - 10.0f }; // Main zone text center
    actTextTargetPos = (Vector2){ VIRTUAL_SCREEN_WIDTH - 100.0f, VIRTUAL_SCREEN_HEIGHT - 80.0f }; // ACT bottom right
    actNumberTargetPos = (Vector2){ VIRTUAL_SCREEN_WIDTH - 50.0f, VIRTUAL_SCREEN_HEIGHT - 80.0f }; // Number bottom right
}

void TitleCardCamera_Update(float deltaTime) {
    if (titleCardState == TITLE_CARD_STATE_INACTIVE) return;

    // Update fade rectangles
    timer += deltaTime;
    
    // Update front fade (fades out immediately)
    if (frontFadeAlpha > 0.0f) {
        frontFadeAlpha -= (255.0f / FRONT_FADE_DURATION) * deltaTime;
        if (frontFadeAlpha < 0.0f) frontFadeAlpha = 0.0f;
    }
    
    // Update back fade (fades out after delay)
    if (timer > BACK_FADE_DELAY && backFadeAlpha > 0.0f) {
        backFadeAlpha -= (255.0f / BACK_FADE_DURATION) * deltaTime;
        if (backFadeAlpha < 0.0f) backFadeAlpha = 0.0f;
    }

    // Update spinning rectangle rotation
    spinningRectRotation += SPINNING_RECT_SPEED * deltaTime;
    if (spinningRectRotation >= 360.0f) {
        spinningRectRotation -= 360.0f;
    }

    // Update title card state machine
    switch (titleCardState) {
        case TITLE_CARD_STATE_INACTIVE:
            titleCardState = TITLE_CARD_STATE_ENTERING;
            break;
        case TITLE_CARD_STATE_ENTERING:
            // Handle target position updates here
            sideGraphicCurrentPos = LerpV2(sideGraphicCurrentPos, sideGraphicTargetPos, deltaTime * 3.0f);
            spikeCurrentPos = LerpV2(spikeCurrentPos, spikeTargetPos, deltaTime * 3.0f);
            spinningSquareCurrentPos = LerpV2(spinningSquareCurrentPos, spinningSquareTargetPos, deltaTime * 2.5f);
            zoneNameCurrentPos = LerpV2(zoneNameCurrentPos, zoneNameTargetPos, deltaTime * 4.0f);
            zoneTextCurrentPos = LerpV2(zoneTextCurrentPos, zoneTextTargetPos, deltaTime * 3.5f);
            actTextCurrentPos = LerpV2(actTextCurrentPos, actTextTargetPos, deltaTime * 2.0f);
            actNumberCurrentPos = LerpV2(actNumberCurrentPos, actNumberTargetPos, deltaTime * 2.0f);

            // Check if elements are mostly in position to transition to display state
            float totalDistance = Vector2Length(Vector2Subtract(sideGraphicCurrentPos, sideGraphicTargetPos)) +
                                 Vector2Length(Vector2Subtract(spinningSquareCurrentPos, spinningSquareTargetPos)) +
                                 Vector2Length(Vector2Subtract(zoneTextCurrentPos, zoneTextTargetPos));
            
            if (totalDistance < 10.0f) { // Elements are close enough to target positions
                titleCardState = TITLE_CARD_STATE_DISPLAY;
                timer = 0.0f; // Reset timer for display duration
            }
            break;
        case TITLE_CARD_STATE_DISPLAY:
            // Hold the title card for 3 seconds
            timer += deltaTime;
            if (timer >= 3.0f) {
                titleCardState = TITLE_CARD_STATE_EXITING;
                timer = 0.0f; // Reset timer for exit animation
            }
            break;
        case TITLE_CARD_STATE_EXITING:
            // Animate elements out of the screen
            Vector2 exitSideGraphicPos = {-400.0f, sideGraphicTargetPos.y};
            Vector2 exitSpinningSquarePos = {VIRTUAL_SCREEN_WIDTH + 200.0f, spinningSquareTargetPos.y};
            Vector2 exitZoneTextPos = {VIRTUAL_SCREEN_WIDTH / 2, -50.0f};
            
            sideGraphicCurrentPos = LerpV2(sideGraphicCurrentPos, exitSideGraphicPos, deltaTime * 4.0f);
            spikeCurrentPos = LerpV2(spikeCurrentPos, exitSideGraphicPos, deltaTime * 4.0f);
            spinningSquareCurrentPos = LerpV2(spinningSquareCurrentPos, exitSpinningSquarePos, deltaTime * 4.0f);
            zoneNameCurrentPos = LerpV2(zoneNameCurrentPos, exitZoneTextPos, deltaTime * 5.0f);
            zoneTextCurrentPos = LerpV2(zoneTextCurrentPos, exitZoneTextPos, deltaTime * 4.5f);
            actTextCurrentPos = LerpV2(actTextCurrentPos, (Vector2){VIRTUAL_SCREEN_WIDTH + 100.0f, actTextTargetPos.y}, deltaTime * 3.0f);
            actNumberCurrentPos = LerpV2(actNumberCurrentPos, (Vector2){VIRTUAL_SCREEN_WIDTH + 120.0f, actNumberTargetPos.y}, deltaTime * 3.0f);
            
            timer += deltaTime;
            if (timer >= 1.5f) { // Exit animation duration
                titleCardState = TITLE_CARD_STATE_INACTIVE;
                isTitleCardActive = false;
            }
            break;
        default:
            break;
    }
}

void TitleCardCamera_Draw(void) {
    if (titleCardState == TITLE_CARD_STATE_INACTIVE) return;

    // Draw red rectangle background (extends beyond screen edges, rotated)
    Rectangle redSquareSource = { 0, 0, 300, 120 };
    Rectangle redSquareDest = { 
        sideGraphicCurrentPos.x, 
        sideGraphicCurrentPos.y, 
        300, 120 
    };
    Vector2 redSquareOrigin = { 0, 0 }; // Rotate from top-left corner
    
    // Draw red rectangle background
    DrawTexturePro(redSquareTexture, redSquareSource, redSquareDest, 
                   redSquareOrigin, sideGraphicRotation, WHITE);

    // Draw spinning square (right side)
    Rectangle spinningSquareSource = { 0, 0, 64, 64 };
    Rectangle spinningSquareDest = { 
        spinningSquareCurrentPos.x, 
        spinningSquareCurrentPos.y, 
        64, 64 
    };
    Vector2 spinningSquareOrigin = { 32, 32 }; // Center rotation
    
    // Draw spinning square as a colored rectangle (since we don't have a texture)
    DrawRectanglePro(spinningSquareDest, spinningSquareOrigin, spinningRectRotation, BLUE);

    // Draw zone name at top (placeholder text for now)
    const char* zoneName = "Zone Name";
    int zoneNameWidth = MeasureText(zoneName, 20);
    DrawText(zoneName, 
             (int)(zoneNameCurrentPos.x - zoneNameWidth/2), 
             (int)zoneNameCurrentPos.y, 
             20, WHITE);

    // Draw main zone text (center)
    const char* zoneText = "ATLANTIC HEIGHTS";
    int zoneTextWidth = MeasureText(zoneText, 24);
    DrawText(zoneText, 
             (int)(zoneTextCurrentPos.x - zoneTextWidth/2), 
             (int)zoneTextCurrentPos.y, 
             24, YELLOW);

    // Draw ACT texture (bottom right)
    if (actText.id != 0) {
        Rectangle actSrc = { 0, 0, (float)actText.width, (float)actText.height };
        Rectangle actDest = { 
            actTextCurrentPos.x, 
            actTextCurrentPos.y, 
            actText.width * ACT_TEXT_SCALE, 
            actText.height * ACT_TEXT_SCALE 
        };
        DrawTexturePro(actText, actSrc, actDest, (Vector2){0, 0}, 0.0f, WHITE);
    }

    // Draw Act Number texture (bottom right, next to ACT)
    if (act1Text.id != 0) {
        Rectangle actNumSrc = { 0, 0, (float)act1Text.width, (float)act1Text.height };
        Rectangle actNumDest = { 
            actNumberCurrentPos.x, 
            actNumberCurrentPos.y, 
            act1Text.width * ACT_NUMBER_SCALE, 
            act1Text.height * ACT_NUMBER_SCALE 
        };
        DrawTexturePro(act1Text, actNumSrc, actNumDest, (Vector2){0, 0}, 0.0f, WHITE);
    }
             
    // Draw animated spikes on top of side graphic
    TitleCardCamera_DrawSpikes(GetFrameTime());
}

void TitleCardCamera_DrawSpikes(float deltaTime) {
    if (titleCardState == TITLE_CARD_STATE_INACTIVE) return;
    
    // Draw scrolling spikes on top of the red rectangle
    static float spikeScrollOffset = 0.0f;
    spikeScrollOffset += SPIKE_SCROLL_SPEED * deltaTime;
    
    // Reset offset when it gets too large (using actual spike width 36)
    if (spikeScrollOffset >= 36.0f) {
        spikeScrollOffset -= 36.0f;
    }
    
    // Calculate offset for spikes to sit on the top surface of the rotated rectangle
    // At 45 degrees, we need to move spikes up and right to sit on the angled top surface
    float angleRad = sideGraphicRotation * PI / 180.0f;
    float offsetX = cosf(angleRad) * 10.0f; // Small offset to position on top surface
    float offsetY = -sinf(angleRad) * 10.0f; // Negative to move up
    
    // Calculate diagonal scroll vector components for 45-degree movement
    float scrollX = cosf(angleRad) * spikeScrollOffset; // Horizontal component of diagonal scroll
    float scrollY = sinf(angleRad) * spikeScrollOffset; // Vertical component of diagonal scroll
    
    // Draw multiple 36x12 spike tiles along the diagonal line of the rectangle
    for (int i = -1; i <= 10; i++) { // Cover diagonal distance with spikes
        Rectangle spikeSource = { 0, 0, 36, 12 }; // Correct dimensions: 36 wide x 12 high
        
        // Position each spike along the diagonal line of the rectangle's edge
        float diagonalSpacing = i * 36; // Distance along the diagonal
        float spikeX = spikeCurrentPos.x + cosf(angleRad) * diagonalSpacing - scrollX + offsetX;
        float spikeY = spikeCurrentPos.y + sinf(angleRad) * diagonalSpacing - scrollY + offsetY;
        
        Rectangle spikeDest = { 
            spikeX, 
            spikeY, 
            36, 12 
        };
        Vector2 spikeOrigin = { 18, 6 }; // Center rotation point for 36x12
        
        // Draw spikes rotated to match the red rectangle rotation
        DrawTexturePro(sideGraphicSpike, spikeSource, spikeDest, 
                       spikeOrigin, sideGraphicRotation, WHITE);
    }
}

void TitleCardCamera_DrawBackFade() {
    if (titleCardState == TITLE_CARD_STATE_INACTIVE) return;
    
    // Draw back fade rectangle (behind all title card elements)
    if (backFadeAlpha > 0.0f) {
        Color fadeColor = { 0, 0, 0, (float)backFadeAlpha };
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, fadeColor);
    }
}

void TitleCardCamera_DrawFrontFade() {
    if (titleCardState == TITLE_CARD_STATE_INACTIVE) return;
    
    // Draw front fade rectangle (on top of everything)
    if (frontFadeAlpha > 0.0f) {
        Color fadeColor = { 0, 0, 0, (unsigned char)frontFadeAlpha };
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, fadeColor);
    }
}

void TitleCardCamera_Unload(void) {
    // Unload textures
    if (actText.id != 0) UnloadTexture(actText);
    if (act1Text.id != 0) UnloadTexture(act1Text);
    if (act2Text.id != 0) UnloadTexture(act2Text);
    if (act3Text.id != 0) UnloadTexture(act3Text);
    if (sideGraphicSpike.id != 0) UnloadTexture(sideGraphicSpike);
    if (redSquareTexture.id != 0) UnloadTexture(redSquareTexture);
    
    isTitleCardActive = false;
    titleCardState = TITLE_CARD_STATE_INACTIVE;
}