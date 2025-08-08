module palette.palette_manager;

import raylib;
import std.stdio;
import std.file;
import std.path;
import std.algorithm;
import std.array;
import std.conv;
import std.string;
import entity.sprite_object;

class PaletteManager {
    // Apply palette using a specific column in the palette image
    bool applyPalette(SpriteObject* sprite, int column) {
        if (paletteImage.data is null) {
            writeln("No palette image loaded!");
            return false;
        }

        lastSprite = sprite;

        if (originalSprite.data is null) {
            originalSprite = LoadImageFromTexture(sprite.texture);
            writeln("Stored original sprite image");
        }

        Image spriteImg = ImageCopy(originalSprite);
        UnloadTexture(sprite.texture);

        for (int y = 0; y < spriteImg.height; y++) {
            for (int x = 0; x < spriteImg.width; x++) {
                Color pixelColor = GetImageColor(spriteImg, x, y);

                for (int i = 0; i < paletteImage.height; i++) {
                    Color paletteColor = GetImageColor(paletteImage, 0, i);
                    if (colorsMatch(pixelColor, paletteColor)) {
                        Color newColor = GetImageColor(paletteImage, column, i);
                        ImageDrawPixel(&spriteImg, x, y, newColor);
                        break;
                    }
                }
            }
        }

        sprite.texture = LoadTextureFromImage(spriteImg);
        UnloadImage(spriteImg);

        return true;
    }
    private static PaletteManager instance;
    private Image paletteImage;
    private Image originalSprite;
    private size_t currentPalette = 0;
    private string[] palettePaths;
    private SpriteObject* lastSprite;
    
    enum string PALETTE_BASE_PATH = "resources/image/palette";

    static PaletteManager getInstance() {
        if (instance is null) {
            instance = new PaletteManager();
        }
        return instance;
    }

    private this() {
        loadPalettePaths();
        if (palettePaths.length > 0) {
            // Use the first available palette file
            currentPalette = 0;
            loadPaletteImage(palettePaths[0]);
            writefln("Starting with palette: %s", palettePaths[0]);
        } else {
            writeln("Warning: No valid palette files found!");
        }
    }

    ~this() {
        if (originalSprite.data !is null) {
            UnloadImage(originalSprite);
        }
        if (paletteImage.data !is null) {
            UnloadImage(paletteImage);
        }
    }

    private void loadPalettePaths() {
        try {
            // Look for .png files directly in the palette directory
            auto entries = dirEntries(PALETTE_BASE_PATH, "*.png", SpanMode.shallow)
                .filter!(e => e.isFile)
                .map!(e => e.name)
                .array;
            
            palettePaths = entries.sort!().array;
            writefln("Found %d palette files", palettePaths.length);
            
            // Debug: print all found palettes
            foreach (i, path; palettePaths) {
                writefln("  Palette %d: %s", i, path);
            }
        } catch (Exception e) {
            writeln("Error loading palette paths: ", e.msg);
            palettePaths = [];
        }
    }

    bool loadPaletteImage(string path) {
        if (paletteImage.data !is null) {
            UnloadImage(paletteImage);
        }
        
        // Ensure proper null termination for C function
        import std.string : toStringz;
        paletteImage = LoadImage(path.toStringz);
        
        if (paletteImage.width == 0 || paletteImage.height == 0) {
            writeln("Failed to load palette image: ", path);
            return false;
        }
        writefln("Loaded palette image: %s (%dx%d)", path, paletteImage.width, paletteImage.height);
        return true;
    }

    void nextPalette() {
        if (palettePaths.length == 0) return;
        currentPalette = (currentPalette + 1) % palettePaths.length;
        loadPaletteImage(palettePaths[currentPalette]);
        if (lastSprite !is null) {
            applyPalette(lastSprite);
        }
        writefln("Switching to palette: %d/%d", currentPalette + 1, palettePaths.length);
    }

    void previousPalette() {
        if (palettePaths.length == 0) return;
        currentPalette = (currentPalette + palettePaths.length - 1) % palettePaths.length;
        loadPaletteImage(palettePaths[currentPalette]);
        if (lastSprite !is null) {
            applyPalette(lastSprite);
        }
        writefln("Switching to palette: %d/%d", currentPalette + 1, palettePaths.length);
    }

    size_t getPaletteCount() { return palettePaths.length; }
    size_t getCurrentPaletteIndex() { return currentPalette; }
    
    // Add this method for the sprite object
    Texture2D getCurrentPalette() {
        if (paletteImage.data !is null) {
            return LoadTextureFromImage(paletteImage);
        }
        return Texture2D(); // Return empty texture if no palette loaded
    }

    bool applyPalette(SpriteObject* sprite) {
        if (paletteImage.data is null) {
            writeln("No palette image loaded!");
            return false;
        }

        lastSprite = sprite;
        
        if (originalSprite.data is null) {
            originalSprite = LoadImageFromTexture(sprite.texture);
            writeln("Stored original sprite image");
        }
        
        Image spriteImg = ImageCopy(originalSprite);
        UnloadTexture(sprite.texture);
        
        for (int y = 0; y < spriteImg.height; y++) {
            for (int x = 0; x < spriteImg.width; x++) {
                Color pixelColor = GetImageColor(spriteImg, x, y);
                
                for (int i = 0; i < paletteImage.height; i++) {
                    Color paletteColor = GetImageColor(paletteImage, 0, i);
                    if (colorsMatch(pixelColor, paletteColor)) {
                        Color newColor = GetImageColor(paletteImage, 1, i);
                        ImageDrawPixel(&spriteImg, x, y, newColor);
                        break;
                    }
                }
            }
        }

        sprite.texture = LoadTextureFromImage(spriteImg);
        UnloadImage(spriteImg);
        
        return true;
    }

    private bool colorsMatch(Color a, Color b) {
        return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
    }
}
