// Player animations header
#ifndef PLAYER_ANIMATIONS_H
#define PLAYER_ANIMATIONS_H

#include "../../../sprite/animation_manager.h"

typedef enum {
    ANIM_IDLE,
    ANIM_IMPATIENT_LOOK,
    ANIM_TIRED,
    ANIM_IMPATIENT,
    ANIM_IM_OUTTA_HERE_LOOK,
    ANIM_IM_OUTTA_HERE,
    ANIM_JUMP_OFF_SCREEN_1,
    ANIM_JUMP_OFF_SCREEN_2,
    ANIM_WALK,
    ANIM_CROUCH,
    ANIM_LOOK_UP,
    ANIM_SKID,
    ANIM_RUN,
    ANIM_DASH,
    ANIM_PUSH,
    ANIM_JUMP,
    ANIM_FALL,
    ANIM_ROLL,
    ANIM_ROLL_FALL,
    ANIM_SPINDASH,
    ANIM_PEELOUT,
    ANIM_PEELOUT_CHARGED,
    ANIM_FLY,
    ANIM_GLIDE,
    ANIM_CLIMB,
    ANIM_SWIM,
    ANIM_MONKEYBARS,
    ANIM_MONKEYBARS_MOVE,
    ANIM_WALLJUMP,
    ANIM_SLIDE,
    ANIM_AIRBUBBLE,
    ANIM_HURT,
    ANIM_DEAD,
    ANIM_LOOK_UP,
    ANIM_LOOK_DOWN,
    ANIM_WOBBLE_FRONT,
    ANIM_WOBBLE_BACK,
    ANIM_SPRING_1,
    ANIM_SPRING_2,
    ANIM_BURN,
    ANIM_DROWN,
    ANIM_FANSPIN,
    ANIM_FANSPIN_FALL,
    ANIM_TAUNT,
    ANIM_CELEBRATE,
    ANIM_SURPRISED
} PlayerAnimationState;

typedef struct {
    Animator* animator;
    AnimationManager animManager;

    PlayerAnimationState currentState;
    PlayerAnimationState previousState;
} PlayerAnimations;

void PlayerAnimations_SetTexture(PlayerAnimations* animations, Texture2D texture);
void PlayerAnimations_SetAnimationState(PlayerAnimations* animations, PlayerAnimationState newState);
void PlayerAnimations_Update(PlayerAnimations* animations, float deltaTime);
void PlayerAnimations_SetPlaybackMultiplier(PlayerAnimations* animations, float multiplier);
void PlayerAnimations_SetFrameTimer(PlayerAnimations* animations, float timer);
const char* PlayerAnimations_GetCurrentAnimation(PlayerAnimations* animations);
void PlayerAnimations_SetPlayerAnimationState(PlayerAnimations* animations, PlayerAnimationState newState);
void PlayerAnimations_Render(PlayerAnimations* animations, Vector2 position, int flip, float scale, Color tint);
Rectangle PlayerAnimations_GetCurrentFrameRect(PlayerAnimations* animations);

#endif // PLAYER_ANIMATIONS_H