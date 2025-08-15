module sprite.presto_numbersB_font;

import raylib;

import std.stdio;
import std.conv;

import sprite.sprite_fonts;

struct PrestoNumbersBGlyph {
    Texture2D texture;
    int width;
    int height;
}

struct PrestoNumbersBFont {
    PrestoNumbersBGlyph[15] glyphs; // 0 = '-', 1 = '/', 2 = ':', 3 = '.', 4 = '"', 5 = '9', ..., 14 = '0'
}

PrestoNumbersBFont prestoNumbersBFont;

void initPrestoNumbersBFont() {
    foreach (i; 0 .. 15) {
        string path = "resources/font/presto-numbersB/" ~ i.to!string ~ ".png";
        Texture2D tex = LoadTexture(path.ptr);
        prestoNumbersBFont.glyphs[i] = PrestoNumbersBGlyph(tex, tex.width, tex.height);
    }
}

char[15] prestoNumbersBGlyphs = ['-', '/', ':', '.', '"', '9', '8', '7', '6', '5', '4', '3', '2', '1', '0'];

void drawPrestoNumbersBText(string text, int x, int y, Color color) {
    int cursorX = x;
    foreach (ch; text) {
        int idx = -1;
        foreach (i, gch; prestoNumbersBGlyphs) {
            if (ch == gch) {
                idx = cast(int)i;
                break;
            }
        }
        if (idx != -1) {
            auto glyph = prestoNumbersBFont.glyphs[idx];
            Rectangle src = Rectangle(0, 0, glyph.width, glyph.height);
            Vector2 pos = Vector2(cursorX, y);
            DrawTextureRec(glyph.texture, src, pos, color);
            cursorX += glyph.width;
        } else if (ch == ' ') {
            cursorX += 8;
        }
    }
}
