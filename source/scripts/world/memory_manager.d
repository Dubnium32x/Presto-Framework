module world.memory_manager;

import raylib;
import std.stdio;
import std.string;
import std.path;
import std.file;
import std.algorithm;
import std.array;
import std.typecons : Tuple;
import std.conv : to;

/**
 * Memory Manager for Presto Framework
 * 
 * Manages and caches game resources to optimize memory usage and loading times.
 * Tracks textures, sounds, music, fonts, and shaders.
 */
class MemoryManager {
    private {
        // Cached resources
        Texture2D[string] textureCache;
        Sound[string] soundCache;
        Music[string] musicCache;
        Font[string] fontCache;
        Shader[string] shaderCache;
        
        // Alpha map associations for advanced sprite rendering
        string[string] textureAlphaMaps; // Maps base texture path to alpha map path

        // Resource usage statistics
        size_t totalTextureMemory = 0;
        size_t totalSoundMemory = 0;
        size_t totalMusicMemory = 0;
        size_t totalFontMemory = 0;
        size_t totalShaderMemory = 0;

        // Singleton instance
        __gshared MemoryManager _instance;
    }

    /**
     * Get singleton instance
     */
    static MemoryManager instance() {
        if (_instance is null) {
            synchronized {
                if (_instance is null) {
                    _instance = new MemoryManager();
                }
            }
        }
        return _instance;
    }

    /**
     * Initialize the memory manager
     */
    void initialize() {
        writeln("MemoryManager initialized for Presto Framework");
    }

    /**
     * Load and cache a texture
     * 
     * Params:
     *   filePath = Path to the texture file
     *   forceReload = Whether to reload the texture even if it's cached
     * 
     * Returns: The loaded texture
     */
    Texture2D loadTexture(string filePath, bool forceReload = false) {
        if (!forceReload && filePath in textureCache) {
            return textureCache[filePath];
        }

        // If we're reloading, unload the previous texture first
        if (forceReload && filePath in textureCache) {
            UnloadTexture(textureCache[filePath]);
            totalTextureMemory -= estimateTextureMemory(textureCache[filePath]);
            textureCache.remove(filePath);
        }

        Texture2D texture = LoadTexture(filePath.toStringz);
        if (texture.id == 0) {
            writeln("ERROR: Failed to load texture: ", filePath);
            // Return an empty texture
            return texture;
        }
        
        textureCache[filePath] = texture;
        
        // Update memory usage statistics
        totalTextureMemory += estimateTextureMemory(texture);
        
        return texture;
    }

    /**
     * Load and cache a sound
     * 
     * Params:
     *   filePath = Path to the sound file
     *   forceReload = Whether to reload the sound even if it's cached
     * 
     * Returns: The loaded sound
     */
    Sound loadSound(string filePath, bool forceReload = false) {
        if (!forceReload && filePath in soundCache) {
            return soundCache[filePath];
        }

        // If we're reloading, unload the previous sound first
        if (forceReload && filePath in soundCache) {
            UnloadSound(soundCache[filePath]);
            totalSoundMemory -= estimateSoundMemory(soundCache[filePath]);
            soundCache.remove(filePath);
        }

        Sound sound = LoadSound(filePath.toStringz);
        if (sound.frameCount <= 0) {
            writeln("ERROR: Failed to load sound: ", filePath);
            // Return the invalid sound
            return sound;
        }
        
        soundCache[filePath] = sound;
        
        // Update memory usage statistics
        totalSoundMemory += estimateSoundMemory(sound);
        
        return sound;
    }

    /**
     * Load and cache music
     * 
     * Params:
     *   filePath = Path to the music file
     *   forceReload = Whether to reload the music even if it's cached
     * 
     * Returns: The loaded music
     */
    Music loadMusic(string filePath, bool forceReload = false) {
        if (!forceReload && filePath in musicCache) {
            return musicCache[filePath];
        }

        // If we're reloading, unload the previous music first
        if (forceReload && filePath in musicCache) {
            UnloadMusicStream(musicCache[filePath]);
            totalMusicMemory -= estimateMusicMemory(musicCache[filePath]);
            musicCache.remove(filePath);
        }

        Music music = LoadMusicStream(filePath.toStringz);
        if (music.ctxData == null) {
            writeln("ERROR: Failed to load music: ", filePath);
            // Return the invalid music
            return music;
        }
        
        musicCache[filePath] = music;
        
        // Update memory usage statistics
        totalMusicMemory += estimateMusicMemory(music);
        
        return music;
    }

    /**
     * Load and cache a font
     * 
     * Params:
     *   filePath = Path to the font file
     *   fontSize = Size of the font to load
     *   forceReload = Whether to reload the font even if it's cached
     * 
     * Returns: The loaded font
     */
    Font loadFont(string filePath, int fontSize = 10, bool forceReload = false) {
        string cacheKey = filePath ~ "_" ~ fontSize.to!string;
        
        if (!forceReload && cacheKey in fontCache) {
            return fontCache[cacheKey];
        }

        // If we're reloading, unload the previous font first
        if (forceReload && cacheKey in fontCache) {
            UnloadFont(fontCache[cacheKey]);
            totalFontMemory -= estimateFontMemory(fontCache[cacheKey]);
            fontCache.remove(cacheKey);
        }

        Font font = LoadFontEx(filePath.toStringz, fontSize, null, 0);
        fontCache[cacheKey] = font;
        
        // Update memory usage statistics
        totalFontMemory += estimateFontMemory(font);
        
        return font;
    }

    /**
     * Get a texture from the cache or load it
     */
    Texture2D getTexture(string filePath) {
        if (filePath in textureCache) {
            return textureCache[filePath];
        }
        
        return loadTexture(filePath);
    }

    /**
     * Get a sound from the cache or load it
     */
    Sound getSound(string filePath) {
        if (filePath in soundCache) {
            return soundCache[filePath];
        }
        
        return loadSound(filePath);
    }

    /**
     * Get music from the cache or load it
     */
    Music getMusic(string filePath) {
        if (filePath in musicCache) {
            return musicCache[filePath];
        }
        
        return loadMusic(filePath);
    }

    /**
     * Check if a texture is in the cache
     */
    bool hasTexture(string filePath) {
        return (filePath in textureCache) !is null;
    }

    /**
     * Unload all cached resources
     */
    void unloadAllResources() {
        // Unload all textures
        foreach (key, texture; textureCache) {
            UnloadTexture(texture);
        }
        textureCache = null;
        totalTextureMemory = 0;

        // Unload all sounds
        foreach (key, sound; soundCache) {
            UnloadSound(sound);
        }
        soundCache = null;
        totalSoundMemory = 0;

        // Unload all music
        foreach (key, music; musicCache) {
            UnloadMusicStream(music);
        }
        musicCache = null;
        totalMusicMemory = 0;

        // Unload all fonts
        foreach (key, font; fontCache) {
            UnloadFont(font);
        }
        fontCache = null;
        totalFontMemory = 0;

        writeln("All cached resources unloaded");
    }

    /**
     * Get memory usage statistics
     */
    string getMemoryUsageStats() {
        import std.format : format;
        return format(
            "Memory Usage:\n" ~
            "  Textures: %.2f MB (%d cached)\n" ~
            "  Sounds: %.2f MB (%d cached)\n" ~
            "  Music: %.2f MB (%d cached)\n" ~
            "  Fonts: %.2f MB (%d cached)\n" ~
            "  Total: %.2f MB",
            totalTextureMemory / 1024.0 / 1024.0, textureCache.length,
            totalSoundMemory / 1024.0 / 1024.0, soundCache.length,
            totalMusicMemory / 1024.0 / 1024.0, musicCache.length,
            totalFontMemory / 1024.0 / 1024.0, fontCache.length,
            (totalTextureMemory + totalSoundMemory + totalMusicMemory + totalFontMemory) / 1024.0 / 1024.0
        );
    }

    /**
     * Estimate memory usage of a texture
     */
    private size_t estimateTextureMemory(Texture2D texture) {
        // Calculate memory usage based on dimensions and format
        int bytesPerPixel = 4; // Assume RGBA format (4 bytes per pixel)
        return texture.width * texture.height * bytesPerPixel;
    }

    /**
     * Estimate memory usage of a sound
     */
    private size_t estimateSoundMemory(Sound sound) {
        // This is a rough estimate since Raylib doesn't expose exact memory usage
        // Assume 16-bit stereo sound at 44.1 kHz
        return 512 * 1024; // Default to 512KB per sound
    }

    /**
     * Estimate memory usage of music
     */
    private size_t estimateMusicMemory(Music music) {
        // This is a rough estimate since Raylib doesn't expose exact memory usage
        return 2 * 1024 * 1024; // Default to 2MB per music track
    }

    /**
     * Estimate memory usage of a font
     */
    private size_t estimateFontMemory(Font font) {
        // Calculate memory usage based on font glyphs
        size_t memory = 0;
        
        // Base font structure
        memory += 256; // Base font structure size
        
        // Texture memory
        memory += estimateTextureMemory(font.texture);
        
        // Glyph data
        memory += font.glyphCount * (8 + 16); // Rectangle + additional data per glyph
        
        return memory;
    }
}
