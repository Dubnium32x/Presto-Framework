// Game Screen header
#ifndef SCREEN_GAME_H
#define SCREEN_GAME_H

#include "raylib.h"
#include "../data/data-csv_loader.h"
#include "../util/util-global.h"

typedef enum {
    GAME_INIT,
    GAME_PLAYING,
    GAME_PAUSED,
    GAME_FADE_OUT
} GameScreenState;

void GameScreen_Init(void);
void GameScreen_Update(float deltaTime);
void GameScreen_Draw(void);
void GameScreen_Unload(void);

#endif // SCREEN_GAME_H