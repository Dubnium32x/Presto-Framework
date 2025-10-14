#pragma once

// Title Screen header
void TitleScreen_Init(void);
void TitleScreen_Update(float deltaTime);
void TitleScreen_Draw(void);
void TitleScreen_Unload(void);

// Title screen states
typedef enum {
    TITLE_LOGO_FALLING,
    TITLE_LOGO_BOUNCING,
    TITLE_LOGO_BOUNCE_DELAY,  
    TITLE_MENU_ACTIVE,
    TITLE_TRANSITION_OUT,
    TITLE_EXITING
} TitleScreenState;