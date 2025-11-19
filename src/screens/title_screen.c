// Title Screen implementation
#include "title_screen.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "raylib.h"
#include "../world/screen_manager.h"
#include "../util/globals.h"
#include "../world/sprite_font_manager.h"
#include "../world/input.h"

// Title screen variables
static Texture2D logoTexture = {0};
static Vector2 logoPosition = {0, 0};
static Vector2 logoVelocity = {0, 0};
static float logoScale = 1.0f;
static TitleScreenState titleState = TITLE_LOGO_FALLING;
static int bounceCount = 0;
static int maxBounces = 3;
static float bounceDelayTimer = 0.0f;
static float bounceDelayDuration = 1.0f;

// Menu system
static const char *menuItems[] = {"START GAME", "LEVEL EDITOR", "OPTIONS", "EXIT GAME"};
static const int menuItemCount = sizeof(menuItems) / sizeof(menuItems[0]);
static int selectedMenu = 0;
static ScreenType pendingScreen = SCREEN_GAMEPLAY;

// Sound effects and music
static Sound bounceSound = {0};
static Sound moveSound = {0};
static Sound acceptSound = {0};
static Music titleMusic = {0};
static bool musicStarted = false;

// Animation and transition variables
static float menuAnimProgress = 0.0f;
static float menuAnimDuration = 0.5f;
static float transitionAlpha = 0.0f;
static float transitionDuration = 1.2f;
static float transitionTimer = 0.0f;
static float exitAlpha = 0.0f;
static float exitDuration = 1.2f;
static float exitTimer = 0.0f;

// Checkerboard background variables
static float checkerFade = 0.0f;
static float checkerFadeSpeed = 1.0f;
static float checkerScrollX = 0.0f;
static float checkerScrollY = 0.0f;
static float checkerScale = 32.0f;

void TitleScreen_Init(void)
{
    // Load resources
    logoTexture = LoadTexture("res/image/logos/Presto.png");
    bounceSound = LoadSound("res/audio/sfx/Sonic Jam S3/18.wav");        // Bounce sound
    moveSound = LoadSound("res/audio/sfx/Sonic World Sounds/004.wav");   // Menu move sound
    acceptSound = LoadSound("res/audio/sfx/Sonic World Sounds/022.wav"); // Menu accept sound
    titleMusic = LoadMusicStream("res/audio/music/04. Digital Manual.mp3");
    titleMusic.looping = true;
    musicStarted = false;

    // Initialize logo position and physics
    logoPosition.x = VIRTUAL_SCREEN_WIDTH - logoTexture.width * logoScale - 40;
    logoPosition.y = -logoTexture.height * logoScale;
    logoVelocity.x = 0;
    logoVelocity.y = 0;

    // Reset state
    titleState = TITLE_LOGO_FALLING;
    bounceCount = 0;
    selectedMenu = 0;
    menuAnimProgress = 0.0f;
    pendingScreen = SCREEN_GAMEPLAY;

    // Reset checkerboard variables
    checkerFade = 0.0f;
    checkerScrollX = 0.0f;
    checkerScrollY = 0.0f;
}

static void DrawCheckerboard(void)
{
    int cols = (int)(VIRTUAL_SCREEN_WIDTH / checkerScale) + 2;
    int rows = (int)(VIRTUAL_SCREEN_HEIGHT / checkerScale) + 2;
    Color color1 = {220, 220, 220, (unsigned char)(180 * checkerFade)};
    Color color2 = {180, 180, 180, (unsigned char)(180 * checkerFade)};

    for (int y = 0; y < rows; y++)
    {
        for (int x = 0; x < cols; x++)
        {
            float px = x * checkerScale + fmodf(checkerScrollX, checkerScale) - checkerScale;
            float py = y * checkerScale + fmodf(checkerScrollY, checkerScale) - checkerScale;
            Color c = ((x + y) % 2 == 0) ? color1 : color2;
            DrawRectangle((int)px, (int)py, (int)checkerScale, (int)checkerScale, c);
        }
    }
}

void TitleScreen_Update(float deltaTime)
{
    float logoTargetY = VIRTUAL_SCREEN_HEIGHT / 2 - logoTexture.height * logoScale / 2; // Center logo vertically

    switch (titleState)
    {
    case TITLE_LOGO_FALLING:
        logoVelocity.y += 1200 * deltaTime; // gravity
        logoPosition.y += logoVelocity.y * deltaTime;
        if (logoPosition.y >= logoTargetY)
        {
            logoPosition.y = logoTargetY;
            logoVelocity.y = -logoVelocity.y * 0.5f; // bounce
            bounceCount++;
            PlaySound(bounceSound);
            titleState = TITLE_LOGO_BOUNCING;
        }
        break;

    case TITLE_LOGO_BOUNCING:
        logoVelocity.y += 1200 * deltaTime;
        logoPosition.y += logoVelocity.y * deltaTime;
        if (logoPosition.y >= logoTargetY)
        {
            logoPosition.y = logoTargetY;
            logoVelocity.y = -logoVelocity.y * 0.5f;
            bounceCount++;
            extern bool sfxEnabled;
            if (sfxEnabled)
                PlaySound(bounceSound);
            if (bounceCount >= maxBounces)
            {
                logoVelocity.y = 0;
                bounceDelayTimer = 0.0f;
                titleState = TITLE_LOGO_BOUNCE_DELAY;
            }
        }
        break;

    case TITLE_LOGO_BOUNCE_DELAY:
        bounceDelayTimer += deltaTime;
        if (bounceDelayTimer >= bounceDelayDuration)
        {
            titleState = TITLE_MENU_ACTIVE;
        }
        break;

    case TITLE_MENU_ACTIVE:
        // Start music when menu becomes active (if enabled)
        if (!musicStarted)
        {
            extern bool musicEnabled;
            if (musicEnabled)
            {
                PlayMusicStream(titleMusic);
                SetMusicVolume(titleMusic, 0.7f);
                musicStarted = true;
            }
        }

        // Update music stream
        UpdateMusicStream(titleMusic);

        // Animate menu sliding in
        if (menuAnimProgress < 1.0f)
        {
            menuAnimProgress += deltaTime / menuAnimDuration;
            if (menuAnimProgress > 1.0f)
                menuAnimProgress = 1.0f;
        }

        // Fade in checkerboard
        if (checkerFade < 1.0f)
        {
            checkerFade += deltaTime * checkerFadeSpeed;
            if (checkerFade > 1.0f)
                checkerFade = 1.0f;
        }

        // Scroll checkerboard diagonally
        checkerScrollX += deltaTime * 40.0f;
        checkerScrollY += deltaTime * 40.0f;

        // Handle menu navigation
        if (IsInputPressed(INPUT_DOWN))
        {
            selectedMenu = (selectedMenu + 1) % menuItemCount;
            extern bool sfxEnabled;
            if (sfxEnabled)
                PlaySound(moveSound);
        }
        else if (IsInputPressed(INPUT_UP))
        {
            selectedMenu = (selectedMenu - 1 + menuItemCount) % menuItemCount;
            extern bool sfxEnabled;
            if (sfxEnabled)
                PlaySound(moveSound);
        }

        // Accept selection
        if (IsInputPressed(INPUT_A) || IsInputPressed(INPUT_START))
        {
            extern bool sfxEnabled;
            if (sfxEnabled)
                PlaySound(acceptSound);
            if (selectedMenu == 0)
            { // START GAME
                pendingScreen = SCREEN_GAMEPLAY;
                titleState = TITLE_TRANSITION_OUT;
                transitionAlpha = 0.0f;
                transitionTimer = 0.0f;
            }
            else if (selectedMenu == 1)
            { // LEVEL EDITOR
                pendingScreen = SCREEN_LEVEL_EDITOR;
                titleState = TITLE_TRANSITION_OUT;
                transitionAlpha = 0.0f;
                transitionTimer = 0.0f;
            }
            else if (selectedMenu == 2)
            { // OPTIONS
                pendingScreen = SCREEN_OPTIONS;
                titleState = TITLE_TRANSITION_OUT;
                transitionAlpha = 0.0f;
                transitionTimer = 0.0f;
            }
            else if (selectedMenu == 3)
            { // EXIT GAME
                titleState = TITLE_EXITING;
                exitAlpha = 0.0f;
                exitTimer = 0.0f;
            }
        }
        break;

    case TITLE_TRANSITION_OUT:
        // Continue updating music during transition
        if (musicStarted)
        {
            UpdateMusicStream(titleMusic);
            // Fade out music during transition
            float fadeVolume = (1.0f - (transitionTimer / transitionDuration)) * 0.7f;
            SetMusicVolume(titleMusic, fadeVolume);
        }

        transitionTimer += deltaTime;
        transitionAlpha = fminf(transitionTimer / transitionDuration, 1.0f) * 255.0f;
        if (transitionTimer >= transitionDuration)
        {
            SetCurrentScreenGlobal(pendingScreen);
        }
        break;

    case TITLE_EXITING:
        exitTimer += deltaTime;
        exitAlpha = fminf(exitTimer / exitDuration, 1.0f) * 255.0f;
        if (exitTimer >= exitDuration)
        {
            CloseWindow();
        }
        break;
    }
}

void TitleScreen_Draw(void)
{
    // White background
    ClearBackground(WHITE);

    // Draw checkerboard after logo stops bouncing or during transition
    if (titleState == TITLE_MENU_ACTIVE || titleState == TITLE_TRANSITION_OUT)
    {
        DrawCheckerboard();
    }

    // Draw logo on the right
    DrawTextureEx(logoTexture, logoPosition, 0.0f, logoScale, WHITE);

    // Draw menu
    if (titleState == TITLE_MENU_ACTIVE || titleState == TITLE_TRANSITION_OUT)
    {
        // Animate menu sliding in from the left
        float menuXStart = -120;
        float menuXEnd = 40;
        float menuX = menuXStart + (menuXEnd - menuXStart) * menuAnimProgress;
        float menuY = VIRTUAL_SCREEN_HEIGHT / 2 - menuItemCount * 16 / 2;

        // Draw trapezoidal highlight for selected menu
        float highlightY = menuY + selectedMenu * 24;
        float highlightWidth = 180.0f;
        float highlightHeight = 24.0f;
        float skew = 24.0f;

        Vector2 a = {menuX - skew, highlightY};
        Vector2 b = {menuX + highlightWidth - skew, highlightY};
        Vector2 c = {menuX + highlightWidth + skew, highlightY + highlightHeight};
        Vector2 d = {menuX + skew, highlightY + highlightHeight};

        Color highlightColor = {255, 255, 0, 120}; // Semi-transparent yellow
        DrawTriangle(a, b, d, highlightColor);
        DrawTriangle(b, c, d, highlightColor);

        // Draw menu items
        for (int i = 0; i < menuItemCount; i++)
        {
            Color textColor = (i == selectedMenu) ? WHITE : BLACK;
            float itemX = menuX - 20; // Start items just off-screen to the left
            float itemY = menuY + i * 24;
            DrawDiscoveryText(menuItems[i], (Vector2){itemX, itemY}, 1.0f, textColor);
        }
    }

    // Draw Saturn-style white fade transition
    if (titleState == TITLE_TRANSITION_OUT)
    {
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT,
                      (Color){255, 255, 255, (unsigned char)transitionAlpha});
    }

    // Draw fade-to-black exit effect
    if (titleState == TITLE_EXITING)
    {
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT,
                      (Color){0, 0, 0, (unsigned char)exitAlpha});
    }
}

void TitleScreen_Unload(void)
{
    UnloadTexture(logoTexture);
    UnloadSound(bounceSound);
    UnloadSound(moveSound);
    UnloadSound(acceptSound);

    // Stop and unload music
    if (musicStarted)
    {
        StopMusicStream(titleMusic);
    }
    UnloadMusicStream(titleMusic);
}