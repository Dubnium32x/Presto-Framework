module game.hud;

import raylib;

import std.stdio;
import std.array;
import std.string;
import std.conv;
import std.format;

import sprite.presto_numbersB_font;
import sprite.sprite_fonts;
import game.title_card;

class HUD {
    Texture2D[] hudSprites; // 0: lives, 1: rings, 2: time, 3: score
    int score, rings, lives;
    int time; // Timer in milliseconds
    bool timerActive = false;

    this() {
        hudSprites.length = 4;
        foreach (i; 0 .. 4) {
            int idx = cast(int)i;
            hudSprites[idx] = LoadTexture(("resources/image/spritesheet/HUD/" ~ to!string(i) ~ ".png").ptr);
        }
        // Initialize values
        score = 0;
        time = 0;
        rings = 0;
        lives = 3;
    }

    // Call this to start the HUD timer (e.g., after title card animation is done)
    void startTimer() {
        timerActive = true;
    }

    // Call this to stop the HUD timer (e.g., for pause/game over)
    void stopTimer() {
        timerActive = false;
    }

    // Update HUD values except timer
    void updateValues(int newScore, int newRings, int newLives) {
        score = newScore;
        rings = newRings;
        lives = newLives;
    }

    // Call this every frame to update the timer
    void update(float deltaTime) {
        if (timerActive) {
            time += cast(int)(deltaTime * 1000); // Convert seconds to milliseconds
        }
    }

    void draw() {
        // Top-left HUD layout
        int baseX = 12;
        int baseY = 8;
        int spacingY = 20;
        // Score
        DrawTexture(hudSprites[3], baseX, baseY, Colors.WHITE);
        drawPrestoNumbersBText(score.to!string, baseX + 70, baseY, Colors.WHITE);
    // Time
    DrawTexture(hudSprites[2], baseX, baseY + spacingY, Colors.WHITE);
    // Format time as MM:SS.mmm
    int totalMilliseconds = time;
    int minutes = totalMilliseconds / 60000;
    int seconds = (totalMilliseconds % 60000) / 1000;
    int milliseconds = totalMilliseconds % 1000;
    string timeStr = format("%02d:%02d.%03d", minutes, seconds, milliseconds);
    drawPrestoNumbersBText(timeStr, baseX + 70, baseY + spacingY, Colors.WHITE);
        // Rings
        DrawTexture(hudSprites[1], baseX, baseY + spacingY * 2, Colors.WHITE);
        drawPrestoNumbersBText(rings.to!string, baseX + 70, baseY + spacingY * 2, Colors.WHITE);

    // Bottom-left lives counter using smallSonicFont for the value
    import sprite.sprite_fonts;
    int livesX = 12;
    int livesY = 224 - 24; // Adjust for your screen height
    DrawTexture(hudSprites[0], livesX, livesY, Colors.WHITE);
    drawSpriteText(smallSonicFont, "SONIC", livesX + 20, livesY, Colors.YELLOW);
    drawSpriteText(smallSonicFont, "x", livesX + 24, livesY + 12, Colors.WHITE);
    drawSpriteText(smallSonicFont, lives.to!string, livesX + 36, livesY + 10, Colors.WHITE);
    }
}