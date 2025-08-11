module sprite.animation_manager;

import raylib;
import sprite.sprite_manager;

import std.stdio;
import std.string;
import std.array;
import std.math;

enum AnimationManagerInitialized {
    UNINITIALIZED,
    INITIALIZED
}

class AnimationManager {
    private AnimationManagerInitialized state = AnimationManagerInitialized.UNINITIALIZED;
    private string[] animations;
    private int currentAnimationIndex = -1;
    private float frameTime = 0.0f;
    private float elapsedTime = 0.0f;
    private Texture2D texture;
    void setTexture(Texture2D tex) {
        texture = tex;
    }

    this() {
        animations = [];
        state = AnimationManagerInitialized.INITIALIZED;
    }

    void addAnimation(string animation) {
        animations ~= animation;
    }

    void setAnimation(int index) {
        if (index >= 0 && index < animations.length) {
            currentAnimationIndex = index;
            elapsedTime = 0.0f;
        } else {
            writeln("Invalid animation index: ", index);
        }
    }

    void update(float deltaTime) {
        if (currentAnimationIndex == -1 || animations.length == 0) {
            return;
        }

        elapsedTime += deltaTime;
        if (elapsedTime >= frameTime) {
            elapsedTime = 0.0f;
            // Logic to update the animation frame can be added here
        }
    }

    void setFrameTime(float time) {
        frameTime = time;
    }

    Rectangle getFrameRectangle(int frameIndex) {
        // For an 11x11 grid, valid frame indices are 0 to 120
        if (frameIndex < 0 || frameIndex >= 121) {
            writeln("Invalid frame index: ", frameIndex);
            return Rectangle(0, 0, 0, 0); // Return an empty rectangle
        }
        return SpriteManager.getInstance().getRectangleByFrameIndex(frameIndex);
    }

    string getCurrentAnimation() {
        if (currentAnimationIndex != -1 && currentAnimationIndex < animations.length) {
            return animations[currentAnimationIndex];
        }
        return "";
    }

    bool isInitialized() {
        return state == AnimationManagerInitialized.INITIALIZED;
    }

    Texture2D getTexture() {
        if (texture.id != 0) {
            return texture;
        }
        if (currentAnimationIndex == -1 || animations.length == 0) {
            writeln("No valid animation set.");
            return Texture2D(); // Return an empty texture
        }
        // Fallback: try to get from SpriteManager
        return SpriteManager.getInstance().getTextureByAnimation(animations[currentAnimationIndex]);
    }
}