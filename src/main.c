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
#include <unistd.h>  // for chdir()
#include <limits.h>  // for PATH_MAX

#ifdef __APPLE__
#include <mach-o/dyld.h>  // for _NSGetExecutablePath
#endif

// Ensure PATH_MAX is defined on all platforms
#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

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
#include "world/data.h"
#include "util/level_loader.h"
#include "entity/player/player.h"

GameCamera cam;
Player player;

// Global variables (defined in globals.h)
const int scrMult = 2;
int screenWidth = 400 * scrMult;  // Default window size
int screenHeight = 240 * scrMult;

// Audio settings
bool musicEnabled = true;
bool sfxEnabled = true;
float masterVolume = 1.0f;

// Font variables
Font s1TitleFont = {0};
Font s1ClassicOpenCFont = {0};
Font sonicGameworldFont = {0};
Font fontFamily[3] = {0};

// Global audio manager instance
AudioManager g_audioManager;

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

void initializeGame(int x, int y, float zoom, float rot) {
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

// Update screen size based on current window size from data system
void UpdateScreenSize(void) {
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

    // Initialize global audio manager
    InitAudioManager(&g_audioManager);
    
    printf("Basic framework systems initialized successfully\n");
    return true;
}

// Cleanup all framework systems
void CleanupFramework(void) {
    printf("Cleaning up framework systems...\n");
    
    CloseAudioDevice();
    
    printf("Framework cleanup complete\n");
}

// On macOS, detect if we're running from a bundle and adjust working directory
#if defined(__APPLE__)
static bool SetupMacOSBundleResources(void) {
    char execPath[PATH_MAX];
    char bundlePath[PATH_MAX];
    char currentPath[PATH_MAX];
    uint32_t size = sizeof(execPath);
    
    // Get the current working directory for debugging
    if (getcwd(currentPath, sizeof(currentPath)) != NULL) {
        printf("Initial working directory: %s\n", currentPath);
    }
    
    if (_NSGetExecutablePath(execPath, &size) == 0) {
        printf("Executable path: %s\n", execPath);
        
        // Check if we're in a .app bundle
        if (strstr(execPath, ".app/Contents/MacOS/") != NULL) {
            // Get the full path to the Resources directory
            strncpy(bundlePath, execPath, sizeof(bundlePath) - 1);
            char *lastSlash = strrchr(bundlePath, '/');
            if (lastSlash) {
                *lastSlash = '\0';  // Remove executable name
                char *macosDir = strstr(bundlePath, ".app/Contents/MacOS");
                if (macosDir) {
                    *macosDir = '\0';  // Remove .app/Contents/MacOS
                    strncat(bundlePath, ".app/Contents/Resources", sizeof(bundlePath) - strlen(bundlePath) - 1);
                    printf("Bundle detected! Resources directory should be: %s\n", bundlePath);
                    
                    if (chdir(bundlePath) == 0) {
                        if (getcwd(currentPath, sizeof(currentPath)) != NULL) {
                            printf("Changed working directory to: %s\n", currentPath);
                        }
                        
                        // Verify critical resource paths exist
                        const char *checkPaths[] = {
                            "res",
                            "res/fonts",
                            "res/sprite",
                            "res/audio",
                            "options.ini"
                        };
                        
                        bool allPathsExist = true;
                        for (size_t i = 0; i < sizeof(checkPaths)/sizeof(checkPaths[0]); i++) {
                            if (access(checkPaths[i], F_OK) == -1) {
                                printf("Warning: %s not found in bundle Resources\n", checkPaths[i]);
                                allPathsExist = false;
                            } else {
                                printf("✓ Found %s\n", checkPaths[i]);
                            }
                        }
                        
                        if (!allPathsExist) {
                            printf("\nListing Resources directory contents:\n");
                            system("ls -la");
                            printf("\nListing res directory contents:\n");
                            system("ls -la res");
                        }
                        
                        return true; // Continue even if some paths are missing
                    } else {
                        perror("Failed to change to Resources directory");
                    }
                }
            }
        } else {
            printf("Not running from a bundle, using current directory\n");
        }
    } else {
        printf("Warning: Could not get executable path\n");
    }
    
    return true; // Continue with current directory if anything fails
}
#endif

int main(void) {
    printf("Starting Presto Framework v%s...\n", VERSION);
    
    // Get initial working directory for debugging
    char initialPath[PATH_MAX] = {0};
    if (getcwd(initialPath, sizeof(initialPath)) != NULL) {
        printf("Initial working directory: %s\n", initialPath);
    }
    
    #if defined(__APPLE__)
        // When running from a .app bundle, change to Resources directory BEFORE loading any resources
        if (!SetupMacOSBundleResources()) {
            fprintf(stderr, "Warning: Failed to set bundle resource path\n");
        }
    #endif
    
    // Get working directory after potential bundle change
    char workingPath[PATH_MAX] = {0};
    if (getcwd(workingPath, sizeof(workingPath)) != NULL) {
        printf("Working directory for resource loading: %s\n", workingPath);
    }
    
    // Initialize data system (configuration loaded automatically)
    InitializeDataSystem();
    
    // Update screen size based on loaded configuration
    UpdateScreenSize();    // Set raylib configuration flags
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
    
    if (isFullscreen) { ToggleBorderlessWindowed(); }
    
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

    //initializeGame(, , , );
    cam = GameCamera_Init(510, 510, VIRTUAL_SCREEN_WIDTH/2, VIRTUAL_SCREEN_HEIGHT/2, 1.0f, 0.0f);
    // Start the player near center; camera will follow and keep centered
    player = Player_Init(VIRTUAL_SCREEN_WIDTH * 0.5f, VIRTUAL_SCREEN_HEIGHT * 0.5f);

    
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
    RegisterScreen(&screenManager, SCREEN_DEBUG2, LevelDemo_Init, LevelDemo_Update, LevelDemo_Draw, LevelDemo_Unload);
    RegisterScreen(&screenManager, SCREEN_GAMEPLAY, LevelDemo_Init, LevelDemo_Update, LevelDemo_Draw, LevelDemo_Unload);

    // Set initial screen
    // For the demo, jump directly to the level demo screen
    SetCurrentScreen(&screenManager, SCREEN_INIT);
    
    printf("Starting main game loop...\n");

    //MoveCamTo(&cam, (Vector2){0, 0});
    
    // Main game loop
    while (!WindowShouldClose()) {
        float deltaTime = GetFrameTime();
        
        // Update unified input system
        UpdateUnifiedInput(deltaTime);
        
        // Handle dynamic window size changes (only if not fullscreen)
        if (!isFullscreen) {
            static int lastWindowSize = 0;
            if (windowSize != lastWindowSize && windowSize > 0) {
                screenWidth = VIRTUAL_SCREEN_WIDTH * windowSize;
                screenHeight = VIRTUAL_SCREEN_HEIGHT * windowSize;
                SetWindowSize(screenWidth, screenHeight);
                lastWindowSize = windowSize;
            }
        }
        
        // Update framework systems (simplified for now)
        // TODO: Add back framework system updates when they're properly implemented

            // Update audio manager (required for module music playback)
            UpdateAudioManager(&g_audioManager);
            // Player update and camera follow happen within the current screen (LevelDemo_Update)
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
                DrawText(TextFormat("Virtual Mouse: %f, %f", GetMousePositionVirtual().x, GetMousePositionVirtual().y), 10, 100, 20, GRAY);
                DrawText(TextFormat("Window Size: %dx%d (Scale: %d)", GetScreenWidth(), GetScreenHeight(), windowSize), 10, 130, 20, GRAY);
                DrawText(TextFormat("Camera Pos: %f, %f", cam.position.x, cam.position.y), 10, 160, 20, GRAY);
                DrawText(TextFormat("Player Pos: %f, %f", player.position.x, player.position.y), 10, 190, 20, GRAY);

                int minX = (player.position.x + player.hitbox.x - cam.position.x);
                int minY = (player.position.y + player.hitbox.y - cam.position.y);
                DrawRectangleLines(minX * 2, minY * 2, player.hitbox.w, player.hitbox.h, BLACK);
            }
            // Player is drawn by the current screen inside the virtual render pass
        EndDrawing();
    }
    
    // Cleanup
    printf("Shutting down...\n");
    
    UnloadScreenManager(&screenManager);
    
    // Cleanup sprite font manager
    CleanupSpriteFontManager();
    
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
