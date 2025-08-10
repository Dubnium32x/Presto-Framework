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
        // Placeholder logic: Return a dummy rectangle for now
        // Replace with actual logic to fetch the rectangle for the frame index
        return Rectangle(0, 0, 32, 32); // Example: 32x32 frame size
    }

    Texture2D getTextureByAnimation(string animationName) {
        // Placeholder logic: Return a dummy texture for now
        // Replace with actual logic to fetch the texture for the animation name
        if (sprites.length > 0) {
            return sprites[0].texture; // Example: Return the first sprite's texture
        }
        return Texture2D(); // Return an empty texture if no sprites are available
    }
}