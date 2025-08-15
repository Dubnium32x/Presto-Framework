module world.audio_manager;

import raylib;

import std.stdio;
import std.file;
import std.path;
import std.string;
import std.algorithm;

import world.memory_manager;

// ---- ENUMS ----
enum AudioType {
    MUSIC,
    SFX,
    VOX,
    AMBIENCE
}

// ---- CLASS ----
class AudioManager {
    // Public setters for SFX/music enabled flags
    void setSFXEnabled(bool enabled) {
        isSFXEnabled = enabled;
    }
    void setMusicEnabled(bool enabled) {
        isMusicEnabled = enabled;
    }
    // Singleton instance
    private __gshared AudioManager instance;
    
    // Memory manager reference
    private MemoryManager memoryManager;

    // Add a variable to track the currently playing music
    private Music currentMusic;
    private bool isMusicPlaying = false;
    private float currentMusicVolume = 1.0f; // Track current music volume
    
    // Default volume levels
    private float masterVolume = 1.0f;
    private float musicVolume = 0.8f;
    private float sfxVolume = 1.0f;
    private float voxVolume = 1.0f;
    private float ambienceVolume = 0.7f;
    
    // Audio type enabled flags
    private bool isMusicEnabled = true;
    private bool isSFXEnabled = true;
    private bool isVoxEnabled = true;
    private bool isAmbienceEnabled = true;
    
    // For music fade effects
    private bool isFadingOut = false;
    private float fadeOutDuration = 0.0f;
    private float fadeOutTimer = 0.0f;
    private float originalVolume = 1.0f;
    private string pendingMusicPath = "";
    private float pendingMusicVolume = -1.0f;
    private bool pendingMusicLoop = true;
    private float pendingMusicDelay = 0.0f; // Delay before starting pending music
    private float pendingMusicDelayTimer = 0.0f; // Timer for delay
    private bool isPendingMusicDelayed = false; // Whether pending music is in delay phase
    
    this() {
        memoryManager = MemoryManager.instance();
    }
    
    // Static method to get the singleton instance
    static AudioManager getInstance() {
        if (instance is null) {
            synchronized {
                if (instance is null) {
                    instance = new AudioManager();
                }
            }
        }
        return instance;
    }

    // Initialize audio manager
    void initialize() {
        if (!IsAudioDeviceReady()) {
            writeln("Failed to initialize audio device.");
            return;
        }
        writeln("AudioManager initialized successfully for Presto Framework.");
    }

    // Update audio system
    void update(float deltaTime = 0.0f) {
        // Update music stream with improved error handling
        if (isMusicPlaying && currentMusic.ctxData != null) {
            try {
                UpdateMusicStream(currentMusic);
                
                // Check if music finished playing (non-looping music)
                if (!IsMusicStreamPlaying(currentMusic)) {
                    isMusicPlaying = false;
                }
            } catch (Exception e) {
                writeln("Error updating music stream: ", e.msg);
                isMusicPlaying = false;
            }
        }
        
        // Handle music fade out
        if (isFadingOut && isMusicPlaying && currentMusic.ctxData !is null) {
            fadeOutTimer += deltaTime;
            
            if (fadeOutTimer >= fadeOutDuration) {
                // Fade complete, stop current music
                StopMusicStream(currentMusic);
                isFadingOut = false;
                writeln("AudioManager: Music fade complete, stopped current music");
                
                // Check if pending music should be delayed
                if (pendingMusicPath != "" && pendingMusicDelay > 0.0f) {
                    isPendingMusicDelayed = true;
                    pendingMusicDelayTimer = 0.0f;
                    writeln("AudioManager: Starting ", pendingMusicDelay, "s delay before pending music");
                } else if (pendingMusicPath != "") {
                    // No delay, play immediately
                    playMusic(pendingMusicPath, pendingMusicVolume, pendingMusicLoop);
                    writeln("AudioManager: Started pending music: ", pendingMusicPath);
                    pendingMusicPath = "";
                }
            } else {
                // Calculate and apply fade volume
                float fadeRatio = fadeOutTimer / fadeOutDuration;
                float currentFadeVolume = originalVolume * (1.0f - fadeRatio);
                SetMusicVolume(currentMusic, currentFadeVolume);
                currentMusicVolume = currentFadeVolume; // Update the tracked volume
            }
        }
        
        // Handle pending music delay after fade completes
        if (isPendingMusicDelayed) {
            pendingMusicDelayTimer += deltaTime;
            
            if (pendingMusicDelayTimer >= pendingMusicDelay) {
                // Delay complete, play the pending music
                if (pendingMusicPath != "") {
                    playMusic(pendingMusicPath, pendingMusicVolume, pendingMusicLoop);
                    writeln("AudioManager: Started delayed pending music: ", pendingMusicPath);
                    pendingMusicPath = "";
                }
                isPendingMusicDelayed = false;
                pendingMusicDelay = 0.0f;
                pendingMusicDelayTimer = 0.0f;
            }
        }
    }
    
    /**
     * Play a sound with volume based on settings
     * 
     * Params:
     *   filePath = Path to the sound file
     *   audioType = Type of audio (SFX, MUSIC, VOX, AMBIENCE)
     *   overrideVolume = Optional volume override (0.0 to 1.0). If -1.0f, uses category volume.
     *   loop = Whether to loop the sound (for music and ambience)
     *   
     * Returns: Success flag
     */
    bool playSound(string filePath, AudioType audioType, float overrideVolume = -1.0f, bool loop = false) {
        // Check if the requested audio type is enabled
        final switch (audioType) {
            case AudioType.SFX:
                if (!isSFXEnabled) return false;
                break;
            case AudioType.MUSIC:
                if (!isMusicEnabled) return false;
                break;
            case AudioType.VOX:
                if (!isVoxEnabled) return false;
                break;
            case AudioType.AMBIENCE:
                if (!isAmbienceEnabled) return false;
                break;
        }
        
        if (!exists(filePath)) {
            writeln("Sound file does not exist: ", filePath);
            return false;
        }
        
        float baseVolume;
        // Use overrideVolume if provided and valid, otherwise use category volume
        if (overrideVolume >= 0.0f && overrideVolume <= 1.0f) {
            baseVolume = overrideVolume;
        } else {
            switch (audioType) {
                case AudioType.SFX:
                    baseVolume = sfxVolume;
                    break;
                case AudioType.MUSIC:
                    baseVolume = musicVolume;
                    break;
                case AudioType.VOX:
                    baseVolume = voxVolume;
                    break;
                case AudioType.AMBIENCE:
                    baseVolume = ambienceVolume;
                    break;
                default:
                    baseVolume = 1.0f; 
                    break;
            }
        }
        
        // Calculate final volume by applying master volume
        float finalVolume = baseVolume * masterVolume;
        
        // Clamp final volume between 0.0 and 1.0
        if (finalVolume < 0.0f) finalVolume = 0.0f;
        if (finalVolume > 1.0f) finalVolume = 1.0f;
        
        // Use MemoryManager to load and cache the sound
        if (audioType == AudioType.MUSIC) {
            // Stop any currently playing music first
            if (isMusicPlaying && currentMusic.ctxData != null) {
                StopMusicStream(currentMusic);
            }
            
            Music music = memoryManager.loadMusic(filePath);
            if (music.ctxData == null) {
                writeln("Failed to load music: ", filePath);
                return false;
            }
            
            // Store the current music for later updates
            currentMusic = music;
            isMusicPlaying = true;
            currentMusicVolume = finalVolume; // Store the current volume
            
            SetMusicVolume(music, finalVolume);
            currentMusic.looping = loop; // Set looping before playing

            PlayMusicStream(music);
            
            writeln("Started playing music: ", filePath, " with volume ", finalVolume);
            return true;
        } else {
            Sound sound = memoryManager.loadSound(filePath);
            if (sound.frameCount <= 0) {
                writeln("Failed to load sound: ", filePath);
                return false;
            }
            SetSoundVolume(sound, finalVolume);
            PlaySound(sound);
            return true;
        }
    }
    
    /**
     * Play a music track with volume based on settings
     */
    bool playMusic(string filePath, float volume = -1.0f, bool loop = true) {
        return playSound(filePath, AudioType.MUSIC, volume, loop);
    }
    
    /**
     * Play an SFX with volume based on settings
     */
    bool playSFX(string filePath, float volume = -1.0f) {
        return playSound(filePath, AudioType.SFX, volume);
    }
    
    /**
     * Play a voice clip with volume based on settings
     */
    bool playVOX(string filePath, float volume = -1.0f) {
        return playSound(filePath, AudioType.VOX, volume);
    }
    
    /**
     * Play an ambience track with volume based on settings
     */
    bool playAmbience(string filePath, float volume = -1.0f, bool loop = true) {
        return playSound(filePath, AudioType.AMBIENCE, volume, loop);
    }
    
    /**
     * Start fading out the current music
     * 
     * Params:
     *   duration = Fade-out duration in seconds
     *   nextMusicPath = Music to play after fade completes (optional)
     *   nextMusicVolume = Volume for the next music (optional)
     *   nextMusicLoop = Whether to loop the next music (optional)
     *   nextMusicDelay = Delay in seconds before starting the next music (optional)
     */
    void fadeOutMusic(float duration, string nextMusicPath = "", float nextMusicVolume = -1.0f, bool nextMusicLoop = true, float nextMusicDelay = 0.0f) {
        if (!isMusicPlaying || currentMusic.ctxData is null) {
            // If no music is playing, handle delay and then play the next music
            if (nextMusicPath != "" && nextMusicDelay > 0.0f) {
                isPendingMusicDelayed = true;
                pendingMusicDelayTimer = 0.0f;
                pendingMusicDelay = nextMusicDelay;
                pendingMusicPath = nextMusicPath;
                pendingMusicVolume = nextMusicVolume;
                pendingMusicLoop = nextMusicLoop;
            } else if (nextMusicPath != "") {
                playMusic(nextMusicPath, nextMusicVolume, nextMusicLoop);
            }
            return;
        }
        
        // Save current volume as the starting point for the fade
        originalVolume = currentMusicVolume;
        
        // Setup fade parameters
        isFadingOut = true;
        fadeOutDuration = duration;
        fadeOutTimer = 0.0f;
        
        // Store pending music to play after fade completes
        pendingMusicPath = nextMusicPath;
        pendingMusicVolume = nextMusicVolume;
        pendingMusicLoop = nextMusicLoop;
        pendingMusicDelay = nextMusicDelay;
    }

    // Volume control methods
    void setMasterVolume(float volume) {
        masterVolume = volume;
        if (masterVolume < 0.0f) masterVolume = 0.0f;
        if (masterVolume > 1.0f) masterVolume = 1.0f;
    }

    void setMusicVolume(float volume) {
        musicVolume = volume;
        if (musicVolume < 0.0f) musicVolume = 0.0f;
        if (musicVolume > 1.0f) musicVolume = 1.0f;
        
        // Update current playing music volume
        if (isMusicPlaying && currentMusic.ctxData != null) {
            float newVolume = musicVolume * masterVolume;
            SetMusicVolume(currentMusic, newVolume);
            currentMusicVolume = newVolume;
        }
    }

    void setSFXVolume(float volume) {
        sfxVolume = volume;
        if (sfxVolume < 0.0f) sfxVolume = 0.0f;
        if (sfxVolume > 1.0f) sfxVolume = 1.0f;
    }

    void stopMusic() {
        if (isMusicPlaying && currentMusic.ctxData != null) {
            StopMusicStream(currentMusic);
            isMusicPlaying = false;
        }
    }

    // Getter methods
    float getMasterVolume() { return masterVolume; }
    float getMusicVolume() { return musicVolume; }
    float getSFXVolume() { return sfxVolume; }
    float getVoxVolume() { return voxVolume; }
    float getAmbienceVolume() { return ambienceVolume; }
    
    bool isMusicPlayingNow() { return isMusicPlaying; }
}
