module app;

import raylib;

import std.stdio;
import std.file;
import std.process;
import std.path;
import std.string;
import std.algorithm;

import data;
import world.screen_manager;
import world.screen_states;
import world.audio_manager;
import world.screen_settings;

// Define the world settings
public const int SCREEN_WIDTH = 400;
public const int SCREEN_HEIGHT = 224;
public int VIRTUAL_SCREEN_WIDTH = 800;
public int VIRTUAL_SCREEN_HEIGHT = 448;

// Function to get mouse position in virtual screen coordinates
Vector2 GetMousePositionVirtual() {
    Vector2 mouseScreenPos = GetMousePosition();
    
    float scale = min(cast(float)GetScreenWidth() / VIRTUAL_SCREEN_WIDTH, 
                      cast(float)GetScreenHeight() / VIRTUAL_SCREEN_HEIGHT);
                      
    // Calculate the top-left position of the scaled virtual screen on the actual screen
    float destX = (GetScreenWidth() - (VIRTUAL_SCREEN_WIDTH * scale)) / 2.0f;
    float destY = (GetScreenHeight() - (VIRTUAL_SCREEN_HEIGHT * scale)) / 2.0f;

    // Convert screen mouse position to virtual screen mouse position
    float virtualMouseX = (mouseScreenPos.x - destX) / scale;
    float virtualMouseY = (mouseScreenPos.y - destY) / scale;

    // Clamp to virtual screen bounds if necessary, though often not strictly needed
    // virtualMouseX = clamp(virtualMouseX, 0, VIRTUAL_SCREEN_WIDTH);
    // virtualMouseY = clamp(virtualMouseY, 0, VIRTUAL_SCREEN_HEIGHT);

    return Vector2(virtualMouseX, virtualMouseY);
}

// ---- MAIN FUNCTION ----
void main() {
    InitAudioDevice();
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Presto Framework Pre-Alpha v 0.1.0");
    SetTargetFPS(60);

    SetExitKey(KeyboardKey.KEY_ESCAPE);

    virtualScreen = LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT);
    SetTextureFilter(virtualScreen.texture, TextureFilter.TEXTURE_FILTER_NEAREST);

    auto memManager = MemoryManager();
    auto inputManager = InputManager();
    auto audioManager = AudioManager();
    auto screenManager = ScreenManager();
    auto screenSettings = ScreenSettings();
}

