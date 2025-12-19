// Screen Manager implementation

#include "managers-screen.h"
#include <string.h>

void InitScreenManager(ScreenManager *mgr) {
    if (mgr == NULL) return;

    memset(mgr->screens, 0, sizeof(mgr->screens));
    mgr->currentScreen = SCREEN_STATE_INIT;
    mgr->initialized = true;
}

void RegisterScreen(ScreenManager *mgr, ScreenState type, 
                   void (*Init)(void), 
                   void (*Update)(float), 
                   void (*Draw)(void), 
                   void (*Unload)(void)) {
    if (mgr == NULL || type < 0 || type >= MAX_SCREENS) {
        printf("RegisterScreen: Invalid parameters (mgr=%p, type=%d)\n", (void*)mgr, type);
        return;
    }

    mgr->screens[type].Init = Init;
    mgr->screens[type].Update = Update;
    mgr->screens[type].Draw = Draw;
    mgr->screens[type].Unload = Unload;
}

void SetCurrentScreen(ScreenManager *mgr, ScreenState type) {
    if (mgr == NULL || type < 0 || type >= MAX_SCREENS) {
        printf("SetCurrentScreen: Invalid parameters (mgr=%p, type=%d)\n", (void*)mgr, type);
        return;
    }

    // Unload current screen if it has an Unload function
    if (mgr->screens[mgr->currentScreen].Unload != NULL) {
        mgr->screens[mgr->currentScreen].Unload();
    }

    mgr->currentScreen = type;

    // Initialize new screen if it has an Init function
    if (mgr->screens[type].Init != NULL) {
        mgr->screens[type].Init();
    }
}

void UpdateScreenManager(ScreenManager *mgr, float deltaTime) {
    if (mgr == NULL) return;

    // Call the Update function of the current screen
    if (mgr->screens[mgr->currentScreen].Update != NULL) {
        mgr->screens[mgr->currentScreen].Update(deltaTime);
    }
}

void DrawScreenManager(ScreenManager *mgr) {
    if (mgr == NULL) return;

    // Call the Draw function of the current screen
    if (mgr->screens[mgr->currentScreen].Draw != NULL) {
        mgr->screens[mgr->currentScreen].Draw();
    }
}

void UnloadScreenManager(ScreenManager *mgr) {
    if (mgr == NULL) return;

    // Unload all registered screens
    for (int i = 0; i < MAX_SCREENS; i++) {
        if (mgr->screens[i].Unload != NULL) {
            mgr->screens[i].Unload();
        }
    }

    mgr->initialized = false;
}

IScreen* GetActiveScreen(ScreenManager *manager) {
    if (manager == NULL) return NULL;
    return &manager->screens[manager->currentScreen];
}

// Global helper to switch screens from anywhere after InitScreenManager
void SetCurrentScreenGlobal(ScreenState type) {
    if (gScreenManager != NULL) {
        SetCurrentScreen(gScreenManager, type);
    }
}