/*
    PRESTO FRAMEWORK
    Sonic-style Game Engine in C23

    A high-performance, extensible game framework for rapid prototyping and development.
    This file is part of the Presto Framework.

    Created by DiSKO and Birb64
*/

#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

// Framework includes
#include "util/globals.h"
#include "screens/init_screen.h"
#include "screens/title_screen.h"
#include "screens/options_screen.h"
#include "screens/anim_demo_screen.h"
#include "screens/level_demo_screen.h"
#include "world/screen_manager.h"
#include "world/sprite_font_manager.h"
#include "world/input.h"

// Global variables (defined in globals.h)
int screenWidth = 400 * 2;  // Default window size
int screenHeight = 240 * 2;
int windowSize = 2;
bool isFullscreen = false;
bool isVSync = true;
bool isDebugMode = false;

// Audio settings
bool musicEnabled = true;
bool sfxEnabled = true;
float masterVolume = 1.0f;

// Font variables
Font s1TitleFont = {0};
Font s1ClassicOpenCFont = {0};
Font sonicGameworldFont = {0};
Font fontFamily[3] = {0};

// Function to get mouse position in virtual screen coordinates
Vector2 GetMousePositionVirtual(void) {
    Vector2 mouseScreenPos = GetMousePosition();
    
    float scale = fminf((float)GetScreenWidth() / VIRTUAL_SCREEN_WIDTH, 
                        (float)GetScreenHeight() / VIRTUAL_SCREEN_HEIGHT);
                        
    // Calculate the top-left position of the scaled virtual screen on the actual screen
    float destX = (GetScreenWidth() - (VIRTUAL_SCREEN_WIDTH * scale)) / 2.0f;
    float destY = (GetScreenHeight() - (VIRTUAL_SCREEN_HEIGHT * scale)) / 2.0f;

    // Convert screen mouse position to virtual screen mouse position
    float virtualMouseX = (mouseScreenPos.x - destX) / scale;
    float virtualMouseY = (mouseScreenPos.y - destY) / scale;

    return (Vector2){virtualMouseX, virtualMouseY};
}

// Load audio settings from options.ini
void LoadAudioSettings(void) {
    FILE* file = fopen("options.ini", "r");
    if (file == NULL) return;
    
    char line[256];
    while (fgets(line, sizeof(line), file)) {
        // Remove newline
        line[strcspn(line, "\n")] = 0;
        
        // Find the '=' separator
        char* equals = strchr(line, '=');
        if (equals == NULL) continue;
        
        *equals = '\0';
        char* key = line;
        char* value = equals + 1;
        
        // Trim whitespace
        while (*key == ' ' || *key == '\t') key++;
        while (*value == ' ' || *value == '\t') value++;
        
        // Load audio settings
        if (strcmp(key, "musicEnabled") == 0) {
            musicEnabled = (strcmp(value, "true") == 0);
        } else if (strcmp(key, "sfxEnabled") == 0) {
            sfxEnabled = (strcmp(value, "true") == 0);
        }
    }
    
    fclose(file);
    printf("Audio settings loaded - Music: %s, SFX: %s\n", 
           musicEnabled ? "enabled" : "disabled",
           sfxEnabled ? "enabled" : "disabled");
}

// Load configuration from options.ini
void LoadConfiguration(void) {
    FILE *file = fopen("options.ini", "r");
    if (file == NULL) {
        printf("options.ini not found, using defaults\n");
        return;
    }
    
    char line[256];
    while (fgets(line, sizeof(line), file)) {
        char key[128], value[128];
        if (sscanf(line, "%127[^=]=%127s", key, value) == 2) {
            // Remove whitespace
            char *trimmed_key = key;
            while (*trimmed_key == ' ' || *trimmed_key == '\t') trimmed_key++;
            char *end = trimmed_key + strlen(trimmed_key) - 1;
            while (end > trimmed_key && (*end == ' ' || *end == '\t' || *end == '\n' || *end == '\r')) *end-- = '\0';
            
            char *trimmed_value = value;
            while (*trimmed_value == ' ' || *trimmed_value == '\t') trimmed_value++;
            end = trimmed_value + strlen(trimmed_value) - 1;
            while (end > trimmed_value && (*end == ' ' || *end == '\t' || *end == '\n' || *end == '\r')) *end-- = '\0';
            
            if (strcmp(trimmed_key, "windowSize") == 0) {
                windowSize = atoi(trimmed_value);
                if (windowSize < 1) windowSize = 1;
                if (windowSize > 8) windowSize = 8;
            } else if (strcmp(trimmed_key, "fullscreen") == 0) {
                isFullscreen = (strcmp(trimmed_value, "true") == 0);
            } else if (strcmp(trimmed_key, "vsync") == 0) {
                isVSync = (strcmp(trimmed_value, "true") == 0);
            } else if (strcmp(trimmed_key, "debug") == 0) {
                isDebugMode = (strcmp(trimmed_value, "true") == 0);
            }
        }
    }
    fclose(file);
    
    screenWidth = VIRTUAL_SCREEN_WIDTH * windowSize;
    screenHeight = VIRTUAL_SCREEN_HEIGHT * windowSize;
}

// Initialize all framework systems
bool InitializeFramework(void) {
    printf("Initializing Presto Framework systems...\n");
    
    // Initialize audio device
    InitAudioDevice();
    if (!IsAudioDeviceReady()) {
        printf("Warning: Failed to initialize audio device\n");
        return false;
    }
    
    printf("Basic framework systems initialized successfully\n");
    return true;
}

// Cleanup all framework systems
void CleanupFramework(void) {
    printf("Cleaning up framework systems...\n");
    
    CloseAudioDevice();
    
    printf("Framework cleanup complete\n");
}

int main(void) {
    printf("Starting Presto Framework v%s...\n", VERSION);
    
    // Load configuration
    LoadConfiguration();
    
    // Set raylib configuration flags
    if (isVSync) {
        SetConfigFlags(FLAG_VSYNC_HINT);
    }
    
    // Initialize window
    if (isFullscreen) {
        int displayWidth = GetMonitorWidth(GetCurrentMonitor());
        int displayHeight = GetMonitorHeight(GetCurrentMonitor());
        screenWidth = displayWidth;
        screenHeight = displayHeight;
    } else {
        // Ensure window size is a clean multiple of virtual screen size
        screenWidth = VIRTUAL_SCREEN_WIDTH * windowSize;
        screenHeight = VIRTUAL_SCREEN_HEIGHT * windowSize;
    }
    
    InitWindow(screenWidth, screenHeight, GAME_TITLE " " VERSION);
    
    if (isFullscreen) {
        ToggleBorderlessWindowed();
    }
    
    SetTargetFPS(60);
    SetExitKey(KEY_NULL); // Disable ESC key to close window
    
    // Create virtual screen render texture
    RenderTexture2D virtualScreen = LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT);
    SetTextureFilter(virtualScreen.texture, TEXTURE_FILTER_POINT);
    
    // Initialize framework systems
    if (!InitializeFramework()) {
        printf("Error: Failed to initialize framework systems\n");
        UnloadRenderTexture(virtualScreen);
        CloseWindow();
        return -1;
    }
    
    // Initialize sprite font manager
    InitSpriteFontManager();
    
    // Initialize unified input system
    InitUnifiedInput();
    
    // Load audio settings from options.ini
    LoadAudioSettings();
    
    // Load fonts
    s1TitleFont = LoadFont("res/fonts/DiscoveryFont/Discovery-Regular.otf");
    if (s1TitleFont.texture.id == 0) {
        s1TitleFont = GetFontDefault(); // Fallback to default font
        printf("Warning: Could not load Discovery font, using default\n");
    }
    s1ClassicOpenCFont = LoadFont("res/fonts/presto-numbersA/presto-numbersA.ttf");
    if (s1ClassicOpenCFont.texture.id == 0) {
        s1ClassicOpenCFont = GetFontDefault();
        printf("Warning: Could not load presto-numbersA font, using default\n");
    }
    sonicGameworldFont = LoadFont("res/fonts/presto-numbersB/presto-numbersB.ttf");
    if (sonicGameworldFont.texture.id == 0) {
        sonicGameworldFont = GetFontDefault();
        printf("Warning: Could not load presto-numbersB font, using default\n");
    }
    
    // Initialize screen manager
    ScreenManager screenManager;
    InitScreenManager(&screenManager);
    g_screenManager = &screenManager;  // Set global reference
    
    // Register screens
    RegisterScreen(&screenManager, SCREEN_INIT, InitScreen_Init, InitScreen_Update, InitScreen_Draw, InitScreen_Unload);
    RegisterScreen(&screenManager, SCREEN_TITLE, TitleScreen_Init, TitleScreen_Update, TitleScreen_Draw, TitleScreen_Unload);
    RegisterScreen(&screenManager, SCREEN_OPTIONS, OptionsScreen_Init, OptionsScreen_Update, OptionsScreen_Draw, OptionsScreen_Unload);
    RegisterScreen(&screenManager, SCREEN_ANIM_DEMO, AnimDemo_Init, AnimDemo_Update, AnimDemo_Draw, AnimDemo_Unload);
    RegisterScreen(&screenManager, SCREEN_DEBUG1, LevelDemo_Init, LevelDemo_Update, LevelDemo_Draw, LevelDemo_Unload);
    
    // Set initial screen
    // For the demo, jump directly to the level demo screen
    SetCurrentScreen(&screenManager, SCREEN_INIT);
    
    printf("Starting main game loop...\n");
    
    // Main game loop
    while (!WindowShouldClose()) {
        float deltaTime = GetFrameTime();
        
        // Update unified input system
        UpdateUnifiedInput(deltaTime);
        
        // Handle dynamic window size changes (only if not fullscreen)
        if (!isFullscreen) {
            static int lastWindowSize = 0;
            LoadConfiguration(); // Check for config changes
            if (windowSize != lastWindowSize && windowSize > 0) {
                screenWidth = VIRTUAL_SCREEN_WIDTH * windowSize;
                screenHeight = VIRTUAL_SCREEN_HEIGHT * windowSize;
                SetWindowSize(screenWidth, screenHeight);
                lastWindowSize = windowSize;
            }
        }
        
        // Update framework systems (simplified for now)
        // TODO: Add back framework system updates when they're properly implemented
        
        // Update screen manager
        UpdateScreenManager(&screenManager, deltaTime);
        
        // Draw everything to virtual screen
        BeginTextureMode(virtualScreen);
            ClearBackground(BLACK);
            DrawScreenManager(&screenManager);
        EndTextureMode();
        
        // Draw virtual screen to actual screen
        BeginDrawing();
            ClearBackground(BLACK);
            
            // Calculate scale to fit virtual screen into actual screen, maintaining aspect ratio
            float scale = fminf((float)GetScreenWidth() / VIRTUAL_SCREEN_WIDTH, 
                               (float)GetScreenHeight() / VIRTUAL_SCREEN_HEIGHT);
            
            // Calculate position to center the scaled virtual screen
            float destX = (GetScreenWidth() - (VIRTUAL_SCREEN_WIDTH * scale)) / 2.0f;
            float destY = (GetScreenHeight() - (VIRTUAL_SCREEN_HEIGHT * scale)) / 2.0f;

            // Define source and destination rectangles for drawing the texture
            Rectangle sourceRec = { 0, 0, (float)VIRTUAL_SCREEN_WIDTH, -(float)VIRTUAL_SCREEN_HEIGHT }; 
            Rectangle destRec = { destX, destY, VIRTUAL_SCREEN_WIDTH * scale, VIRTUAL_SCREEN_HEIGHT * scale };
            Vector2 origin = { 0, 0 };

            DrawTexturePro(virtualScreen.texture, sourceRec, destRec, origin, 0.0f, WHITE);
            
            // Optional: Display FPS and debug info
            if (isDebugMode) {
                DrawFPS(10, 10);
                DrawText(TextFormat("Virtual Mouse: %.1f, %.1f", 
                    GetMousePositionVirtual().x, GetMousePositionVirtual().y), 10, 30, 10, LIME);
                DrawText(TextFormat("Window Size: %dx%d (Scale: %d)", 
                    GetScreenWidth(), GetScreenHeight(), windowSize), 10, 50, 10, LIME);
            }
            
        EndDrawing();
    }
    
    // Cleanup
    printf("Shutting down...\n");
    
    UnloadScreenManager(&screenManager);
    
    // Unload fonts
    if (s1TitleFont.texture.id != 0) UnloadFont(s1TitleFont);
    if (s1ClassicOpenCFont.texture.id != 0) UnloadFont(s1ClassicOpenCFont);
    if (sonicGameworldFont.texture.id != 0) UnloadFont(sonicGameworldFont);
    
    // Cleanup framework
    CleanupFramework();
    
    // Cleanup raylib
    UnloadRenderTexture(virtualScreen);
    CloseWindow();
    
    printf("Presto Framework shutdown complete\n");
    return 0;
}
