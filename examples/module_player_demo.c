/*
    PRESTO FRAMEWORK - MODULE PLAYER DEMO
    Example demonstrating how to use the integrated module player for XM, IT, S3M files
    
    This example shows:
    - How to load and play module files
    - Volume control
    - Crossfading between modules
    - Integration with the main audio manager
*/

#include "raylib.h"
#include "world/audio_manager.h"
#include <stdio.h>
#include <string.h>

// Example function to demonstrate module player usage
void ModulePlayerDemo(void) {
    // Initialize audio manager (this includes the module player)
    AudioManager audioManager;
    InitAudioManager(&audioManager);
    
    printf("=== Presto Framework Module Player Demo ===\n");
    printf("Module Player Info: %s\n", GetModulePlayerInfo(&audioManager));
    printf("Module Player Enabled: %s\n", IsModulePlayerEnabled(&audioManager) ? "Yes" : "No");
    
    // Example module files (you would replace these with actual file paths)
    const char* moduleFiles[] = {
        "res/audio/music/song1.xm",
        "res/audio/music/song2.it",
        "res/audio/music/song3.s3m",
        "res/audio/music/song4.mod"
    };
    
    printf("\n=== Supported Module Formats ===\n");
    for (int i = 0; i < 4; i++) {
        printf("File: %s - Supported: %s\n", 
               moduleFiles[i], 
               IsModuleFile(moduleFiles[i]) ? "Yes" : "No");
    }
    
    // Example 1: Play a module file
    printf("\n=== Example 1: Playing Module Music ===\n");
    if (PlayModuleMusic(&audioManager, "res/audio/music/example.xm", 0.8f, true)) {
        printf("✓ Started playing example.xm at 80%% volume with looping\n");
    } else {
        printf("✗ Failed to play example.xm (file may not exist)\n");
    }
    
    // Example 2: Volume control
    printf("\n=== Example 2: Volume Control ===\n");
    SetModuleMusicVolume(&audioManager, 0.5f);
    printf("✓ Set module music volume to 50%%\n");
    printf("Current module volume: %.2f\n", GetModuleMusicVolume(&audioManager));
    
    // Example 3: Check playback status
    printf("\n=== Example 3: Playback Status ===\n");
    printf("Is module music playing: %s\n", IsModuleMusicPlaying(&audioManager) ? "Yes" : "No");
    
    // Example 4: Crossfade to another module
    printf("\n=== Example 4: Crossfading ===\n");
    CrossfadeToModuleMusic(&audioManager, "res/audio/music/another.it", 0.7f, true, 2.0f);
    printf("✓ Started crossfade to another.it over 2 seconds\n");
    
    // Example 5: Fade out
    printf("\n=== Example 5: Fade Out ===\n");
    FadeOutModuleMusic(&audioManager, 1.5f);
    printf("✓ Started fade out over 1.5 seconds\n");
    
    // Example 6: Stop module music
    printf("\n=== Example 6: Stop Module Music ===\n");
    StopModuleMusic(&audioManager);
    printf("✓ Stopped module music\n");
    
    // Example 7: Disable/Enable module player
    printf("\n=== Example 7: Enable/Disable Module Player ===\n");
    SetModulePlayerEnabled(&audioManager, false);
    printf("✓ Disabled module player\n");
    printf("Module Player Enabled: %s\n", IsModulePlayerEnabled(&audioManager) ? "Yes" : "No");
    
    SetModulePlayerEnabled(&audioManager, true);
    printf("✓ Re-enabled module player\n");
    
    // Cleanup
    UnloadAllAudio(&audioManager);
    printf("\n✓ Demo completed and audio cleaned up\n");
}

// Integration example: Using modules in a game loop
void GameLoopModuleExample(void) {
    InitWindow(800, 600, "Presto Framework - Module Player Example");
    InitAudioDevice();
    
    AudioManager audioManager;
    InitAudioManager(&audioManager);
    
    // Game state variables
    bool showInstructions = true;
    int currentSong = 0;
    const char* songs[] = {
        "res/audio/music/level1.xm",
        "res/audio/music/level2.it", 
        "res/audio/music/menu.s3m"
    };
    const int songCount = sizeof(songs) / sizeof(songs[0]);
    
    SetTargetFPS(60);
    
    while (!WindowShouldClose()) {
        // Update audio manager (important!)
        UpdateAudioManager(&audioManager);
        
        // Input handling
        if (IsKeyPressed(KEY_SPACE)) {
            showInstructions = !showInstructions;
        }
        
        if (IsKeyPressed(KEY_ONE)) {
            currentSong = 0;
            PlayModuleMusic(&audioManager, songs[currentSong], 0.8f, true);
        }
        if (IsKeyPressed(KEY_TWO)) {
            currentSong = 1;
            CrossfadeToModuleMusic(&audioManager, songs[currentSong], 0.8f, true, 1.0f);
        }
        if (IsKeyPressed(KEY_THREE)) {
            currentSong = 2;
            CrossfadeToModuleMusic(&audioManager, songs[currentSong], 0.8f, true, 1.0f);
        }
        
        if (IsKeyPressed(KEY_S)) {
            StopModuleMusic(&audioManager);
        }
        
        if (IsKeyPressed(KEY_UP)) {
            float vol = GetModuleMusicVolume(&audioManager);
            SetModuleMusicVolume(&audioManager, fminf(vol + 0.1f, 1.0f));
        }
        if (IsKeyPressed(KEY_DOWN)) {
            float vol = GetModuleMusicVolume(&audioManager);
            SetModuleMusicVolume(&audioManager, fmaxf(vol - 0.1f, 0.0f));
        }
        
        // Rendering
        BeginDrawing();
        ClearBackground(DARKBLUE);
        
        DrawText("PRESTO FRAMEWORK - MODULE PLAYER", 10, 10, 20, WHITE);
        DrawText("Supports XM, IT, S3M, MOD and other tracker formats", 10, 40, 16, GRAY);
        
        if (showInstructions) {
            DrawText("CONTROLS:", 10, 80, 16, YELLOW);
            DrawText("1/2/3 - Play different module songs", 10, 100, 14, WHITE);
            DrawText("S - Stop music", 10, 120, 14, WHITE);
            DrawText("UP/DOWN - Volume control", 10, 140, 14, WHITE);
            DrawText("SPACE - Toggle this help", 10, 160, 14, WHITE);
            DrawText("ESC - Exit", 10, 180, 14, WHITE);
        }
        
        // Status display
        char statusText[256];
        snprintf(statusText, sizeof(statusText), "Playing: %s | Volume: %.1f", 
                IsModuleMusicPlaying(&audioManager) ? "Yes" : "No",
                GetModuleMusicVolume(&audioManager));
        DrawText(statusText, 10, GetScreenHeight() - 40, 14, LIME);
        
        DrawText(GetModulePlayerInfo(&audioManager), 10, GetScreenHeight() - 20, 12, GRAY);
        
        EndDrawing();
    }
    
    UnloadAllAudio(&audioManager);
    CloseAudioDevice();
    CloseWindow();
}

// Utility function to check what module files are available
void ScanForModuleFiles(const char* directory) {
    printf("=== Scanning for Module Files in %s ===\n", directory);
    
    // This is a simplified example - in a real implementation you'd use
    // directory scanning functions appropriate for your platform
    const char* commonExtensions[] = {
        ".xm", ".it", ".s3m", ".mod", ".mtm", ".669", 
        ".ult", ".dsm", ".far", ".gdm", ".med", ".okt", ".stm"
    };
    
    printf("Supported module formats:\n");
    for (int i = 0; i < 13; i++) {
        printf("  %s\n", commonExtensions[i]);
    }
    
    printf("\nTo use module files:\n");
    printf("1. Place your module files in %s\n", directory);
    printf("2. Use PlayModuleMusic() to play them\n");
    printf("3. Use CrossfadeToModuleMusic() for smooth transitions\n");
    printf("4. Remember to call UpdateAudioManager() in your game loop!\n");
}