// Audio Manager 
#include "managers-audio.h"

void InitAudioManager(AudioManager* manager) {
    if (manager == NULL) return;

    manager->sound_count = 0;
    manager->music_count = 0;
    manager->vox_count = 0;
    manager->ambience_count = 0;

    manager->masterVolume = 1.0f;
    manager->musicVolume = 1.0f;
    manager->sfxVolume = 1.0f;
    manager->voxVolume = 1.0f;
    manager->ambienceVolume = 1.0f;

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
    manager->pendingMusicVolume = 1.0f;
    manager->pendingMusicLoop = false;
    manager->pendingMusicDelay = 0.0f;
    manager->pendingMusicDelayTimer = 0.0f;
    manager->isPendingMusicDelayed = false;
}

void UpdateAudioManager(AudioManager* manager, float deltaTime) {
    if (manager == NULL) return;

    // Update music fading
    if (manager->isFadingOut) {
        manager->fadeOutTimer += deltaTime;
        float fadeProgress = manager->fadeOutTimer / manager->fadeOutDuration;
        if (fadeProgress >= 1.0f) {
            // Fade out complete
            StopMusic(manager);
            manager->isFadingOut = false;
            manager->fadeOutTimer = 0.0f;

            // If there's pending music, play it now
            if (manager->pendingMusicPath[0] != '\0') {
                // Load and play pending music
                PlayMusic(manager, manager->pendingMusicPath, manager->pendingMusicVolume, manager->pendingMusicLoop, manager->pendingMusicDelay);
                manager->pendingMusicPath[0] = '\0';
                manager->pendingMusicVolume = 1.0f;
                manager->pendingMusicLoop = false;
                manager->pendingMusicDelay = 0.0f;
                manager->pendingMusicDelayTimer = 0.0f;
                manager->isPendingMusicDelayed = false;
            }
        }
    }

    // Update pending music delay
    if (manager->isPendingMusicDelayed) {
        manager->pendingMusicDelayTimer += deltaTime;
        if (manager->pendingMusicDelayTimer >= manager->pendingMusicDelay) {
            // Load and play pending music
            PlayMusic(manager, manager->pendingMusicPath, manager->pendingMusicVolume, manager->pendingMusicLoop, 0.0f);
            manager->pendingMusicPath[0] = '\0';
            manager->isPendingMusicDelayed = false; 
        }
    }
}

bool PlaySFX(AudioManager* manager, const char* path, float volume) {
    if (manager == NULL || !manager->isSfxEnabled) return false;

    Sound sound = LoadSound(path);
    PrestoSetSFXVolume(manager, volume * manager->sfxVolume * manager->masterVolume);
    PlaySound(sound);

    return true;
}

bool PlayMusic(AudioManager* manager, const char* path, float volume, bool loop, float delay) {
    if (manager == NULL || !manager->isMusicEnabled) return false;

    // If music is currently playing, stop it first
    if (manager->isMusicPlaying) {
        StopMusic(manager);
    }

    if (delay > 0.0f) {
        // Set pending music to play after delay
        strncpy(manager->pendingMusicPath, path, sizeof(manager->pendingMusicPath) - 1);
        manager->pendingMusicPath[sizeof(manager->pendingMusicPath) - 1] = '\0';
        manager->pendingMusicVolume = volume;
        manager->pendingMusicLoop = loop;
        manager->pendingMusicDelay = delay;
        manager->pendingMusicDelayTimer = 0.0f;
        manager->isPendingMusicDelayed = true;
    } else {
        // Load and play music immediately
        Music music = LoadMusicStream(path);
        PrestoSetMusicVolume(manager, volume * manager->musicVolume * manager->masterVolume);
        PlayMusicStream(music);
        manager->isMusicPlaying = true;
    }
    return true;
}

void StopMusic(AudioManager* manager) {
    if (manager == NULL || !manager->isMusicPlaying) return;

    Music music = LoadMusicStream(manager->pendingMusicPath);
    StopMusicStream(music);
    manager->isMusicPlaying = false;
}

void PrestoSetMasterVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;

    manager->masterVolume = volume;

    // Update volumes of all audio types
    PrestoSetMusicVolume(manager, manager->musicVolume * volume);
    // Note: Sound, Vox, and Ambience volumes are set during playback
}

void PrestoSetMusicVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;

    manager->musicVolume = volume;

    // If music is playing, update its volume
    if (manager->isMusicPlaying) {
        Music music = LoadMusicStream(manager->pendingMusicPath);
        PrestoSetMusicVolume(manager, volume * manager->masterVolume);
    }
}

void PrestoSetSFXVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;

    manager->sfxVolume = volume;
}

void PrestoSetVoxVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;

    manager->voxVolume = volume;
}

void PrestoSetAmbienceVolume(AudioManager* manager, float volume) {
    if (manager == NULL) return;

    manager->ambienceVolume = volume;
}

float PrestoGetMasterVolume(AudioManager* manager) {
    return manager ? manager->masterVolume : 0.0f;
}

float PrestoGetMusicVolume(AudioManager* manager) {
    return manager ? manager->musicVolume : 0.0f;
}

float PrestoGetSFXVolume(AudioManager* manager) {
    return manager ? manager->sfxVolume : 0.0f;
}

float PrestoGetVoxVolume(AudioManager* manager) {
    return manager ? manager->voxVolume : 0.0f;
}

float PrestoGetAmbienceVolume(AudioManager* manager) {
    return manager ? manager->ambienceVolume : 0.0f;
}

bool IsMusicPlaying(AudioManager* manager) {
    if (manager == NULL) return false;
    return manager->isMusicPlaying;
}

Music GetCurrentMusic(AudioManager* manager) {
    if (manager == NULL || !manager->isMusicPlaying) {
        return (Music){ 0 };
    }
    return LoadMusicStream(manager->pendingMusicPath);
}

void FadeOutMusic(AudioManager* manager, float duration) {
    if (manager == NULL || !manager->isMusicPlaying) return;

    manager->isFadingOut = true;
    manager->fadeOutDuration = duration;
    manager->fadeOutTimer = 0.0f;
    manager->originalVolume = manager->musicVolume;
}

void UnloadAllAudio(AudioManager* manager) {
    if (manager == NULL) return;

    // Stop music first
    if (manager->isMusicPlaying) {
        StopMusic(manager);
    }

    // Unload sounds
    for (size_t i = 0; i < manager->sound_count; i++) {
        UnloadSound(manager->sounds[i].sound);
        manager->sounds[i].loaded = false;
    }
}