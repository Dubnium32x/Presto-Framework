// Title card camera header file
#ifndef CAMERA_TITLE_CARD_H
#define CAMERA_TITLE_CARD_H

#include "raylib.h"

// Texture declarations (to be loaded in Init function)
extern Texture2D actText;
extern Texture2D act1Text;
extern Texture2D act2Text;
extern Texture2D act3Text;
extern Texture2D sideGraphicSpike;
extern Texture2D redSquareTexture;
extern Rectangle sideGraphicRect;
extern Rectangle zoneRect;

typedef enum {
    TITLE_CARD_STATE_INACTIVE,
    TITLE_CARD_STATE_ENTERING,
    TITLE_CARD_STATE_DISPLAY,
    TITLE_CARD_STATE_EXITING
} TitleCardState;

extern TitleCardState titleCardState;

void TitleCardCamera_Init(const char* zoneName, int actNumber);
void TitleCardCamera_Update(float deltaTime);
void TitleCardCamera_Draw();
void TitleCardCamera_DrawBackFade();
void TitleCardCamera_DrawSideGraphic();
void TitleCardCamera_DrawSpikes(float deltaTime);
void TitleCardCamera_DrawText();
void TitleCardCamera_DrawFrontFade();
void TitleCardCamera_Unload(void);

#endif // CAMERA_TITLE_CARD_H