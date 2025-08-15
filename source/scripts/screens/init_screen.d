module screens.init_screen;

import raylib;

import std.stdio;
import std.string;
import std.array;
import std.range;

import world.screen_manager;
import world.audio_manager;
import world.screen_state;
import sprite.sprite_fonts;
import app;
import app : VIRTUAL_SCREEN_HEIGHT, VIRTUAL_SCREEN_WIDTH;

// This is the first screen that appears when you start the game. 

enum InitScreenState {
    UNINITIALIZED,
    DISCLAIMER,
    SPLASH,
    DONE
}

string disclaimerText = "DISCLAIMER";

Texture2D segaLogo;
Sound segaJingle;
bool disclaimerPlayer = false;
bool jinglePlayed = false;
float timer = 0.0f;
float disclaimerTimer = 0.0f;
float disclaimerDuration = 5.0f; // Duration to show the disclaimer
float fadeOutDuration = 1.0f; // Duration to fade out the disclaimer
float logoAnimateInTime = 1.0f; // Duration for logo scale-up animation
float logoDisplayTime = 4.5f; // Duration to show the logo

enum InitScreenPhase {
    DISCLAIMER_FADEIN,
    DISCLAIMER_DISPLAY,
    DISCLAIMER_FADEOUT,
    LOGO_ANIMATE,
    LOGO_DISPLAY,
    LOGO_FADEOUT,
    DONE
}

class InitScreen : IScreen {
    // Animation variables
    float disclaimerAlpha;
    float logoScaleX;
    float logoScaleY;
    Vector2* logoPosition;
    int backgroundColorModifier; // Use this in R G and B inputs to modify the background color

    InitScreenState initState;
    InitScreenPhase initPhase;

    // Singleton Instance
    static InitScreen instance;

    static InitScreen getInstance() {
        if (instance is null) {
            instance = new InitScreen();
        }
        return instance;
    }

    this() {
        initialize();
    }

    void initialize() {
    // Update init states
    initState = InitScreenState.UNINITIALIZED;
    initPhase = InitScreenPhase.DISCLAIMER_FADEIN;

    disclaimerPlayer = false;
    jinglePlayed = false;
    timer = 0.0f;
    disclaimerTimer = 0.0f;

    disclaimerAlpha = 1.0f;
    logoScaleX = 0.0f;
    logoScaleY = 0.0f;
    logoPosition = new Vector2(VIRTUAL_SCREEN_WIDTH / 2.0f, VIRTUAL_SCREEN_HEIGHT);
    backgroundColorModifier = 0;
    // Load assets
    segaLogo = LoadTexture("resources/image/spritesheet/Sega-logo.png");
    segaJingle = LoadSound("resources/sound/sfx/jingle.ogg");
    initSpriteFonts();
    }

    void update(float deltaTime) {
        // Print debug info
        writeln("initState=", initState, " initPhase=", initPhase);
        if (initState == InitScreenState.UNINITIALIZED) {
            initState = InitScreenState.DISCLAIMER;
        }

        if (initState == InitScreenState.DISCLAIMER) {
            // Fade in text and background
            if (initPhase == InitScreenPhase.DISCLAIMER_FADEIN) {
                disclaimerAlpha += deltaTime / fadeOutDuration;
                if (disclaimerAlpha >= 1.0f) {
                    disclaimerAlpha = 1.0f;
                    initPhase = InitScreenPhase.DISCLAIMER_DISPLAY;
                }
            } else if (initPhase == InitScreenPhase.DISCLAIMER_DISPLAY) {
                disclaimerTimer += deltaTime;
                if (disclaimerTimer >= disclaimerDuration) {
                    initPhase = InitScreenPhase.DISCLAIMER_FADEOUT;
                }
            } else if (initPhase == InitScreenPhase.DISCLAIMER_FADEOUT) {
                disclaimerAlpha -= deltaTime / fadeOutDuration;
                if (disclaimerAlpha <= 0.0f) {
                    disclaimerAlpha = 0.0f;
                    // Advance to logo animation phase
                    initState = InitScreenState.SPLASH;
                    initPhase = InitScreenPhase.LOGO_ANIMATE;
                    timer = 0.0f;
                }
            }
            // Background fade: interpolate from black to white using disclaimerAlpha
            backgroundColorModifier = cast(int)((1.0f - disclaimerAlpha) * 255.0f);
        }
        if (initState == InitScreenState.SPLASH) {
            // Keep background white
            backgroundColorModifier = 255;
            float targetScale = 1.0f;
            float animationDuration = logoAnimateInTime;
            float holdDuration = logoDisplayTime;
            if (initPhase == InitScreenPhase.LOGO_ANIMATE) {
                float t = timer / animationDuration;
                if (t > 1.0f) t = 1.0f;
                logoScaleX = segaLogo.width * t;
                logoScaleY = segaLogo.height * t;
                logoPosition.x = (VIRTUAL_SCREEN_WIDTH - logoScaleX) / 2.0f;
                logoPosition.y = VIRTUAL_SCREEN_HEIGHT + (VIRTUAL_SCREEN_HEIGHT/2 - segaLogo.height/2 - VIRTUAL_SCREEN_HEIGHT) * t;
                timer += deltaTime;
                if (timer >= animationDuration) {
                    initPhase = InitScreenPhase.LOGO_DISPLAY;
                    timer = 0.0f;
                }
            } else if (initPhase == InitScreenPhase.LOGO_DISPLAY) {
                if (!jinglePlayed) {
                    PlaySound(segaJingle);
                    jinglePlayed = true;
                }
                logoScaleX = segaLogo.width * targetScale;
                logoScaleY = segaLogo.height * targetScale;
                logoPosition.x = (VIRTUAL_SCREEN_WIDTH - logoScaleX) / 2.0f;
                logoPosition.y = (VIRTUAL_SCREEN_HEIGHT - logoScaleY) / 2.0f;
                timer += deltaTime;
                if (timer >= holdDuration) {
                    initPhase = InitScreenPhase.LOGO_FADEOUT;
                    timer = 0.0f;
                }
            } else if (initPhase == InitScreenPhase.LOGO_FADEOUT) {
                float t = timer / fadeOutDuration;
                if (t > 1.0f) t = 1.0f;
                logoScaleX = segaLogo.width * (1.0f - t);
                logoScaleY = segaLogo.height * (1.0f - t);
                logoPosition.x = (VIRTUAL_SCREEN_WIDTH - logoScaleX) / 2.0f;
                logoPosition.y = (VIRTUAL_SCREEN_HEIGHT - logoScaleY) / 2.0f;
                timer += deltaTime;
                if (timer >= fadeOutDuration) {
                    initPhase = InitScreenPhase.DONE;
                    initState = InitScreenState.DONE;
                }
            }
        }
        if (initPhase == InitScreenPhase.DONE) {
            ScreenManager.getInstance().changeState(ScreenState.TITLE);
        }
    }

    void draw() {
        // Fade background from black to white, then keep white
        ubyte bgValue = cast(ubyte)backgroundColorModifier;
        Color bgColor = Color(bgValue, bgValue, bgValue, 255);
        ClearBackground(bgColor);

        if (initState == InitScreenState.DISCLAIMER) {
            if (initPhase == InitScreenPhase.DISCLAIMER_FADEIN || initPhase == InitScreenPhase.DISCLAIMER_DISPLAY || initPhase == InitScreenPhase.DISCLAIMER_FADEOUT) {
                import sprite.sprite_fonts;
                string header = "DISCLAIMER";
                string[] disclaimerLines = [
                    "",
                    "THIS IS A FAN PROJECT MADE WITH LOVE FOR THE",
                    "SONIC COMMUNITY.",
                    "IT IS NOT AFFILIATED WITH SEGA OR SONIC TEAM.",
                    "THIS PROJECT IS STRICTLY NON-COMMERCIAL.",
                    "ALL RIGHTS BELONG TO THEIR RESPECTIVE OWNERS.",
                    "THANK YOU FOR YOUR SUPPORT!"
                ];
                float lineHeight = 10.0f;
                float totalHeight = (disclaimerLines.length + 1) * lineHeight;
                float startY = (VIRTUAL_SCREEN_HEIGHT - totalHeight) / 2.0f;
                Color fadeColor = Colors.WHITE;
                fadeColor.a = cast(ubyte)(255 * disclaimerAlpha);
                // Draw header with DiscoveryFont
                int headerWidth = 0;
                foreach (ch; header) {
                    if (ch >= 'A' && ch <= 'Z') {
                        int idx = ch - 'A';
                        headerWidth += discoveryFont.glyphs[idx].width;
                    } else if (ch == ' ') {
                        headerWidth += 8; // Space width, adjust as needed
                    }
                }
                float headerX = (VIRTUAL_SCREEN_WIDTH - headerWidth) / 2.0f;
                float headerY = startY;
                drawDiscoveryText(header, cast(int)headerX, cast(int)headerY, fadeColor);
                // Draw paragraph with Sonic font
                foreach (i, line; disclaimerLines) {
                    if (line.length > 0) {
                        int textWidth = cast(int)line.length * smallSonicFont.glyphWidth;
                        float textX = (VIRTUAL_SCREEN_WIDTH - textWidth) / 2.0f;
                        float textY = startY + (i + 1) * lineHeight;
                        drawSpriteText(smallSonicFont, line, cast(int)textX, cast(int)textY, fadeColor);
                    }
                }
            }
        }

        if (initState == InitScreenState.SPLASH) {
            if (initPhase == InitScreenPhase.LOGO_ANIMATE || initPhase == InitScreenPhase.LOGO_DISPLAY || initPhase == InitScreenPhase.LOGO_FADEOUT) {
                // Draw Sega logo
                DrawTexturePro(
                    segaLogo,
                    Rectangle(0, 0, segaLogo.width, segaLogo.height),
                    Rectangle(logoPosition.x, logoPosition.y, logoScaleX, logoScaleY),
                    Vector2(0, 0),
                    0.0f,
                    Colors.WHITE
                );
            }
        }
    }

    void unload() {
        UnloadTexture(segaLogo);
        UnloadSound(segaJingle);
    }
}