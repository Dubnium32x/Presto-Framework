// Screen Manager for Jacky and Wacky
// Manages different game screens and transitions
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"

#include "screen_manager.h"
#include "screen_state.h"


void InitScreenManager(ScreenManager *manager) {
    if (manager == NULL) return;

    memset(manager->screens, 0, sizeof(manager->screens));
    manager->currentScreen = SCREEN_INIT;
    manager->initialized = true;
}

void RegisterScreen(ScreenManager *manager, ScreenType type, 
                   void (*Init)(void), 
                   void (*Update)(float), 
                   void (*Draw)(void), 
                   void (*Unload)(void)) {
    if (manager == NULL || type < 0 || type >= MAX_SCREENS) return;

    manager->screens[type].Init = Init;
    manager->screens[type].Update = Update;
    manager->screens[type].Draw = Draw;
    manager->screens[type].Unload = Unload;
}

void SetCurrentScreen(ScreenManager *manager, ScreenType type) {
    if (manager == NULL || type < 0 || type >= MAX_SCREENS) return;

    // Unload current screen if it has an Unload function
    if (manager->screens[manager->currentScreen].Unload != NULL) {
        manager->screens[manager->currentScreen].Unload();
    }

    manager->currentScreen = type;

    // Initialize new screen if it has an Init function
    if (manager->screens[type].Init != NULL) {
        manager->screens[type].Init();
    }
}

void UpdateScreenManager(ScreenManager *manager, float deltaTime) {
    if (manager == NULL) return;

    // Call the Update function of the current screen
    if (manager->screens[manager->currentScreen].Update != NULL) {
        manager->screens[manager->currentScreen].Update(deltaTime);
    }
}

void DrawScreenManager(ScreenManager *manager) {
    if (manager == NULL) return;

    // Call the Draw function of the current screen
    if (manager->screens[manager->currentScreen].Draw != NULL) {
        manager->screens[manager->currentScreen].Draw();
    }
}

void UnloadScreenManager(ScreenManager *manager) {
    if (manager == NULL) return;

    // Unload all registered screens
    for (int i = 0; i < MAX_SCREENS; i++) {
        if (manager->screens[i].Unload != NULL) {
            manager->screens[i].Unload();
        }
    }

    manager->initialized = false;
}

void SetCurrentScreenGlobal(ScreenType type) {
    // Use external global screen manager pointer
    extern ScreenManager *g_screenManager;
    if (g_screenManager != NULL) {
        SetCurrentScreen(g_screenManager, type);
    }
}