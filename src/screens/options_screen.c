// Options Screen implementation
#include "options_screen.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "raylib.h"
#include "../world/screen_manager.h"
#include "../util/globals.h"
#include "../world/sprite_font_manager.h"
#include "../world/input.h"

#define MAX_OPTIONS 20
#define VISIBLE_OPTIONS 8

// Options screen variables
static OptionsScreenState optionsState = OPTIONS_FADE_IN;
static float transitionAlpha = 255.0f;
static float transitionDuration = 1.2f;
static float transitionTimer = 0.0f;

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

// Helper functions
static void LoadOptions(void);
static void SaveOptions(void);
static void ToggleOption(int index);
static void CycleOption(int index, bool left);

void OptionsScreen_Init(void) {
    // Load sounds
    moveSound = LoadSound("res/audio/sfx/Sonic World Sounds/004.wav");
    acceptSound = LoadSound("res/audio/sfx/Sonic World Sounds/022.wav");
    backSound = LoadSound("res/audio/sfx/Sonic World Sounds/002.wav");
    
    // Reset state
    optionsState = OPTIONS_FADE_IN;
    transitionAlpha = 255.0f;
    transitionTimer = 0.0f;
    selectedOption = 0;
    cameraOffset = 0;
    showFullscreenNote = false;
    
    // Load options from file
    LoadOptions();
}

static void LoadOptions(void) {
    optionCount = 0;
    FILE* file = fopen("options.ini", "r");
    
    if (file == NULL) {
        // Create default options if file doesn't exist
        strcpy(options[optionCount].key, "No options.ini found!");
        strcpy(options[optionCount].value, "");
        options[optionCount].isBool = false;
        optionCount++;
        return;
    }
    
    char line[256];
    while (fgets(line, sizeof(line), file) && optionCount < MAX_OPTIONS) {
        // Remove newline
        line[strcspn(line, "\n")] = 0;
        
        // Find the '=' separator
        char* equals = strchr(line, '=');
        if (equals == NULL) continue;
        
        *equals = '\0';  // Split the string
        char* key = line;
        char* value = equals + 1;
        
        // Trim whitespace (simple version)
        while (*key == ' ' || *key == '\t') key++;
        while (*value == ' ' || *value == '\t') value++;
        
        // Remove quotes if present
        if (value[0] == '"' && value[strlen(value)-1] == '"') {
            value[strlen(value)-1] = '\0';
            value++;
        }
        
        // Skip certain options
        if (strcmp(key, "colorswapmethod") == 0) continue;
        
        // Store the option
        strncpy(options[optionCount].key, key, sizeof(options[optionCount].key) - 1);
        strncpy(options[optionCount].value, value, sizeof(options[optionCount].value) - 1);
        options[optionCount].isBool = (strcmp(value, "true") == 0 || strcmp(value, "false") == 0);
        optionCount++;
    }
    
    fclose(file);
}

static void SaveOptions(void) {
    FILE* file = fopen("options.ini", "w");
    if (file == NULL) return;
    
    for (int i = 0; i < optionCount; i++) {
        if (strlen(options[i].key) > 0 && strlen(options[i].value) > 0) {
            fprintf(file, "%s=%s\n", options[i].key, options[i].value);
        }
    }
    
    fclose(file);
}

static void ToggleOption(int index) {
    if (options[index].isBool) {
        if (strcmp(options[index].value, "true") == 0) {
            strcpy(options[index].value, "false");
        } else {
            strcpy(options[index].value, "true");
        }
        
        // Apply audio settings immediately
        if (strcmp(options[index].key, "musicEnabled") == 0) {
            extern bool musicEnabled;
            musicEnabled = (strcmp(options[index].value, "true") == 0);
            if (!musicEnabled) {
                // Stop any currently playing music
                // Note: This would need access to the music stream
                printf("Music disabled\n");
            }
        } else if (strcmp(options[index].key, "sfxEnabled") == 0) {
            extern bool sfxEnabled;
            sfxEnabled = (strcmp(options[index].value, "true") == 0);
            printf("SFX %s\n", sfxEnabled ? "enabled" : "disabled");
        }
    }
}

static void CycleOption(int index, bool left) {
    const char* key = options[index].key;
    
    if (strcmp(key, "cameraType") == 0) {
        const char* values[] = {"Genesis", "CD", "Pocket"};
        int valueCount = 3;
        int currentIndex = 0;
        
        for (int i = 0; i < valueCount; i++) {
            if (strcmp(options[index].value, values[i]) == 0) {
                currentIndex = i;
                break;
            }
        }
        
        if (left) {
            currentIndex = (currentIndex == 0) ? valueCount - 1 : currentIndex - 1;
        } else {
            currentIndex = (currentIndex + 1) % valueCount;
        }
        
        strcpy(options[index].value, values[currentIndex]);
        
    } else if (strcmp(key, "levelLoadType") == 0) {
        const char* values[] = {"JSON", "Binary", "CSV"};
        int valueCount = 3;
        int currentIndex = 0;
        
        for (int i = 0; i < valueCount; i++) {
            if (strcmp(options[index].value, values[i]) == 0) {
                currentIndex = i;
                break;
            }
        }
        
        if (left) {
            currentIndex = (currentIndex == 0) ? valueCount - 1 : currentIndex - 1;
        } else {
            currentIndex = (currentIndex + 1) % valueCount;
        }
        
        strcpy(options[index].value, values[currentIndex]);
        
    } else if (strcmp(key, "windowSize") == 0) {
        const char* values[] = {"1", "2", "3", "4"};
        int valueCount = 4;
        int currentIndex = 0;
        
        for (int i = 0; i < valueCount; i++) {
            if (strcmp(options[index].value, values[i]) == 0) {
                currentIndex = i;
                break;
            }
        }
        
        if (left) {
            currentIndex = (currentIndex == 0) ? valueCount - 1 : currentIndex - 1;
        } else {
            currentIndex = (currentIndex + 1) % valueCount;
        }
        
        strcpy(options[index].value, values[currentIndex]);
        
        // Save immediately for window size changes
        SaveOptions();
    }
}

void OptionsScreen_Update(float deltaTime) {
    switch (optionsState) {
        case OPTIONS_FADE_IN:
            transitionTimer += deltaTime;
            transitionAlpha = 255.0f - fminf(transitionTimer / transitionDuration, 1.0f) * 255.0f;
            if (transitionTimer >= transitionDuration) {
                optionsState = OPTIONS_ACTIVE;
            }
            break;
            
        case OPTIONS_ACTIVE:
            // Handle navigation
            if (IsInputPressed(INPUT_DOWN)) {
                selectedOption = (selectedOption + 1) % optionCount;
                if (selectedOption - cameraOffset >= VISIBLE_OPTIONS) {
                    cameraOffset = selectedOption - VISIBLE_OPTIONS + 1;
                } else if (selectedOption == 0) {
                    cameraOffset = 0;
                }
                extern bool sfxEnabled;
                if (sfxEnabled) PlaySound(moveSound);
            } else if (IsInputPressed(INPUT_UP)) {
                selectedOption = (selectedOption - 1 + optionCount) % optionCount;
                if (selectedOption < cameraOffset) {
                    cameraOffset = selectedOption;
                } else if (selectedOption == optionCount - 1) {
                    cameraOffset = optionCount - VISIBLE_OPTIONS;
                    if (cameraOffset < 0) cameraOffset = 0;
                }
                extern bool sfxEnabled;
                if (sfxEnabled) PlaySound(moveSound);
            }
            
            // Handle option modification
            if (IsInputPressed(INPUT_LEFT)) {
                if (options[selectedOption].isBool) {
                    ToggleOption(selectedOption);
                } else {
                    CycleOption(selectedOption, true);
                }
                extern bool sfxEnabled;
                if (sfxEnabled) PlaySound(moveSound);
            } else if (IsInputPressed(INPUT_RIGHT)) {
                if (options[selectedOption].isBool) {
                    ToggleOption(selectedOption);
                } else {
                    CycleOption(selectedOption, false);
                }
                extern bool sfxEnabled;
                if (sfxEnabled) PlaySound(moveSound);
            }
            
            // Save options
            if (IsInputPressed(INPUT_A) || IsInputPressed(INPUT_START)) {
                SaveOptions();
                extern bool sfxEnabled;
                if (sfxEnabled) PlaySound(acceptSound);
                
                // Check if fullscreen was changed
                for (int i = 0; i < optionCount; i++) {
                    if (strcmp(options[i].key, "fullscreen") == 0) {
                        showFullscreenNote = true;
                        fullscreenNoteTimer = 3.0f;
                        break;
                    }
                }
            }
            
            // Back to title screen
            if (IsInputPressed(INPUT_B)) {
                extern bool sfxEnabled;
                if (sfxEnabled) PlaySound(backSound);
                optionsState = OPTIONS_FADE_OUT;
                transitionAlpha = 0.0f;
                transitionTimer = 0.0f;
            }
            
            // Update fullscreen note timer
            if (showFullscreenNote) {
                fullscreenNoteTimer -= deltaTime;
                if (fullscreenNoteTimer <= 0) {
                    showFullscreenNote = false;
                }
            }
            break;
            
        case OPTIONS_FADE_OUT:
            transitionTimer += deltaTime;
            transitionAlpha = fminf(transitionTimer / transitionDuration, 1.0f) * 255.0f;
            if (transitionTimer >= transitionDuration) {
                SetCurrentScreenGlobal(SCREEN_TITLE);
            }
            break;
    }
}

void OptionsScreen_Draw(void) {
    // Dark gray background
    ClearBackground(DARKGRAY);
    
    // Draw title
    const char* title = "OPTIONS";
    int titleWidth = MeasureDiscoveryTextWidth(title, 2.0f);
    float titleX = (VIRTUAL_SCREEN_WIDTH - titleWidth) / 2.0f;
    DrawDiscoveryText(title, (Vector2){titleX, 20}, 2.0f, WHITE);
    
    // Calculate display area
    float lineHeight = 18.0f;
    float startY = 60.0f;
    float maxWidth = 300.0f;  // Estimated max width
    float startX = (VIRTUAL_SCREEN_WIDTH - maxWidth) / 2.0f;
    
    // Draw viewport background
    DrawRectangle((int)(startX - 12), (int)(startY - 4), 
                  (int)(maxWidth + 24), (int)(VISIBLE_OPTIONS * lineHeight), 
                  (Color){220, 220, 220, 40});
    
    // Draw visible options
    for (int i = cameraOffset; i < cameraOffset + VISIBLE_OPTIONS && i < optionCount; i++) {
        char display[128];
        
        // Format display string
        if (strcmp(options[i].key, "windowSize") == 0) {
            int windowSizeValue = atoi(options[i].value);
            if (windowSizeValue < 1 || windowSizeValue > 4) windowSizeValue = 1;
            snprintf(display, sizeof(display), "%s: %d", options[i].key, windowSizeValue - 1);
        } else {
            snprintf(display, sizeof(display), "%s: %s", options[i].key, options[i].value);
        }
        
        // Calculate position
        int textWidth = MeasureSmallSonicTextWidth(display, 1.0f);
        float textX = (VIRTUAL_SCREEN_WIDTH - textWidth) / 2.0f;
        float textY = startY + (i - cameraOffset) * lineHeight;
        
        // Draw highlight for selected option
        if (i == selectedOption) {
            int highlightPadding = 4;
            int highlightWidth = textWidth + highlightPadding * 2;
            int highlightX = (int)(textX - highlightPadding);
            DrawRectangle(highlightX, (int)(textY - 2), highlightWidth, (int)lineHeight, 
                         (Color){220, 220, 40, 120});
        }
        
        // Draw option text
        Color textColor = (i == selectedOption) ? WHITE : (Color){100, 100, 255, 255};
        DrawSmallSonicText(display, (Vector2){textX, textY}, 1.0f, textColor);
    }
    
    // Draw scroll indicators if needed
    if (cameraOffset > 0) {
        // Up arrow (triangle pointing up)
        Vector2 points[3] = {
            {startX - 16, startY + 8},
            {startX - 8, startY},
            {startX - 24, startY}
        };
        DrawTriangle(points[0], points[1], points[2], WHITE);
    }
    
    if (cameraOffset + VISIBLE_OPTIONS < optionCount) {
        // Down arrow (triangle pointing down)
        float arrowY = startY + VISIBLE_OPTIONS * lineHeight - 8;
        Vector2 points[3] = {
            {startX - 16, arrowY},
            {startX - 8, arrowY + 8},
            {startX - 24, arrowY + 8}
        };
        DrawTriangle(points[0], points[1], points[2], WHITE);
    }
    
    // Draw help text
    const char* help = "ENTER: Save   ESC: Back   Left/Right: Toggle";
    int helpWidth = MeasureSmallSonicTextWidth(help, 1.0f);
    float helpX = (VIRTUAL_SCREEN_WIDTH - helpWidth) / 2.0f;
    DrawSmallSonicText(help, (Vector2){helpX, VIRTUAL_SCREEN_HEIGHT - 24}, 1.0f, LIGHTGRAY);
    
    // Show fullscreen note if needed
    if (showFullscreenNote) {
        const char* note = "* FULLSCREEN WILL BE APPLIED UPON NEXT RESET";
        int noteWidth = MeasureSmallSonicTextWidth(note, 1.0f);
        float noteX = (VIRTUAL_SCREEN_WIDTH - noteWidth) / 2.0f;
        DrawSmallSonicText(note, (Vector2){noteX, VIRTUAL_SCREEN_HEIGHT - 40}, 1.0f, YELLOW);
    }
    
    // Draw transition overlay
    if (optionsState == OPTIONS_FADE_IN || optionsState == OPTIONS_FADE_OUT) {
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, 
                     (Color){255, 255, 255, (unsigned char)transitionAlpha});
    }
}

void OptionsScreen_Unload(void) {
    UnloadSound(moveSound);
    UnloadSound(acceptSound);
    UnloadSound(backSound);
}