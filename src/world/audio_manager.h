// Audio Manager header
#ifndef AUDIO_MANAGER_H
#define AUDIO_MANAGER_H

#include "raylib.h"
#include "module_player.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_SOUNDS 100
#define MAX_MUSIC_TRACKS 10

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
} AudioResource;

typedef struct {
    AudioResource sounds[MAX_SOUNDS];
    AudioResource music[MAX_MUSIC_TRACKS];
    size_t sound_count;
    size_t music_count;
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
    
    // Module player for tracker music (XM, IT, S3M, etc.)
    ModulePlayer modulePlayer;
    bool useModulePlayer;
} AudioManager;

void InitAudioManager(AudioManager* manager);
void UpdateAudioManager(AudioManager* manager);
bool PrestoPlaySound(AudioManager* manager, const char* filePath, AudioType type, float volume);
bool PrestoPlayMusic(AudioManager* manager, const char* filePath, float volume, bool loop, float fadeInDuration);
bool PlayVOX(AudioManager* manager, const char* filePath, float volume);
bool PlayAmbience(AudioManager* manager, const char* filePath, float volume, bool loop);
void FadeOutMusic(AudioManager* manager, float duration);
void PrestoSetMasterVolume(AudioManager* manager, float volume);
void PrestoSetMusicVolume(AudioManager* manager, float volume);
void SetSFXVolume(AudioManager* manager, float volume);
void SetVOXVolume(AudioManager* manager, float volume);
void SetAmbienceVolume(AudioManager* manager, float volume);
void StopMusic(AudioManager* manager);
void StopAllSFX(AudioManager* manager);

// Getter functions (implemented in .c file)
float PrestoGetMasterVolume(AudioManager* manager);
float GetMusicVolume(AudioManager* manager);
float GetSFXVolume(AudioManager* manager);
float GetVOXVolume(AudioManager* manager);
float GetAmbienceVolume(AudioManager* manager);

bool IsMusicPlayingNow(AudioManager* manager);
bool IsMusicEnabled(AudioManager* manager);
bool IsSFXEnabled(AudioManager* manager);
bool IsVOXEnabled(AudioManager* manager);
bool IsAmbienceEnabled(AudioManager* manager);

void UnloadAllAudio(AudioManager* manager);

// Module player functions (XM, IT, S3M, MOD, etc.)
bool LoadModuleMusic(AudioManager* manager, const char* filePath);
bool PlayModuleMusic(AudioManager* manager, const char* filePath, float volume, bool loop);
void StopModuleMusic(AudioManager* manager);
void SetModuleMusicVolume(AudioManager* manager, float volume);
float GetModuleMusicVolume(AudioManager* manager);
bool IsModuleMusicPlaying(AudioManager* manager);
void FadeOutModuleMusic(AudioManager* manager, float duration);
void CrossfadeToModuleMusic(AudioManager* manager, const char* filePath, float volume, bool loop, float duration);
bool IsModuleFile(const char* filePath);
const char* GetModulePlayerInfo(AudioManager* manager);
void SetModulePlayerEnabled(AudioManager* manager, bool enabled);
bool IsModulePlayerEnabled(AudioManager* manager);

#endif // AUDIO_MANAGER_H