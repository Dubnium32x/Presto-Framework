// HUD (Heads-Up Display) management
#include "hud.h"
#include "raylib.h"
#include <stdio.h>
#include <string.h>
#include "../world/sprite_font_manager.h"

HUD gameHUD;
int totalMilliseconds = 0;
int minutes = 0;
int seconds = 0;
int milliseconds = 0;
const char* timeString = "";

void InitHUD() {
    memset(&gameHUD, 0, sizeof(HUD));
    // Load HUD sprites here if needed
}

void UpdateHUD(float deltaTime) {
    if (gameHUD.isTimerActive) {
        gameHUD.time += (int)(deltaTime * 1000); // Convert to milliseconds
    }
}

void UpdateValues(int scoreDelta, int livesDelta, int ringsDelta) {
    gameHUD.score += scoreDelta;
    gameHUD.lives += livesDelta;
    gameHUD.rings += ringsDelta;
}

void DrawHUD() {
    // Draw HUD elements here using gameHUD data
    // Example: Draw score, lives, rings, and time
    // Draw the text and the numbers separately using the sprite font manager
    DrawDiscoveryText(TextFormat("Score: %d", gameHUD.score), (Vector2){10, 10}, 1.0f, WHITE);
    DrawDiscoveryText(TextFormat("Lives: %d", gameHUD.lives), (Vector2){10, 40}, 1.0f, WHITE);
    DrawDiscoveryText(TextFormat("Rings: %d", gameHUD.rings), (Vector2){10, 70}, 1.0f, WHITE); 

    int totalMilliseconds = (int)gameHUD.time;
    int minutes = totalMilliseconds / 60000;
    int seconds = (totalMilliseconds / 1000) % 60;
    int milliseconds = totalMilliseconds % 1000;
    DrawDiscoveryText(TextFormat("Time: %02d:%02d.%03d", minutes, seconds, milliseconds), (Vector2){10, 100}, 1.0f, WHITE);
}

void UnloadHUD() {
    // Unload HUD sprites here if needed
}

void StartTimer() {
    gameHUD.isTimerActive = true;
}

void StopTimer() {
    gameHUD.isTimerActive = false;
}
