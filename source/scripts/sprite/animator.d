module sprite.animator;

import raylib;

import std.stdio;
import std.array;
import std.math;
import std.string;

import entity.sprite_object;
import utils.spritesheet_splitter;
import sprite.sprite_manager;

enum AnimationSequenceType {
    ONCE,
    LOOP,
    SEQUENCE_WITH_FIRST_FRAME_ALTERNATING,
    REVERSE,
    PINGPONG
}

struct AnimationFrame {
    int frameIndex;
    float duration; // Duration in seconds
}

struct AnimationSequence {
    string name;
    AnimationSequenceType type;
    AnimationFrame[] frames;
}

struct Animator {
    AnimationSequence sequence;
    AnimationFrame currentFrame;
    AnimationSequenceType currentType;
    int currentFrameIndex; // Track which frame we're on
    float frameTimer; // Track how long we've been on current frame
    float speedMultiplier = 1.0f; // Playback speed multiplier (1.0 = normal)

    void setAnimationState(AnimationSequence newSequence) {
        sequence = newSequence;
        currentFrameIndex = 0;
        frameTimer = 0.0f;
        if (sequence.frames.length > 0) {
            currentFrame = sequence.frames[0];
            currentType = sequence.type;
            // Debug: report initial frame and duration
            writeln("[ANIMATOR] setAnimationState: '", sequence.name, "' starting frameIndex=", currentFrameIndex, " sprite=", currentFrame.frameIndex, " duration=", currentFrame.duration);
        }
    }

    void update(float deltaTime) {
        if (sequence.frames.length == 0) return;

        // Debug: trace timing each update
        frameTimer += deltaTime;
        writeln("[ANIMATOR] update: delta=", deltaTime, " frameTimer=", frameTimer, " currentDuration=", currentFrame.duration, " idx=", currentFrameIndex, " sprite=", currentFrame.frameIndex);
        // Guard: if duration is zero or negative, set a small default to avoid busy loops
        float baseDuration = currentFrame.duration > 0.0f ? currentFrame.duration : 0.016f; // default to ~60fps
        float curDuration = baseDuration / (speedMultiplier > 0.0f ? speedMultiplier : 1.0f);
        while (frameTimer >= curDuration) {
            frameTimer -= curDuration; // Consume the actual playback duration for this frame
            int oldIndex = currentFrameIndex;
            advanceFrame();
            // Debug output to see if frames are advancing
            if (currentFrameIndex != oldIndex) {
                writeln("[ANIMATOR] Advanced from frame ", oldIndex, " (sprite ", sequence.frames[oldIndex].frameIndex, ") to frame ", currentFrameIndex, " (sprite ", currentFrame.frameIndex, ")");
            } else {
                writeln("[ANIMATOR] advanceFrame called but index unchanged (idx=", currentFrameIndex, ")");
            }
            // Update curDuration in case the new frame has a different duration
            baseDuration = currentFrame.duration > 0.0f ? currentFrame.duration : 0.016f;
            curDuration = baseDuration / (speedMultiplier > 0.0f ? speedMultiplier : 1.0f);
        }
    }

    void setSpeedMultiplier(float m) {
        if (m <= 0.0f) m = 1.0f;
        speedMultiplier = m;
        writeln("[ANIMATOR] setSpeedMultiplier: ", speedMultiplier);
    }

    void advanceFrame() {
        switch (currentType) {
            case AnimationSequenceType.ONCE:
                if (currentFrameIndex < sequence.frames.length - 1) {
                    currentFrameIndex++;
                } else {
                    // End of sequence, stay on last frame or reset to first
                    currentFrameIndex = 0;
                }
                currentFrame = sequence.frames[currentFrameIndex];
                break;
            case AnimationSequenceType.LOOP:
                currentFrameIndex = cast(int)((currentFrameIndex + 1) % sequence.frames.length);
                currentFrame = sequence.frames[currentFrameIndex];
                break;
            case AnimationSequenceType.SEQUENCE_WITH_FIRST_FRAME_ALTERNATING:
                // Logic for SEQUENCE_WITH_FIRST_FRAME_ALTERNATING type
                // What this does is it plays the first frame every other frame.
                static bool playFirstFrame = true;
                if (playFirstFrame) {
                    currentFrameIndex = 0;
                } else {
                    // Cycle through frames 1 to end
                    if (currentFrameIndex == 0) {
                        currentFrameIndex = 1;
                    } else if (currentFrameIndex < sequence.frames.length - 1) {
                        currentFrameIndex++;
                    } else {
                        currentFrameIndex = 1; // Loop back to frame 1
                    }
                }
                playFirstFrame = !playFirstFrame;
                currentFrame = sequence.frames[currentFrameIndex];
                break;
            case AnimationSequenceType.REVERSE:
                // Logic for REVERSE type
                if (currentFrameIndex > 0) {
                    currentFrameIndex--;
                } else {
                    currentFrameIndex = cast(int)sequence.frames.length - 1;
                }
                currentFrame = sequence.frames[currentFrameIndex];
                break;
            case AnimationSequenceType.PINGPONG:
                // Logic for PINGPONG type
                static bool forward = true;
                if (forward) {
                    if (currentFrameIndex < sequence.frames.length - 1) {
                        currentFrameIndex++;
                    } else {
                        forward = false; // Change direction
                        currentFrameIndex--;
                    }
                } else {
                    if (currentFrameIndex > 0) {
                        currentFrameIndex--;
                    } else {
                        forward = true; // Change direction
                        currentFrameIndex++;
                    }
                }
                currentFrame = sequence.frames[currentFrameIndex];
                break;
            default:
                // Handle unknown sequence types
                break;
        }
    }

    void addAnimation(string name, Texture2D texture, int[] frameIndices, float frameDuration) {
        AnimationFrame[] frames;
        foreach (index; frameIndices) {
            frames ~= AnimationFrame(index, frameDuration);
        }
        sequence = AnimationSequence(name, AnimationSequenceType.LOOP, frames);
    }

    void play(string name) {
        // Assuming only one sequence for simplicity
        if (sequence.name == name) {
            setAnimationState(sequence);
        }
    }

    Rectangle getCurrentFrameRectangle() {
        return SpriteManager.getInstance().getRectangleByFrameIndex(currentFrame.frameIndex);
    }

    Texture2D getCurrentTexture() {
        return SpriteManager.getInstance().getTextureByAnimation(sequence.name);
    }
}