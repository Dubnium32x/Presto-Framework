# Presto Framework Module Player

The Presto Framework now includes built-in support for playing tracker module files (XM, IT, S3M, MOD, and many others) via the integrated libmikmod library.

## Supported Formats

- **XM** (Extended Module) - FastTracker II format
- **IT** (Impulse Tracker) format
- **S3M** (Scream Tracker 3) format
- **MOD** (ProTracker/NoiseTracker) format
- **MTM** (MultiTracker) format
- **669** (Composer 669) format
- **ULT** (UltraTracker) format
- **DSM** (Dynamic Studio) format
- **FAR** (Farandole) format
- **GDM** (General Digital Music) format
- **MED** (OctaMED) format
- **OKT** (Oktalyzer) format
- **STM** (Scream Tracker) format

## Installation

The module player is automatically available when you build the Presto Framework with libmikmod installed.

### Installing libmikmod

#### Ubuntu/Debian
```bash
make install-mikmod
# or manually:
sudo apt install libmikmod-dev libmikmod3
```

#### CentOS/RHEL
```bash
sudo yum install libmikmod-devel
```

#### Arch Linux
```bash
sudo pacman -S libmikmod
```

## Quick Start

```c
#include "world/audio_manager.h"

// Initialize audio manager (includes module player)
AudioManager audioManager;
InitAudioManager(&audioManager);

// Play a module file
PlayModuleMusic(&audioManager, "path/to/song.xm", 0.8f, true);

// Update in your game loop
UpdateAudioManager(&audioManager);

// Cleanup when done
UnloadAllAudio(&audioManager);
```

## API Reference

### Core Functions

#### `bool PlayModuleMusic(AudioManager* manager, const char* filePath, float volume, bool loop)`
Plays a module file with specified volume (0.0-1.0) and loop setting.

#### `void StopModuleMusic(AudioManager* manager)`
Stops the currently playing module.

#### `void UpdateAudioManager(AudioManager* manager)`
**Important**: Must be called every frame to update module playback.

### Volume Control

#### `void SetModuleMusicVolume(AudioManager* manager, float volume)`
Sets the module music volume (0.0 to 1.0).

#### `float GetModuleMusicVolume(AudioManager* manager)`
Gets the current module music volume.

### Advanced Features

#### `void CrossfadeToModuleMusic(AudioManager* manager, const char* filePath, float volume, bool loop, float duration)`
Smoothly crossfades from the current module to a new one over the specified duration.

#### `void FadeOutModuleMusic(AudioManager* manager, float duration)`
Fades out the current module over the specified duration.

### Status Queries

#### `bool IsModuleMusicPlaying(AudioManager* manager)`
Returns true if a module is currently playing.

#### `bool IsModuleFile(const char* filePath)`
Checks if a file has a supported module format extension.

#### `const char* GetModulePlayerInfo(AudioManager* manager)`
Returns version and library information.

### Enable/Disable

#### `void SetModulePlayerEnabled(AudioManager* manager, bool enabled)`
Enables or disables the module player.

#### `bool IsModulePlayerEnabled(AudioManager* manager)`
Returns true if the module player is enabled.

## Usage Examples

### Basic Playback
```c
// Play a module with 80% volume and looping enabled
if (PlayModuleMusic(&audioManager, "res/audio/music/level1.xm", 0.8f, true)) {
    printf("Playing level1.xm\n");
} else {
    printf("Failed to play module file\n");
}
```

### Crossfading Between Tracks
```c
// Crossfade to a new track over 2 seconds
CrossfadeToModuleMusic(&audioManager, "res/audio/music/level2.it", 0.7f, true, 2.0f);
```

### Dynamic Volume Control
```c
// Increase volume
float currentVol = GetModuleMusicVolume(&audioManager);
SetModuleMusicVolume(&audioManager, fminf(currentVol + 0.1f, 1.0f));

// Decrease volume
SetModuleMusicVolume(&audioManager, fmaxf(currentVol - 0.1f, 0.0f));
```

### Checking File Support
```c
const char* filename = "mymusic.xm";
if (IsModuleFile(filename)) {
    printf("%s is a supported module format\n", filename);
    PlayModuleMusic(&audioManager, filename, 1.0f, true);
} else {
    printf("%s is not a supported module format\n", filename);
}
```

### Game State Music Management
```c
typedef enum {
    GAME_STATE_MENU,
    GAME_STATE_LEVEL1,
    GAME_STATE_LEVEL2,
    GAME_STATE_BOSS
} GameState;

void ChangeGameState(AudioManager* audioManager, GameState newState) {
    switch (newState) {
        case GAME_STATE_MENU:
            CrossfadeToModuleMusic(audioManager, "res/audio/music/menu.s3m", 0.8f, true, 1.0f);
            break;
        case GAME_STATE_LEVEL1:
            CrossfadeToModuleMusic(audioManager, "res/audio/music/level1.xm", 0.9f, true, 1.5f);
            break;
        case GAME_STATE_LEVEL2:
            CrossfadeToModuleMusic(audioManager, "res/audio/music/level2.it", 0.9f, true, 1.5f);
            break;
        case GAME_STATE_BOSS:
            CrossfadeToModuleMusic(audioManager, "res/audio/music/boss.mod", 1.0f, true, 0.5f);
            break;
    }
}
```

## Integration with Regular Audio

The module player integrates seamlessly with the regular Presto Framework audio system:

- Module music and regular raylib music are mutually exclusive (playing one stops the other)
- Volume settings respect the master volume and music volume settings
- All audio (modules and regular) can be managed through the same AudioManager instance

```c
// This will stop any playing module and play regular music
PrestoPlayMusic(&audioManager, "regular_song.ogg", 0.8f, true, 0.0f);

// This will stop any regular music and play a module
PlayModuleMusic(&audioManager, "tracker_song.xm", 0.8f, true);
```

## Best Practices

1. **Always call UpdateAudioManager()** in your main game loop
2. **Check file support** before attempting to play unknown files
3. **Use crossfading** for smooth music transitions in games
4. **Clean up properly** with UnloadAllAudio() when shutting down
5. **Keep modules in a organized folder structure** (e.g., `res/audio/music/modules/`)

## Troubleshooting

### Module won't play
- Ensure the file exists and is readable
- Check that libmikmod is properly installed
- Verify the file format is supported with `IsModuleFile()`
- Make sure the module player is enabled

### No sound
- Check that `UpdateAudioManager()` is being called every frame
- Verify volume settings with `GetModuleMusicVolume()`
- Ensure audio device is initialized (`InitAudioDevice()`)

### Build errors
- Make sure libmikmod is installed: `make install-mikmod`
- Check that the Makefile includes the mikmod flags: `make check-raylib`

## Example Demo

See `examples/module_player_demo.c` for a complete working example that demonstrates all the module player features.

## Notes

- Module files are typically much smaller than regular audio files
- Modules contain both the musical data and the samples, making them self-contained
- The module player supports the full range of tracker effects and features
- Performance is excellent - modules use very little memory and CPU compared to streaming audio