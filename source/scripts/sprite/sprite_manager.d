module sprite.sprite_manager;

import raylib;

import std.stdio;

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
        sprites = sprites.filter!(s => s.id != id);
    }

    void update(float deltaTime) {
        foreach (sprite; sprites) {
            sprite.update(deltaTime);
        }
    }

    void draw() {
        foreach (sprite; sprites) {
            if (sprite.visible) {
                DrawTextureEx(sprite.texture, sprite.position, 0.0f, sprite.scale, sprite.tint);
            }
        }
    }
}