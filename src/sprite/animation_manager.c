// Animation manager
#include "animation_manager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"
#include "../entity/sprite_object.h"

void InitAnimationManager(AnimationManager* manager) {
    if (manager == NULL) return;
    manager->animatorCount = 0;
    manager->state = ANIMATION_MANAGER_INITIALIZED;
    for (int i = 0; i < MAX_ANIMATIONS; i++) {
        manager->animators[i] = NULL;
    }
}

void AddAnimator(AnimationManager* manager, Animator* animator) {
    if (manager == NULL || animator == NULL) return;
    if (manager->animatorCount >= MAX_ANIMATIONS) {
        printf("Error: Maximum animator limit reached.\n");
        return;
    }
    manager->animators[manager->animatorCount++] = animator;
}

void RemoveAnimator(AnimationManager* manager, const char* name) {
    if (manager == NULL || name == NULL) return;
    for (size_t i = 0; i < manager->animatorCount; i++) {
        if (manager->animators[i] != NULL && strcmp(manager->animators[i]->sequence.name, name) == 0) {
            free(manager->animators[i]->sequence.frames);
            free(manager->animators[i]);
            manager->animators[i] = NULL;
            // Shift remaining animators
            for (size_t j = i; j < manager->animatorCount - 1; j++) {
                manager->animators[j] = manager->animators[j + 1];
            }
            manager->animators[--manager->animatorCount] = NULL;
            return;
        }
    }
    printf("Warning: Animator with name %s not found.\n", name);
}

void UpdateAnimators(AnimationManager* manager, float deltaTime) {
    if (manager == NULL) return;
    for (size_t i = 0; i < manager->animatorCount; i++) {
        Animator* animator = manager->animators[i];
        if (animator != NULL && animator->currentFrame != NULL) {
            animator->frameTimer += deltaTime * animator->speedMultiplier;
            if (animator->frameTimer >= animator->currentFrame->duration) {
                animator->frameTimer -= animator->currentFrame->duration;
                animator->currentFrameIndex++;
                if (animator->currentFrameIndex >= sizeof(animator->sequence.frames) / sizeof(animator->sequence.frames[0])) {
                    if (animator->sequence.sequenceType == ANIMATION_SEQUENCE_LOOP) {
                        animator->currentFrameIndex = 0;
                    } else if (animator->sequence.sequenceType == ANIMATION_SEQUENCE_ONCE) {
                        animator->currentFrameIndex = sizeof(animator->sequence.frames) / sizeof(animator->sequence.frames[0]) - 1; // Stay on last frame
                    } else if (animator->sequence.sequenceType == ANIMATION_SEQUENCE_PINGPONG) {
                        // Implement pingpong logic if needed
                    }
                }
                animator->currentFrame = &animator->sequence.frames[animator->currentFrameIndex];
            }
        }
    }
}

void PlayAnimation(Animator* animator, const char* animationName) {
    if (animator == NULL || animationName == NULL) return;
    if (strcmp(animator->sequence.name, animationName) == 0) {
        animator->currentFrameIndex = 0;
        animator->currentFrame = &animator->sequence.frames[0];
        animator->frameTimer = 0.0f;
    } else {
        printf("Warning: Animation %s not found in animator %s.\n", animationName, animator->sequence.name);
    }
}

void StopAnimation(Animator* animator) {
    if (animator == NULL) return;
    animator->currentFrame = NULL;
    animator->currentFrameIndex = 0;
    animator->frameTimer = 0.0f;
}

void SetAnimationSpeed(Animator* animator, float speedMultiplier) {
    if (animator == NULL) return;
    animator->speedMultiplier = speedMultiplier;
}

bool IsAnimationPlaying(const Animator* animator) {
    if (animator == NULL) return false;
    return animator->currentFrame != NULL;
}

void UnloadAllAnimators(AnimationManager* manager) {
    if (manager == NULL) return;
    for (size_t i = 0; i < manager->animatorCount; i++) {
        if (manager->animators[i] != NULL) {
            free(manager->animators[i]->sequence.frames);
            free(manager->animators[i]);
            manager->animators[i] = NULL;
        }
    }
    manager->animatorCount = 0;
}

void SetAnimationState(Animator* animator, AnimationSequenceType state) {
    if (animator == NULL) return;
    animator->currentType = state;
}

AnimationSequence* GetAnimationByName(const char* name) {
    // This function would typically search a global or passed-in list of animations.
    // For simplicity, we return NULL here.
    return NULL;
}

// Note: The above function is a placeholder. In a real implementation, you would have a collection of AnimationSequence objects to search through.