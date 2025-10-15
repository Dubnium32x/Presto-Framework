// Animation Manager header
#ifndef ANIMATION_MANAGER_H
#define ANIMATION_MANAGER_H

#include "raylib.h"
#include "../entity/sprite_object.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ANIMATIONS 100
#define MAX_ANIMATION_NAME_LENGTH 64

typedef enum {
    ANIMATION_SEQUENCE_LOOP,
    ANIMATION_SEQUENCE_ONCE,
    ANIMATION_SEQUENCE_PINGPONG
} AnimationSequenceType;

typedef struct {
    int frameIndex;
    float duration;
} AnimationFrame;

typedef struct {
    const char* name;
    AnimationSequenceType sequenceType;
    int frameCount;
    AnimationFrame* frames;
} AnimationSequence;

typedef struct {
    AnimationSequence sequence;
    AnimationFrame *currentFrame;
    AnimationSequenceType currentType;
    int currentFrameIndex;
    float frameTimer;
    float speedMultiplier;
} Animator;


typedef enum {
    ANIMATION_MANAGER_UNINITIALIZED,
    ANIMATION_MANAGER_INITIALIZED
} AnimationManagerState;

typedef struct {
    Animator* animators[MAX_ANIMATIONS];
    size_t animatorCount;
    AnimationManagerState state;
    float frameTime;
    float elapsedTime;
    const char* animations;
    Texture2D texture;
} AnimationManager;

void InitAnimationManager(AnimationManager* manager);
void AddAnimator(AnimationManager* manager, Animator* animator);
void RemoveAnimator(AnimationManager* manager, const char* name);
void UpdateAnimators(AnimationManager* manager, float deltaTime);
void PlayAnimation(Animator* animator, const char* animationName);
void StopAnimation(Animator* animator);
void SetAnimationSpeed(Animator* animator, float speedMultiplier);
bool IsAnimationPlaying(const Animator* animator);
void UnloadAllAnimators(AnimationManager* manager);
void SetAnimationState(Animator* animator, AnimationSequenceType state);
AnimationSequence* GetAnimationByName(const char* name);
#endif // ANIMATION_MANAGER_H