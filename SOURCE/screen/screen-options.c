// Options Screen implementation
#include "screen-options.h"
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"
#include "../util/util-global.h"
#include "../data/data-root.h"
#include "../managers/managers-screen_settings.h"

#define MAX_OPTIONS 20
#define VISIBLE_OPTIONS 8

// Options screen variables
static OptionsScreenState optionsState = OPTIONS_FADE_IN;
static float transitionAlpha = 255.0f;
static float transitionDuration = 0.6f;
static float transitionTimer = 0.0f;
static float inputRepeatTimer = 0.0f;
static float inputRepeatDelay = 0.12f;
static float lrRepeatTimer = 0.0f;
static float lrRepeatDelay = 0.12f;

static OptionItem options[MAX_OPTIONS];
static int optionCount = 0;
static int selectedOption = 0;
static int cameraOffset = 0;

static bool showFullscreenNote = false;
static float fullscreenNoteTimer = 0.0f;

// Sound effects
static Sound moveSound = {0};
static Sound acceptSound = {0};
static Sound backSound = {0};

// Helper functions for options management
void LoadOptionsData(void) {
    optionCount = 0;
    // Load options from file into g_Options
    LoadOptions(g_OptionsFilePath);

    // Music volume
    strcpy(options[optionCount].key, "musicVolume");
    snprintf(options[optionCount].value, sizeof(options[optionCount].value), "%d", g_Options.musicVolume);
    options[optionCount].isBool = false;
    optionCount++;

    // SFX volume
    strcpy(options[optionCount].key, "sfxVolume");
    snprintf(options[optionCount].value, sizeof(options[optionCount].value), "%d", g_Options.sfxVolume);
    options[optionCount].isBool = false;
    optionCount++;

    // Fullscreen
    strcpy(options[optionCount].key, "fullscreen");
    strcpy(options[optionCount].value, g_Options.fullscreen ? "true" : "false");
    options[optionCount].isBool = true;
    optionCount++;

    // Screen size
    strcpy(options[optionCount].key, "screenSize");
    snprintf(options[optionCount].value, sizeof(options[optionCount].value), "%zu", g_Options.screenSize);
    options[optionCount].isBool = false;
    optionCount++;

    // VSync
    strcpy(options[optionCount].key, "vsync");
    strcpy(options[optionCount].value, g_Options.vsync ? "true" : "false");
    options[optionCount].isBool = true;
    optionCount++;

    // Show FPS
    strcpy(options[optionCount].key, "showFPS");
    strcpy(options[optionCount].value, g_Options.showFPS ? "true" : "false");
    options[optionCount].isBool = true;
    optionCount++;

    // Dropdash
    strcpy(options[optionCount].key, "dropdashEnabled");
    strcpy(options[optionCount].value, g_Options.dropdashEnabled ? "true" : "false");
    options[optionCount].isBool = true;
    optionCount++;

    // Insta Shield
    strcpy(options[optionCount].key, "instaShieldEnabled");
    strcpy(options[optionCount].value, g_Options.instaShieldEnabled ? "true" : "false");
    options[optionCount].isBool = true;
    optionCount++;

    // Peelout
    strcpy(options[optionCount].key, "peeloutEnabled");
    strcpy(options[optionCount].value, g_Options.peeloutEnabled ? "true" : "false");
    options[optionCount].isBool = true;
    optionCount++;

    // Camera type
    strcpy(options[optionCount].key, "cameraType");
    switch (g_Options.cameraType) {
        case CAMERA_GENESIS: strcpy(options[optionCount].value, "GENESIS"); break;
        case CAMERA_CD: strcpy(options[optionCount].value, "CD"); break;
        case CAMERA_POCKET: strcpy(options[optionCount].value, "POCKET"); break;
        default: strcpy(options[optionCount].value, "GENESIS"); break;
    }
    options[optionCount].isBool = false;
    optionCount++;
}

void SaveOptionsData(void) {
    for (int i = 0; i < optionCount; i++) {
        if (strcmp(options[i].key, "musicVolume") == 0) {
            g_Options.musicVolume = (uint8_t)atoi(options[i].value);
        } else if (strcmp(options[i].key, "sfxVolume") == 0) {
            g_Options.sfxVolume = (uint8_t)atoi(options[i].value);
        } else if (strcmp(options[i].key, "fullscreen") == 0) {
            g_Options.fullscreen = (strcmp(options[i].value, "true") == 0);
        } else if (strcmp(options[i].key, "screenSize") == 0) {
            g_Options.screenSize = (size_t)atoi(options[i].value);
        } else if (strcmp(options[i].key, "vsync") == 0) {
            g_Options.vsync = (strcmp(options[i].value, "true") == 0);
        } else if (strcmp(options[i].key, "showFPS") == 0) {
            g_Options.showFPS = (strcmp(options[i].value, "true") == 0);
        } else if (strcmp(options[i].key, "dropdashEnabled") == 0) {
            g_Options.dropdashEnabled = (strcmp(options[i].value, "true") == 0);
        } else if (strcmp(options[i].key, "instaShieldEnabled") == 0) {
            g_Options.instaShieldEnabled = (strcmp(options[i].value, "true") == 0);
        } else if (strcmp(options[i].key, "peeloutEnabled") == 0) {
            g_Options.peeloutEnabled = (strcmp(options[i].value, "true") == 0);
        } else if (strcmp(options[i].key, "cameraType") == 0) {
            if (strcmp(options[i].value, "GENESIS") == 0) g_Options.cameraType = CAMERA_GENESIS;
            else if (strcmp(options[i].value, "CD") == 0) g_Options.cameraType = CAMERA_CD;
            else if (strcmp(options[i].value, "POCKET") == 0) g_Options.cameraType = CAMERA_POCKET;
        }
    }
    SaveOptions(g_OptionsFilePath);
}

void ApplyCurrentOptions(void) {
    // Simple function for startup initialization
    // The actual options application is now handled directly in toggle functions
}

static void ToggleOption(int index) {
    if (!options[index].isBool) return;

    // Toggle the value in the display array
    if (strcmp(options[index].value, "true") == 0) {
        strcpy(options[index].value, "false");
    } else {
        strcpy(options[index].value, "true");
    }

    // Update the underlying struct and file
    SaveOptionsData();

    // Reload display from g_Options to ensure sync
    LoadOptionsData();

    // Apply special handling for specific options
    const char* key = options[index].key;
    if (strcmp(key, "fullscreen") == 0) {
        if (g_Options.fullscreen && !IsWindowFullscreen()) {
            ToggleFullscreen();
        } else if (!g_Options.fullscreen && IsWindowFullscreen()) {
            ToggleFullscreen();
        }
    }
}

static void CycleOption(int index, bool left) {
    if (strcmp(options[index].key, "cameraType") == 0) {
        if (strcmp(options[index].value, "GENESIS") == 0) {
            strcpy(options[index].value, left ? "POCKET" : "CD");
        } else if (strcmp(options[index].value, "CD") == 0) {
            strcpy(options[index].value, left ? "GENESIS" : "POCKET");
        } else if (strcmp(options[index].value, "POCKET") == 0) {
            strcpy(options[index].value, left ? "CD" : "GENESIS");
        }
        SaveOptionsData();
        printf("Camera Type: %s\n", options[index].value);
    } else if (strcmp(options[index].key, "screenSize") == 0) {
        size_t size = (size_t)atoi(options[index].value);
        if (left) size = (size <= 1) ? 4 : size - 1;
        else size = (size >= 4) ? 1 : size + 1;
        snprintf(options[index].value, sizeof(options[index].value), "%zu", size);
        SaveOptionsData();
        
        // Apply screen size immediately if not fullscreen
        if (!IsWindowFullscreen()) {
            int actualWidth = VIRTUAL_SCREEN_WIDTH * (int)size;
            int actualHeight = VIRTUAL_SCREEN_HEIGHT * (int)size;
            SetWindowSize(actualWidth, actualHeight);
            SetWindowPosition((GetMonitorWidth(0) - actualWidth) / 2, (GetMonitorHeight(0) - actualHeight) / 2);
        }
        printf("Screen Size: %zu\n", size);
    } else if (strcmp(options[index].key, "musicVolume") == 0) {
        int volume = atoi(options[index].value);
        if (left) volume = (volume <= 0) ? 0 : volume - 5;
        else volume = (volume >= 100) ? 100 : volume + 5;
        snprintf(options[index].value, sizeof(options[index].value), "%d", volume);
        SaveOptionsData();
        printf("Music Volume: %d\n", volume);
    } else if (strcmp(options[index].key, "sfxVolume") == 0) {
        int volume = atoi(options[index].value);
        if (left) volume = (volume <= 0) ? 0 : volume - 5;
        else volume = (volume >= 100) ? 100 : volume + 5;
        snprintf(options[index].value, sizeof(options[index].value), "%d", volume);
        SaveOptionsData();
        printf("SFX Volume: %d\n", volume);
    }
    LoadOptionsData();
}

void OptionsScreen_Init(void) {
    // Load sounds
    moveSound = LoadSound("RESOURCES/sound/sfx/Sonic World Sounds/004.wav");
    acceptSound = LoadSound("RESOURCES/sound/sfx/Sonic World Sounds/022.wav");
    backSound = LoadSound("RESOURCES/sound/sfx/Sonic World Sounds/002.wav");

    // Reset state
    optionsState = OPTIONS_FADE_IN;
    transitionAlpha = 255.0f;
    transitionTimer = 0.0f;
    selectedOption = 0;
    cameraOffset = 0;
    showFullscreenNote = false;

    // Load options from file and populate options array
    LoadOptionsData();
}

void OptionsScreen_Update(float deltaTime) {
    switch (optionsState) {
        case OPTIONS_FADE_IN:
            transitionTimer += deltaTime;
            transitionAlpha = 255.0f - (transitionTimer / transitionDuration) * 255.0f;
            if (transitionAlpha < 0.0f) transitionAlpha = 0.0f;
            if (transitionTimer >= transitionDuration) {
                optionsState = OPTIONS_ACTIVE;
                transitionAlpha = 0.0f;
                inputRepeatTimer = 0.0f;
            }
            break;
        case OPTIONS_ACTIVE:
            inputRepeatTimer += deltaTime;
            lrRepeatTimer += deltaTime;
            bool moved = false;
            if ((IsKeyDown(KEY_DOWN) || IsInputDown(INPUT_DOWN)) && inputRepeatTimer > inputRepeatDelay) {
                selectedOption = (selectedOption + 1) % optionCount;
                if (moveSound.frameCount > 0) PlaySound(moveSound);
                inputRepeatTimer = 0.0f;
                moved = true;
            } else if ((IsKeyDown(KEY_UP) || IsInputDown(INPUT_UP)) && inputRepeatTimer > inputRepeatDelay) {
                selectedOption = (selectedOption - 1 + optionCount) % optionCount;
                if (moveSound.frameCount > 0) PlaySound(moveSound);
                inputRepeatTimer = 0.0f;
                moved = true;
            }
            if (!moved && !(IsKeyDown(KEY_UP) || IsKeyDown(KEY_DOWN) || IsInputDown(INPUT_UP) || IsInputDown(INPUT_DOWN))) {
                inputRepeatTimer = inputRepeatDelay;
            }

            // Toggle boolean option
            if (IsKeyPressed(KEY_ENTER) || IsKeyPressed(KEY_SPACE) || IsInputPressed(INPUT_A)) {
                if (acceptSound.frameCount > 0) PlaySound(acceptSound);
                ToggleOption(selectedOption);
            }

            // Cycle left/right for non-bool options
            bool lrMoved = false;
            if ((IsKeyDown(KEY_LEFT) || IsInputDown(INPUT_LEFT)) && lrRepeatTimer > lrRepeatDelay) {
                CycleOption(selectedOption, true);
                if (moveSound.frameCount > 0) PlaySound(moveSound);
                lrRepeatTimer = 0.0f;
                lrMoved = true;
            } else if ((IsKeyDown(KEY_RIGHT) || IsInputDown(INPUT_RIGHT)) && lrRepeatTimer > lrRepeatDelay) {
                CycleOption(selectedOption, false);
                if (moveSound.frameCount > 0) PlaySound(moveSound);
                lrRepeatTimer = 0.0f;
                lrMoved = true;
            }
            if (!lrMoved && !(IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_RIGHT) || IsInputDown(INPUT_LEFT) || IsInputDown(INPUT_RIGHT))) {
                lrRepeatTimer = lrRepeatDelay;
            }

            if (IsKeyPressed(KEY_ESCAPE) || IsInputPressed(INPUT_B)) {
                if (backSound.frameCount > 0) PlaySound(backSound);
                optionsState = OPTIONS_FADE_OUT;
                transitionTimer = 0.0f;
            }

            // Manual save with S key
            if (IsKeyPressed(KEY_S)) {
                if (acceptSound.frameCount > 0) PlaySound(acceptSound);
                SaveOptionsData();
            }

            // Reload options with R key
            if (IsKeyPressed(KEY_R)) {
                if (moveSound.frameCount > 0) PlaySound(moveSound);
                LoadOptionsData();
            }
            break;
        case OPTIONS_FADE_OUT:
            transitionTimer += deltaTime;
            transitionAlpha = (transitionTimer / transitionDuration) * 255.0f;
            if (transitionAlpha > 255.0f) transitionAlpha = 255.0f;
            if (transitionTimer >= transitionDuration) {
                SetCurrentScreenGlobal(SCREEN_STATE_TITLE);
            }
            break;
    }
}

void OptionsScreen_Draw(void) {
    BeginDrawing();
    ClearBackground(DARKGRAY);
    // Draw title higher up
    const char* title = "OPTIONS";
    float titleScale = 2.0f;
    int titleWidth = MeasureDiscoveryTextWidth(title, titleScale);
    float titleX = (VIRTUAL_SCREEN_WIDTH - titleWidth) / 2.0f;
    DrawDiscoveryText(title, (Vector2){titleX, 12}, titleScale, WHITE);

    // Scrolling logic
    int visibleOptions = 6;
    int scrollOffset = 0;
    if (selectedOption >= visibleOptions) {
        scrollOffset = selectedOption - visibleOptions + 1;
    }
    if (scrollOffset > optionCount - visibleOptions) {
        scrollOffset = optionCount - visibleOptions;
    }
    if (scrollOffset < 0) scrollOffset = 0;

    // Box dimensions
    int boxWidth = 360;
    int boxHeight = visibleOptions * 22 + 32;
    int boxX = (VIRTUAL_SCREEN_WIDTH - boxWidth) / 2;
    int boxY = 56;
    DrawRectangle(boxX, boxY, boxWidth, boxHeight, (Color){40, 40, 40, 180});

    // Draw options with small font, toggles/sliders, and highlight
    float optionScale = 1.0f;
    int keyColX = boxX + 24;
    int valColX = boxX + boxWidth - 120;
    int optionY = boxY + 12;
    int optionHeight = 22;
    for (int i = 0; i < visibleOptions && (i + scrollOffset) < optionCount; i++) {
        int optIdx = i + scrollOffset;
        // Highlight bar
        if (optIdx == selectedOption) {
            DrawRectangle(boxX + 8, optionY + i * optionHeight - 2, boxWidth - 16, optionHeight, (Color){200, 200, 80, 180});
        }
        // Key
        DrawSmallSonicText(options[optIdx].key, (Vector2){keyColX, optionY + i * optionHeight}, optionScale, (optIdx == selectedOption) ? YELLOW : SKYBLUE);

        // Value: show toggle or slider for known types
        if (strcmp(options[optIdx].key, "musicVolume") == 0 || strcmp(options[optIdx].key, "sfxVolume") == 0) {
            // Draw slider bar
            int value = atoi(options[optIdx].value);
            int sliderX = valColX;
            int sliderY = optionY + i * optionHeight + 6;
            int sliderW = 60;
            int sliderH = 6;
            DrawRectangle(sliderX, sliderY, sliderW, sliderH, DARKGRAY);
            DrawRectangle(sliderX, sliderY, (int)(sliderW * (value / 100.0f)), sliderH, (optIdx == selectedOption) ? YELLOW : SKYBLUE);
            char valStr[8];
            snprintf(valStr, sizeof(valStr), "%d", value);
            DrawSmallSonicText(valStr, (Vector2){sliderX + sliderW + 8, sliderY - 8}, 1.0f, (optIdx == selectedOption) ? YELLOW : SKYBLUE);
        } else if (options[optIdx].isBool) {
            // Draw toggle
            const char* toggleStr = (strcmp(options[optIdx].value, "true") == 0) ? "ON" : "OFF";
            Color toggleColor = (strcmp(options[optIdx].value, "true") == 0) ? GREEN : RED;
            DrawSmallSonicText(toggleStr, (Vector2){valColX, optionY + i * optionHeight}, 1.0f, (optIdx == selectedOption) ? YELLOW : toggleColor);
        } else {
            // Draw value as text
            DrawSmallSonicText(options[optIdx].value, (Vector2){valColX, optionY + i * optionHeight}, 1.0f, (optIdx == selectedOption) ? YELLOW : SKYBLUE);
        }
    }

    // Draw instructions at the bottom using small font
    const char* instr1 = "S SAVE";
    const char* instr2 = "A BACK";
    const char* instr3 = "LEFTRIGHT TOGGLE";
    const char* instr4 = "R RELOAD";
    float instrScale = 1.0f;
    int instrY = VIRTUAL_SCREEN_HEIGHT - 32;
    int instr1W = MeasureSmallSonicTextWidth(instr1, instrScale);
    int instr2W = MeasureSmallSonicTextWidth(instr2, instrScale);
    int instr3W = MeasureSmallSonicTextWidth(instr3, instrScale);
    int instr4W = MeasureSmallSonicTextWidth(instr4, instrScale);
    int spacing = 24;
    int totalW = instr1W + instr2W + instr3W + instr4W + 3 * spacing;
    int instrX = (VIRTUAL_SCREEN_WIDTH - totalW) / 2;
    DrawSmallSonicText(instr1, (Vector2){instrX, instrY}, instrScale, LIGHTGRAY);
    DrawSmallSonicText(instr2, (Vector2){instrX + instr1W + spacing, instrY}, instrScale, LIGHTGRAY);
    DrawSmallSonicText(instr3, (Vector2){instrX + instr1W + spacing + instr2W + spacing, instrY}, instrScale, LIGHTGRAY);
    DrawSmallSonicText(instr4, (Vector2){instrX + instr1W + spacing + instr2W + spacing + instr3W + spacing, instrY}, instrScale, LIGHTGRAY);

    // Draw red arrow under 'A BACK' (centered under instr2)
    int arrowX = instrX + instr1W + spacing + instr2W / 2 - 8;
    int arrowY = instrY + 16;
    DrawTriangle((Vector2){arrowX, arrowY}, (Vector2){arrowX + 16, arrowY}, (Vector2){arrowX + 8, arrowY + 12}, RED);

    // Fade in/out overlay
    if (optionsState == OPTIONS_FADE_IN || optionsState == OPTIONS_FADE_OUT) {
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, (Color){255, 255, 255, (unsigned char)transitionAlpha});
    }

    EndDrawing();
}

void OptionsScreen_Unload(void) {
    // Unload sounds safely - check if they're valid first
    if (moveSound.frameCount > 0) {
        UnloadSound(moveSound);
        moveSound = (Sound){0}; // Clear the handle
    }
    if (acceptSound.frameCount > 0) {
        UnloadSound(acceptSound);
        acceptSound = (Sound){0}; // Clear the handle
    }
    if (backSound.frameCount > 0) {
        UnloadSound(backSound);
        backSound = (Sound){0}; // Clear the handle
    }
}