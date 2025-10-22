// Init Screen implementation
#include "init_screen.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"
#include "../world/screen_manager.h"
#include "../util/globals.h"
#include "../world/sprite_font_manager.h"

// Define init screen variables
const char* disclaimerText = "DISCLAIMER";
Texture2D segaLogo = {0};
Sound segaJingle = {0};
bool disclaimerPlayer = false;
bool jinglePlayed = false;
float timer = 0.0f;
float disclaimerTimer = 0.0f;
float disclaimerDuration = 5.0f;
float fadeOutDuration = 1.0f;
float logoAnimateInTime = 1.0f;
float logoDisplayTime = 4.5f;
float disclaimerAlpha = 0.0f;
float logoScaleX = 0.0f;
float logoScaleY = 0.0f;
Vector2* logoPosition = NULL;
int backgroundColorModifier = 0;
InitScreenStateEnum* initState = NULL;
InitScreenPhase* currentPhase = NULL;

void InitScreen_Init(void) {
    // Load resources
    segaLogo = LoadTexture("res/image/logos/Sega-logo.png");
    segaJingle = LoadSound("res/audio/sfx/jingle.ogg");
    logoPosition = (Vector2*)malloc(sizeof(Vector2));
    logoPosition->x = VIRTUAL_SCREEN_WIDTH / 2 - segaLogo.width / 2;
    logoPosition->y = VIRTUAL_SCREEN_HEIGHT / 2 - segaLogo.height / 2;
    logoScaleX = 0.1f;
    logoScaleY = 0.1f;
    disclaimerAlpha = 0.0f;
    backgroundColorModifier = 0;
    initState = (InitScreenStateEnum*)malloc(sizeof(InitScreenStateEnum));
    *initState = INIT_DISCLAIMER;
    currentPhase = (InitScreenPhase*)malloc(sizeof(InitScreenPhase));
    *currentPhase = DISCLAIMER_FADE_IN;
}

void InitScreen_Update(float deltaTime) {
    // Print debug info (assuming you have a debug print function)
    // printf("initState=%d initPhase=%d\n", *initState, *currentPhase);
    
    if (*initState == INIT_DISCLAIMER) {
        // Fade in text and background
        if (*currentPhase == DISCLAIMER_FADE_IN) {
            disclaimerAlpha += deltaTime / fadeOutDuration;
            if (disclaimerAlpha >= 1.0f) {
                disclaimerAlpha = 1.0f;
                *currentPhase = DISCLAIMER_DISPLAY;
            }
        } else if (*currentPhase == DISCLAIMER_DISPLAY) {
            disclaimerTimer += deltaTime;
            if (disclaimerTimer >= disclaimerDuration) {
                *currentPhase = DISCLAIMER_FADE_OUT;
            }
        } else if (*currentPhase == DISCLAIMER_FADE_OUT) {
            disclaimerAlpha -= deltaTime / fadeOutDuration;
            if (disclaimerAlpha <= 0.0f) {
                disclaimerAlpha = 0.0f;
                // Advance to logo animation phase
                *initState = INIT_SPLASH;
                *currentPhase = LOGO_ANIMATE_IN;
                timer = 0.0f;
            }
        }
        // Background fade: interpolate from black to white using disclaimerAlpha
        backgroundColorModifier = (int)((1.0f - disclaimerAlpha) * 255.0f);
    }
    
    if (*initState == INIT_SPLASH) {
        // Keep background white
        backgroundColorModifier = 255;
        float targetScale = 1.0f;
        float animationDuration = logoAnimateInTime;
        float holdDuration = logoDisplayTime;
        
        if (*currentPhase == LOGO_ANIMATE_IN) {
            float t = timer / animationDuration;
            if (t > 1.0f) t = 1.0f;
            logoScaleX = segaLogo.width * t;
            logoScaleY = segaLogo.height * t;
            logoPosition->x = (VIRTUAL_SCREEN_WIDTH - logoScaleX) / 2.0f;
            logoPosition->y = VIRTUAL_SCREEN_HEIGHT + (VIRTUAL_SCREEN_HEIGHT/2 - segaLogo.height/2 - VIRTUAL_SCREEN_HEIGHT) * t;
            timer += deltaTime;
            if (timer >= animationDuration) {
                *currentPhase = LOGO_DISPLAY;
                timer = 0.0f;
            }
        } else if (*currentPhase == LOGO_DISPLAY) {
            if (!jinglePlayed) {
                PlaySound(segaJingle);
                jinglePlayed = true;
            }
            logoScaleX = segaLogo.width * targetScale;
            logoScaleY = segaLogo.height * targetScale;
            logoPosition->x = (VIRTUAL_SCREEN_WIDTH - logoScaleX) / 2.0f;
            logoPosition->y = (VIRTUAL_SCREEN_HEIGHT - logoScaleY) / 2.0f;
            timer += deltaTime;
            if (timer >= holdDuration) {
                *currentPhase = LOGO_FADE_OUT;
                timer = 0.0f;
            }
        } else if (*currentPhase == LOGO_FADE_OUT) {
            float t = timer / fadeOutDuration;
            if (t > 1.0f) t = 1.0f;
            logoScaleX = segaLogo.width * (1.0f - t);
            logoScaleY = segaLogo.height * (1.0f - t);
            logoPosition->x = (VIRTUAL_SCREEN_WIDTH - logoScaleX) / 2.0f;
            logoPosition->y = (VIRTUAL_SCREEN_HEIGHT - logoScaleY) / 2.0f;
            timer += deltaTime;
            if (timer >= fadeOutDuration) {
                *currentPhase = PHASE_DONE;
                *initState = INIT_DONE;
            }
        }
    }
    
    if (*currentPhase == PHASE_DONE) {
        // Call screen manager to change state
        SetCurrentScreenGlobal(SCREEN_TITLE);
    }
}

void InitScreen_Draw(void) {
    // Fade background from black to white, then keep white
    unsigned char bgValue = (unsigned char)backgroundColorModifier;
    Color bgColor = (Color){bgValue, bgValue, bgValue, 255};
    ClearBackground(bgColor);

    if (*initState == INIT_DISCLAIMER) {
        if (*currentPhase == DISCLAIMER_FADE_IN || *currentPhase == DISCLAIMER_DISPLAY || *currentPhase == DISCLAIMER_FADE_OUT) {
            const char* header = "DISCLAIMER";
            const char* disclaimerLines[] = {
                "THIS IS A FAN PROJECT MADE WITH LOVE FOR THE",
                "SONIC COMMUNITY.",
                "",
                "IT IS NOT AFFILIATED WITH SEGA OR SONIC TEAM.",
                "THIS PROJECT IS STRICTLY NON-COMMERCIAL.",
                "",
                "ALL RIGHTS BELONG TO THEIR RESPECTIVE OWNERS.",
                "THANK YOU FOR YOUR SUPPORT!"
            };
            int lineCount = sizeof(disclaimerLines) / sizeof(disclaimerLines[0]);
            float lineHeight = 12.0f;
            float headerScale = 2.0f; // Discovery glyphs are per-letter textures - make it bigger for impact
            float bodyScale = 1.0f;    // Small Sonic glyphs are 8x8
            float startY = 60.0f; // Start a bit higher to accommodate larger header
            
            // Text fades in and out with background
            
            // Draw header with Discovery font (properly centered and faded)
            int headerWidth = MeasureDiscoveryTextWidth(header, headerScale);
            float headerX = (VIRTUAL_SCREEN_WIDTH - headerWidth) / 2.0f;
            float headerY = startY;
            Color headerColor = WHITE;
            headerColor.a = (unsigned char)(255 * disclaimerAlpha);
            DrawDiscoveryText(header, (Vector2){headerX, headerY}, headerScale, headerColor);
            
            // Draw disclaimer lines with proper font and spacing
            int headerHeight = MeasureDiscoveryTextHeight(header, headerScale);
            float currentY = startY + (float)headerHeight + 20.0f;
            for (int i = 0; i < lineCount; i++) {
                if (strlen(disclaimerLines[i]) > 0) {
                    int textWidth = MeasureSmallSonicTextWidth(disclaimerLines[i], bodyScale);
                    float textX = (VIRTUAL_SCREEN_WIDTH - textWidth) / 2.0f;
                    
                    // Use the fade color for proper animation
                    Color textColor = WHITE;
                    textColor.a = (unsigned char)(255 * disclaimerAlpha);
                    
                    DrawSmallSonicText(disclaimerLines[i], (Vector2){textX, currentY}, bodyScale, textColor);
                    
                    currentY += lineHeight;
                }
            }
        }
    }

    if (*initState == INIT_SPLASH) {
        if (*currentPhase == LOGO_ANIMATE_IN || *currentPhase == LOGO_DISPLAY || *currentPhase == LOGO_FADE_OUT) {
            // Draw Sega logo
            Rectangle source = {0, 0, (float)segaLogo.width, (float)segaLogo.height};
            Rectangle dest = {logoPosition->x, logoPosition->y, logoScaleX, logoScaleY};
            Vector2 origin = {0, 0};
            DrawTexturePro(segaLogo, source, dest, origin, 0.0f, WHITE);
        }
    }
}

void InitScreen_Unload(void) {
    UnloadTexture(segaLogo);
    UnloadSound(segaJingle);
    free(logoPosition);
    free(initState);
    free(currentPhase);
}
