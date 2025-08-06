module utils.random;

import std.random;

/**
 * Returns a random float value between min and max (inclusive).
 *
 * Params:
 *   min = The minimum value
 *   max = The maximum value
 * Returns: A random float between min and max
 */
float GetRandomFloat(float min, float max) {
    return min + (max - min) * uniform01();
}

/**
 * Returns a random integer value between min and max (inclusive).
 *
 * Params:
 *   min = The minimum value
 *   max = The maximum value
 * Returns: A random integer between min and max
 */
int GetRandomInt(int min, int max) {
    return uniform(min, max + 1);
}

/**
 * Returns true with the given probability.
 *
 * Params:
 *   probability = The probability (0.0 to 1.0)
 * Returns: true if the random check succeeds
 */
bool GetRandomChance(float probability) {
    return uniform01() < probability;
}
