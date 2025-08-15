module sprite.presto_numbersA_font;

import raylib;

import std.stdio;
import std.conv;

import sprite.sprite_fonts;

struct PrestoNumbersAGlyph {
    Texture2D texture;
    int width;
    int height;
}

struct PrestoNumbersAFont {
    PrestoNumbersAGlyph[14] glyphs; // 0 = '-', 1 = '/', 2 = ':', 3 = '.', 4 = '"', 5 = '9', ..., 14 = '0'
}

PrestoNumbersAFont prestoNumbersAFont;

void initPrestoNumbersAFont() {
    foreach (i; 0 .. 14) {
        string path = "resources/font/presto-numbersA/" ~ i.to!string ~ ".png";
        Texture2D tex = LoadTexture(path.ptr);
        prestoNumbersAFont.glyphs[i] = PrestoNumbersAGlyph(tex, tex.width, tex.height);
    }
}

char[15] prestoNumbersAGlyphs = ['"', ':', '/', '-', '9', '8', '7', '6', '5', '4', '3', '2', '1', '0'];

void drawPrestoNumbersAText(string text, int x, int y, Color color) {
    int cursorX = x;
    foreach (ch; text) {
        int idx = -1;
        foreach (i, gch; prestoNumbersAGlyphs) {
            if (ch == gch) {
                idx = cast(int)i;
                break;
            }
        }
        if (idx != -1) {
            auto glyph = prestoNumbersAFont.glyphs[idx];
            Rectangle src = Rectangle(0, 0, glyph.width, glyph.height);
            Vector2 pos = Vector2(cursorX, y);
            DrawTextureRec(glyph.texture, src, pos, color);
            cursorX += glyph.width;
        } else if (ch == ' ') {
            cursorX += 8;
        }
    }
}
