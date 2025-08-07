module entity.sprite_object;

import raylib;

import std.stdio;
import std.string;
import std.conv : to;
import std.file;
import std.exception;
import std.array;

import palette.palette_manager;
import entity.player.player;
import sprite.sprite_manager;
import sprite.animation_manager;
import utils.spritesheet_splitter;

enum SpriteObjectType {
    PLAYER,
    ENEMY,
    ITEM,
    BACKGROUND,
    EFFECT
}

struct SpriteObject {
    // Basic properties
    int id;
    string name;
    Texture2D texture;
    float x;
    float y;
    int width;
    int height;
    float scale;
    Color tint;
    bool flipHorizontal;
    bool flipVertical;
    bool visible;
    SpriteObjectType type;
    
    // Animation properties
    int currentFrame;
    int totalFrames;
    float frameTime;
    float frameTimer;
    bool animating;
    
    this(Texture2D tex, Vector2 pos = Vector2(0, 0), int id = 0, string name = "sprite", SpriteObjectType type = SpriteObjectType.PLAYER) {
        this.id = id;
        this.name = name;
        this.type = type;
        texture = tex;
        x = pos.x;
        y = pos.y;
        width = tex.width;
        height = tex.height;
        scale = 4.0f; // Scale up for better visibility
        tint = Colors.WHITE;
        flipHorizontal = false;
        flipVertical = false;
        visible = true;
        currentFrame = 0;
        totalFrames = 1;
        frameTime = 0.1f; // 100ms per frame
        frameTimer = 0.0f;
        animating = false;
    }
    
    void update(float deltaTime) {
        if (totalFrames > 1 && animating) {
            frameTimer += deltaTime;
            if (frameTimer >= frameTime) {
                frameTimer = 0.0f;
                currentFrame = (currentFrame + 1) % totalFrames;
            }
        }
    }
    
    void draw() {
        if (!visible) return;
        
        Rectangle sourceRec = Rectangle(
            0, 0,
            flipHorizontal ? -cast(float)width : cast(float)width,
            flipVertical ? -cast(float)height : cast(float)height
        );
        
        Rectangle destRec = Rectangle(
            x, y,
            width * scale, height * scale
        );
        
        // Draw the sprite with its current texture (which should be palette-swapped)
        DrawTexturePro(texture, sourceRec, destRec, Vector2(0, 0), 0.0f, tint);
        
        // Draw debug info
        PaletteManager paletteManager = PaletteManager.getInstance();
        ulong paletteIndex = paletteManager.getCurrentPaletteIndex();
        string debugText = name ~ " (Palette: " ~ paletteIndex.to!string ~ ")";
        DrawText(debugText.toStringz, cast(int)x, cast(int)y - 20, 10, Colors.WHITE);
    }
    
    // Method to apply palette swapping to this sprite
    void applyCurrentPalette() {
        PaletteManager paletteManager = PaletteManager.getInstance();
        paletteManager.applyPalette(&this);
    }
    
    void setPosition(Vector2 newPos) {
        x = newPos.x;
        y = newPos.y;
    }
    
    void setScale(float newScale) {
        scale = newScale;
    }
    
    void setTint(Color newTint) {
        tint = newTint;
    }
    
    void setVisible(bool isVisible) {
        visible = isVisible;
    }
    
    void startAnimation(int frames, float fps = 10.0f) {
        totalFrames = frames;
        frameTime = 1.0f / fps;
        currentFrame = 0;
        frameTimer = 0.0f;
        animating = true;
    }
    
    void stopAnimation() {
        animating = false;
        currentFrame = 0;
        frameTimer = 0.0f;
    }
}