// Options Screen header
#pragma once

// Options screen lifecycle functions
void OptionsScreen_Init(void);
void OptionsScreen_Update(float deltaTime);
void OptionsScreen_Draw(void);
void OptionsScreen_Unload(void);

// Options screen states
typedef enum {
    OPTIONS_FADE_IN,
    OPTIONS_ACTIVE,
    OPTIONS_FADE_OUT
} OptionsScreenState;
