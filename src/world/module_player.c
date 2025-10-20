// Module Player implementation - Handles XM, IT, S3M, and other tracker formats via libmikmod
#include "module_player.h"
#include <mikmod.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

// Internal helper functions
static bool InitMikModLibrary(void);
static void CleanupMikModLibrary(void);
static bool IsValidTrackId(ModulePlayer* player, int track_id);
static int FindFreeTrackSlot(ModulePlayer* player);
static void UpdateFading(ModulePlayer* player);

bool InitModulePlayer(ModulePlayer* player) {
    if (player == NULL) return false;
    
    // Initialize the player structure
    player->track_count = 0;
    player->is_initialized = false;
    player->master_volume = 1.0f;
    player->is_enabled = true;
    player->current_track = -1;
    player->is_fading_out = false;
    player->is_fading_in = false;
    player->fade_duration = 0.0f;
    player->fade_timer = 0.0f;
    player->fade_start_volume = 0.0f;
    player->fade_target_volume = 0.0f;
    player->pending_track = -1;
    player->has_pending_track = false;
    
    // Initialize all tracks
    for (int i = 0; i < MAX_MODULES; i++) {
        player->tracks[i].filepath[0] = '\0';
        player->tracks[i].module = NULL;
        player->tracks[i].is_playing = false;
        player->tracks[i].is_looping = false;
        player->tracks[i].volume = 1.0f;
        player->tracks[i].is_loaded = false;
    }
    
    // Initialize MikMod library
    if (!InitMikModLibrary()) {
        printf("Error: Failed to initialize MikMod library\n");
        return false;
    }
    
    player->is_initialized = true;
    printf("Module Player initialized successfully\n");
    return true;
}

void UpdateModulePlayer(ModulePlayer* player) {
    if (player == NULL || !player->is_initialized || !player->is_enabled) return;
    
    // Update MikMod
    MikMod_Update();
    
    // Update fading effects
    UpdateFading(player);
    
    // Check if current module has finished and handle looping
    if (player->current_track >= 0 && IsValidTrackId(player, player->current_track)) {
        ModuleTrack* track = &player->tracks[player->current_track];
        if (track->is_playing && track->module) {
            if (!Player_Active()) {
                // Module finished playing
                if (track->is_looping) {
                    // Restart the module
                    Player_Start(track->module);
                } else {
                    // Module finished, mark as stopped
                    track->is_playing = false;
                    player->current_track = -1;
                }
            }
        }
    }
}

void CleanupModulePlayer(ModulePlayer* player) {
    if (player == NULL || !player->is_initialized) return;
    
    // Stop all playing modules and unload them
    StopAllModules(player);
    for (int i = 0; i < MAX_MODULES; i++) {
        UnloadModule(player, i);
    }
    
    // Stop MikMod player
    Player_Stop();
    
    // Cleanup MikMod library
    CleanupMikModLibrary();
    
    player->is_initialized = false;
    printf("Module Player cleaned up\n");
}

int ModuleLoad(ModulePlayer* player, const char* filepath) {
    if (player == NULL || !player->is_initialized || filepath == NULL) return -1;
    
    // Check if module is already loaded
    for (int i = 0; i < MAX_MODULES; i++) {
        if (player->tracks[i].is_loaded && strcmp(player->tracks[i].filepath, filepath) == 0) {
            return i; // Already loaded, return existing track ID
        }
    }
    
    // Find free slot
    int track_id = FindFreeTrackSlot(player);
    if (track_id < 0) {
        printf("Error: No free module slots available\n");
        return -1;
    }
    
    // Load the module
    MODULE* module = Player_Load(filepath, 64, 0);
    if (module == NULL) {
        printf("Error: Failed to load module from %s\n", filepath);
        return -1;
    }
    
    // Store in track slot
    ModuleTrack* track = &player->tracks[track_id];
    strncpy(track->filepath, filepath, MAX_MODULE_PATH - 1);
    track->filepath[MAX_MODULE_PATH - 1] = '\0';
    track->module = module;
    track->is_loaded = true;
    track->is_playing = false;
    track->is_looping = false;
    track->volume = 1.0f;
    
    if (track_id >= (int)player->track_count) {
        player->track_count = track_id + 1;
    }
    
    printf("Module loaded: %s (track ID: %d)\n", filepath, track_id);
    return track_id;
}

bool PlayModule(ModulePlayer* player, int track_id, bool loop) {
    if (player == NULL || !player->is_initialized || !player->is_enabled) return false;
    if (!IsValidTrackId(player, track_id)) return false;
    
    ModuleTrack* track = &player->tracks[track_id];
    if (!track->is_loaded || track->module == NULL) {
        printf("Error: Module not loaded for track ID %d\n", track_id);
        return false;
    }
    
    // Stop current playing module if any
    if (player->current_track >= 0 && player->current_track != track_id) {
        StopCurrentModule(player);
    }
    
    // Set volume based on track and master volume
    Player_SetVolume((int)(track->volume * player->master_volume * 128));
    
    // Start playing
    Player_Start(track->module);
    track->is_playing = true;
    track->is_looping = loop;
    player->current_track = track_id;
    
    printf("Playing module: %s (loop: %s)\n", track->filepath, loop ? "yes" : "no");
    return true;
}

bool PlayModuleByPath(ModulePlayer* player, const char* filepath, bool loop) {
    if (player == NULL || filepath == NULL) return false;
    
    // Try to find if already loaded
    for (int i = 0; i < MAX_MODULES; i++) {
        if (player->tracks[i].is_loaded && strcmp(player->tracks[i].filepath, filepath) == 0) {
            return PlayModule(player, i, loop);
        }
    }
    
    // Load and play
    int track_id = ModuleLoad(player, filepath);
    if (track_id < 0) return false;
    
    return PlayModule(player, track_id, loop);
}

void StopModule(ModulePlayer* player, int track_id) {
    if (player == NULL || !IsValidTrackId(player, track_id)) return;
    
    ModuleTrack* track = &player->tracks[track_id];
    if (track->is_playing) {
        if (player->current_track == track_id) {
            Player_Stop();
            player->current_track = -1;
        }
        track->is_playing = false;
        printf("Stopped module: %s\n", track->filepath);
    }
}

void StopCurrentModule(ModulePlayer* player) {
    if (player == NULL || player->current_track < 0) return;
    StopModule(player, player->current_track);
}

void StopAllModules(ModulePlayer* player) {
    if (player == NULL) return;
    
    Player_Stop();
    for (int i = 0; i < MAX_MODULES; i++) {
        if (player->tracks[i].is_playing) {
            player->tracks[i].is_playing = false;
        }
    }
    player->current_track = -1;
}

void PauseModule(ModulePlayer* player, int track_id) {
    if (player == NULL || !IsValidTrackId(player, track_id)) return;
    if (player->current_track == track_id && player->tracks[track_id].is_playing) {
        Player_TogglePause();
    }
}

void ResumeModule(ModulePlayer* player, int track_id) {
    if (player == NULL || !IsValidTrackId(player, track_id)) return;
    if (player->current_track == track_id && player->tracks[track_id].is_playing) {
        Player_TogglePause();
    }
}

bool UnloadModule(ModulePlayer* player, int track_id) {
    if (player == NULL || !IsValidTrackId(player, track_id)) return false;
    
    ModuleTrack* track = &player->tracks[track_id];
    if (!track->is_loaded) return true; // Already unloaded
    
    // Stop if playing
    if (track->is_playing) {
        StopModule(player, track_id);
    }
    
    // Free the module
    if (track->module) {
        Player_Free(track->module);
        track->module = NULL;
    }
    
    // Clear track info
    track->filepath[0] = '\0';
    track->is_loaded = false;
    track->is_playing = false;
    track->is_looping = false;
    track->volume = 1.0f;
    
    printf("Unloaded module (track ID: %d)\n", track_id);
    return true;
}

void SetModuleVolume(ModulePlayer* player, int track_id, float volume) {
    if (player == NULL || !IsValidTrackId(player, track_id)) return;
    
    // Clamp volume to valid range
    if (volume < 0.0f) volume = 0.0f;
    if (volume > 1.0f) volume = 1.0f;
    
    player->tracks[track_id].volume = volume;
    
    // Update current playing volume if this is the current track
    if (player->current_track == track_id && player->tracks[track_id].is_playing) {
        Player_SetVolume((int)(volume * player->master_volume * 128));
    }
}

void SetModuleMasterVolume(ModulePlayer* player, float volume) {
    if (player == NULL) return;
    
    // Clamp volume to valid range
    if (volume < 0.0f) volume = 0.0f;
    if (volume > 1.0f) volume = 1.0f;
    
    player->master_volume = volume;
    
    // Update current playing volume
    if (player->current_track >= 0 && IsValidTrackId(player, player->current_track)) {
        ModuleTrack* track = &player->tracks[player->current_track];
        if (track->is_playing) {
            Player_SetVolume((int)(track->volume * volume * 128));
        }
    }
}

float GetModuleVolume(ModulePlayer* player, int track_id) {
    if (player == NULL || !IsValidTrackId(player, track_id)) return 0.0f;
    return player->tracks[track_id].volume;
}

float GetModuleMasterVolume(ModulePlayer* player) {
    return player ? player->master_volume : 0.0f;
}

void FadeOutModule(ModulePlayer* player, int track_id, float duration) {
    if (player == NULL || !IsValidTrackId(player, track_id) || duration <= 0.0f) return;
    if (player->current_track != track_id || !player->tracks[track_id].is_playing) return;
    
    player->is_fading_out = true;
    player->is_fading_in = false;
    player->fade_duration = duration;
    player->fade_timer = 0.0f;
    player->fade_start_volume = player->tracks[track_id].volume * player->master_volume;
    player->fade_target_volume = 0.0f;
}

void FadeInModule(ModulePlayer* player, int track_id, float duration) {
    if (player == NULL || !IsValidTrackId(player, track_id) || duration <= 0.0f) return;
    if (player->current_track != track_id || !player->tracks[track_id].is_playing) return;
    
    player->is_fading_in = true;
    player->is_fading_out = false;
    player->fade_duration = duration;
    player->fade_timer = 0.0f;
    player->fade_start_volume = 0.0f;
    player->fade_target_volume = player->tracks[track_id].volume * player->master_volume;
    
    // Set initial volume to 0
    Player_SetVolume(0);
}

void CrossfadeToModule(ModulePlayer* player, int from_track, int to_track, float duration) {
    if (player == NULL || duration <= 0.0f) return;
    if (!IsValidTrackId(player, from_track) || !IsValidTrackId(player, to_track)) return;
    
    // Set up crossfade
    player->pending_track = to_track;
    player->has_pending_track = true;
    FadeOutModule(player, from_track, duration * 0.5f);
}

void CrossfadeToModuleByPath(ModulePlayer* player, const char* filepath, bool loop, float duration) {
    if (player == NULL || filepath == NULL || duration <= 0.0f) return;
    
    // Load the target module
    int track_id = ModuleLoad(player, filepath);
    if (track_id < 0) return;
    
    // Set loop flag
    player->tracks[track_id].is_looping = loop;
    
    // Start crossfade
    if (player->current_track >= 0) {
        CrossfadeToModule(player, player->current_track, track_id, duration);
    } else {
        // No current track, just play the new one
        PlayModule(player, track_id, loop);
    }
}

bool IsModulePlaying(ModulePlayer* player, int track_id) {
    if (player == NULL || !IsValidTrackId(player, track_id)) return false;
    return player->tracks[track_id].is_playing && player->current_track == track_id;
}

bool IsModuleLoaded(ModulePlayer* player, int track_id) {
    if (player == NULL || !IsValidTrackId(player, track_id)) return false;
    return player->tracks[track_id].is_loaded;
}

bool IsAnyModulePlaying(ModulePlayer* player) {
    if (player == NULL) return false;
    return player->current_track >= 0 && Player_Active();
}

int GetCurrentModuleTrack(ModulePlayer* player) {
    return player ? player->current_track : -1;
}

const char* GetModulePath(ModulePlayer* player, int track_id) {
    if (player == NULL || !IsValidTrackId(player, track_id)) return NULL;
    return player->tracks[track_id].is_loaded ? player->tracks[track_id].filepath : NULL;
}

bool IsModuleFileSupported(const char* filepath) {
    if (filepath == NULL) return false;
    
    const char* ext = strrchr(filepath, '.');
    if (ext == NULL) return false;
    
    // Convert to lowercase for comparison
    char ext_lower[10];
    strncpy(ext_lower, ext, sizeof(ext_lower) - 1);
    ext_lower[sizeof(ext_lower) - 1] = '\0';
    for (int i = 0; ext_lower[i]; i++) {
        if (ext_lower[i] >= 'A' && ext_lower[i] <= 'Z') {
            ext_lower[i] += 32; // Convert to lowercase
        }
    }
    
    // Check supported formats
    return (strcmp(ext_lower, ".xm") == 0 ||
            strcmp(ext_lower, ".it") == 0 ||
            strcmp(ext_lower, ".s3m") == 0 ||
            strcmp(ext_lower, ".mod") == 0 ||
            strcmp(ext_lower, ".mtm") == 0 ||
            strcmp(ext_lower, ".669") == 0 ||
            strcmp(ext_lower, ".ult") == 0 ||
            strcmp(ext_lower, ".dsm") == 0 ||
            strcmp(ext_lower, ".far") == 0 ||
            strcmp(ext_lower, ".gdm") == 0 ||
            strcmp(ext_lower, ".imf") == 0 ||
            strcmp(ext_lower, ".med") == 0 ||
            strcmp(ext_lower, ".okt") == 0 ||
            strcmp(ext_lower, ".stm") == 0);
}

const char* GetModulePlayerVersion(void) {
    return "Presto Framework Module Player v1.0 (libmikmod)";
}

void SetModulePlayerEnabledState(ModulePlayer* player, bool enabled) {
    if (player == NULL) return;
    player->is_enabled = enabled;
    if (!enabled) {
        StopAllModules(player);
    }
}

bool IsModulePlayerEnabledState(ModulePlayer* player) {
    return player ? player->is_enabled : false;
}

// Internal helper functions

static bool InitMikModLibrary(void) {
    // Register all drivers
    MikMod_RegisterAllDrivers();
    
    // Register all loaders
    MikMod_RegisterAllLoaders();
    
    // Initialize MikMod
    if (MikMod_Init("")) {
        printf("Error: Could not initialize MikMod: %s\n", MikMod_strerror(MikMod_errno));
        return false;
    }
    
    // Set some default settings
    md_mode |= DMODE_SOFT_MUSIC | DMODE_SOFT_SNDFX;
    md_mixfreq = 44100;
    md_mode &= ~DMODE_16BITS;  // Use 16-bit output
    
    return true;
}

static void CleanupMikModLibrary(void) {
    MikMod_Exit();
}

static bool IsValidTrackId(ModulePlayer* player, int track_id) {
    return (player != NULL && track_id >= 0 && track_id < MAX_MODULES);
}

static int FindFreeTrackSlot(ModulePlayer* player) {
    if (player == NULL) return -1;
    
    for (int i = 0; i < MAX_MODULES; i++) {
        if (!player->tracks[i].is_loaded) {
            return i;
        }
    }
    return -1; // No free slots
}

static void UpdateFading(ModulePlayer* player) {
    if (player == NULL || (!player->is_fading_out && !player->is_fading_in)) return;
    
    player->fade_timer += 1.0f / 60.0f; // Assume 60 FPS, you might want to use actual frame time
    
    if (player->fade_timer >= player->fade_duration) {
        // Fade completed
        if (player->is_fading_out) {
            Player_SetVolume(0);
            if (player->current_track >= 0) {
                StopCurrentModule(player);
            }
            
            // Start pending track if any
            if (player->has_pending_track && IsValidTrackId(player, player->pending_track)) {
                ModuleTrack* pending = &player->tracks[player->pending_track];
                PlayModule(player, player->pending_track, pending->is_looping);
                FadeInModule(player, player->pending_track, player->fade_duration);
                player->has_pending_track = false;
                player->pending_track = -1;
            }
        } else if (player->is_fading_in) {
            // Fade in completed, set to target volume
            if (player->current_track >= 0) {
                Player_SetVolume((int)(player->fade_target_volume * 128));
            }
        }
        
        player->is_fading_out = false;
        player->is_fading_in = false;
    } else {
        // Calculate current fade volume
        float progress = player->fade_timer / player->fade_duration;
        float current_volume;
        
        if (player->is_fading_out) {
            current_volume = player->fade_start_volume * (1.0f - progress);
        } else {
            current_volume = player->fade_start_volume + (player->fade_target_volume - player->fade_start_volume) * progress;
        }
        
        Player_SetVolume((int)(current_volume * 128));
    }
}