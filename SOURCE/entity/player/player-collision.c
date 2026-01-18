// Player Collision System Implementation
// SPG-accurate sensor-based collision

#include "player-collision.h"
#include "../../data/collision_data/collision-generated_heightmaps.h"
#include "../../data/collision_data/collision-generated_widthmaps.h"
#include "../../data/collision_data/collision-generated_tile_angles.h"
#include <stdio.h>

// Tiled flip flags (same as in screen-game.c)
#define FLIPPED_HORIZONTALLY_FLAG 0x80000000
#define FLIPPED_VERTICALLY_FLAG   0x40000000
#define FLIPPED_DIAGONALLY_FLAG   0x20000000
#define TILE_ID_MASK              0x1FFFFFFF

// ========== Mode Determination ==========

CollisionMode GetCollisionModeFromAngle(float groundAngle) {
    // Normalize angle to 0-360
    while (groundAngle < 0) groundAngle += 360.0f;
    while (groundAngle >= 360) groundAngle -= 360.0f;

    // SPG ranges for ground sensors
    if ((groundAngle >= 0 && groundAngle <= 45) || (groundAngle >= 315 && groundAngle < 360)) {
        return MODE_FLOOR;
    } else if (groundAngle >= 46 && groundAngle <= 134) {
        return MODE_RIGHT_WALL;
    } else if (groundAngle >= 135 && groundAngle <= 225) {
        return MODE_CEILING;
    } else {
        return MODE_LEFT_WALL;
    }
}

CollisionMode GetPushSensorModeFromAngle(float groundAngle) {
    // Normalize angle to 0-360
    while (groundAngle < 0) groundAngle += 360.0f;
    while (groundAngle >= 360) groundAngle -= 360.0f;

    // SPG ranges for push sensors (slightly different from ground sensors)
    if ((groundAngle >= 0 && groundAngle <= 44) || (groundAngle >= 316 && groundAngle < 360)) {
        return MODE_FLOOR;
    } else if (groundAngle >= 45 && groundAngle <= 135) {
        return MODE_RIGHT_WALL;
    } else if (groundAngle >= 136 && groundAngle <= 224) {
        return MODE_CEILING;
    } else {
        return MODE_LEFT_WALL;
    }
}

// ========== Tile Data Access ==========

void InitLevelCollision(LevelCollision* collision, int** tileData, int width, int height) {
    collision->tileData = tileData;
    collision->levelWidth = width;
    collision->levelHeight = height;
}

int GetTileAtPosition(float worldX, float worldY, const LevelCollision* level) {
    if (!level || !level->tileData) return 0;

    int tileX = (int)(worldX / TILE_SIZE);
    int tileY = (int)(worldY / TILE_SIZE);

    // Bounds check
    if (tileX < 0 || tileX >= level->levelWidth ||
        tileY < 0 || tileY >= level->levelHeight) {
        return 0;
    }

    return level->tileData[tileY][tileX];
}

// Extract tile ID and flip flags from raw tile value
static void ParseTileValue(int rawValue, int* outTileId, bool* outFlipH, bool* outFlipV, bool* outFlipD) {
    uint32_t raw = (uint32_t)rawValue;
    *outFlipH = (raw & FLIPPED_HORIZONTALLY_FLAG) != 0;
    *outFlipV = (raw & FLIPPED_VERTICALLY_FLAG) != 0;
    *outFlipD = (raw & FLIPPED_DIAGONALLY_FLAG) != 0;
    *outTileId = (int)(raw & TILE_ID_MASK);
}

int GetHeightAtPosition(int tileId, int localX, bool flipH, bool flipV) {
    if (tileId <= 0 || tileId >= TILESET_TILE_COUNT) return 0;

    // Clamp localX to valid range
    if (localX < 0) localX = 0;
    if (localX >= TILE_SIZE) localX = TILE_SIZE - 1;

    // Handle horizontal flip
    int x = flipH ? (TILE_SIZE - 1 - localX) : localX;

    int height = TILESET_HEIGHTMAPS[tileId][x];

    // Handle vertical flip - if flipped, invert the height
    if (flipV && height > 0) {
        height = TILE_SIZE - height;
    }

    return height;
}

int GetWidthAtPosition(int tileId, int localY, bool flipH, bool flipV) {
    if (tileId <= 0 || tileId >= TILESET_TILE_COUNT) return 0;

    // Clamp localY to valid range
    if (localY < 0) localY = 0;
    if (localY >= TILE_SIZE) localY = TILE_SIZE - 1;

    // Handle vertical flip
    int y = flipV ? (TILE_SIZE - 1 - localY) : localY;

    int width = TILESET_WIDTHMAPS[tileId][y];

    // Handle horizontal flip - if flipped, invert the width
    if (flipH && width > 0) {
        width = TILE_SIZE - width;
    }

    return width;
}

float GetTileAngleFlipped(int tileId, bool flipH, bool flipV) {
    if (tileId <= 0 || tileId >= TILESET_TILE_COUNT) return 0.0f;

    float angle = (float)TILESET_HEIGHT_ANGLES[tileId];

    // Handle flips - angles need to be mirrored/inverted
    if (flipH) {
        // Mirror horizontally: 360 - angle (or negate and wrap)
        angle = 360.0f - angle;
        if (angle >= 360.0f) angle -= 360.0f;
    }
    if (flipV) {
        // Mirror vertically: 180 - angle (then wrap)
        angle = 180.0f - angle;
        if (angle < 0) angle += 360.0f;
    }

    return angle;
}

bool IsTileFlagged(int tileId) {
    if (tileId <= 0 || tileId >= TILESET_TILE_COUNT) return false;
    // In original games, angle of 255 (hex) means flagged
    // We'll check if angle is exactly 0 for full blocks which should snap
    return TILESET_HEIGHT_ANGLES[tileId] == 0 && tileId > 0;
}

float SnapAngleToCardinal(float currentAngle) {
    // Snap to nearest 90 degrees (0, 90, 180, 270)
    float snapped = roundf(currentAngle / 90.0f);
    snapped = fmodf(snapped, 4.0f) * 90.0f;
    if (snapped < 0) snapped += 360.0f;
    return snapped;
}

// ========== Core Sensor Casting ==========

SensorResult CastSensor(float anchorX, float anchorY, SensorDirection direction,
                        const LevelCollision* level) {
    SensorResult result = {
        .distance = SENSOR_EXTENSION_LIMIT,
        .angle = 0.0f,
        .tileId = 0,
        .found = false,
        .flagged = false
    };

    if (!level || !level->tileData) return result;

    // Determine which tile the anchor is in
    int tileX = (int)floorf(anchorX / TILE_SIZE);
    int tileY = (int)floorf(anchorY / TILE_SIZE);

    // Local position within tile
    int localX = (int)anchorX % TILE_SIZE;
    int localY = (int)anchorY % TILE_SIZE;
    if (localX < 0) localX += TILE_SIZE;
    if (localY < 0) localY += TILE_SIZE;

    // Get tile at anchor position
    int rawTile = GetTileAtPosition(anchorX, anchorY, level);
    int tileId;
    bool flipH, flipV, flipD;
    ParseTileValue(rawTile, &tileId, &flipH, &flipV, &flipD);

    int detectedHeight = 0;
    float tileTopY, tileSurfaceY;
    float tileLeftX, tileSurfaceX;

    switch (direction) {
        case SENSOR_DOWN: {
            // Sensor pointing downward, looking for floor
            detectedHeight = GetHeightAtPosition(tileId, localX, flipH, flipV);

            if (detectedHeight > 0 && detectedHeight < TILE_SIZE) {
                // Found surface in this tile
                tileSurfaceY = (tileY + 1) * TILE_SIZE - detectedHeight;
                result.distance = tileSurfaceY - anchorY;
                result.tileId = tileId;
                result.angle = GetTileAngleFlipped(tileId, flipH, flipV);
                result.found = true;
                result.flagged = IsTileFlagged(tileId);
            } else if (detectedHeight == TILE_SIZE) {
                // Full tile - regress (check tile above)
                int aboveRawTile = GetTileAtPosition(anchorX, anchorY - TILE_SIZE, level);
                int aboveTileId;
                bool aboveFlipH, aboveFlipV, aboveFlipD;
                ParseTileValue(aboveRawTile, &aboveTileId, &aboveFlipH, &aboveFlipV, &aboveFlipD);

                int aboveHeight = GetHeightAtPosition(aboveTileId, localX, aboveFlipH, aboveFlipV);

                if (aboveHeight > 0) {
                    tileSurfaceY = tileY * TILE_SIZE - aboveHeight;
                    result.distance = tileSurfaceY - anchorY;
                    result.tileId = aboveTileId;
                    result.angle = GetTileAngleFlipped(aboveTileId, aboveFlipH, aboveFlipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(aboveTileId);
                } else {
                    // Above tile is empty, use current tile's surface
                    tileSurfaceY = tileY * TILE_SIZE;
                    result.distance = tileSurfaceY - anchorY;
                    result.tileId = tileId;
                    result.angle = GetTileAngleFlipped(tileId, flipH, flipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(tileId);
                }
            } else {
                // Empty tile - extend (check tile below)
                int belowRawTile = GetTileAtPosition(anchorX, anchorY + TILE_SIZE, level);
                int belowTileId;
                bool belowFlipH, belowFlipV, belowFlipD;
                ParseTileValue(belowRawTile, &belowTileId, &belowFlipH, &belowFlipV, &belowFlipD);

                int belowHeight = GetHeightAtPosition(belowTileId, localX, belowFlipH, belowFlipV);

                if (belowHeight > 0) {
                    tileSurfaceY = (tileY + 2) * TILE_SIZE - belowHeight;
                    result.distance = tileSurfaceY - anchorY;
                    result.tileId = belowTileId;
                    result.angle = GetTileAngleFlipped(belowTileId, belowFlipH, belowFlipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(belowTileId);
                }
                // If still not found, result.found remains false
            }
            break;
        }

        case SENSOR_UP: {
            // Sensor pointing upward, looking for ceiling
            // For ceiling, we check from bottom of tile
            detectedHeight = GetHeightAtPosition(tileId, localX, flipH, !flipV); // Invert V for ceiling check

            if (detectedHeight > 0 && detectedHeight < TILE_SIZE) {
                tileSurfaceY = tileY * TILE_SIZE + detectedHeight;
                result.distance = anchorY - tileSurfaceY;
                result.tileId = tileId;
                result.angle = GetTileAngleFlipped(tileId, flipH, flipV);
                result.found = true;
                result.flagged = IsTileFlagged(tileId);
            } else if (detectedHeight == TILE_SIZE) {
                // Full tile - regress (check tile below)
                int belowRawTile = GetTileAtPosition(anchorX, anchorY + TILE_SIZE, level);
                int belowTileId;
                bool belowFlipH, belowFlipV, belowFlipD;
                ParseTileValue(belowRawTile, &belowTileId, &belowFlipH, &belowFlipV, &belowFlipD);

                int belowHeight = GetHeightAtPosition(belowTileId, localX, belowFlipH, !belowFlipV);

                if (belowHeight > 0) {
                    tileSurfaceY = (tileY + 1) * TILE_SIZE + belowHeight;
                    result.distance = anchorY - tileSurfaceY;
                    result.tileId = belowTileId;
                    result.angle = GetTileAngleFlipped(belowTileId, belowFlipH, belowFlipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(belowTileId);
                } else {
                    tileSurfaceY = (tileY + 1) * TILE_SIZE;
                    result.distance = anchorY - tileSurfaceY;
                    result.tileId = tileId;
                    result.angle = GetTileAngleFlipped(tileId, flipH, flipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(tileId);
                }
            } else {
                // Empty tile - extend (check tile above)
                int aboveRawTile = GetTileAtPosition(anchorX, anchorY - TILE_SIZE, level);
                int aboveTileId;
                bool aboveFlipH, aboveFlipV, aboveFlipD;
                ParseTileValue(aboveRawTile, &aboveTileId, &aboveFlipH, &aboveFlipV, &aboveFlipD);

                int aboveHeight = GetHeightAtPosition(aboveTileId, localX, aboveFlipH, !aboveFlipV);

                if (aboveHeight > 0) {
                    tileSurfaceY = (tileY - 1) * TILE_SIZE + aboveHeight;
                    result.distance = anchorY - tileSurfaceY;
                    result.tileId = aboveTileId;
                    result.angle = GetTileAngleFlipped(aboveTileId, aboveFlipH, aboveFlipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(aboveTileId);
                }
            }
            break;
        }

        case SENSOR_RIGHT: {
            // Sensor pointing right, looking for wall
            int detectedWidth = GetWidthAtPosition(tileId, localY, flipH, flipV);

            if (detectedWidth > 0 && detectedWidth < TILE_SIZE) {
                tileSurfaceX = (tileX + 1) * TILE_SIZE - detectedWidth;
                result.distance = tileSurfaceX - anchorX;
                result.tileId = tileId;
                result.angle = GetTileAngleFlipped(tileId, flipH, flipV);
                result.found = true;
                result.flagged = IsTileFlagged(tileId);
            } else if (detectedWidth == TILE_SIZE) {
                // Full tile - regress (check tile to left)
                int leftRawTile = GetTileAtPosition(anchorX - TILE_SIZE, anchorY, level);
                int leftTileId;
                bool leftFlipH, leftFlipV, leftFlipD;
                ParseTileValue(leftRawTile, &leftTileId, &leftFlipH, &leftFlipV, &leftFlipD);

                int leftWidth = GetWidthAtPosition(leftTileId, localY, leftFlipH, leftFlipV);

                if (leftWidth > 0) {
                    tileSurfaceX = tileX * TILE_SIZE - leftWidth;
                    result.distance = tileSurfaceX - anchorX;
                    result.tileId = leftTileId;
                    result.angle = GetTileAngleFlipped(leftTileId, leftFlipH, leftFlipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(leftTileId);
                } else {
                    tileSurfaceX = tileX * TILE_SIZE;
                    result.distance = tileSurfaceX - anchorX;
                    result.tileId = tileId;
                    result.angle = GetTileAngleFlipped(tileId, flipH, flipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(tileId);
                }
            } else {
                // Empty tile - extend (check tile to right)
                int rightRawTile = GetTileAtPosition(anchorX + TILE_SIZE, anchorY, level);
                int rightTileId;
                bool rightFlipH, rightFlipV, rightFlipD;
                ParseTileValue(rightRawTile, &rightTileId, &rightFlipH, &rightFlipV, &rightFlipD);

                int rightWidth = GetWidthAtPosition(rightTileId, localY, rightFlipH, rightFlipV);

                if (rightWidth > 0) {
                    tileSurfaceX = (tileX + 2) * TILE_SIZE - rightWidth;
                    result.distance = tileSurfaceX - anchorX;
                    result.tileId = rightTileId;
                    result.angle = GetTileAngleFlipped(rightTileId, rightFlipH, rightFlipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(rightTileId);
                }
            }
            break;
        }

        case SENSOR_LEFT: {
            // Sensor pointing left, looking for wall
            int detectedWidth = GetWidthAtPosition(tileId, localY, !flipH, flipV); // Invert H for left-facing

            if (detectedWidth > 0 && detectedWidth < TILE_SIZE) {
                tileSurfaceX = tileX * TILE_SIZE + detectedWidth;
                result.distance = anchorX - tileSurfaceX;
                result.tileId = tileId;
                result.angle = GetTileAngleFlipped(tileId, flipH, flipV);
                result.found = true;
                result.flagged = IsTileFlagged(tileId);
            } else if (detectedWidth == TILE_SIZE) {
                // Full tile - regress (check tile to right)
                int rightRawTile = GetTileAtPosition(anchorX + TILE_SIZE, anchorY, level);
                int rightTileId;
                bool rightFlipH, rightFlipV, rightFlipD;
                ParseTileValue(rightRawTile, &rightTileId, &rightFlipH, &rightFlipV, &rightFlipD);

                int rightWidth = GetWidthAtPosition(rightTileId, localY, !rightFlipH, rightFlipV);

                if (rightWidth > 0) {
                    tileSurfaceX = (tileX + 1) * TILE_SIZE + rightWidth;
                    result.distance = anchorX - tileSurfaceX;
                    result.tileId = rightTileId;
                    result.angle = GetTileAngleFlipped(rightTileId, rightFlipH, rightFlipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(rightTileId);
                } else {
                    tileSurfaceX = (tileX + 1) * TILE_SIZE;
                    result.distance = anchorX - tileSurfaceX;
                    result.tileId = tileId;
                    result.angle = GetTileAngleFlipped(tileId, flipH, flipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(tileId);
                }
            } else {
                // Empty tile - extend (check tile to left)
                int leftRawTile = GetTileAtPosition(anchorX - TILE_SIZE, anchorY, level);
                int leftTileId;
                bool leftFlipH, leftFlipV, leftFlipD;
                ParseTileValue(leftRawTile, &leftTileId, &leftFlipH, &leftFlipV, &leftFlipD);

                int leftWidth = GetWidthAtPosition(leftTileId, localY, !leftFlipH, leftFlipV);

                if (leftWidth > 0) {
                    tileSurfaceX = (tileX - 1) * TILE_SIZE + leftWidth;
                    result.distance = anchorX - tileSurfaceX;
                    result.tileId = leftTileId;
                    result.angle = GetTileAngleFlipped(leftTileId, leftFlipH, leftFlipV);
                    result.found = true;
                    result.flagged = IsTileFlagged(leftTileId);
                }
            }
            break;
        }
    }

    return result;
}

// ========== Ground Sensors ==========

SensorResult CastGroundSensors(float playerX, float playerY,
                                float widthRadius, float heightRadius,
                                CollisionMode mode, const LevelCollision* level,
                                SensorResult* outSensorA, SensorResult* outSensorB) {
    SensorResult sensorA, sensorB;
    float anchorAX, anchorAY, anchorBX, anchorBY;
    SensorDirection direction;

    // Calculate sensor positions based on mode
    switch (mode) {
        case MODE_FLOOR:
            anchorAX = playerX - widthRadius;
            anchorAY = playerY + heightRadius;
            anchorBX = playerX + widthRadius;
            anchorBY = playerY + heightRadius;
            direction = SENSOR_DOWN;
            break;

        case MODE_RIGHT_WALL:
            anchorAX = playerX + heightRadius;
            anchorAY = playerY + widthRadius;
            anchorBX = playerX + heightRadius;
            anchorBY = playerY - widthRadius;
            direction = SENSOR_RIGHT;
            break;

        case MODE_CEILING:
            anchorAX = playerX + widthRadius;
            anchorAY = playerY - heightRadius;
            anchorBX = playerX - widthRadius;
            anchorBY = playerY - heightRadius;
            direction = SENSOR_UP;
            break;

        case MODE_LEFT_WALL:
            anchorAX = playerX - heightRadius;
            anchorAY = playerY - widthRadius;
            anchorBX = playerX - heightRadius;
            anchorBY = playerY + widthRadius;
            direction = SENSOR_LEFT;
            break;
    }

    // Cast both sensors
    sensorA = CastSensor(anchorAX, anchorAY, direction, level);
    sensorB = CastSensor(anchorBX, anchorBY, direction, level);

    // Output individual results if requested
    if (outSensorA) *outSensorA = sensorA;
    if (outSensorB) *outSensorB = sensorB;

    // Determine winner - smaller distance wins, A wins ties
    if (!sensorA.found && !sensorB.found) {
        // Neither found anything
        SensorResult noResult = {.distance = SENSOR_EXTENSION_LIMIT, .found = false};
        return noResult;
    } else if (!sensorB.found) {
        return sensorA;
    } else if (!sensorA.found) {
        return sensorB;
    } else {
        // Both found - compare distances
        if (sensorA.distance <= sensorB.distance) {
            return sensorA;
        } else {
            return sensorB;
        }
    }
}

// ========== Ceiling Sensors ==========

SensorResult CastCeilingSensors(float playerX, float playerY,
                                 float widthRadius, float heightRadius,
                                 CollisionMode mode, const LevelCollision* level,
                                 SensorResult* outSensorC, SensorResult* outSensorD) {
    SensorResult sensorC, sensorD;
    float anchorCX, anchorCY, anchorDX, anchorDY;
    SensorDirection direction;

    // Ceiling sensors are mirrored from ground sensors
    switch (mode) {
        case MODE_FLOOR:
            anchorCX = playerX - widthRadius;
            anchorCY = playerY - heightRadius;
            anchorDX = playerX + widthRadius;
            anchorDY = playerY - heightRadius;
            direction = SENSOR_UP;
            break;

        case MODE_RIGHT_WALL:
            anchorCX = playerX - heightRadius;
            anchorCY = playerY + widthRadius;
            anchorDX = playerX - heightRadius;
            anchorDY = playerY - widthRadius;
            direction = SENSOR_LEFT;
            break;

        case MODE_CEILING:
            anchorCX = playerX + widthRadius;
            anchorCY = playerY + heightRadius;
            anchorDX = playerX - widthRadius;
            anchorDY = playerY + heightRadius;
            direction = SENSOR_DOWN;
            break;

        case MODE_LEFT_WALL:
            anchorCX = playerX + heightRadius;
            anchorCY = playerY - widthRadius;
            anchorDX = playerX + heightRadius;
            anchorDY = playerY + widthRadius;
            direction = SENSOR_RIGHT;
            break;
    }

    sensorC = CastSensor(anchorCX, anchorCY, direction, level);
    sensorD = CastSensor(anchorDX, anchorDY, direction, level);

    if (outSensorC) *outSensorC = sensorC;
    if (outSensorD) *outSensorD = sensorD;

    // Determine winner
    if (!sensorC.found && !sensorD.found) {
        SensorResult noResult = {.distance = SENSOR_EXTENSION_LIMIT, .found = false};
        return noResult;
    } else if (!sensorD.found) {
        return sensorC;
    } else if (!sensorC.found) {
        return sensorD;
    } else {
        if (sensorC.distance <= sensorD.distance) {
            return sensorC;
        } else {
            return sensorD;
        }
    }
}

// ========== Push Sensors ==========

SensorResult CastPushSensorE(float playerX, float playerY,
                              float pushRadius, float heightRadius,
                              CollisionMode mode, float groundAngle,
                              const LevelCollision* level) {
    float anchorX, anchorY;
    SensorDirection direction;

    switch (mode) {
        case MODE_FLOOR:
            anchorX = playerX - pushRadius;
            // On flat ground, push sensor is 8px below center
            anchorY = (groundAngle == 0.0f) ? playerY + 8.0f : playerY;
            direction = SENSOR_LEFT;
            break;

        case MODE_RIGHT_WALL:
            anchorX = playerX;
            anchorY = playerY - pushRadius;
            direction = SENSOR_UP;
            break;

        case MODE_CEILING:
            anchorX = playerX + pushRadius;
            anchorY = playerY;
            direction = SENSOR_RIGHT;
            break;

        case MODE_LEFT_WALL:
            anchorX = playerX;
            anchorY = playerY + pushRadius;
            direction = SENSOR_DOWN;
            break;
    }

    return CastSensor(anchorX, anchorY, direction, level);
}

SensorResult CastPushSensorF(float playerX, float playerY,
                              float pushRadius, float heightRadius,
                              CollisionMode mode, float groundAngle,
                              const LevelCollision* level) {
    float anchorX, anchorY;
    SensorDirection direction;

    switch (mode) {
        case MODE_FLOOR:
            anchorX = playerX + pushRadius;
            anchorY = (groundAngle == 0.0f) ? playerY + 8.0f : playerY;
            direction = SENSOR_RIGHT;
            break;

        case MODE_RIGHT_WALL:
            anchorX = playerX;
            anchorY = playerY + pushRadius;
            direction = SENSOR_DOWN;
            break;

        case MODE_CEILING:
            anchorX = playerX - pushRadius;
            anchorY = playerY;
            direction = SENSOR_LEFT;
            break;

        case MODE_LEFT_WALL:
            anchorX = playerX;
            anchorY = playerY - pushRadius;
            direction = SENSOR_UP;
            break;
    }

    return CastSensor(anchorX, anchorY, direction, level);
}

SensorDirection GetSensorDirectionForMode(CollisionMode mode, bool isGroundSensor) {
    if (isGroundSensor) {
        switch (mode) {
            case MODE_FLOOR: return SENSOR_DOWN;
            case MODE_RIGHT_WALL: return SENSOR_RIGHT;
            case MODE_CEILING: return SENSOR_UP;
            case MODE_LEFT_WALL: return SENSOR_LEFT;
        }
    } else {
        // Ceiling sensor - opposite of ground
        switch (mode) {
            case MODE_FLOOR: return SENSOR_UP;
            case MODE_RIGHT_WALL: return SENSOR_LEFT;
            case MODE_CEILING: return SENSOR_DOWN;
            case MODE_LEFT_WALL: return SENSOR_RIGHT;
        }
    }
    return SENSOR_DOWN;
}
