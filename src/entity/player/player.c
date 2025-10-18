// Player script
// ... oh boy...
// This is going to be a long one...

#include "player.h"
#include "raylib.h"
#include "var.h"
#include "../sprite_object.h"
#include "../../util/globals.h"
#include "../../util/math_utils.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

void Player_Init(Player* player, float startX, float startY) {
    playerX = startX;
    playerY = startY;
    playerSpeedX = 0.0f;
    playerSpeedY = 0.0f;
    groundAngle = 0.0f;
    groundSpeed = 0.0f;
    hasJumped = false;
    isOnGround = true;
    isSpindashing = false;
    isRolling = false;
    isHurt = false;
    isDead = false;
    isSuper = false;
    controlLockTimer = 0;
    facing = 1; // Facing right
}

// More player functions to be implemented...

