// Player header file
#ifndef PLAYER_PLAYER_H
#define PLAYER_PLAYER_H

#include "raylib.h"

/* NOTE:
    We'll come back to this later.
    We need a foundation for the start of the game first,
    along with a solid grasp of the player mechanics.
*/

typedef struct {
    Vector2 position;
    Vector2 velocity;
    int health;
    int score;
    bool isJumping;
    bool isOnGround;
} Player;

#endif // PLAYER_PLAYER_H