// Screen manager header
#ifndef MANAGERS_SCREEN_MANAGER_H
#define MANAGERS_SCREEN_MANAGER_H

#include "managers-screen_state.h"

#include "raylib.h"

#define MAX_SCREENS 32

typedef struct {
    void (*Init)(void);
    void (*Update)(float deltaTime);
    void (*Draw)(void);
    void (*Unload)(void);
} IScreen;

typedef struct {
    IScreen screens[MAX_SCREENS];
    ScreenState currentScreen;
    bool initialized;
} ScreenManager;

// Note: ScreenManager g_ScreenManager is defined in util-global.h

extern bool screenManagerInitialized;

void InitScreenManager(ScreenManager *manager);
void RegisterScreen(ScreenManager *manager, ScreenState type, 
                   void (*Init)(void), 
                   void (*Update)(float), 
                   void (*Draw)(void), 
                   void (*Unload)(void));
void SetCurrentScreen(ScreenManager *manager, ScreenState type);
void UpdateScreenManager(ScreenManager *manager, float deltaTime);
void DrawScreenManager(ScreenManager *manager);
void UnloadScreenManager(ScreenManager *manager);
IScreen* GetActiveScreen(ScreenManager *manager);

// Global helper to switch screens from anywhere after InitScreenManager
void SetCurrentScreenGlobal(ScreenState type);

#endif // MANAGERS_SCREEN_MANAGER_H