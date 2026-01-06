// Options Screen implementation
#include "screen-options.h"
#include <math.h>
#include <string.h>
#include "raylib.h"
#include "../util/util-global.h"
#include "../visual/visual-sprite_fonts.h"
#include "../managers/managers-input.h"
#include "../managers/managers-screen_settings.h"

// Option item for display purposes
typedef struct {
    char key[64];
    char value[64];
    bool isBool;
} OptionItem;

// Screen state
static OptionsScreenState optionsState = OPTIONS_FADE_IN;
static float fadeAlpha = 255.0f;
static float fadeDuration = 0.6f;
static float fadeTimer = 0.0f;

// Menu state
static int selectedOption = 0;
static int scrollOffset = 0;
static int visibleOptions = 6;
static float inputRepeatTimer = 0.0f;
static float inputRepeatDelay = 0.12f;

// Options data (local copy for editing)
static OptionItem optionItems[10];
static int optionCount = 10;

// Sound effects
static Sound moveSound = {0};
static Sound acceptSound = {0};
static Sound backSound = {0};

// Camera type names for display
static const char* cameraTypeNames[] = {"GENESIS", "CD", "POCKET"};

// Screen size names for display
static const char* screenSizeNames[] = {"1X", "2X", "3X", "4X"};

// Forward declarations
static void LoadOptionsData(void);
static void SaveOptionsData(void);
static void UpdateOptionValue(int index, int direction);

void OptionsScreen_Init(void) {
    // Load sound effects
    moveSound = LoadSound("RESOURCES/sound/sfx/Sonic World Sounds/004.wav");
    acceptSound = LoadSound("RESOURCES/sound/sfx/Sonic World Sounds/022.wav");
    backSound = LoadSound("RESOURCES/sound/sfx/Sonic World Sounds/002.wav");

    // Reset state
    optionsState = OPTIONS_FADE_IN;
    fadeAlpha = 255.0f;
    fadeTimer = 0.0f;
    selectedOption = 0;
    scrollOffset = 0;
    inputRepeatTimer = 0.0f;

    // Load options from global g_Options into local display items
    LoadOptionsData();
}

static void LoadOptionsData(void) {
    // Load from g_Options into our local OptionItem array
    strcpy(optionItems[0].key, "MUSIC VOLUME");
    snprintf(optionItems[0].value, sizeof(optionItems[0].value), "%d", g_Options.musicVolume);
    optionItems[0].isBool = false;

    strcpy(optionItems[1].key, "SFX VOLUME");
    snprintf(optionItems[1].value, sizeof(optionItems[1].value), "%d", g_Options.sfxVolume);
    optionItems[1].isBool = false;

    strcpy(optionItems[2].key, "FULLSCREEN");
    strcpy(optionItems[2].value, g_Options.fullscreen ? "ON" : "OFF");
    optionItems[2].isBool = true;

    strcpy(optionItems[3].key, "SCREEN SIZE");
    snprintf(optionItems[3].value, sizeof(optionItems[3].value), "%s", screenSizeNames[g_Options.screenSize - 1]);
    optionItems[3].isBool = false;

    strcpy(optionItems[4].key, "VSYNC");
    strcpy(optionItems[4].value, g_Options.vsync ? "ON" : "OFF");
    optionItems[4].isBool = true;

    strcpy(optionItems[5].key, "SHOW FPS");
    strcpy(optionItems[5].value, g_Options.showFPS ? "ON" : "OFF");
    optionItems[5].isBool = true;

    strcpy(optionItems[6].key, "DROPDASH");
    strcpy(optionItems[6].value, g_Options.dropdashEnabled ? "ON" : "OFF");
    optionItems[6].isBool = true;

    strcpy(optionItems[7].key, "INSTA SHIELD");
    strcpy(optionItems[7].value, g_Options.instaShieldEnabled ? "ON" : "OFF");
    optionItems[7].isBool = true;

    strcpy(optionItems[8].key, "PEELOUT");
    strcpy(optionItems[8].value, g_Options.peeloutEnabled ? "ON" : "OFF");
    optionItems[8].isBool = true;

    strcpy(optionItems[9].key, "CAMERA TYPE");
    strcpy(optionItems[9].value, cameraTypeNames[g_Options.cameraType]);
    optionItems[9].isBool = false;
}

static void SaveOptionsData(void) {
    // Save to file
    SaveOptions(g_OptionsFilePath);
}


static void UpdateOptionValue(int index, int direction) {
    switch (index) {
        case 0: // Music Volume
            g_Options.musicVolume = (uint8_t)fmax(0, fmin(100, g_Options.musicVolume + direction * 5));
            snprintf(optionItems[0].value, sizeof(optionItems[0].value), "%d", g_Options.musicVolume);
            break;
        case 1: // SFX Volume
            g_Options.sfxVolume = (uint8_t)fmax(0, fmin(100, g_Options.sfxVolume + direction * 5));
            snprintf(optionItems[1].value, sizeof(optionItems[1].value), "%d", g_Options.sfxVolume);
            break;
        case 2: // Fullscreen
            g_Options.fullscreen = !g_Options.fullscreen;
            strcpy(optionItems[2].value, g_Options.fullscreen ? "ON" : "OFF");
            ToggleGameFullscreen();
            // If exiting fullscreen, apply the saved screen size
            if (!g_Options.fullscreen) {
                PrestoSetWindowSize(g_Options.screenSize);
            }
            break;
        case 3: // Screen Size
            if (direction > 0) {
                g_Options.screenSize = (g_Options.screenSize % 4) + 1;
            } else {
                g_Options.screenSize = g_Options.screenSize <= 1 ? 4 : g_Options.screenSize - 1;
            }
            snprintf(optionItems[3].value, sizeof(optionItems[3].value), "%s", screenSizeNames[g_Options.screenSize - 1]);
            // Only apply screen size changes when not in fullscreen mode
            if (!g_Options.fullscreen) {
                PrestoSetWindowSize(g_Options.screenSize);
            }
            break;
        case 4: // VSync
            g_Options.vsync = !g_Options.vsync;
            strcpy(optionItems[4].value, g_Options.vsync ? "ON" : "OFF");
            SetVSync(g_Options.vsync);
            break;
        case 5: // Show FPS
            g_Options.showFPS = !g_Options.showFPS;
            strcpy(optionItems[5].value, g_Options.showFPS ? "ON" : "OFF");
            break;
        case 6: // Dropdash
            g_Options.dropdashEnabled = !g_Options.dropdashEnabled;
            strcpy(optionItems[6].value, g_Options.dropdashEnabled ? "ON" : "OFF");
            break;
        case 7: // Insta Shield
            g_Options.instaShieldEnabled = !g_Options.instaShieldEnabled;
            strcpy(optionItems[7].value, g_Options.instaShieldEnabled ? "ON" : "OFF");
            break;
        case 8: // Peelout
            g_Options.peeloutEnabled = !g_Options.peeloutEnabled;
            strcpy(optionItems[8].value, g_Options.peeloutEnabled ? "ON" : "OFF");
            break;
        case 9: // Camera Type
            if (direction > 0) {
                g_Options.cameraType = (g_Options.cameraType + 1) % 3;
            } else {
                g_Options.cameraType = g_Options.cameraType == 0 ? 2 : g_Options.cameraType - 1;
            }
            strcpy(optionItems[9].value, cameraTypeNames[g_Options.cameraType]);
            break;
    }
}

void OptionsScreen_Update(float deltaTime) {
    switch (optionsState) {
        case OPTIONS_FADE_IN:
            fadeTimer += deltaTime;
            fadeAlpha = 255.0f * (1.0f - (fadeTimer / fadeDuration));
            if (fadeTimer >= fadeDuration) {
                fadeAlpha = 0.0f;
                optionsState = OPTIONS_ACTIVE;
            }
            break;

        case OPTIONS_ACTIVE:
            // Handle vertical navigation with repeat
            if (IsInputDown(INPUT_DOWN)) {
                inputRepeatTimer += deltaTime;
                if (IsInputPressed(INPUT_DOWN) || inputRepeatTimer >= inputRepeatDelay) {
                    selectedOption = (selectedOption + 1) % optionCount;
                    // Adjust scroll offset
                    if (selectedOption >= scrollOffset + visibleOptions) {
                        scrollOffset = selectedOption - visibleOptions + 1;
                    } else if (selectedOption < scrollOffset) {
                        scrollOffset = selectedOption;
                    }
                    if (moveSound.frameCount > 0) PlaySound(moveSound);
                    if (inputRepeatTimer >= inputRepeatDelay) inputRepeatTimer = 0.0f;
                }
            } else if (IsInputDown(INPUT_UP)) {
                inputRepeatTimer += deltaTime;
                if (IsInputPressed(INPUT_UP) || inputRepeatTimer >= inputRepeatDelay) {
                    selectedOption = (selectedOption - 1 + optionCount) % optionCount;
                    // Adjust scroll offset
                    if (selectedOption < scrollOffset) {
                        scrollOffset = selectedOption;
                    } else if (selectedOption >= scrollOffset + visibleOptions) {
                        scrollOffset = selectedOption - visibleOptions + 1;
                    }
                    if (moveSound.frameCount > 0) PlaySound(moveSound);
                    if (inputRepeatTimer >= inputRepeatDelay) inputRepeatTimer = 0.0f;
                }
            } else {
                inputRepeatTimer = 0.0f;
            }

            // Handle left/right for value changes
            if (IsInputPressed(INPUT_LEFT)) {
                UpdateOptionValue(selectedOption, -1);
                if (moveSound.frameCount > 0) PlaySound(moveSound);
            } else if (IsInputPressed(INPUT_RIGHT)) {
                UpdateOptionValue(selectedOption, 1);
                if (moveSound.frameCount > 0) PlaySound(moveSound);
            }

            // Handle A button for toggles
            if (IsInputPressed(INPUT_A)) {
                UpdateOptionValue(selectedOption, 1);
                if (acceptSound.frameCount > 0) PlaySound(acceptSound);
            }

            // Handle B button or Escape to go back
            if (IsInputPressed(INPUT_B)) {
                if (backSound.frameCount > 0) PlaySound(backSound);
                SaveOptionsData();
                optionsState = OPTIONS_FADE_OUT;
                fadeTimer = 0.0f;
            }

            // S key to save manually
            if (IsInputPressed(INPUT_RB)) {
                SaveOptionsData();
                if (acceptSound.frameCount > 0) PlaySound(acceptSound);
            }

            // R key to reload options
            if (IsInputPressed(INPUT_LB)) {
                LoadOptions(g_OptionsFilePath);
                LoadOptionsData();
                if (moveSound.frameCount > 0) PlaySound(moveSound);
            }
            break;

        case OPTIONS_FADE_OUT:
            fadeTimer += deltaTime;
            fadeAlpha = 255.0f * (fadeTimer / fadeDuration);
            if (fadeTimer >= fadeDuration) {
                fadeAlpha = 255.0f;
                SetCurrentScreenGlobal(SCREEN_STATE_TITLE);
            }
            break;
    }
}

void OptionsScreen_Draw(void) {
    // Dark background
    ClearBackground((Color){40, 40, 40, 255});

    // Draw title
    const char* title = "OPTIONS";
    int titleWidth = MeasureDiscoveryTextWidth(title, 2.0f);
    DrawDiscoveryText(title, (Vector2){(VIRTUAL_SCREEN_WIDTH - titleWidth) / 2, 20}, 2.0f, WHITE);

    // Draw options box background
    int boxX = 20;
    int boxY = 60;
    int boxWidth = 360;
    int boxHeight = 132;
    DrawRectangle(boxX, boxY, boxWidth, boxHeight, (Color){30, 30, 30, 200});

    // Draw visible options
    float itemHeight = 20.0f;
    float startY = boxY + 8;

    for (int i = 0; i < visibleOptions && (scrollOffset + i) < optionCount; i++) {
        int optIndex = scrollOffset + i;
        float itemY = startY + i * itemHeight;

        // Draw selection highlight
        if (optIndex == selectedOption) {
            DrawRectangle(boxX + 4, (int)itemY - 2, boxWidth - 8, (int)itemHeight, (Color){255, 255, 0, 80});
        }

        // Draw key (option name)
        Color keyColor = (optIndex == selectedOption) ? YELLOW : WHITE;
        DrawSmallSonicText(optionItems[optIndex].key, (Vector2){boxX + 12, itemY}, 1.0f, keyColor);

        // Draw value
        Color valueColor;
        if (optionItems[optIndex].isBool) {
            // Color based on ON/OFF
            if (strcmp(optionItems[optIndex].value, "ON") == 0) {
                valueColor = GREEN;
            } else {
                valueColor = RED;
            }
        } else {
            valueColor = (optIndex == selectedOption) ? SKYBLUE : LIGHTGRAY;
        }

        // Right-align the value
        int valueWidth = MeasureSmallSonicTextWidth(optionItems[optIndex].value, 1.0f);
        DrawSmallSonicText(optionItems[optIndex].value, (Vector2){boxX + boxWidth - valueWidth - 16, itemY}, 1.0f, valueColor);

        // Draw volume bar for volume options
        if (optIndex == 0 || optIndex == 1) {
            int barX = boxX + 140;
            int barY = (int)itemY + 4;
            int barWidth = 100;
            int barHeight = 10;
            int volume = (optIndex == 0) ? g_Options.musicVolume : g_Options.sfxVolume;
            int fillWidth = (volume * barWidth) / 100;

            DrawRectangle(barX, barY, barWidth, barHeight, DARKGRAY);
            DrawRectangle(barX, barY, fillWidth, barHeight, (optIndex == selectedOption) ? SKYBLUE : GRAY);
            DrawRectangleLines(barX, barY, barWidth, barHeight, WHITE);
        }
    }

    // Draw scroll indicators if needed
    if (scrollOffset > 0) {
        DrawTriangle(
            (Vector2){VIRTUAL_SCREEN_WIDTH / 2, boxY - 8},
            (Vector2){VIRTUAL_SCREEN_WIDTH / 2 - 8, boxY - 2},
            (Vector2){VIRTUAL_SCREEN_WIDTH / 2 + 8, boxY - 2},
            WHITE
        );
    }
    if (scrollOffset + visibleOptions < optionCount) {
        DrawTriangle(
            (Vector2){VIRTUAL_SCREEN_WIDTH / 2 - 8, boxY + boxHeight + 2},
            (Vector2){VIRTUAL_SCREEN_WIDTH / 2 + 8, boxY + boxHeight + 2},
            (Vector2){VIRTUAL_SCREEN_WIDTH / 2, boxY + boxHeight + 8},
            WHITE
        );
    }

    // Draw instructions at bottom
    DrawSmallSonicText("UP/DOWN SELECT   LEFT/RIGHT CHANGE   B BACK",
                       (Vector2){20, VIRTUAL_SCREEN_HEIGHT - 30}, 1.0f, LIGHTGRAY);
    DrawSmallSonicText("RSHIFT SAVE   LSHIFT RELOAD",
                       (Vector2){20, VIRTUAL_SCREEN_HEIGHT - 16}, 1.0f, LIGHTGRAY);

    // Draw fade overlay
    if (fadeAlpha > 0) {
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT,
                     (Color){255, 255, 255, (unsigned char)fadeAlpha});
    }
}

void OptionsScreen_Unload(void) {
    // Unload sounds safely
    if (moveSound.frameCount > 0) {
        UnloadSound(moveSound);
        moveSound = (Sound){0};
    }
    if (acceptSound.frameCount > 0) {
        UnloadSound(acceptSound);
        acceptSound = (Sound){0};
    }
    if (backSound.frameCount > 0) {
        UnloadSound(backSound);
        backSound = (Sound){0};
    }
}
