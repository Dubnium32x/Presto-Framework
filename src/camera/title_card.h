// Title card camera header file
#ifndef TITLE_CARD_H
#define TITLE_CARD_H

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

// How will this be set up?
// So we want to have the ACT text be at the bottom right corner, with the act number to its right
// The side graphic will be on the left side, rotated 60 degrees counterclockwise. 
// The side graphic spikes will be aligned on top of the side graphic, rotated the same way.
// That said, the spikes will also be seamlessly tiled on top of the graphic, scrolling to the left over time.
// The zone name will be on top of the zoneRect, which will be rotating rapidly clockwise in the centerish right of the screen.

typedef enum {
    TITLE_CARD_STATE_INACTIVE,
    TITLE_CARD_STATE_ENTERING,
    TITLE_CARD_STATE_DISPLAY,
    TITLE_CARD_STATE_EXITING
} TitleCardState;

void TitleCardCamera_Init(void);
void TitleCardCamera_Update(float deltaTime);
void TitleCardCamera_Draw();
void TitleCardCamera_DrawBackFade();
void TitleCardCamera_DrawSideGraphic();
void TitleCardCamera_DrawSpikes(float deltaTime);
void TitleCardCamera_DrawText();
void TitleCardCamera_DrawFrontFade();
void TitleCardCamera_Unload(void);

#endif // TITLE_CARD_H
