module screens.title_screen;

import raylib;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;
import std.algorithm;

import world.screen_manager;
import world.screen_state;
import world.audio_manager;
import app;
import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT;

// Title screen states
enum TitleScreenState {
    LOGO_FALLING,
    LOGO_BOUNCING,
    MENU_ACTIVE
}

class TitleScreen : IScreen {
    Texture2D logoTexture;
    Vector2 logoPosition;
    Vector2 logoVelocity;
    float logoScale = 1.0f;
    TitleScreenState state;
    int bounceCount = 0;
    int maxBounces = 3;

    string[] menuItems = ["Start Game", "Options", "Exit Game"];
    int selectedMenu = 0;

    Sound bounceSound;
    Sound moveSound;
    Sound acceptSound;

    float menuAnimProgress = 0.0f;
    float menuAnimDuration = 0.5f;

    // Checkerboard background variables
    float checkerFade = 0.0f;
    float checkerFadeSpeed = 1.0f;
    float checkerScrollX = 0.0f;
    float checkerScrollY = 0.0f;
    float checkerScale = 32.0f;

    this() {
        logoTexture = LoadTexture("resources/image/spritesheet/Presto.png");
        bounceSound = LoadSound("resources/sound/sfx/Sonic Jam S3/18.wav");
        moveSound = LoadSound("resources/sound/sfx/Sonic World Sounds/004.wav");
        acceptSound = LoadSound("resources/sound/sfx/Sonic World Sounds/022.wav");
        logoPosition = Vector2(VIRTUAL_SCREEN_WIDTH - logoTexture.width * logoScale - 40, -logoTexture.height * logoScale);
        logoVelocity = Vector2(0, 0);
        state = TitleScreenState.LOGO_FALLING;
    }

    void initialize() {
        // Reset logo position and velocity for re-entry
        logoPosition = Vector2(VIRTUAL_SCREEN_WIDTH - logoTexture.width * logoScale - 40, -logoTexture.height * logoScale);
        logoVelocity = Vector2(0, 0);
        state = TitleScreenState.LOGO_FALLING;
        bounceCount = 0;
        selectedMenu = 0;
        menuAnimProgress = 0.0f;

        // Reset checkerboard variables
        checkerFade = 0.0f;
        checkerScrollX = 0.0f;
        checkerScrollY = 0.0f;
        checkerScale = 32.0f;

        // Reload sounds if needed
        if (moveSound.frameCount == 0) {
            moveSound = LoadSound("resources/sound/sfx/Sonic World Sounds/004.wav");
        }
        if (acceptSound.frameCount == 0) {
            acceptSound = LoadSound("resources/sound/sfx/Sonic World Sounds/022.wav");
        }
    }

    void update(float deltaTime) {
        float logoTargetY = VIRTUAL_SCREEN_HEIGHT / 2 - logoTexture.height * logoScale / 2; // Center logo vertically
        switch (state) {
            case TitleScreenState.LOGO_FALLING:
                logoVelocity.y += 1200 * deltaTime; // gravity
                logoPosition.y += logoVelocity.y * deltaTime;
                if (logoPosition.y >= logoTargetY) {
                    logoPosition.y = logoTargetY;
                    logoVelocity.y = -logoVelocity.y * 0.5f; // bounce
                    bounceCount++;
                    PlaySound(bounceSound);
                    state = TitleScreenState.LOGO_BOUNCING;
                }
                break;
            case TitleScreenState.LOGO_BOUNCING:
                logoVelocity.y += 1200 * deltaTime;
                logoPosition.y += logoVelocity.y * deltaTime;
                if (logoPosition.y >= logoTargetY) {
                    logoPosition.y = logoTargetY;
                    logoVelocity.y = -logoVelocity.y * 0.5f;
                    bounceCount++;
                    PlaySound(bounceSound);
                    if (bounceCount >= maxBounces) {
                        logoVelocity.y = 0;
                        state = TitleScreenState.MENU_ACTIVE;
                    }
                }
                break;
            case TitleScreenState.MENU_ACTIVE:
                if (menuAnimProgress < 1.0f) {
                    menuAnimProgress += deltaTime / menuAnimDuration;
                    if (menuAnimProgress > 1.0f) menuAnimProgress = 1.0f;
                }
                // Fade in checkerboard
                if (checkerFade < 1.0f) {
                    checkerFade += deltaTime * checkerFadeSpeed;
                    if (checkerFade > 1.0f) checkerFade = 1.0f;
                }
                // Scroll checkerboard diagonally
                checkerScrollX += deltaTime * 40.0f;
                checkerScrollY += deltaTime * 40.0f;

                // Handle menu navigation (up/down/enter)
                if (IsKeyPressed(KeyboardKey.KEY_DOWN)) {
                    selectedMenu = cast(int)((selectedMenu + 1) % menuItems.length);
                    PlaySound(moveSound);
                } else if (IsKeyPressed(KeyboardKey.KEY_UP)) {
                    selectedMenu = cast(int)((selectedMenu - 1 + menuItems.length) % menuItems.length);
                    PlaySound(moveSound);
                }
                // Accept: S key
                if (IsKeyPressed(KeyboardKey.KEY_S)) {
                    import world.audio_manager;
                    AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic World Sounds/022.wav");
                    if (menuItems[selectedMenu] == "Options") {
                        import world.screen_manager;
                        import world.screen_state;
                        ScreenManager.getInstance().changeState(ScreenState.SETTINGS);
                    }
                    // Add logic for other menu items as needed
                }
                // Back: A key
                if (IsKeyPressed(KeyboardKey.KEY_A)) {
                    // For now, do nothing or add logic to exit or go back
                }
                break;
            default:
                // Handle unexpected states
                writeln("ERROR: Unexpected TitleScreenState: ", state);
                break;
        }
    }

    void drawCheckerboard() {
        int cols = cast(int)(VIRTUAL_SCREEN_WIDTH / checkerScale) + 2;
        int rows = cast(int)(VIRTUAL_SCREEN_HEIGHT / checkerScale) + 2;
        Color color1 = Color(220, 220, 220, cast(ubyte)(180 * checkerFade));
        Color color2 = Color(180, 180, 180, cast(ubyte)(180 * checkerFade));
        for (int y = 0; y < rows; ++y) {
            for (int x = 0; x < cols; ++x) {
                float px = x * checkerScale + checkerScrollX % checkerScale - checkerScale;
                float py = y * checkerScale + checkerScrollY % checkerScale - checkerScale;
                Color c = ((x + y) % 2 == 0) ? color1 : color2;
                DrawRectangle(cast(int)px, cast(int)py, cast(int)checkerScale, cast(int)checkerScale, c);
            }
        }
    }

    void draw() {
        // White background
        ClearBackground(Colors.WHITE);
        // Draw checkerboard after logo stops bouncing
        if (state == TitleScreenState.MENU_ACTIVE) {
            drawCheckerboard();
        }
        // Draw logo on the right
        DrawTextureEx(logoTexture, logoPosition, 0.0f, logoScale, Colors.WHITE);
        // Animate menu sliding in from the left
        float menuXStart = -120;
        float menuXEnd = 40;
        float menuX = menuXStart + (menuXEnd - menuXStart) * menuAnimProgress;
        float menuY = VIRTUAL_SCREEN_HEIGHT / 2 - menuItems.length * 16 / 2;
        // Draw trapezoidal highlight for selected menu
        if (state == TitleScreenState.MENU_ACTIVE) {
            float highlightY = menuY + selectedMenu * 24;
            float highlightWidth = 180.0f;
            float highlightHeight = 24.0f;
            float skew = 24.0f;
            Vector2 a = Vector2(menuX - skew, highlightY);
            Vector2 b = Vector2(menuX + highlightWidth - skew, highlightY);
            Vector2 c = Vector2(menuX + highlightWidth + skew, highlightY + highlightHeight);
            Vector2 d = Vector2(menuX + skew, highlightY + highlightHeight);
            Color highlightColor = Color(255, 255, 0, 120); // Semi-transparent yellow
            DrawTriangle(a, b, d, highlightColor);
            DrawTriangle(b, c, d, highlightColor);
        }
        foreach (i, item; menuItems) {
            Color color = (i == selectedMenu) ? Colors.BLUE : Colors.BLACK;
            float textWidth = MeasureTextEx(fontFamily[2], item.toStringz(), 16, 1.0f).x;
            DrawTextEx(fontFamily[2], item.toStringz(), Vector2(menuX, menuY + i * 24), 16, 1.0f, color);
        }
    }

    void unload() {
        // Only unload on actual exit
        if (moveSound.frameCount != 0) {
            UnloadSound(moveSound);
            moveSound = Sound.init;
        }
        if (acceptSound.frameCount != 0) {
            UnloadSound(acceptSound);
            acceptSound = Sound.init;
        }
    }
}
