// Animation Demo Screen
#include "anim_demo_screen.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "raylib.h"

#include "../world/screen_manager.h"
#include "../util/globals.h"
#include "../world/input.h"
#include "../sprite/animation_manager.h"
#include "../entity/player/animations/animations.h"

// Simple demo state
static Texture2D characterTexture = {0};
static PlayerAnimations playerAnims = {0};
static Animator playerAnimator = {0};

static Vector2 pos = { VIRTUAL_SCREEN_WIDTH/2.0f, VIRTUAL_SCREEN_HEIGHT/2.0f };
static float scale = 1.0f;
static int flip = 0;

// Static frames array to ensure persistence
static AnimationFrame testFrames[4] = {
    {0, 0.5f},  // Frame 0 for 0.5 seconds
    {1, 0.5f},  // Frame 1 for 0.5 seconds
    {2, 0.5f},  // Frame 2 for 0.5 seconds
    {3, 0.5f}   // Frame 3 for 0.5 seconds
};

// Helpers
static void ApplyWalkSequence(void) {
    playerAnimator.sequence.name = "FrameCycle";
    playerAnimator.sequence.sequenceType = ANIMATION_SEQUENCE_LOOP;
    playerAnimator.sequence.frameCount = 4;
    playerAnimator.sequence.frames = testFrames;
    playerAnimator.currentFrameIndex = 0;
    playerAnimator.currentFrame = &testFrames[0];
    playerAnimator.frameTimer = 0.0f;
    playerAnimator.speedMultiplier = 1.0f;
    playerAnimator.currentType = ANIMATION_SEQUENCE_LOOP;
    
    printf("[DEBUG] Sequence setup: frameCount=%d, first frame index=%d\n", 
           playerAnimator.sequence.frameCount, playerAnimator.currentFrame->frameIndex);
}

void AnimDemo_Init(void) {
    // Load a character spritesheet
    characterTexture = LoadTexture("res/sprite/spritesheet/character/Sonic_spritemap.png");
    if (characterTexture.id == 0) {
        printf("[AnimDemo] Failed to load character texture.\n");
    }

    // Initialize animation manager + animator
    InitAnimationManager(&playerAnims.animManager);
    playerAnims.animator = &playerAnimator;
    AddAnimator(&playerAnims.animManager, &playerAnimator);

    // Apply a default sequence
    ApplyWalkSequence();
}

void AnimDemo_Update(float deltaTime) {
    // Input: switch sequences quickly
    if (IsInputPressed(INPUT_LEFT)) { flip = !flip; }
    if (IsInputPressed(INPUT_UP)) { scale += 0.1f; }
    if (IsInputPressed(INPUT_DOWN)) { scale = fmaxf(0.5f, scale - 0.1f); }

    // Move with WASD or D-pad
    if (IsInputDown(INPUT_LEFT)) pos.x -= 80.0f * deltaTime;
    if (IsInputDown(INPUT_RIGHT)) pos.x += 80.0f * deltaTime;
    if (IsInputDown(INPUT_UP)) pos.y -= 80.0f * deltaTime;
    if (IsInputDown(INPUT_DOWN)) pos.y += 80.0f * deltaTime;

    // Update animation
    playerAnims.animManager.texture = characterTexture;
    UpdateAnimators(&playerAnims.animManager, deltaTime);
}

void AnimDemo_Draw(void) {
    ClearBackground(DARKBLUE);

    // Draw current frame
    if (characterTexture.id != 0 && playerAnimator.currentFrame) {
        int frameIndex = playerAnimator.currentFrame->frameIndex;
        Rectangle src = GetAnimationFrameRect(&playerAnims.animManager, frameIndex);
        Rectangle dst = { pos.x - src.width * scale / 2, pos.y - src.height * scale / 2, src.width * scale, src.height * scale };
        Vector2 origin = { src.width/2.0f, src.height/2.0f };
        if (flip) src.width = -src.width;
        DrawTexturePro(characterTexture, src, dst, origin, 0.0f, WHITE);
    } else {
        DrawText("No texture or frame", 10, 10, 10, YELLOW);
    }

    DrawText("Animation Demo: arrows to move, UP/DOWN to scale, LEFT to flip", 8, 8, 10, WHITE);
}

void AnimDemo_Unload(void) {
    if (characterTexture.id != 0) UnloadTexture(characterTexture);
    UnloadAllAnimators(&playerAnims.animManager);
}
