// Player Collision - SPG-accurate collision detection implementation
#include "player-collision.h"
#include "../../util/util-global.h"
#include <math.h>
#include <stdio.h>

// Tiled flip flags
#define FLIPPED_HORIZONTALLY_FLAG 0x80000000
#define FLIPPED_VERTICALLY_FLAG   0x40000000
#define FLIPPED_DIAGONALLY_FLAG   0x20000000
#define TILE_ID_MASK              0x1FFFFFFF

// Global level collision data
LevelCollision g_LevelCollision = {NULL, 0, 0};

// Initialize collision system
void InitCollisionSystem(int** levelData, int levelWidth, int levelHeight) {
    g_LevelCollision.tileData = levelData;
    g_LevelCollision.width = levelWidth;
    g_LevelCollision.height = levelHeight;
}

// Get collision mode from angle (SPG four-mode system)
// Angles are 0-255 where 0=flat ground, 64=right wall, 128=ceiling, 192=left wall
CollisionMode GetCollisionModeFromAngle(uint8_t angle) {
    // Convert to degrees for easier understanding: angle * 360 / 256 = angle * 1.40625
    // Floor: 0-45° (0-32) and 315-360° (224-255)
    // Right Wall: 46-134° (33-95)
    // Ceiling: 135-225° (96-160)
    // Left Wall: 226-314° (161-223)

    if (angle <= 32 || angle >= 224) {
        return MODE_FLOOR;
    } else if (angle >= 33 && angle <= 95) {
        return MODE_RIGHT_WALL;
    } else if (angle >= 96 && angle <= 160) {
        return MODE_CEILING;
    } else {
        return MODE_LEFT_WALL;
    }
}

// Convert angle byte (0-255) to radians
float AngleByteToRadians(uint8_t angleByte) {
    return (angleByte / 256.0f) * 2.0f * PI;
}

// Convert angle byte to degrees
float AngleByteToDegrees(uint8_t angleByte) {
    return (angleByte / 256.0f) * 360.0f;
}

// Get tile at world position with flip flags
int GetTileAtPosition(int worldX, int worldY, bool* flipH, bool* flipV) {
    if (!g_LevelCollision.tileData) return 0;

    int tileX = worldX / TILE_SIZE;
    int tileY = worldY / TILE_SIZE;

    // Bounds check
    if (tileX < 0 || tileX >= g_LevelCollision.width ||
        tileY < 0 || tileY >= g_LevelCollision.height) {
        if (flipH) *flipH = false;
        if (flipV) *flipV = false;
        return 0;
    }

    uint32_t rawValue = (uint32_t)g_LevelCollision.tileData[tileY][tileX];

    // Extract flip flags
    if (flipH) *flipH = (rawValue & FLIPPED_HORIZONTALLY_FLAG) != 0;
    if (flipV) *flipV = (rawValue & FLIPPED_VERTICALLY_FLAG) != 0;

    // Return tile ID
    return (int)(rawValue & TILE_ID_MASK);
}

// Check if tile is solid
bool IsTileSolid(int tileId) {
    return tileId > 0 && tileId < TILESET_TILE_COUNT;
}

// Get height at X position within a tile (for floor/ceiling collision)
int GetTileHeightAtX(int tileId, int localX, bool flipH, bool flipV) {
    if (tileId <= 0 || tileId >= TILESET_TILE_COUNT) return 0;

    // Handle horizontal flip - mirror the X coordinate
    int x = flipH ? (TILE_SIZE - 1 - localX) : localX;

    // Clamp to valid range
    if (x < 0) x = 0;
    if (x >= TILE_SIZE) x = TILE_SIZE - 1;

    int height = TILESET_HEIGHTMAPS[tileId][x];

    // Handle vertical flip - invert height
    if (flipV && height > 0) {
        height = TILE_SIZE - height;
    }

    return height;
}

// Get width at Y position within a tile (for wall collision)
int GetTileWidthAtY(int tileId, int localY, bool flipH, bool flipV) {
    if (tileId <= 0 || tileId >= TILESET_TILE_COUNT) return 0;

    // Handle vertical flip - mirror the Y coordinate
    int y = flipV ? (TILE_SIZE - 1 - localY) : localY;

    // Clamp to valid range
    if (y < 0) y = 0;
    if (y >= TILE_SIZE) y = TILE_SIZE - 1;

    int width = TILESET_WIDTHMAPS[tileId][y];

    // Handle horizontal flip - invert width
    if (flipH && width > 0) {
        width = TILE_SIZE - width;
    }

    return width;
}

// Core sensor check for floor mode (downward-pointing sensor)
static SensorResult CheckFloorSensor(Vector2 sensorPos) {
    SensorResult result = {0};
    result.found = false;
    result.distance = TILE_SIZE; // Default to "not found" distance

    // Get the tile we're in
    int tileX = (int)sensorPos.x / TILE_SIZE;
    int tileY = (int)sensorPos.y / TILE_SIZE;
    int localX = (int)sensorPos.x % TILE_SIZE;
    int localY = (int)sensorPos.y % TILE_SIZE;

    // Handle negative coordinates
    if (sensorPos.x < 0) {
        tileX--;
        localX = TILE_SIZE + ((int)sensorPos.x % TILE_SIZE);
        if (localX == TILE_SIZE) { localX = 0; tileX++; }
    }
    if (sensorPos.y < 0) {
        tileY--;
        localY = TILE_SIZE + ((int)sensorPos.y % TILE_SIZE);
        if (localY == TILE_SIZE) { localY = 0; tileY++; }
    }

    bool flipH, flipV;
    int tileId = GetTileAtPosition((int)sensorPos.x, (int)sensorPos.y, &flipH, &flipV);

    if (IsTileSolid(tileId)) {
        int height = GetTileHeightAtX(tileId, localX, flipH, flipV);

        if (height > 0) {
            // Calculate distance from sensor to surface
            // Height is measured from bottom of tile
            int surfaceY;
            if (flipV) {
                // Flipped vertically - height is from top
                surfaceY = tileY * TILE_SIZE + height;
            } else {
                // Normal - height is from bottom
                surfaceY = (tileY + 1) * TILE_SIZE - height;
            }

            result.distance = surfaceY - (int)sensorPos.y;
            result.found = true;
            result.tileX = tileX;
            result.tileY = tileY;
            result.tileId = tileId;
            result.angle = GetTileAngle(tileId);
            result.surfacePoint = (Vector2){sensorPos.x, (float)surfaceY};

            // If height is 16 (full tile), check tile above for regression
            if (height == TILE_SIZE && result.distance >= 0) {
                // Check tile above
                int aboveTileId = GetTileAtPosition((int)sensorPos.x, (int)sensorPos.y - TILE_SIZE, &flipH, &flipV);
                if (IsTileSolid(aboveTileId)) {
                    int aboveHeight = GetTileHeightAtX(aboveTileId, localX, flipH, flipV);
                    if (aboveHeight > 0) {
                        int aboveSurfaceY;
                        if (flipV) {
                            aboveSurfaceY = (tileY - 1) * TILE_SIZE + aboveHeight;
                        } else {
                            aboveSurfaceY = tileY * TILE_SIZE - aboveHeight;
                        }
                        result.distance = aboveSurfaceY - (int)sensorPos.y;
                        result.tileY = tileY - 1;
                        result.tileId = aboveTileId;
                        result.angle = GetTileAngle(aboveTileId);
                        result.surfacePoint.y = (float)aboveSurfaceY;
                    }
                }
            }

            return result;
        }
    }

    // No solid tile at sensor position - check tile below (extension)
    tileId = GetTileAtPosition((int)sensorPos.x, (int)sensorPos.y + TILE_SIZE, &flipH, &flipV);

    if (IsTileSolid(tileId)) {
        int height = GetTileHeightAtX(tileId, localX, flipH, flipV);

        if (height > 0) {
            int surfaceY;
            if (flipV) {
                surfaceY = (tileY + 1) * TILE_SIZE + height;
            } else {
                surfaceY = (tileY + 2) * TILE_SIZE - height;
            }

            result.distance = surfaceY - (int)sensorPos.y;
            result.found = true;
            result.tileX = tileX;
            result.tileY = tileY + 1;
            result.tileId = tileId;
            result.angle = GetTileAngle(tileId);
            result.surfacePoint = (Vector2){sensorPos.x, (float)surfaceY};
        }
    }

    return result;
}

// Core sensor check for ceiling mode (upward-pointing sensor)
static SensorResult CheckCeilingSensor(Vector2 sensorPos) {
    SensorResult result = {0};
    result.found = false;
    result.distance = TILE_SIZE;

    int tileX = (int)sensorPos.x / TILE_SIZE;
    int tileY = (int)sensorPos.y / TILE_SIZE;
    int localX = (int)sensorPos.x % TILE_SIZE;

    if (sensorPos.x < 0) {
        tileX--;
        localX = TILE_SIZE + ((int)sensorPos.x % TILE_SIZE);
        if (localX == TILE_SIZE) { localX = 0; tileX++; }
    }
    if (sensorPos.y < 0) {
        tileY--;
    }

    bool flipH, flipV;
    int tileId = GetTileAtPosition((int)sensorPos.x, (int)sensorPos.y, &flipH, &flipV);

    if (IsTileSolid(tileId)) {
        int height = GetTileHeightAtX(tileId, localX, flipH, flipV);

        if (height > 0) {
            // For ceiling, we check from below
            int surfaceY;
            if (flipV) {
                surfaceY = (tileY + 1) * TILE_SIZE - height;
            } else {
                surfaceY = tileY * TILE_SIZE + height;
            }

            result.distance = (int)sensorPos.y - surfaceY;
            result.found = true;
            result.tileX = tileX;
            result.tileY = tileY;
            result.tileId = tileId;
            result.angle = GetTileAngle(tileId);
            result.surfacePoint = (Vector2){sensorPos.x, (float)surfaceY};

            return result;
        }
    }

    // Check tile above for extension
    tileId = GetTileAtPosition((int)sensorPos.x, (int)sensorPos.y - TILE_SIZE, &flipH, &flipV);

    if (IsTileSolid(tileId)) {
        int height = GetTileHeightAtX(tileId, localX, flipH, flipV);

        if (height > 0) {
            int surfaceY;
            if (flipV) {
                surfaceY = tileY * TILE_SIZE - height;
            } else {
                surfaceY = (tileY - 1) * TILE_SIZE + height;
            }

            result.distance = (int)sensorPos.y - surfaceY;
            result.found = true;
            result.tileX = tileX;
            result.tileY = tileY - 1;
            result.tileId = tileId;
            result.angle = GetTileAngle(tileId);
            result.surfacePoint = (Vector2){sensorPos.x, (float)surfaceY};
        }
    }

    return result;
}

// Core sensor check for right wall mode (rightward-pointing sensor)
static SensorResult CheckRightWallSensor(Vector2 sensorPos) {
    SensorResult result = {0};
    result.found = false;
    result.distance = TILE_SIZE;

    int tileX = (int)sensorPos.x / TILE_SIZE;
    int tileY = (int)sensorPos.y / TILE_SIZE;
    int localY = (int)sensorPos.y % TILE_SIZE;

    if (sensorPos.x < 0) {
        tileX--;
    }
    if (sensorPos.y < 0) {
        tileY--;
        localY = TILE_SIZE + ((int)sensorPos.y % TILE_SIZE);
        if (localY == TILE_SIZE) { localY = 0; tileY++; }
    }

    bool flipH, flipV;
    int tileId = GetTileAtPosition((int)sensorPos.x, (int)sensorPos.y, &flipH, &flipV);

    if (IsTileSolid(tileId)) {
        int width = GetTileWidthAtY(tileId, localY, flipH, flipV);

        if (width > 0) {
            // Width is from left side of tile
            int surfaceX = tileX * TILE_SIZE + width;

            if (flipH) {
                surfaceX = (tileX + 1) * TILE_SIZE - width;
            }

            result.distance = surfaceX - (int)sensorPos.x;
            result.found = true;
            result.tileX = tileX;
            result.tileY = tileY;
            result.tileId = tileId;
            result.angle = (uint8_t)TILESET_WIDTH_ANGLES[tileId];
            result.surfacePoint = (Vector2){(float)surfaceX, sensorPos.y};

            return result;
        }
    }

    // Check tile to the right for extension
    tileId = GetTileAtPosition((int)sensorPos.x + TILE_SIZE, (int)sensorPos.y, &flipH, &flipV);

    if (IsTileSolid(tileId)) {
        int width = GetTileWidthAtY(tileId, localY, flipH, flipV);

        if (width > 0) {
            int surfaceX = (tileX + 1) * TILE_SIZE + width;

            if (flipH) {
                surfaceX = (tileX + 2) * TILE_SIZE - width;
            }

            result.distance = surfaceX - (int)sensorPos.x;
            result.found = true;
            result.tileX = tileX + 1;
            result.tileY = tileY;
            result.tileId = tileId;
            result.angle = (uint8_t)TILESET_WIDTH_ANGLES[tileId];
            result.surfacePoint = (Vector2){(float)surfaceX, sensorPos.y};
        }
    }

    return result;
}

// Core sensor check for left wall mode (leftward-pointing sensor)
static SensorResult CheckLeftWallSensor(Vector2 sensorPos) {
    SensorResult result = {0};
    result.found = false;
    result.distance = TILE_SIZE;

    int tileX = (int)sensorPos.x / TILE_SIZE;
    int tileY = (int)sensorPos.y / TILE_SIZE;
    int localY = (int)sensorPos.y % TILE_SIZE;

    if (sensorPos.x < 0) {
        tileX--;
    }
    if (sensorPos.y < 0) {
        tileY--;
        localY = TILE_SIZE + ((int)sensorPos.y % TILE_SIZE);
        if (localY == TILE_SIZE) { localY = 0; tileY++; }
    }

    bool flipH, flipV;
    int tileId = GetTileAtPosition((int)sensorPos.x, (int)sensorPos.y, &flipH, &flipV);

    if (IsTileSolid(tileId)) {
        int width = GetTileWidthAtY(tileId, localY, flipH, flipV);

        if (width > 0) {
            int surfaceX = (tileX + 1) * TILE_SIZE - width;

            if (flipH) {
                surfaceX = tileX * TILE_SIZE + width;
            }

            result.distance = (int)sensorPos.x - surfaceX;
            result.found = true;
            result.tileX = tileX;
            result.tileY = tileY;
            result.tileId = tileId;
            result.angle = (uint8_t)TILESET_WIDTH_ANGLES[tileId];
            result.surfacePoint = (Vector2){(float)surfaceX, sensorPos.y};

            return result;
        }
    }

    // Check tile to the left for extension
    tileId = GetTileAtPosition((int)sensorPos.x - TILE_SIZE, (int)sensorPos.y, &flipH, &flipV);

    if (IsTileSolid(tileId)) {
        int width = GetTileWidthAtY(tileId, localY, flipH, flipV);

        if (width > 0) {
            int surfaceX = tileX * TILE_SIZE - width;

            if (flipH) {
                surfaceX = (tileX - 1) * TILE_SIZE + width;
            }

            result.distance = (int)sensorPos.x - surfaceX;
            result.found = true;
            result.tileX = tileX - 1;
            result.tileY = tileY;
            result.tileId = tileId;
            result.angle = (uint8_t)TILESET_WIDTH_ANGLES[tileId];
            result.surfacePoint = (Vector2){(float)surfaceX, sensorPos.y};
        }
    }

    return result;
}

// Generic sensor check based on collision mode
SensorResult CheckSensor(Vector2 position, Vector2 direction, CollisionMode mode) {
    switch (mode) {
        case MODE_FLOOR:
            return CheckFloorSensor(position);
        case MODE_CEILING:
            return CheckCeilingSensor(position);
        case MODE_RIGHT_WALL:
            return CheckRightWallSensor(position);
        case MODE_LEFT_WALL:
            return CheckLeftWallSensor(position);
        default:
            return CheckFloorSensor(position);
    }
}

// Check ground sensors A and B, return the winning result
SensorResult CheckGroundSensors(Vector2 playerPos, float widthRadius, float heightRadius,
                                 CollisionMode mode, uint8_t currentAngle,
                                 SensorResult* outSensorA, SensorResult* outSensorB) {
    // Calculate sensor positions based on collision mode
    Vector2 sensorAPos, sensorBPos;
    float angleRad = AngleByteToRadians(currentAngle);

    // Rotate sensor offsets by current angle
    float cosA = cosf(angleRad);
    float sinA = sinf(angleRad);

    // Base offsets (floor mode)
    float offsetX = widthRadius;
    float offsetY = heightRadius;

    switch (mode) {
        case MODE_FLOOR:
            // A is left, B is right, both at bottom
            sensorAPos = (Vector2){
                playerPos.x - widthRadius,
                playerPos.y + heightRadius
            };
            sensorBPos = (Vector2){
                playerPos.x + widthRadius,
                playerPos.y + heightRadius
            };
            break;

        case MODE_RIGHT_WALL:
            // Sensors rotated 90° CW - now on right side
            sensorAPos = (Vector2){
                playerPos.x + heightRadius,
                playerPos.y - widthRadius
            };
            sensorBPos = (Vector2){
                playerPos.x + heightRadius,
                playerPos.y + widthRadius
            };
            break;

        case MODE_CEILING:
            // Sensors rotated 180° - now on top
            sensorAPos = (Vector2){
                playerPos.x + widthRadius,
                playerPos.y - heightRadius
            };
            sensorBPos = (Vector2){
                playerPos.x - widthRadius,
                playerPos.y - heightRadius
            };
            break;

        case MODE_LEFT_WALL:
            // Sensors rotated 270° - now on left side
            sensorAPos = (Vector2){
                playerPos.x - heightRadius,
                playerPos.y + widthRadius
            };
            sensorBPos = (Vector2){
                playerPos.x - heightRadius,
                playerPos.y - widthRadius
            };
            break;
    }

    // Perform sensor checks
    SensorResult resultA = CheckSensor(sensorAPos, (Vector2){0, 1}, mode);
    SensorResult resultB = CheckSensor(sensorBPos, (Vector2){0, 1}, mode);

    // Output individual results if requested
    if (outSensorA) *outSensorA = resultA;
    if (outSensorB) *outSensorB = resultB;

    // Determine winner - smallest distance wins, A wins ties
    if (!resultA.found && !resultB.found) {
        // Neither found anything
        SensorResult empty = {0};
        empty.found = false;
        empty.distance = TILE_SIZE * 2; // Max distance
        return empty;
    }

    if (!resultA.found) return resultB;
    if (!resultB.found) return resultA;

    // Both found - compare distances (SPG: if equal, A wins)
    if (resultA.distance <= resultB.distance) {
        return resultA;
    }
    return resultB;
}

// Check ceiling sensors C and D
SensorResult CheckCeilingSensors(Vector2 playerPos, float widthRadius, float heightRadius,
                                  CollisionMode mode, uint8_t currentAngle,
                                  SensorResult* outSensorC, SensorResult* outSensorD) {
    Vector2 sensorCPos, sensorDPos;

    switch (mode) {
        case MODE_FLOOR:
            // C is left, D is right, both at top
            sensorCPos = (Vector2){
                playerPos.x - widthRadius,
                playerPos.y - heightRadius
            };
            sensorDPos = (Vector2){
                playerPos.x + widthRadius,
                playerPos.y - heightRadius
            };
            break;

        case MODE_RIGHT_WALL:
            sensorCPos = (Vector2){
                playerPos.x - heightRadius,
                playerPos.y - widthRadius
            };
            sensorDPos = (Vector2){
                playerPos.x - heightRadius,
                playerPos.y + widthRadius
            };
            break;

        case MODE_CEILING:
            sensorCPos = (Vector2){
                playerPos.x + widthRadius,
                playerPos.y + heightRadius
            };
            sensorDPos = (Vector2){
                playerPos.x - widthRadius,
                playerPos.y + heightRadius
            };
            break;

        case MODE_LEFT_WALL:
            sensorCPos = (Vector2){
                playerPos.x + heightRadius,
                playerPos.y + widthRadius
            };
            sensorDPos = (Vector2){
                playerPos.x + heightRadius,
                playerPos.y - widthRadius
            };
            break;
    }

    // Check as ceiling sensors (upward)
    CollisionMode ceilingMode;
    switch (mode) {
        case MODE_FLOOR: ceilingMode = MODE_CEILING; break;
        case MODE_RIGHT_WALL: ceilingMode = MODE_LEFT_WALL; break;
        case MODE_CEILING: ceilingMode = MODE_FLOOR; break;
        case MODE_LEFT_WALL: ceilingMode = MODE_RIGHT_WALL; break;
        default: ceilingMode = MODE_CEILING; break;
    }

    SensorResult resultC = CheckSensor(sensorCPos, (Vector2){0, -1}, ceilingMode);
    SensorResult resultD = CheckSensor(sensorDPos, (Vector2){0, -1}, ceilingMode);

    if (outSensorC) *outSensorC = resultC;
    if (outSensorD) *outSensorD = resultD;

    if (!resultC.found && !resultD.found) {
        SensorResult empty = {0};
        empty.found = false;
        empty.distance = TILE_SIZE * 2;
        return empty;
    }

    if (!resultC.found) return resultD;
    if (!resultD.found) return resultC;

    if (resultC.distance <= resultD.distance) {
        return resultC;
    }
    return resultD;
}

// Check wall/push sensors E and F
void CheckWallSensors(Vector2 playerPos, float pushRadius, CollisionMode mode,
                      SensorResult* outSensorE, SensorResult* outSensorF) {
    // Push sensors are always at player center height
    // E is left, F is right (in floor mode)
    Vector2 sensorEPos, sensorFPos;

    switch (mode) {
        case MODE_FLOOR:
        case MODE_CEILING:
            sensorEPos = (Vector2){playerPos.x - pushRadius, playerPos.y};
            sensorFPos = (Vector2){playerPos.x + pushRadius, playerPos.y};
            break;

        case MODE_RIGHT_WALL:
        case MODE_LEFT_WALL:
            sensorEPos = (Vector2){playerPos.x, playerPos.y - pushRadius};
            sensorFPos = (Vector2){playerPos.x, playerPos.y + pushRadius};
            break;
    }

    // E checks left wall, F checks right wall
    SensorResult resultE = CheckLeftWallSensor(sensorEPos);
    SensorResult resultF = CheckRightWallSensor(sensorFPos);

    if (outSensorE) *outSensorE = resultE;
    if (outSensorF) *outSensorF = resultF;
}
