// HUD (Heads-Up Display) management header
#ifndef HUD_H
#define HUD_H

#include "raylib.h"
#include <stdio.h>
#include <string.h>

#define HUD_SPRITE_COUNT 10

typedef struct {
    int score, lives, rings;
    float time; // in seconds
    bool isTimerActive;
    Texture2D hudSprites[HUD_SPRITE_COUNT];
} HUD;

int totalMilliseconds;
int minutes = totalMilliseconds / 60000;
int seconds = (totalMilliseconds / 1000) % 60;
int milliseconds = totalMilliseconds % 1000;
const char* timeString = TextFormat("%02d:%02d.%03d", minutes, seconds, milliseconds);

// Function declarations for HUD management
void InitHUD();
void UpdateHUD();
void UpdateValues(int scoreDelta, int livesDelta, int ringsDelta);
void DrawHUD();
void UnloadHUD();
void StartTimer();
void StopTimer();

#endif // HUD_H