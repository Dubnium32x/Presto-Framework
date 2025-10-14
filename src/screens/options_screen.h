#pragma once

// Options Screen header
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

// Option item structure
typedef struct {
    char key[64];
    char value[64];
    bool isBool;
} OptionItem;