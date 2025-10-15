// Player Animations
#include "animations.h"
#include "../var.h"
#include "../player.h"
#include <stdio.h>
#include <math.h>  
#include "../../util/math_utils.h"
#include "raylib.h"

void PlayerAnimations_SetTexture(PlayerAnimations* animations, Texture2D texture) {
    animations->animManager.texture = texture;
}

void PlayerAnimations_SetAnimationState(PlayerAnimations* animations, PlayerAnimationState newState) {
    if (animations->currentState == newState) {
        return; // No change
    }

    SetAnimationState(animations->animator, newState);
    animations->previousState = animations->currentState;
    animations->currentState = newState;
}

void PlayerAnimations_Update(PlayerAnimations* animations, float deltaTime) {
    UpdateAnimators(&animations->animManager, deltaTime);
    float debugTimer = 0.0f;
    debugTimer += deltaTime;
    if (debugTimer >= 1.0f) {
        debugTimer = 0.0f;
        // printf("Current Animation State: %d\n", animations->currentState);
    }
}

void PlayerAnimations_SetPlaybackMultiplier(PlayerAnimations* animations, float multiplier) {
    if (animations->animator != NULL) {
        animations->animator->speedMultiplier = multiplier;
    }
}

void PlayerAnimations_SetFrameTimer(PlayerAnimations* animations, float timer) {
    if (animations->animator != NULL) {
        animations->animator->frameTimer = timer;
    }
}

const char* PlayerAnimations_GetCurrentAnimation(PlayerAnimations* animations) {
    if (animations->animator != NULL && animations->animator->currentFrame != NULL) {
        return animations->animator->sequence.name;
    }
    return NULL;
}

void PlayerAnimations_SetPlayerAnimationState(PlayerAnimations* animations, PlayerAnimationState newState) {
    if (animations->currentState != newState) {
        return;
    }

    AnimationSequence sequence;

    switch (newState) {
        case ANIM_IDLE:
            sequence = (AnimationSequence){
                .name = "Idle",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 0, .duration = 0.2f },
                    { .frameIndex = 0, .duration = 0.2f }
                }
            };
            break;
        case ANIM_IMPATIENT_LOOK:
            sequence = (AnimationSequence){
                .name = "ImpatientLook",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 1, .duration = 0.2f },
                    { .frameIndex = 2, .duration = 0.2f }
                }
            };
            break;
        case ANIM_TIRED:
        case ANIM_IMPATIENT:
            sequence = (AnimationSequence){
                .name = "Impatient",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 3, .duration = 0.2f },
                    { .frameIndex = 4, .duration = 0.2f }
                }
            };
            break;
        case ANIM_IM_OUTTA_HERE_LOOK:
            sequence = (AnimationSequence){
                .name = "ImOuttaHereLook",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 104, .duration = 0.2f },
                    { .frameIndex = 105, .duration = 0.2f }
                }
            };
            break;
        case ANIM_IM_OUTTA_HERE:
            sequence = (AnimationSequence){
                .name = "ImOuttaHere",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 106, .duration = 0.2f },
                    { .frameIndex = 107, .duration = 0.2f }
                }
            };
            break;
        case ANIM_JUMP_OFF_SCREEN_1:
            sequence = (AnimationSequence){
                .name = "JumpOffScreen1",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 4,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 108, .duration = 0.1f },
                    { .frameIndex = 109, .duration = 0.1f },
                    { .frameIndex = 110, .duration = 0.1f },
                    { .frameIndex = 111, .duration = 0.1f }
                }
            };
            break;
        case ANIM_JUMP_OFF_SCREEN_2:
            sequence = (AnimationSequence){
                .name = "JumpOffScreen2",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 3,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 112, .duration = 0.1f },
                    { .frameIndex = 113, .duration = 0.1f },
                    { .frameIndex = 114, .duration = 0.1f }
                }
            };
            break;
        case ANIM_WALK:
            sequence = (AnimationSequence){
                .name = "Walk",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 8,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 5, .duration = 0.1f },
                    { .frameIndex = 6, .duration = 0.1f },
                    { .frameIndex = 7, .duration = 0.1f },
                    { .frameIndex = 8, .duration = 0.1f },
                    { .frameIndex = 9, .duration = 0.1f },
                    { .frameIndex = 10, .duration = 0.1f },
                    { .frameIndex = 11, .duration = 0.1f },
                    { .frameIndex = 12, .duration = 0.1f }
                }
            };
            break;
        case ANIM_RUN:
            sequence = (AnimationSequence){
                .name = "Run",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 4,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 20, .duration = 0.08f },
                    { .frameIndex = 21, .duration = 0.08f },
                    { .frameIndex = 22, .duration = 0.08f },
                    { .frameIndex = 23, .duration = 0.08f } 
                }
            };
            break;
        case ANIM_SKID:
            sequence = (AnimationSequence){
                .name = "Skid",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 46, .duration = 0.1f },
                    { .frameIndex = 47, .duration = 0.1f }  
                }
            };
            break;
        case ANIM_JUMP:
        case ANIM_ROLL:
        case ANIM_ROLL_FALL:
            sequence = (AnimationSequence){
                .name = "Jump",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 8,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 14, .duration = 0.1f },
                    { .frameIndex = 15, .duration = 0.1f },
                    { .frameIndex = 14, .duration = 0.1f },
                    { .frameIndex = 16, .duration = 0.1f },
                    { .frameIndex = 14, .duration = 0.1f },
                    { .frameIndex = 17, .duration = 0.1f },
                    { .frameIndex = 14, .duration = 0.1f },
                    { .frameIndex = 18, .duration = 0.1f }
                }
            };
            break;
        case ANIM_FALL:
            break; // This animation will play depending on horizontal speed
        case ANIM_CROUCH:
        case ANIM_LOOK_DOWN:
            sequence = (AnimationSequence){
                .name = "Crouch",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 1,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 66, .duration = 0.1f }
                }
            };
            break;
        case ANIM_LOOK_UP:
            sequence = (AnimationSequence){
                .name = "LookUp",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 1,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 19, .duration = 0.1f }
                }
            };
            break;
        case ANIM_PUSH:
            sequence = (AnimationSequence){
                .name = "Push",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 4,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 48, .duration = 0.1f },
                    { .frameIndex = 49, .duration = 0.1f },
                    { .frameIndex = 50, .duration = 0.1f },
                    { .frameIndex = 51, .duration = 0.1f }  
                }
            };
            break;
        case ANIM_DASH:
        case ANIM_PEELOUT_CHARGED:
            sequence = (AnimationSequence){
                .name = "Dash",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 4,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 24, .duration = 0.05f },
                    { .frameIndex = 25, .duration = 0.05f },
                    { .frameIndex = 26, .duration = 0.05f },
                    { .frameIndex = 27, .duration = 0.05f }  
                }
            };
            break;
        case ANIM_SPINDASH:
            sequence = (AnimationSequence){
                .name = "Spindash",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 10,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 28, .duration = 0.1f },
                    { .frameIndex = 29, .duration = 0.1f },
                    { .frameIndex = 30, .duration = 0.1f },
                    { .frameIndex = 31, .duration = 0.1f },
                    { .frameIndex = 32, .duration = 0.1f },
                    { .frameIndex = 33, .duration = 0.1f },
                    { .frameIndex = 34, .duration = 0.1f },
                    { .frameIndex = 35, .duration = 0.1f },
                    { .frameIndex = 36, .duration = 0.1f },
                    { .frameIndex = 37, .duration = 0.1f }
                }
            };
            break;
        case ANIM_PEELOUT:
            sequence = (AnimationSequence){
                .name = "Peelout",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 12,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 5, .duration = 0.05f },
                    { .frameIndex = 6, .duration = 0.05f },
                    { .frameIndex = 7, .duration = 0.05f },
                    { .frameIndex = 8, .duration = 0.05f },
                    { .frameIndex = 9, .duration = 0.05f },
                    { .frameIndex = 10, .duration = 0.05f },
                    { .frameIndex = 11, .duration = 0.05f },
                    { .frameIndex = 12, .duration = 0.05f },
                    { .frameIndex = 20, .duration = 0.05f },
                    { .frameIndex = 21, .duration = 0.05f },
                    { .frameIndex = 22, .duration = 0.05f },
                    { .frameIndex = 23, .duration = 0.05f }
                }
            };
            break;
        case ANIM_FLY:
            break; // Not implemented yet
        case ANIM_GLIDE:
            break; // Not implemented yet
        case ANIM_CLIMB:
            break; // Not implemented yet
        case ANIM_SWIM:
            break; // Not implemented yet
        case ANIM_MONKEYBARS:
            break; // Not implemented yet
        case ANIM_MONKEYBARS_MOVE:
            break; // Not implemented yet
        case ANIM_WALLJUMP:
            break; // Not implemented yet
        case ANIM_SLIDE:
            sequence = (AnimationSequence){
                .name = "Slide",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 88, .duration = 0.1f },
                    { .frameIndex = 89, .duration = 0.1f }  
                }
            };
            break;
        case ANIM_HURT:
            sequence = (AnimationSequence){
                .name = "Hurt",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 1,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 88, .duration = 0.1f }
                }
            };
            break;
        case ANIM_DEAD:
            sequence = (AnimationSequence){
                .name = "Dead",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 1,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 77, .duration = 0.1f }
                }
            };
            break;
        case ANIM_WOBBLE_FRONT:
            sequence = (AnimationSequence){
                .name = "WobbleFront",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 4,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 38, .duration = 0.1f },
                    { .frameIndex = 39, .duration = 0.1f },
                    { .frameIndex = 40, .duration = 0.1f },
                    { .frameIndex = 41, .duration = 0.1f }
                }
            };
            break;
        case ANIM_WOBBLE_BACK:
            sequence = (AnimationSequence){
                .name = "WobbleBack",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 4,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 42, .duration = 0.1f },
                    { .frameIndex = 43, .duration = 0.1f },
                    { .frameIndex = 44, .duration = 0.1f },
                    { .frameIndex = 45, .duration = 0.1f }
                }
            };
            break;
        case ANIM_SPRING_1:
            sequence = (AnimationSequence){
                .name = "Spring1",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 8,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 69, .duration = 0.1f },
                    { .frameIndex = 70, .duration = 0.1f },
                    { .frameIndex = 71, .duration = 0.1f },
                    { .frameIndex = 72, .duration = 0.1f },
                    { .frameIndex = 73, .duration = 0.1f },
                    { .frameIndex = 74, .duration = 0.1f },
                    { .frameIndex = 75, .duration = 0.1f },
                    { .frameIndex = 76, .duration = 0.1f }
                }
            };
            break;
        case ANIM_SPRING_2:
            sequence = (AnimationSequence){
                .name = "Spring2",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 67, .duration = 0.1f },
                    { .frameIndex = 68, .duration = 0.1f }
                }
            };
            break;
        case ANIM_BURN:
            break; // Not implemented yet
        case ANIM_DROWN:
            sequence = (AnimationSequence){
                .name = "Drown",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 1,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 78, .duration = 0.1f }
                }
            };
            break;
        case ANIM_FANSPIN:
        case ANIM_FANSPIN_FALL:
            sequence = (AnimationSequence){
                .name = "FanSpin",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 6,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 79, .duration = 0.1f },
                    { .frameIndex = 80, .duration = 0.1f },
                    { .frameIndex = 81, .duration = 0.1f },
                    { .frameIndex = 82, .duration = 0.1f },
                    { .frameIndex = 83, .duration = 0.1f },
                    { .frameIndex = 84, .duration = 0.1f }
                }
            };
            break;
        case ANIM_TAUNT:
            sequence = (AnimationSequence){
                .name = "Taunt",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 91, .duration = 0.2f },
                    { .frameIndex = 92, .duration = 0.2f }
                }
            };
            break;
        case ANIM_CELEBRATE:
            sequence = (AnimationSequence){
                .name = "Celebrate",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 2,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 102, .duration = 0.2f },
                    { .frameIndex = 103, .duration = 0.2f }
                }
            };
            break;
        case ANIM_SURPRISED:
            sequence = (AnimationSequence){
                .name = "Surprised",
                .sequenceType = ANIMATION_SEQUENCE_ONCE,
                .frameCount = 3,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 85, .duration = 0.2f },
                    { .frameIndex = 86, .duration = 0.2f },
                    { .frameIndex = 87, .duration = 0.2f }
                }
            };
            break;
        case ANIM_AIRBUBBLE:
            sequence = (AnimationSequence){
                .name = "AirBubble",
                .sequenceType = ANIMATION_SEQUENCE_LOOP,
                .frameCount = 1,
                .frames = (AnimationFrame[]) {
                    { .frameIndex = 90, .duration = 0.1f }
                }
            };
            break;
        default:
            // Unknown state, do nothing
            return;
    }
}

void PlayerAnimations_Render(PlayerAnimations* animations, Vector2 position, int flip, float scale, Color tint) {
    int frameIndex = animations->animator->currentFrame->frameIndex;

    Texture2D texture = animations->animManager.texture;
    auto frameRect = GetAnimationFrameRect(&animations->animManager, frameIndex);

    if (texture.id == 0) {
        // No texture set, cannot render
        return;
    } else if (texture.id != 0 && frameRect.width > 0 && frameRect.height > 0) {
        float destW = frameRect.width * scale;
        float destH = frameRect.height * scale;

        Rectangle destRect = (Rectangle){ position.x - destW / 2, position.y - destH / 2, destW, destH };
        Vector2 origin = (Vector2){ frameRect.width / 2, frameRect.height / 2 };                            

        Rectangle sourceRect = frameRect;
        if (flip) {
            sourceRect.width = -sourceRect.width; // Flip horizontally
        }

        DrawTexturePro(texture, sourceRect, destRect, origin, 0.0f, tint);
    } else {
        // Invalid frame, render placeholder
        float fallbackW = 32 * scale;
        float fallbackH = 32 * scale;
        Rectangle fallback = (Rectangle){ position.x - fallbackW / 2, position.y - fallbackH / 2, fallbackW, fallbackH };
        DrawRectangleRec(fallback, MAGENTA);
        DrawText("No Frame", position.x - 20, position.y - 5, 10, BLACK);
    }
}


