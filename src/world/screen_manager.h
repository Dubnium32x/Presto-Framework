// Screen Manager Header for Jacky and Wacky
#ifndef SCREEN_MANAGER_H
#define SCREEN_MANAGER_H

#include <stdio.h>
#include <stdbool.h>
#include "screen_state.h"  // Include for ScreenType enum

#define MAX_SCREENS 32

typedef struct {
    void (*Init)(void);
    void (*Update)(float deltaTime);
    void (*Draw)(void);
    void (*Unload)(void);
} IScreen;

typedef struct {
    IScreen screens[MAX_SCREENS];
    ScreenType currentScreen;
    bool initialized;
} ScreenManager;

extern bool screenManagerInitialized;
extern ScreenManager* g_screenManager;

void InitScreenManager(ScreenManager *manager);
void RegisterScreen(ScreenManager *manager, ScreenType type, 
                   void (*Init)(void), 
                   void (*Update)(float), 
                   void (*Draw)(void), 
                   void (*Unload)(void));
void SetCurrentScreen(ScreenManager *manager, ScreenType type);
void UpdateScreenManager(ScreenManager *manager, float deltaTime);
void DrawScreenManager(ScreenManager *manager);
void UnloadScreenManager(ScreenManager *manager);

// Global helper to switch screens from anywhere after InitScreenManager
void SetCurrentScreenGlobal(ScreenType type);

#endif // SCREEN_MANAGER_H