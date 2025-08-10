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
        if (frameIndex < 0 || frameIndex >= animations.length) {
            writeln("Invalid frame index: ", frameIndex);
            return Rectangle(0, 0, 0, 0); // Return an empty rectangle
        }
        // Assuming SpriteManager has a method to get the rectangle for a frame index
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
        if (currentAnimationIndex == -1 || animations.length == 0) {
            writeln("No valid animation set.");
            return Texture2D(); // Return an empty texture
        }
        // Assuming SpriteManager can provide a texture for the current animation
        return SpriteManager.getInstance().getTextureByAnimation(animations[currentAnimationIndex]);
    }
}