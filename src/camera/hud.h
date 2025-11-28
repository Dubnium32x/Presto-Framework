// HUD (Heads-Up Display) management header
#ifndef HUD_H
#define HUD_H

#include "raylib.h"

// Forward declaration to avoid circular dependency
struct Player;

#define HUD_SPRITE_COUNT 10

typedef struct {
    int score, lives, rings;
    float time; // in seconds
    bool isTimerActive;
    Texture2D hudSprites[HUD_SPRITE_COUNT];
} HUD;

extern int totalMilliseconds;
extern int minutes;
extern int seconds;
extern int milliseconds;
extern const char* timeString;

// Function declarations for HUD management
void InitHUD();
void UpdateHUD(float deltaTime);
void UpdateValues(int scoreDelta, int livesDelta, int ringsDelta);
void DrawHUD();
void DrawDebugHUD(void* player);
void UnloadHUD();
void StartTimer();
void StopTimer();

#endif // HUD_H
