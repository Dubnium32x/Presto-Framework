module game.title_card;

import raylib;

import std.stdio;
import std.conv; // For to!string
import std.math;

import sprite.sprite_fonts; // For custom font rendering
import sprite.presto_numbersA_font;
import app : VIRTUAL_SCREEN_HEIGHT, VIRTUAL_SCREEN_WIDTH;

class TitleCard {
    string zoneName;
    int actNumber;
    float alpha = 0.0f; // For fade effect
    float zonePosX, actPosX;
    float zoneTargetX, actTargetX;
    float zoneStartX, actStartX;
    float zoneY, actY;
    int bgAlpha = 255;
    float rectHoldTimer = 0.0f;
    float cardHoldTimer = 0.0f;
    bool cardFadeOut = false;
    float animSpeed = 400.0f; // pixels/sec (slower for debug)
    bool animatingIn = true;
    float rectFadeSpeed = 2.0f; // Rectangle fade speed (alpha/sec)
    float cardFadeSpeed = 1.5f; // Title card fade speed (alpha/sec)
    float cardFadeDelay = 0.2f; // Delay after rectangle is gone before card fades
    float cardFadeDelayTimer = 0.0f;

    this(string zone, int act) {
        zoneName = zone;
        actNumber = act;
        string actText = "ACT " ~ to!string(actNumber);
        // Center both texts horizontally
        zoneTargetX = cast(float)((VIRTUAL_SCREEN_WIDTH - zoneName.length * 16) / 2);
        actTargetX = cast(float)((VIRTUAL_SCREEN_WIDTH - actText.length * 16) / 2);
        // Start off-screen: zone from right, act from left
        zoneStartX = cast(float)(VIRTUAL_SCREEN_WIDTH + 100); // right off-screen
        actStartX = - (cast(float)(actText.length * 16) + 100.0f); // left off-screen
        zonePosX = zoneStartX;
        actPosX = actStartX;
        // Y positions for classic layout
        zoneY = cast(float)(VIRTUAL_SCREEN_HEIGHT / 2 - 32); // slightly above center
        actY = cast(float)(VIRTUAL_SCREEN_HEIGHT / 2 + 8); // closer to zone name
    bgAlpha = cast(int)(1.0f * 255);
    rectHoldTimer = 0.0f;
    }

    void update(float deltaTime) {
    writeln("[DEBUG] bgAlpha: ", bgAlpha, " | rectHoldTimer: ", rectHoldTimer, " | animatingIn: ", animatingIn);
    writeln("[DEBUG] zonePosX: ", zonePosX, " | zoneTargetX: ", zoneTargetX, " | actPosX: ", actPosX, " | actTargetX: ", actTargetX);
        if (animatingIn) {
            // Animate positions
            if (zonePosX > zoneTargetX) {
                zonePosX -= animSpeed * deltaTime;
                if (zonePosX < zoneTargetX) zonePosX = zoneTargetX;
            }
            if (actPosX < actTargetX) {
                actPosX += animSpeed * deltaTime;
                if (actPosX > actTargetX) actPosX = actTargetX;
            }
            // Fade in title card only
            alpha += cardFadeSpeed * deltaTime;
            if (alpha >= 1.0f) alpha = 1.0f;
            // End animation when both are in place and fully visible (use epsilon for float comparison)
            if (abs(zonePosX - zoneTargetX) < 1.0f && abs(actPosX - actTargetX) < 1.0f && alpha >= 1.0f) {
                animatingIn = false;
            }
        } else {
            // Black rectangle hold and fade
            rectHoldTimer += deltaTime;
            if (rectHoldTimer > 1.0f && bgAlpha > 0) {
                bgAlpha -= cast(int)(rectFadeSpeed * 255 * deltaTime);
                if (bgAlpha < 0) bgAlpha = 0;
            }
            // Title card fade starts only after rectangle is fully gone, with a short delay
            if (bgAlpha == 0) {
                if (cardFadeDelayTimer < cardFadeDelay) {
                    cardFadeDelayTimer += deltaTime;
                } else {
                    alpha -= cardFadeSpeed * deltaTime;
                    if (alpha < 0.0f) alpha = 0.0f;
                }
            }
        }
    }

    void draw() {
        // Draw fullscreen black rectangle, fully opaque until fade out
        if (bgAlpha > 0) {
            DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, Color(0, 0, 0, cast(ubyte)bgAlpha));
        }
        // ...existing code for title card...
    string actText = "ACT " ~ to!string(actNumber);
        int zoneTextWidth = cast(int)(zoneName.length * 16);
        int actTextWidth = cast(int)(actText.length * 16);
        int cardWidth = (zoneTextWidth > actTextWidth ? zoneTextWidth : actTextWidth) + 64;
        int cardHeight = 96;
        int cardX = (VIRTUAL_SCREEN_WIDTH - cardWidth) / 2;
        int cardY = cast(int)(zoneY - 32);
        // Draw blue ellipse behind zone name, rotated by 60 degrees
        int ellipseX = cast(int)(zonePosX + zoneTextWidth / 2);
        int ellipseY = cast(int)zoneY + 16;
        rlPushMatrix();
        rlTranslatef(ellipseX, ellipseY, 0);
        rlRotatef(60, 0, 0, 1); // rotate by 60 degrees
        DrawEllipse(0, 0, zoneTextWidth / 2 + 24, 32, Color(80, 120, 255, cast(ubyte)(180 * alpha)));
        rlPopMatrix();
        // Draw zone name centered
        drawDiscoveryText(zoneName, cast(int)zonePosX, cast(int)zoneY, Color(180, 220, 255, cast(ubyte)(255 * alpha)));
        // Draw 'ACT' text centered below
        drawDiscoveryText("ACT", cast(int)actPosX, cast(int)actY, Color(255, 220, 80, cast(ubyte)(255 * alpha)));
        // Draw act number using prestoNumbersB font, centered below 'ACT'
        int actNumWidth = 16; // adjust if needed for your font
        int actNumX = cast(int)(actPosX + 48); // offset to center under 'ACT'
        int actNumY = cast(int)(actY); // slightly below 'ACT'
        drawPrestoNumbersAText(to!string(actNumber), actNumX, actNumY, Colors.WHITE);
    }
}

