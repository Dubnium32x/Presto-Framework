module sprite.sprite_manager;

import raylib;

import std.stdio;
import std.algorithm : filter;
import std.array : array;

import entity.sprite_object;
import utils.spritesheet_splitter;

class SpriteManager {
    private static SpriteManager instance;
    private SpriteObject[] sprites;

    static SpriteManager getInstance() {
        if (instance is null) {
            instance = new SpriteManager();
        }
        return instance;
    }

    private this() {
        // Initialize with an empty sprite list
        sprites = [];
    }

    void addSprite(SpriteObject sprite) {
        sprites ~= sprite;
    }

    void removeSprite(int id) {
        sprites = sprites.filter!(s => s.id != id).array;
    }

    void update(float deltaTime) {
        foreach (sprite; sprites) {
            sprite.update(deltaTime);
        }
    }

    void draw() {
        foreach (sprite; sprites) {
            if (sprite.visible) {
                DrawTextureEx(sprite.texture, Vector2(sprite.x, sprite.y), 0.0f, sprite.scale, sprite.tint);
            }
        }
    }

    Rectangle getRectangleByFrameIndex(int frameIndex) {
        // For an 11x11 grid of 64x64 frames
        int framesPerRow = 11;
        int frameWidth = 64;
        int frameHeight = 64;
        int column = frameIndex % framesPerRow;
        int row = frameIndex / framesPerRow;
        float x = column * frameWidth;
        float y = row * frameHeight;
        return Rectangle(x, y, frameWidth, frameHeight);
    }

    Texture2D getTextureByAnimation(string animationName) {
        // Placeholder logic: Return a dummy texture for now
        // Replace with actual logic to fetch the texture for the animation name
        if (sprites.length > 0) {
            return sprites[0].texture; // Example: Return the first sprite's texture
        }
        return Texture2D(); // Return an empty texture if no sprites are available
    }

    void loadSprite(string name, string filePath, int frameWidth, int frameHeight) {
        import std.string : toStringz;
        Texture2D texture = LoadTexture(filePath.toStringz);
        SpriteObject sprite = SpriteObject(texture, Vector2(0, 0), cast(int)sprites.length, name, SpriteObjectType.PLAYER);
        sprite.setFrameSize(frameWidth, frameHeight);
        addSprite(sprite);
    }

    void unloadAll() {
        foreach (sprite; sprites) {
            if (sprite.texture.id != 0) {
                UnloadTexture(sprite.texture);
            }
        }
        sprites = [];
    }

    SpriteObject getSprite(string name) {
        foreach (sprite; sprites) {
            if (sprite.name == name) {
                return sprite;
            }
        }
        throw new Exception("Sprite not found: " ~ name);
    }
}