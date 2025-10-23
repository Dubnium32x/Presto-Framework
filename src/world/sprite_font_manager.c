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

    // Load the sprite fonts
    LoadPrestoNumbersFontA("res/fonts/presto-numbersA/");
    LoadPrestoNumbersFontB("res/fonts/presto-numbersB/");
    
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
    (void)basePath; // Suppress unused parameter warning
    
    // Allocate memory first
    prestoNumbersAFont = (PrestoNumbersFontA*)malloc(sizeof(PrestoNumbersFontA));
    if (!prestoNumbersAFont) {
        printf("Error: Failed to allocate memory for PrestoNumbersFontA\n");
        return;
    }
    
    // Initialize all glyphs to zero
    memset(prestoNumbersAFont, 0, sizeof(PrestoNumbersFontA));
    
    // Load textures (files are numbered 0-13)
    int loaded = 0;
    for (int i = 0; i < 14; i++) {
        char path[256];
        snprintf(path, sizeof(path), "res/fonts/presto-numbersA/%d.png", i);
        Texture2D tex = LoadTexture(path);
        if (tex.id > 0) {
            prestoNumbersAFont->glyphs[i].texture = tex;
            prestoNumbersAFont->glyphs[i].width = tex.width;
            prestoNumbersAFont->glyphs[i].height = tex.height;
            loaded++;
        }
    }
    printf("PrestoNumbersA font: loaded %d/14 glyph textures\n", loaded);
}

void LoadPrestoNumbersFontB(const char* basePath) {
    (void)basePath; // Suppress unused parameter warning
    
    // Allocate memory first
    prestoNumbersBFont = (PrestoNumbersFontB*)malloc(sizeof(PrestoNumbersFontB));
    if (!prestoNumbersBFont) {
        printf("Error: Failed to allocate memory for PrestoNumbersFontB\n");
        return;
    }
    
    // Initialize all glyphs to zero
    memset(prestoNumbersBFont, 0, sizeof(PrestoNumbersFontB));
    
    // Load textures (files are numbered 0-14)
    int loaded = 0;
    for (int i = 0; i < 15; i++) {
        char path[256];
        snprintf(path, sizeof(path), "res/fonts/presto-numbersB/%d.png", i);
        Texture2D tex = LoadTexture(path);
        if (tex.id > 0) {
            prestoNumbersBFont->glyphs[i].texture = tex;
            prestoNumbersBFont->glyphs[i].width = tex.width;
            prestoNumbersBFont->glyphs[i].height = tex.height;
            loaded++;
        }
    }
    printf("PrestoNumbersB font: loaded %d/15 glyph textures\n", loaded);
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
    if (!text || !prestoNumbersAFont) return;
    
    Vector2 pos = position;
    for (int i = 0; text[i] != '\0'; i++) {
        char c = text[i];
        int glyphIndex = -1;
        
        // Map characters to glyph indices (Sonic-style font layout)
        // Based on typical Sonic font ordering: 0,1,2,3,4,5,6,7,8,9,:,',",dash,slash
        if (c >= '0' && c <= '9') {
            glyphIndex = 9 - (c - '0'); // Reverse order: '0'->9, '1'->8, etc.
        } else if (c == ':') {
            glyphIndex = 2; // Colon 
        } else if (c == '.') {
            glyphIndex = 3; // Period  
        } else if (c == '-') {
            glyphIndex = 0; // Dash at index 0
        } else if (c == '/') {
            glyphIndex = 1; // Slash at index 1
        } else if (c == '\"') {
            glyphIndex = 4; // Quote
        }
        
        if (glyphIndex >= 0 && glyphIndex < 14) {
            PrestoNumbersAGlyph glyph = prestoNumbersAFont->glyphs[glyphIndex];
            if (glyph.texture.id > 0) {
                DrawTextureEx(glyph.texture, pos, 0.0f, scale, tint);
                pos.x += glyph.width * scale;
            }
        } else if (c == ' ') {
            pos.x += 8 * scale; // Space width
        }
    }
}

void DrawPrestoNumbersB(const char* text, Vector2 position, float scale, Color tint) {
    if (!text || !prestoNumbersBFont) return;
    
    Vector2 pos = position;
    for (int i = 0; text[i] != '\0'; i++) {
        char c = text[i];
        int glyphIndex = -1;
        
        // Map characters to glyph indices (Sonic-style font layout)
        // Based on typical Sonic font ordering: 0,1,2,3,4,5,6,7,8,9,:,',",dash,slash
        if (c >= '0' && c <= '9') {
            glyphIndex = 14 - (c - '0'); // Reverse order for font B: '0'->14, '1'->13, etc.
        } else if (c == ':') {
            glyphIndex = 2; // Colon at index 2
        } else if (c == '.') {
            glyphIndex = 3; // Period at index 3
        } else if (c == '-') {
            glyphIndex = 0; // Dash at index 0
        } else if (c == '/') {
            glyphIndex = 1; // Slash at index 1
        } else if (c == '"') {
            glyphIndex = 4; // Quote at index 4
        }
        
        if (glyphIndex >= 0 && glyphIndex < 15) {
            PrestoNumbersBGlyph glyph = prestoNumbersBFont->glyphs[glyphIndex];
            if (glyph.texture.id > 0) {
                DrawTextureEx(glyph.texture, pos, 0.0f, scale, tint);
                pos.x += glyph.width * scale;
            }
        } else if (c == ' ') {
            pos.x += 8 * scale; // Space width
        }
    }
}

void UnloadPrestoNumbersFontA() {
    if (prestoNumbersAFont) {
        for (int i = 0; i < 14; i++) {
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

void CleanupSpriteFontManager() {
    printf("Cleaning up Sprite Font Manager...\n");
    
    // Unload Discovery font
    if (discoveryFont) {
        for (int i = 0; i < 26; i++) {
            if (discoveryFont->glyphs[i].texture.id > 0) {
                UnloadTexture(discoveryFont->glyphs[i].texture);
            }
        }
        free(discoveryFont);
        discoveryFont = NULL;
    }
    
    // Unload Small Sonic font
    if (smallSonicFont) {
        if (smallSonicFont->texture.id > 0) {
            UnloadTexture(smallSonicFont->texture);
        }
        free(smallSonicFont);
        smallSonicFont = NULL;
    }
    
    // Unload Presto Numbers fonts
    UnloadPrestoNumbersFontA();
    UnloadPrestoNumbersFontB();
    
    printf("Sprite Font Manager cleanup complete\n");
}
