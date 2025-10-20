// Audio Manager
#include "audio_manager.h"
#include "module_player.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"

void InitAudioManager(AudioManager* manager) {
    if (manager == NULL) return;
    manager->sound_count = 0;
    manager->music_count = 0;
    manager->masterVolume = 1.0f;
    manager->musicVolume = 1.0f;
    manager->sfxVolume = 1.0f;
    manager->voxVolume = 1.0f;
    manager->ambienceVolume = 0.7f;
    manager->isMusicPlaying = false;
    manager->isMusicEnabled = true;
    manager->isSfxEnabled = true;
    manager->isVoxEnabled = true;
    manager->isAmbienceEnabled = true;
    manager->isFadingOut = false;
    manager->fadeOutDuration = 0.0f;
    manager->fadeOutTimer = 0.0f;
    manager->originalVolume = 1.0f;
    manager->pendingMusicPath[0] = '\0';
    manager->pendingMusicVolume = -1.0f;
    manager->pendingMusicLoop = true;
    manager->pendingMusicDelay = 0.0f;
    manager->pendingMusicDelayTimer = 0.0f;
    manager->isPendingMusicDelayed = false;
    manager->useModulePlayer = false;

    // Initialize module player
    if (InitModulePlayer(&manager->modulePlayer)) {
        printf("Module player initialized successfully\n");
    } else {
        printf("Warning: Failed to initialize module player\n");
    }

    for (int i = 0; i < MAX_SOUNDS; i++) {
        manager->sounds[i].type = SFX; // Default type
        manager->sounds[i].sound = (Sound){ 0 };
        manager->sounds[i].music = (Music){ 0 };
    }
    for (int i = 0; i < MAX_MUSIC_TRACKS; i++) {
        manager->music[i].type = MUSIC; // Default type
        manager->music[i].sound = (Sound){ 0 };
        manager->music[i].music = (Music){ 0 };
    }
}

void UpdateAudioManager(AudioManager* manager) {
    if (manager == NULL) return;

    // Update module player
    UpdateModulePlayer(&manager->modulePlayer);

    // Update fading out music
    if (manager->isFadingOut) {
        manager->fadeOutTimer += GetFrameTime();
        float fadeProgress = manager->fadeOutTimer / manager->fadeOutDuration;
        if (fadeProgress >= 1.0f) {
            fadeProgress = 1.0f;
            manager->isFadingOut = false;
            StopMusicStream(manager->music[0].music); // Assuming only one music track at a time
            manager->isMusicPlaying = false;

            // Start pending music if any
            if (manager->pendingMusicPath[0] != '\0') {
                PrestoPlaySound(manager, manager->pendingMusicPath, MUSIC, manager->pendingMusicVolume);
                manager->pendingMusicPath[0] = '\0'; // Clear pending path
            }
        } else {
            float newVolume = manager->originalVolume * (1.0f - fadeProgress);
            SetMusicVolume(manager->music[0].music, newVolume * manager->musicVolume * manager->masterVolume);
        }
    }

    // Update pending music delay
    if (manager->isPendingMusicDelayed) {
        manager->pendingMusicDelayTimer += GetFrameTime();
        if (manager->pendingMusicDelayTimer >= manager->pendingMusicDelay) {
            PrestoPlaySound(manager, manager->pendingMusicPath, MUSIC, manager->pendingMusicVolume);
            manager->pendingMusicPath[0] = '\0'; // Clear pending path
            manager->isPendingMusicDelayed = false;
        }
    }

    // Update music stream
    if (manager->isMusicPlaying && manager->music_count > 0) {
        UpdateMusicStream(manager->music[0].music);
    }
}

bool PrestoPlaySound(AudioManager* manager, const char* filePath, AudioType type, float volume) {
    if (manager == NULL || filePath == NULL) return false;

    if (type == MUSIC) {
        if (!manager->isMusicEnabled) return false;
        if (manager->music_count >= MAX_MUSIC_TRACKS) {
            printf("Error: Maximum music track limit reached.\n");
            return false;
        }
        Music music = LoadMusicStream(filePath);
        if (music.ctxData == NULL) {
            printf("Error: Failed to load music from %s\n", filePath);
            return false;
        }
        manager->music[manager->music_count].type = MUSIC;
        manager->music[manager->music_count].music = music;
        manager->music_count++;
        SetMusicVolume(music, volume * manager->musicVolume * manager->masterVolume);
        PlayMusicStream(music);
        manager->isMusicPlaying = true;
        return true;
    } else {
        if (!manager->isSfxEnabled && type == SFX) return false;
        if (!manager->isVoxEnabled && type == VOX) return false;
        if (!manager->isAmbienceEnabled && type == AMBIENCE) return false;
        if (manager->sound_count >= MAX_SOUNDS) {
            printf("Error: Maximum sound effect limit reached.\n");
            return false;
        }
        Sound sound = LoadSound(filePath);
        if (sound.frameCount == 0) {
            printf("Error: Failed to load sound from %s\n", filePath);
            return false;
        }
        manager->sounds[manager->sound_count].type = type;
        manager->sounds[manager->sound_count].sound = sound;
        manager->sound_count++;
        float finalVolume = volume * manager->sfxVolume * manager->voxVolume * manager->ambienceVolume * manager->masterVolume;
        SetSoundVolume(sound, finalVolume);
        PlaySound(sound); // This is raylib's PlaySound
        return true;
    }
}

bool PrestoPlayMusic(AudioManager* manager, const char* filePath, float volume, bool loop, float fadeInDuration) {
    if (manager == NULL || filePath == NULL) return false;
    if (!manager->isMusicEnabled) return false;

    if (manager->isMusicPlaying) {
        // If music is already playing, set pending music
        strncpy(manager->pendingMusicPath, filePath, sizeof(manager->pendingMusicPath) - 1);
        manager->pendingMusicVolume = volume;
        manager->pendingMusicLoop = loop;
        manager->isPendingMusicDelayed = false;
        if (fadeInDuration > 0.0f) {
            manager->isFadingOut = true;
            manager->fadeOutDuration = fadeInDuration;
            manager->fadeOutTimer = 0.0f;
            manager->originalVolume = 1.0f; // Default volume, raylib's GetMusicVolume doesn't exist
        } else {
            StopMusicStream(manager->music[0].music);
            manager->isMusicPlaying = false;
            PrestoPlaySound(manager, filePath, MUSIC, volume);
        }
        return true;
    } else {
        return PrestoPlaySound(manager, filePath, MUSIC, volume);
    }
}

bool PlayVOX(AudioManager* manager, const char* filePath, float volume) {
    return PrestoPlaySound(manager, filePath, VOX, volume);
}

bool PlayAmbience(AudioManager* manager, const char* filePath, float volume, bool loop) {
    (void)loop; // Suppress unused parameter warning
    return PrestoPlaySound(manager, filePath, AMBIENCE, volume);
}

void FadeOutMusic(AudioManager* manager, float duration) {
    if (manager == NULL || !manager->isMusicPlaying) return;
    manager->isFadingOut = true;
    manager->fadeOutDuration = duration;
    manager->fadeOutTimer = 0.0f;
    manager->originalVolume = 1.0f; // Default volume, raylib's GetMusicVolume doesn't exist
}

void PrestoSetMasterVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;
    manager->masterVolume = volume;
    if (manager->isMusicPlaying && manager->music_count > 0) {
        SetMusicVolume(manager->music[0].music, manager->musicVolume * manager->masterVolume);
    }
}

void PrestoSetMusicVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;
    manager->musicVolume = volume;
    if (manager->isMusicPlaying && manager->music_count > 0) {
        SetMusicVolume(manager->music[0].music, volume * manager->masterVolume);
    }
}

void SetSFXVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;
    manager->sfxVolume = volume;
    for (size_t i = 0; i < manager->sound_count; i++) {
        if (manager->sounds[i].type == SFX) {
            SetSoundVolume(manager->sounds[i].sound, volume * manager->masterVolume);
        }
    }
}

void SetVOXVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;
    manager->voxVolume = volume;
    for (size_t i = 0; i < manager->sound_count; i++) {
        if (manager->sounds[i].type == VOX) {
            SetSoundVolume(manager->sounds[i].sound, volume * manager->masterVolume);
        }
    }
}

void SetAmbienceVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;
    manager->ambienceVolume = volume;
    for (size_t i = 0; i < manager->sound_count; i++) {
        if (manager->sounds[i].type == AMBIENCE) {
            SetSoundVolume(manager->sounds[i].sound, volume * manager->masterVolume);
        }
    }
}

void StopMusic(AudioManager* manager) {
    if (manager == NULL || !manager->isMusicPlaying) return;
    StopMusicStream(manager->music[0].music);
    manager->isMusicPlaying = false;
}

void StopAllSFX(AudioManager* manager) {
    if (manager == NULL) return;
    for (size_t i = 0; i < manager->sound_count; i++) {
        if (manager->sounds[i].type == SFX || manager->sounds[i].type == VOX || manager->sounds[i].type == AMBIENCE) {
            StopSound(manager->sounds[i].sound);
        }
    }
}

// Getter function implementations
float PrestoGetMasterVolume(AudioManager* manager) {
    return manager ? manager->masterVolume : 0.0f;
}

float GetMusicVolume(AudioManager* manager) {
    return manager ? manager->musicVolume : 0.0f;
}

float GetSFXVolume(AudioManager* manager) {
    return manager ? manager->sfxVolume : 0.0f;
}

float GetVOXVolume(AudioManager* manager) {
    return manager ? manager->voxVolume : 0.0f;
}

float GetAmbienceVolume(AudioManager* manager) {
    return manager ? manager->ambienceVolume : 0.0f;
}

bool IsMusicPlayingNow(AudioManager* manager) {
    return manager ? manager->isMusicPlaying : false;
}

bool IsMusicEnabled(AudioManager* manager) {
    return manager ? manager->isMusicEnabled : false;
}

bool IsSFXEnabled(AudioManager* manager) {
    return manager ? manager->isSfxEnabled : false;
}

bool IsVOXEnabled(AudioManager* manager) {
    return manager ? manager->isVoxEnabled : false;
}

bool IsAmbienceEnabled(AudioManager* manager) {
    return manager ? manager->isAmbienceEnabled : false;
}

void UnloadAllAudio(AudioManager* manager) {
    if (manager == NULL) return;
    
    // Stop and unload all regular audio
    StopMusic(manager);
    StopAllSFX(manager);
    
    // Unload sounds
    for (size_t i = 0; i < manager->sound_count; i++) {
        if (manager->sounds[i].sound.frameCount > 0) {
            UnloadSound(manager->sounds[i].sound);
        }
    }
    
    // Unload music
    for (size_t i = 0; i < manager->music_count; i++) {
        if (manager->music[i].music.ctxData != NULL) {
            UnloadMusicStream(manager->music[i].music);
        }
    }
    
    // Cleanup module player
    CleanupModulePlayer(&manager->modulePlayer);
    
    // Reset counters
    manager->sound_count = 0;
    manager->music_count = 0;
}

// Module player integration functions

bool LoadModuleMusic(AudioManager* manager, const char* filePath) {
    if (manager == NULL || filePath == NULL) return false;
    if (!manager->isMusicEnabled) return false;
    
    int track_id = LoadModule(&manager->modulePlayer, filePath);
    return track_id >= 0;
}

bool PlayModuleMusic(AudioManager* manager, const char* filePath, float volume, bool loop) {
    if (manager == NULL || filePath == NULL) return false;
    if (!manager->isMusicEnabled) return false;
    
    // Stop regular music if playing
    if (manager->isMusicPlaying) {
        StopMusic(manager);
    }
    
    // Set module player volume based on music volume settings
    float finalVolume = volume * manager->musicVolume * manager->masterVolume;
    SetModuleMasterVolume(&manager->modulePlayer, finalVolume);
    
    bool success = PlayModuleByPath(&manager->modulePlayer, filePath, loop);
    if (success) {
        manager->useModulePlayer = true;
    }
    return success;
}

void StopModuleMusic(AudioManager* manager) {
    if (manager == NULL) return;
    StopCurrentModule(&manager->modulePlayer);
    manager->useModulePlayer = false;
}

void SetModuleMusicVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;
    float finalVolume = volume * manager->musicVolume * manager->masterVolume;
    SetModuleMasterVolume(&manager->modulePlayer, finalVolume);
}

float GetModuleMusicVolume(AudioManager* manager) {
    if (manager == NULL) return 0.0f;
    return GetModuleMasterVolume(&manager->modulePlayer);
}

bool IsModuleMusicPlaying(AudioManager* manager) {
    if (manager == NULL) return false;
    return IsAnyModulePlaying(&manager->modulePlayer);
}

void FadeOutModuleMusic(AudioManager* manager, float duration) {
    if (manager == NULL) return;
    int currentTrack = GetCurrentModuleTrack(&manager->modulePlayer);
    if (currentTrack >= 0) {
        FadeOutModule(&manager->modulePlayer, currentTrack, duration);
    }
}

void CrossfadeToModuleMusic(AudioManager* manager, const char* filePath, float volume, bool loop, float duration) {
    if (manager == NULL || filePath == NULL) return;
    if (!manager->isMusicEnabled) return;
    
    // Set volume
    float finalVolume = volume * manager->musicVolume * manager->masterVolume;
    SetModuleMasterVolume(&manager->modulePlayer, finalVolume);
    
    // Perform crossfade
    CrossfadeToModuleByPath(&manager->modulePlayer, filePath, loop, duration);
    manager->useModulePlayer = true;
}

bool IsModuleFile(const char* filePath) {
    return IsModuleFileSupported(filePath);
}

const char* GetModulePlayerInfo(AudioManager* manager) {
    (void)manager; // Suppress unused parameter warning
    return GetModulePlayerVersion();
}

void SetModulePlayerEnabled(AudioManager* manager, bool enabled) {
    if (manager == NULL) return;
    SetModulePlayerEnabledState(&manager->modulePlayer, enabled);
    if (!enabled) {
        manager->useModulePlayer = false;
    }
}

bool IsModulePlayerEnabled(AudioManager* manager) {
    if (manager == NULL) return false;
    return IsModulePlayerEnabledState(&manager->modulePlayer);
}