// Sprite Font Manager

#include "sprite_font_manager.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "raylib.h"

// Define sprite font variables
SmallSonicFont* smallSonicFont = NULL;
DiscoveryFont* discoveryFont = NULL;
PrestoNumbersFontA* prestoNumbersAFont = NULL;
PrestoNumbersFontB* prestoNumbersBFont = NULL;

void InitSpriteFontManager() {
    printf("Initializing Sprite Font Manager...\n");
    
    // Initialize font pointers
    prestoNumbersAFont = NULL;
    prestoNumbersBFont = NULL;
    discoveryFont = NULL;
    smallSonicFont = NULL;
    
    // Try to load fonts
    InitDiscoveryFont();
    InitSmallSonicFont();
    
    printf("Sprite Font Manager initialized\n");
}

void InitDiscoveryFont() {
    discoveryFont = (DiscoveryFont*)malloc(sizeof(DiscoveryFont));
    memset(discoveryFont, 0, sizeof(DiscoveryFont));
    const char* basePath = "res/fonts/DiscoveryFont/";
    // Files appear to be named 0.png..25.png corresponding to A..Z
    int loaded = 0;
    for (int i = 0; i < 26; i++) {
        char path[128];
        snprintf(path, sizeof(path), "%s%d.png", basePath, i);
        Texture2D tex = LoadTexture(path);
        discoveryFont->glyphs[i].texture = tex;
        discoveryFont->glyphs[i].width = (tex.id > 0) ? tex.width : 0;
        discoveryFont->glyphs[i].height = (tex.id > 0) ? tex.height : 0;
        if (tex.id > 0) loaded++;
    }
    printf("Discovery font: loaded %d/26 glyph textures\n", loaded);
}

void InitSmallSonicFont() {
    smallSonicFont = (SmallSonicFont*)malloc(sizeof(SmallSonicFont));
    memset(smallSonicFont, 0, sizeof(SmallSonicFont));
    // Use existing smallText.png as the sprite sheet (8x8 grid assumed)
    const char* basePath = "res/fonts/smallText.png";
    Texture2D tex = LoadTexture(basePath);
    if (tex.id == 0) {
        // Fallback: leave uninitialized to trigger DrawText fallback
        printf("Warning: smallText sprite font texture not found at %s\n", basePath);
    }
    smallSonicFont->texture = tex;
    smallSonicFont->width = tex.width;
    smallSonicFont->height = tex.height;
    const char* glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*.:-=!?";
    // Ensure null-terminated copy
    strncpy(smallSonicFont->glyphs, glyphs, sizeof(smallSonicFont->glyphs) - 1);
    smallSonicFont->glyphs[sizeof(smallSonicFont->glyphs) - 1] = '\0';
}

void LoadPrestoNumbersFontA(const char* basePath) {
    char prestoNumbersAGlyphs[15] = {
        '-', '/', ':', '.', '"', '9', '8', '7', '6', '5', '4', '3', '2', '1', '0'
    };

    for (int i = 0; i < 15; i++) {
        prestoNumbersAFont->glyphs[(int)prestoNumbersAGlyphs[i]] = prestoNumbersAFont->glyphs[i];
    }

    prestoNumbersAFont = (PrestoNumbersFontA*)malloc(sizeof(PrestoNumbersFontA));
    for (int i = 0; i < 15; i++) {
        char path[256];
        snprintf(path, sizeof(path), "res/fonts/presto-numbersA/%d.png", i);
        Texture2D tex = LoadTexture(path);
        prestoNumbersAFont->glyphs[i].texture = tex;
        prestoNumbersAFont->glyphs[i].width = tex.width;
        prestoNumbersAFont->glyphs[i].height = tex.height;
    }
}

void LoadPrestoNumbersFontB(const char* basePath) {
    char prestoNumbersBGlyphs[15] = {
        '-', '/', ':', '.', '"', '9', '8', '7', '6', '5', '4', '3', '2', '1', '0'
    };

    for (int i = 0; i < 15; i++) {
        prestoNumbersBFont->glyphs[(int)prestoNumbersBGlyphs[i]] = prestoNumbersBFont->glyphs[i];
    }

    prestoNumbersBFont = (PrestoNumbersFontB*)malloc(sizeof(PrestoNumbersFontB));
    for (int i = 0; i < 15; i++) {
        char path[256];
        snprintf(path, sizeof(path), "res/fonts/presto-numbersB/%d.png", i);
        Texture2D tex = LoadTexture(path);
        prestoNumbersBFont->glyphs[i].texture = tex;
        prestoNumbersBFont->glyphs[i].width = tex.width;
        prestoNumbersBFont->glyphs[i].height = tex.height;
    }
}

void DrawDiscoveryText(const char* text, Vector2 position, float scale, Color tint) {
    if (!text) return;
    
    // Fallback to default font if sprite font not available
    if (!discoveryFont) {
        DrawText(text, (int)position.x, (int)position.y, (int)(20 * scale), tint);
        return;
    }
    
    Vector2 pos = position;
    for (int i = 0; text[i] != '\0'; i++) {
        char c = text[i];
        if (c == ' ') { pos.x += 8 * scale; continue; }
        if (c >= 'a' && c <= 'z') c -= 32; // Uppercase
        if (c < 'A' || c > 'Z') continue; // Skip unsupported characters
        DiscoveryGlyph glyph = discoveryFont->glyphs[c - 'A'];
        if (glyph.texture.id > 0) {
            DrawTextureEx(glyph.texture, pos, 0.0f, scale, tint);
            pos.x += (glyph.width > 0 ? glyph.width : 8) * scale;
        } else {
            pos.x += 8 * scale;
        }
    }
}

int MeasureDiscoveryTextWidth(const char* text, float scale) {
    if (!text) return 0;
    int width = 0;
    for (int i = 0; text[i] != '\0'; i++) {
        char c = text[i];
        if (c == ' ') { width += (int)(8 * scale); continue; }
        if (c >= 'a' && c <= 'z') c -= 32;
        if (c < 'A' || c > 'Z') continue;
        DiscoveryGlyph glyph = discoveryFont ? discoveryFont->glyphs[c - 'A'] : (DiscoveryGlyph){0};
        width += (int)(((glyph.width > 0) ? glyph.width : 8) * scale);
    }
    return width;
}

int MeasureDiscoveryTextHeight(const char* text, float scale) {
    (void)text; // Suppress unused parameter warning
    // Height is uniform per glyph; choose the first available glyph's height
    int h = 0;
    if (discoveryFont) {
        for (int i = 0; i < 26; i++) {
            if (discoveryFont->glyphs[i].texture.id > 0 && discoveryFont->glyphs[i].height > 0) {
                h = discoveryFont->glyphs[i].height;
                break;
            }
        }
    }
    if (h == 0) h = 8; // reasonable default
    return (int)(h * scale);
}

void DrawSmallSonicText(const char* text, Vector2 position, float scale, Color tint) {
    if (!text) return;
    
    // Fallback to default font if sprite font not available
    if (!smallSonicFont) {
        DrawText(text, (int)position.x, (int)position.y, (int)(10 * scale), tint);
        return;
    }
    if (smallSonicFont->texture.id == 0) {
        DrawText(text, (int)position.x, (int)position.y, (int)(10 * scale), tint);
        return;
    }
    
    Vector2 pos = position;
    for (int i = 0; text[i] != '\0'; i++) {
        char c = text[i];
        
        if (c == ' ') {
            pos.x += 8 * scale; // Space width
            continue;
        }
        
        // Normalize lowercase
        if (c >= 'a' && c <= 'z') c -= 32;
        char* glyphPos = strchr(smallSonicFont->glyphs, c);
        if (!glyphPos) continue; // Skip unsupported characters
        
        int index = glyphPos - smallSonicFont->glyphs;
        
        // Calculate position in spritesheet (assuming 8x8 tiles arranged in rows)
        if (smallSonicFont->texture.width <= 0) continue; // Safety check
        int tilesPerRow = smallSonicFont->texture.width / 8;
        if (tilesPerRow <= 0) tilesPerRow = 1; // Prevent division by zero
        
        int tileX = (index % tilesPerRow) * 8;
        int tileY = (index / tilesPerRow) * 8;
        
        // Bounds check
        if (tileX >= 0 && tileY >= 0 && 
            tileX + 8 <= smallSonicFont->texture.width && 
            tileY + 8 <= smallSonicFont->texture.height) {
            
            Rectangle sourceRec = { (float)tileX, (float)tileY, 8.0f, 8.0f };
            Rectangle destRec = { pos.x, pos.y, 8.0f * scale, 8.0f * scale };
            
            DrawTexturePro(smallSonicFont->texture, sourceRec, destRec, (Vector2){0, 0}, 0.0f, tint);
        }
        pos.x += 8 * scale;
    }
}

int MeasureSmallSonicTextWidth(const char* text, float scale) {
    if (!text) return 0;
    int width = 0;
    for (int i = 0; text[i] != '\0'; i++) {
        char c = text[i];
        if (c == ' ') { width += (int)(8 * scale); continue; }
        if (c >= 'a' && c <= 'z') c -= 32;
        if (!strchr("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*.:-=!?", c)) continue;
        width += (int)(8 * scale);
    }
    return width;
}

void DrawPrestoNumbersA(const char* text, Vector2 position, float scale, Color tint) {
    Vector2 pos = position;
    for (int i = 0; text[i] != '\0'; i++) {
        char c = text[i];
        if (c < 0 || c >= 15) continue; // Skip unsupported characters
        PrestoNumbersAGlyph glyph = prestoNumbersAFont->glyphs[(int)c];
        DrawTextureEx(glyph.texture, pos, 0.0f, scale, tint);
        pos.x += glyph.width * scale;
    }
}

void DrawPrestoNumbersB(const char* text, Vector2 position, float scale, Color tint) {
    Vector2 pos = position;
    for (int i = 0; text[i] != '\0'; i++) {
        char c = text[i];
        if (c < 0 || c >= 15) continue; // Skip unsupported characters
        PrestoNumbersBGlyph glyph = prestoNumbersBFont->glyphs[(int)c];
        DrawTextureEx(glyph.texture, pos, 0.0f, scale, tint);
        pos.x += glyph.width * scale;
    }
}

void UnloadPrestoNumbersFontA() {
    if (prestoNumbersAFont) {
        for (int i = 0; i < 15; i++) {
            UnloadTexture(prestoNumbersAFont->glyphs[i].texture);
        }
        free(prestoNumbersAFont);
        prestoNumbersAFont = NULL;
    }
}

void UnloadPrestoNumbersFontB() {
    if (prestoNumbersBFont) {
        for (int i = 0; i < 15; i++) {
            UnloadTexture(prestoNumbersBFont->glyphs[i].texture);
        }
        free(prestoNumbersBFont);
        prestoNumbersBFont = NULL;
    }
}
