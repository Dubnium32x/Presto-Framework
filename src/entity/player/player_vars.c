// Player variable definitions
#include "var.h"

// Define all the extern variables declared in var.h
float playerX = 0.0f;
float playerY = 0.0f;
float playerSpeedX = 0.0f;
float playerSpeedY = 0.0f;
float groundAngle = 0.0f;
float groundSpeed = 0.0f;
bool hasJumped = false;
bool isOnGround = true;
bool isSpindashing = false;
bool isRolling = false;
bool isHurt = false;
bool isDead = false;
bool isSuper = false;
int controlLockTimer = 0;
int facing = 1; // 1 = right, -1 = left
SlipAngleType slipAngleType = SONIC_1_2_CD;