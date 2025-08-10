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

    void setAnimationState(AnimationSequence newSequence) {
        sequence = newSequence;
        currentFrame = sequence.frames[0];
        currentType = sequence.type;
    }

    void update(float deltaTime) {
        if (sequence.frames.length == 0) return;

        currentFrame.duration -= deltaTime;
        if (currentFrame.duration <= 0) {
            advanceFrame();
        }
    }

    void advanceFrame() {
        switch (currentType) {
            case AnimationSequenceType.ONCE:
                for (int i = 0; i < sequence.frames.length; i++) {
                    if (sequence.frames[i].frameIndex == currentFrame.frameIndex) {
                        if (i < sequence.frames.length - 1) {
                            currentFrame = sequence.frames[i + 1];
                        } else {
                            // End of the sequence, reset or stop
                            currentFrame = sequence.frames[0]; // Reset to first frame
                        }
                        break;
                    }
                }
                break;
            case AnimationSequenceType.LOOP:
                for (int i = 0; i < sequence.frames.length; i++) {
                    if (sequence.frames[i].frameIndex == currentFrame.frameIndex) {
                        if (i < sequence.frames.length - 1) {
                            currentFrame = sequence.frames[i + 1];
                        } else {
                            // Loop back to the first frame
                            currentFrame = sequence.frames[0];
                        }
                        break;
                    }
                }
                break;
            case AnimationSequenceType.SEQUENCE_WITH_FIRST_FRAME_ALTERNATING:
                // Logic for SEQUENCE_WITH_FIRST_FRAME_ALTERNATING type
                // What this does is it plays the first frame every other frame.
                static bool playFirstFrame = true;
                if (playFirstFrame) {
                    currentFrame = sequence.frames[0];
                } else {
                    for (int i = 1; i < sequence.frames.length; i++) {
                        if (sequence.frames[i].frameIndex == currentFrame.frameIndex) {
                            if (i < sequence.frames.length - 1) {
                                currentFrame = sequence.frames[i + 1];
                            } else {
                                currentFrame = sequence.frames[1];
                            }
                            break;
                        }
                    }
                }
                playFirstFrame = !playFirstFrame;
                break;
            case AnimationSequenceType.REVERSE:
                // Logic for REVERSE type
                for (int i = cast(int)sequence.frames.length - 1; i >= 0; i--) {
                    if (sequence.frames[i].frameIndex == currentFrame.frameIndex) {
                        if (i > 0) {
                            currentFrame = sequence.frames[i - 1];
                        } else {
                            // Reverse to the last frame
                            currentFrame = sequence.frames[sequence.frames.length - 1];
                        }
                        break;
                    }
                }
                break;
            case AnimationSequenceType.PINGPONG:
                // Logic for PINGPONG type
                static bool forward = true;
                for (int i = 0; i < sequence.frames.length; i++) {
                    if (sequence.frames[i].frameIndex == currentFrame.frameIndex) {
                        if (forward) {
                            if (i < sequence.frames.length - 1) {
                                currentFrame = sequence.frames[i + 1];
                            } else {
                                forward = false; // Change direction
                                currentFrame = sequence.frames[i - 1];
                            }
                        } else {
                            if (i > 0) {
                                currentFrame = sequence.frames[i - 1];
                            } else {
                                forward = true; // Change direction
                                currentFrame = sequence.frames[1];
                            }
                        }
                        break;
                    }
                }
                break;
            default:
                // Handle unknown sequence types
                break;
        }
    }
}