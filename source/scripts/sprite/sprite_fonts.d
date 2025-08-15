module sprite.sprite_fonts;

import raylib;

import std.stdio;
import std.file;
import std.string;
import std.array;
import std.algorithm;
import std.conv;

import sprite.sprite_manager;
import sprite.presto_numbersB_font;

struct DiscoveryGlyph {
    Texture2D texture;
    int width;
    int height;
}

struct DiscoveryFont {
    DiscoveryGlyph[26] glyphs; // 0 = A, 1 = B, ..., 25 = Z
}

DiscoveryFont discoveryFont;

void initDiscoveryFont() {
    foreach (i; 0 .. 26) {
        string path = "resources/font/DiscoveryFont/" ~ to!string(i) ~ ".png";
        Texture2D tex = LoadTexture(path.ptr);
        discoveryFont.glyphs[i] = DiscoveryGlyph(tex, tex.width, tex.height);
    }
}

void drawDiscoveryText(string text, int x, int y, Color color) {
    int cursorX = x;
    foreach (ch; text) {
        if (ch >= 'A' && ch <= 'Z') {
            int idx = ch - 'A';
            auto glyph = discoveryFont.glyphs[idx];
            Rectangle src = Rectangle(0, 0, glyph.width, glyph.height);
            Vector2 pos = Vector2(cursorX, y);
            DrawTextureRec(glyph.texture, src, pos, color);
            cursorX += glyph.width;
        } else if (ch == ' ') {
            cursorX += 8; // Space width, adjust as needed
        }
        // Optionally, handle other unsupported chars
    }
}

Texture2D smallSonicFontTexture;
int glyphWidth = 8;
int glyphHeight = 8;

struct SpriteFont {
    Texture2D texture;
    int glyphWidth;
    int glyphHeight;
    char[] glyphs;
}

SpriteFont smallSonicFont;

void initSpriteFonts() {
    smallSonicFontTexture = LoadTexture("resources/image/spritesheet/smallText.png");
    smallSonicFont = SpriteFont(smallSonicFontTexture, glyphWidth, glyphHeight, [
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
        'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
        'U', 'V', 'W', 'X', 'Y', 'Z',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '*', '.', ':', '-', '=', '!', '?'
    ]);
    initDiscoveryFont();
    import sprite.presto_numbersA_font;
    initPrestoNumbersAFont();
    initPrestoNumbersBFont();
}

void drawSpriteText(SpriteFont font, string text, int x, int y, Color color) {
    foreach (i, ch; text) {
    auto glyphIndex = font.glyphs.countUntil(ch);
        if (glyphIndex == -1) continue; // skip missing glyphs
        int tx = cast(int)((glyphIndex % (font.texture.width / font.glyphWidth)) * font.glyphWidth);
    auto ty = (glyphIndex / (font.texture.width / font.glyphWidth)) * font.glyphHeight;
        Rectangle src = Rectangle(tx, ty, font.glyphWidth, font.glyphHeight);
        Vector2 pos = Vector2(x + i * font.glyphWidth, y);
        DrawTextureRec(font.texture, src, pos, color);
    }
}

void drawDiscoverySonicFont() {
    foreach (size_t i, ch; "ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
        auto glyphIndex = smallSonicFont.glyphs.countUntil(ch);
        if (glyphIndex == -1) continue; // skip missing glyphs
        int tx = cast(int)((glyphIndex % (smallSonicFont.texture.width / smallSonicFont.glyphWidth)) * smallSonicFont.glyphWidth);
    auto ty = (glyphIndex / (smallSonicFont.texture.width / smallSonicFont.glyphWidth)) * smallSonicFont.glyphHeight;
        Rectangle src = Rectangle(tx, ty, smallSonicFont.glyphWidth, smallSonicFont.glyphHeight);
        Vector2 pos = Vector2(0, 0);
        DrawTextureRec(smallSonicFont.texture, src, pos, Colors.WHITE);
    }
}