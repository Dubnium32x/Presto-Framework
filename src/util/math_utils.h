// Math utilities functions and constants
#ifndef MATH_UTILS_H
#define MATH_UTILS_H

#include <math.h>
#include "raylib.h"
#include "raymath.h"
#include <stdlib.h>
#include <stdio.h>

#define PI 3.14159265358979323846f
#define DEG2RAD (PI / 180.0f)
#define RAD2DEG (180.0f / PI)


static inline float Clamp(float value, float min, float max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

static inline float Lerp(float start, float end, float t) {
    return start + t * (end - start);
}

static inline float ClampedLerp(float start, float end, float t) {
    t = Clamp(t, 0.0f, 1.0f);
    return Lerp(start, end, t);
}

static inline Vector2 LerpV2(Vector2 start, Vector2 end, float t) {
    t = Clamp(t, 0.0f, 1.0f);
    return Vector2Lerp(start, end, t);
}

static inline float Distance(Vector2 a, Vector2 b) {
    return sqrtf((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
}

static inline float AngleBetweenPoints(Vector2 a, Vector2 b) {
    return atan2f(b.y - a.y, b.x - a.x) * RAD2DEG;
}

static inline Vector2 RotatePoint(Vector2 point, Vector2 origin, float angle) {
    float rad = angle * DEG2RAD;
    float s = sinf(rad);
    float c = cosf(rad);

    // Translate point back to origin
    point.x -= origin.x;
    point.y -= origin.y;

    // Rotate point
    float xnew = point.x * c - point.y * s;
    float ynew = point.x * s + point.y * c;

    // Translate point back
    point.x = xnew + origin.x;
    point.y = ynew + origin.y;
    return point;
}

static inline bool IsPointInRectangle(Vector2 point, Rectangle rect) {
    return (point.x >= rect.x && point.x <= rect.x + rect.width &&
            point.y >= rect.y && point.y <= rect.y + rect.height);
}

#endif // MATH_UTILS_H