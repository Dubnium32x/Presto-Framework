// Audio Manager header
#ifndef MANAGERS_AUDIO_H
#define MANAGERS_AUDIO_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"

/* NOTE:
    PlayMusicStream and LoadMusicStream CAN INDEED
    load module files without libmikmod! 
    We'll be making use of this advantage in our audio
    manager implementation.
*/

#define MAX_SOUNDS 100
#define MAX_MUSIC_TRACKS 24

typedef enum {
    MUSIC,
    SFX,
    VOX,
    AMBIENCE
} AudioType;

typedef struct {
    AudioType type;
    Sound sound;
    Music music;
    bool loaded;
} AudioResource;

typedef struct {
    AudioResource sounds[MAX_SOUNDS];
    AudioResource music[MAX_MUSIC_TRACKS];
    AudioResource vox[MAX_SOUNDS];
    AudioResource ambience[MAX_SOUNDS];
    size_t sound_count;
    size_t music_count;
    size_t vox_count;
    size_t ambience_count;

    float masterVolume;
    float musicVolume;
    float sfxVolume;
    float voxVolume;
    float ambienceVolume;

    // Audio enabled flags
    bool isMusicPlaying;
    bool isMusicEnabled;
    bool isSfxEnabled;
    bool isVoxEnabled;
    bool isAmbienceEnabled;

    // For music fading in/out
    bool isFadingOut;
    float fadeOutDuration;
    float fadeOutTimer;
    float originalVolume;
    char pendingMusicPath[256];
    float pendingMusicVolume;
    bool pendingMusicLoop;
    float pendingMusicDelay;
    float pendingMusicDelayTimer;
    bool isPendingMusicDelayed;
} AudioManager;

extern AudioManager* gAudioManager;

void InitAudioManager(AudioManager* manager);
void UpdateAudioManager(AudioManager* manager, float deltaTime);
bool PlaySFX(AudioManager* manager, const char* path, float volume);
bool PlayMusic(AudioManager* manager, const char* path, float volume, bool loop, float delay);
void StopMusic(AudioManager* manager);
void PrestoSetMasterVolume(AudioManager* manager, float volume);
void PrestoSetMusicVolume(AudioManager* manager, float volume);
void PrestoSetSFXVolume(AudioManager* manager, float volume);
void PrestoSetVoxVolume(AudioManager* manager, float volume);
void PrestoSetAmbienceVolume(AudioManager* manager, float volume);

float PrestoGetMasterVolume(AudioManager* manager);
float PrestoGetMusicVolume(AudioManager* manager);
float PrestoGetSFXVolume(AudioManager* manager);
float PrestoGetVoxVolume(AudioManager* manager);
float PrestoGetAmbienceVolume(AudioManager* manager);
bool IsMusicPlaying(AudioManager* manager);
Music GetCurrentMusic(AudioManager* manager);

void FadeOutMusic(AudioManager* manager, float duration);

void UnloadAllAudio(AudioManager* manager);

#endif // MANAGERS_AUDIO_H