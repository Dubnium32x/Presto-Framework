// Random Utilities Header File
#ifndef UTIL_RANDOM_UTILS_H
#define UTIL_RANDOM_UTILS_H

#include <stdlib.h>
#include <stdio.h>
#include <time.h>

// Initialize random number generator
static inline void InitRandom() {
    srand((unsigned int)time(NULL));
}   

static inline int GetRandomInt(int min, int max) {
    return rand() % (max - min + 1) + min;
}

static inline float GetRandomFloat(float min, float max) {
    float scale = rand() / (float) RAND_MAX; // [0, 1.0]
    return min + scale * (max - min);        // [min, max]
}

#endif // UTIL_RANDOM_UTILS_H