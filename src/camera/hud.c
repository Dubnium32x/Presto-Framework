// HUD (Heads-Up Display) management
#include "hud.h"
#include "raylib.h"
#include <stdio.h>
#include <string.h>
#include "../world/sprite_font_manager.h"
#include "../entity/player/player.h"
#include "../util/globals.h"

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
    // Draw HUD elements in classic Sonic layout
    // Top left: SCORE, RINGS, TIME
    DrawDiscoveryText("SCORE", (Vector2){10, 10}, 1.0f, YELLOW);
    DrawDiscoveryText(TextFormat("%d", gameHUD.score), (Vector2){10, 25}, 1.0f, WHITE);
    
    DrawDiscoveryText("RINGS", (Vector2){10, 50}, 1.0f, YELLOW);
    DrawDiscoveryText(TextFormat("%d", gameHUD.rings), (Vector2){10, 65}, 1.0f, WHITE);
    
    DrawDiscoveryText("TIME", (Vector2){10, 90}, 1.0f, YELLOW);
    int totalMilliseconds = (int)gameHUD.time;
    int minutes = totalMilliseconds / 60000;
    int seconds = (totalMilliseconds / 1000) % 60;
    DrawDiscoveryText(TextFormat("%d:%02d", minutes, seconds), (Vector2){10, 105}, 1.0f, WHITE);
    
    // Bottom: Lives using small Sonic font
    DrawSmallSonicText(TextFormat("SONIC * %d", gameHUD.lives), (Vector2){10, VIRTUAL_SCREEN_HEIGHT - 25}, 1.0f, YELLOW);
}

void DrawDebugHUD(void* playerPtr) {
    Player* player = (Player*)playerPtr;
    if (player == NULL) return;
    
    // Debug info on the right side
    int debugX = VIRTUAL_SCREEN_WIDTH - 120;
    int debugY = 10;
    
    DrawDiscoveryText("DEBUG", (Vector2){debugX, debugY}, 1.0f, RED);
    debugY += 20;
    
    DrawSmallSonicText(TextFormat("X: %.1f", player->position.x), (Vector2){debugX, debugY}, 1.0f, WHITE);
    debugY += 12;
    
    DrawSmallSonicText(TextFormat("Y: %.1f", player->position.y), (Vector2){debugX, debugY}, 1.0f, WHITE);
    debugY += 12;
    
    DrawSmallSonicText(TextFormat("VX: %.1f", player->velocity.x), (Vector2){debugX, debugY}, 1.0f, WHITE);
    debugY += 12;
    
    DrawSmallSonicText(TextFormat("VY: %.1f", player->velocity.y), (Vector2){debugX, debugY}, 1.0f, WHITE);
    debugY += 12;
    
    DrawSmallSonicText(TextFormat("GRD: %s", player->isOnGround ? "YES" : "NO"), (Vector2){debugX, debugY}, 1.0f, WHITE);
    debugY += 12;
    
    DrawSmallSonicText(TextFormat("ANG: %.1f", player->groundAngle), (Vector2){debugX, debugY}, 1.0f, WHITE);
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
