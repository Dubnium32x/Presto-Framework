// Sprite Font Manager header

#ifndef SPRITE_FONT_MANAGER_H
#define SPRITE_FONT_MANAGER_H

#include <string.h>
#include "raylib.h"
#include "raymath.h"
#include <stdio.h>
#include <stdbool.h>
#include "../util/globals.h"

typedef struct {
    Texture2D texture;
    int width;
    int height;
} PrestoNumbersAGlyph;

typedef struct {
    Texture2D texture;
    int width;
    int height;
} PrestoNumbersBGlyph;

typedef struct {
    PrestoNumbersAGlyph glyphs[15];
} PrestoNumbersFontA;

typedef struct {
    PrestoNumbersBGlyph glyphs[15];
} PrestoNumbersFontB;

typedef struct {
    Texture2D texture;
    int width;
    int height;
} DiscoveryGlyph;

typedef struct {
    DiscoveryGlyph glyphs[26];
} DiscoveryFont;

typedef struct {
    Texture2D texture;
    int width;
    int height;
    // Storage for 43 glyph identifiers + null-terminator
    char glyphs[44];
} SmallSonicFont;

extern SmallSonicFont* smallSonicFont;
extern DiscoveryFont* discoveryFont;
extern PrestoNumbersFontA* prestoNumbersAFont;
extern PrestoNumbersFontB* prestoNumbersBFont;

void InitSpriteFontManager();
void InitDiscoveryFont();
void InitSmallSonicFont();
void LoadPrestoNumbersFontA(const char* basePath);
void LoadPrestoNumbersFontB(const char* basePath);
void DrawDiscoveryText(const char* text, Vector2 position, float scale, Color tint);
int MeasureDiscoveryTextWidth(const char* text, float scale);
int MeasureDiscoveryTextHeight(const char* text, float scale);
void DrawSmallSonicText(const char* text, Vector2 position, float scale, Color tint);
int MeasureSmallSonicTextWidth(const char* text, float scale);
void DrawPrestoNumbersA(const char* text, Vector2 position, float scale, Color tint);
void DrawPrestoNumbersB(const char* text, Vector2 position, float scale, Color tint);
void UnloadPrestoNumbersFontA();
void UnloadPrestoNumbersFontB();
void CleanupSpriteFontManager();

#endif // SPRITE_FONT_MANAGER_H