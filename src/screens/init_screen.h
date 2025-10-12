// Init Screen header
#ifndef INIT_SCREEN_H
#define INIT_SCREEN_H

#include "raylib.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include "../world/screen_manager.h"

typedef enum InitScreenStateEnum {
    INIT_UNINITIALIZED,
    INIT_DISCLAIMER,
    INIT_SPLASH,
    INIT_DONE
} InitScreenStateEnum;

extern const char* disclaimerText;

extern Texture2D segaLogo;
extern Sound segaJingle;
extern bool disclaimerPlayer;
extern bool jinglePlayed;
extern float timer;
extern float disclaimerTimer;
extern float disclaimerDuration;
extern float fadeOutDuration;
extern float logoAnimateInTime;
extern float logoDisplayTime;
extern float disclaimerAlpha;
extern float logoScaleX;
extern float logoScaleY;
extern Vector2* logoPosition;
extern int backgroundColorModifier;

typedef enum {
    DISCLAIMER_FADE_IN,
    DISCLAIMER_DISPLAY,
    DISCLAIMER_FADE_OUT,
    LOGO_ANIMATE_IN,
    LOGO_DISPLAY,
    LOGO_FADE_OUT,
    PHASE_DONE
} InitScreenPhase;


extern InitScreenStateEnum* initState;
extern InitScreenPhase* currentPhase;

void InitScreen_Init(void);
void InitScreen_Update(float deltaTime);
void InitScreen_Draw(void);
void InitScreen_Unload(void);
#endif