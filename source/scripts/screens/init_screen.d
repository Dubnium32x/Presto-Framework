module screens.init_screen;

import raylib;

import std.stdio;
import std.string;
import std.array;
import std.range;

import world.screen_manager;
import world.audio_manager;
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
    }

    void draw() {
        // Fade background from black to white, then keep white
        ubyte bgValue = cast(ubyte)backgroundColorModifier;
        Color bgColor = Color(bgValue, bgValue, bgValue, 255);
        ClearBackground(bgColor);

        if (initState == InitScreenState.DISCLAIMER) {
            if (initPhase == InitScreenPhase.DISCLAIMER_FADEIN || initPhase == InitScreenPhase.DISCLAIMER_DISPLAY || initPhase == InitScreenPhase.DISCLAIMER_FADEOUT) {
                // Split disclaimer text into multiple lines
                string[] disclaimerLines = [
                    "DISCLAIMER",
                    "",
                    "This is a fan project made from the love of the community",
                    "and the Sonic franchise. This project is not affiliated",
                    "with Sega or Sonic Team, and should not be used as a",
                    "commercial product."
                ];

                float titleFontSize = 28.0f;
                float paragraphFontSize = 14.0f;
                float lineHeight = 28.0f;
                float totalHeight = disclaimerLines.length * lineHeight;
                float startY = (VIRTUAL_SCREEN_HEIGHT - totalHeight) / 2.0f;

                // Fade color for text
                Color fadeColor = Colors.WHITE;
                fadeColor.a = cast(ubyte)(255 * disclaimerAlpha);

                foreach (i, line; disclaimerLines) {
                    if (line.length > 0) {
                        float fontSize = (i == 0) ? titleFontSize : paragraphFontSize;
                        Font font = (i == 0) ? fontFamily[0] : fontFamily[1];
                        float textWidth = MeasureTextEx(font, line.ptr, fontSize, 1.0f).x;
                        float textX = (VIRTUAL_SCREEN_WIDTH - textWidth) / 2.0f;
                        float textY = startY + i * lineHeight;
                        DrawTextEx(font, line.ptr, Vector2(textX, textY), fontSize, 1.0f, fadeColor);
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