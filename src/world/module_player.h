// Module Player header - Handles XM, IT, S3M, and other tracker formats via libmikmod
#ifndef MODULE_PLAYER_H
#define MODULE_PLAYER_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

// Forward declaration to avoid including mikmod.h in header
typedef struct MODULE MODULE;

#define MAX_MODULES 10
#define MAX_MODULE_PATH 256

typedef struct {
    char filepath[MAX_MODULE_PATH];
    MODULE* module;
    bool is_playing;
    bool is_looping;
    float volume;
    bool is_loaded;
} ModuleTrack;

typedef struct {
    ModuleTrack tracks[MAX_MODULES];
    size_t track_count;
    bool is_initialized;
    float master_volume;
    bool is_enabled;
    int current_track;
    
    // Fading support
    bool is_fading_out;
    bool is_fading_in;
    float fade_duration;
    float fade_timer;
    float fade_start_volume;
    float fade_target_volume;
    
    // Pending track for crossfade
    int pending_track;
    bool has_pending_track;
} ModulePlayer;

// Core functions
bool InitModulePlayer(ModulePlayer* player);
void UpdateModulePlayer(ModulePlayer* player);
void CleanupModulePlayer(ModulePlayer* player);

// Module loading and playback
int ModuleLoad(ModulePlayer* player, const char* filepath);
bool PlayModule(ModulePlayer* player, int track_id, bool loop);
bool PlayModuleByPath(ModulePlayer* player, const char* filepath, bool loop);
void StopModule(ModulePlayer* player, int track_id);
void StopCurrentModule(ModulePlayer* player);
void StopAllModules(ModulePlayer* player);
void PauseModule(ModulePlayer* player, int track_id);
void ResumeModule(ModulePlayer* player, int track_id);
bool UnloadModule(ModulePlayer* player, int track_id);

// Volume and settings
void SetModuleVolume(ModulePlayer* player, int track_id, float volume);
void SetModuleMasterVolume(ModulePlayer* player, float volume);
float GetModuleVolume(ModulePlayer* player, int track_id);
float GetModuleMasterVolume(ModulePlayer* player);

// Fading effects
void FadeOutModule(ModulePlayer* player, int track_id, float duration);
void FadeInModule(ModulePlayer* player, int track_id, float duration);
void CrossfadeToModule(ModulePlayer* player, int from_track, int to_track, float duration);
void CrossfadeToModuleByPath(ModulePlayer* player, const char* filepath, bool loop, float duration);

// Status queries
bool IsModulePlaying(ModulePlayer* player, int track_id);
bool IsModuleLoaded(ModulePlayer* player, int track_id);
bool IsAnyModulePlaying(ModulePlayer* player);
int GetCurrentModuleTrack(ModulePlayer* player);
const char* GetModulePath(ModulePlayer* player, int track_id);

// Utility functions
bool IsModuleFileSupported(const char* filepath);
const char* GetModulePlayerVersion(void);
void SetModulePlayerEnabledState(ModulePlayer* player, bool enabled);
bool IsModulePlayerEnabledState(ModulePlayer* player);

#endif // MODULE_PLAYER_H