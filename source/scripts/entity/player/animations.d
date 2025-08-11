module entity.player.animations;

import raylib;

import std.stdio;
import std.string;
import std.array;
import std.math;
import std.algorithm : map;

import sprite.animator;
import sprite.animation_manager;

enum PlayerAnimationState {
    IDLE, IMPATIENT_LOOK, IMPATIENT, IM_OUTTA_HERE_LOOK, IM_OUTTA_HERE, JUMP_OFF_SCREEN_1, JUMP_OFF_SCREEN_2,
    WALK, RUN, DASH, JUMP, ROLL, FALL, SKID, SPINDASH, PEELOUT, PEELOUT_CHARGED,
    LOOKUP, LOOKDOWN, PUSH,
    WOBBLEFRONT, WOBBLEBACK, SPRING_1, SPRING_2,
    HURT, DIE, BURN, DROWN,
    FANSPIN, MONKEYBARS, MONKEYBARSMOVE,
    TAUNT, CELEBRATE, SURPRISED
}


class PlayerAnimations {
    private Animator* animator = new Animator();
    private AnimationManager animationManager = new AnimationManager();

    this() {}

    void setTexture(Texture2D texture) {
        animationManager.setTexture(texture);
    }

    void setAnimationState(AnimationSequence newSequence) {
        animator.setAnimationState(newSequence);
        animationManager.addAnimation(newSequence.name);
    }

    void update(float deltaTime) {
        animationManager.update(deltaTime);
        animator.update(deltaTime); // Advance animation frames
    }

    void setFrameTime(float time) {
        animationManager.setFrameTime(time);
    }

    string getCurrentAnimation() {
        return animationManager.getCurrentAnimation();
    }

    void setPlayerAnimationState(PlayerAnimationState state) {
        AnimationSequence sequence;
        writeln("Switching to animation state: ", state);

        // Reset animation manager state
        animationManager.setAnimation(0); // Always reset to first animation in list

        switch (state) {
            case PlayerAnimationState.IDLE:
                sequence = AnimationSequence("Idle", AnimationSequenceType.LOOP, [
                    AnimationFrame(0, 0.5),
                    AnimationFrame(0, 0.5)
                ]);
                break;
            case PlayerAnimationState.IMPATIENT_LOOK:
                sequence = AnimationSequence("ImpatientLook", AnimationSequenceType.ONCE, [
                    AnimationFrame(1, 0.5),
                    AnimationFrame(2, 2.0)
                ]);
                break;
            case PlayerAnimationState.IMPATIENT:
                sequence = AnimationSequence("Impatient", AnimationSequenceType.LOOP, [
                    AnimationFrame(3, 0.4),
                    AnimationFrame(4, 0.4)
                ]);
                break;
            case PlayerAnimationState.IM_OUTTA_HERE_LOOK:
                sequence = AnimationSequence("ImOuttaHereLook", AnimationSequenceType.ONCE, [
                    AnimationFrame(103, 0.2),
                    AnimationFrame(104, 0.2),
                    AnimationFrame(105, 0.2)
                ]);
                break;
            case PlayerAnimationState.IM_OUTTA_HERE:
                sequence = AnimationSequence("ImOuttaHere", AnimationSequenceType.LOOP, [
                    AnimationFrame(105, 0.2),
                    AnimationFrame(106, 0.3)
                ]);
                break;
            case PlayerAnimationState.JUMP_OFF_SCREEN_1:
                sequence = AnimationSequence("JumpOffScreen1", AnimationSequenceType.ONCE, [
                    AnimationFrame(107, 0.2),
                    AnimationFrame(108, 0.3),
                    AnimationFrame(109, 0.4),
                    AnimationFrame(110, 0.5)
                ]);
                break;
            case PlayerAnimationState.JUMP_OFF_SCREEN_2:
                sequence = AnimationSequence("JumpOffScreen2", AnimationSequenceType.LOOP, [
                    AnimationFrame(111, 0.2),
                    AnimationFrame(112, 0.2),
                    AnimationFrame(113, 0.2)
                ]);
                break;
            case PlayerAnimationState.WALK:
                sequence = AnimationSequence("Walk", AnimationSequenceType.LOOP, [
                    AnimationFrame(5, 0.2),
                    AnimationFrame(6, 0.2),
                    AnimationFrame(7, 0.2),
                    AnimationFrame(8, 0.2),
                    AnimationFrame(9, 0.2),
                    AnimationFrame(10, 0.2),
                    AnimationFrame(11, 0.2),
                    AnimationFrame(12, 0.2),
                ]);
                break;
            case PlayerAnimationState.RUN:
                sequence = AnimationSequence("Run", AnimationSequenceType.LOOP, [
                    AnimationFrame(19, 0.1),
                    AnimationFrame(20, 0.1),
                    AnimationFrame(21, 0.1),
                    AnimationFrame(22, 0.1)
                ]);
                break;
            case PlayerAnimationState.DASH:
                sequence = AnimationSequence("Dash", AnimationSequenceType.LOOP, [
                    AnimationFrame(23, 0.1),
                    AnimationFrame(24, 0.1),
                    AnimationFrame(25, 0.1),
                    AnimationFrame(26, 0.1)
                ]);
                break;
            case PlayerAnimationState.JUMP:
                sequence = AnimationSequence("Jump", AnimationSequenceType.SEQUENCE_WITH_FIRST_FRAME_ALTERNATING, [
                    AnimationFrame(13, 0.2),
                    AnimationFrame(14, 0.2),
                    AnimationFrame(15, 0.2),
                    AnimationFrame(16, 0.2),
                    AnimationFrame(17, 0.2)
                ]);
                break;
            case PlayerAnimationState.ROLL:
                sequence = AnimationSequence("Roll", AnimationSequenceType.SEQUENCE_WITH_FIRST_FRAME_ALTERNATING, [
                    AnimationFrame(13, 0.2),
                    AnimationFrame(14, 0.2),
                    AnimationFrame(15, 0.2),
                    AnimationFrame(16, 0.2),
                    AnimationFrame(17, 0.2)
                ]);
                break;
            case PlayerAnimationState.FALL:
                sequence = AnimationSequence("Fall", AnimationSequenceType.LOOP, [
                    AnimationFrame(0, 0.2)
                ]);
                break;
            case PlayerAnimationState.SKID:
                sequence = AnimationSequence("Skid", AnimationSequenceType.LOOP, [
                    AnimationFrame(45, 0.2),
                    AnimationFrame(46, 0.2)
                ]);
                break;
            case PlayerAnimationState.SPINDASH:
                sequence = AnimationSequence("SpinDash", AnimationSequenceType.LOOP, [
                    AnimationFrame(27, 0.1),
                    AnimationFrame(28, 0.1),
                    AnimationFrame(29, 0.1),
                    AnimationFrame(30, 0.1),
                    AnimationFrame(31, 0.1),
                    AnimationFrame(32, 0.1),
                    AnimationFrame(33, 0.1),
                    AnimationFrame(34, 0.1),
                    AnimationFrame(35, 0.1),
                    AnimationFrame(36, 0.1)
                ]);
                break;
            case PlayerAnimationState.PEELOUT:
                // We will have to build it up using walk -> run -> dash
                sequence = AnimationSequence("Peelout", AnimationSequenceType.ONCE, [
                    AnimationFrame(5, 0.2),
                    AnimationFrame(6, 0.2),
                    AnimationFrame(7, 0.2),
                    AnimationFrame(8, 0.1),
                    AnimationFrame(9, 0.1),
                    AnimationFrame(10, 0.1),
                    AnimationFrame(11, 0.1),
                    AnimationFrame(19, 0.1),
                    AnimationFrame(20, 0.1),
                    AnimationFrame(21, 0.1),
                    AnimationFrame(22, 0.1),
                    AnimationFrame(23, 0.1),
                    AnimationFrame(24, 0.1),
                    AnimationFrame(25, 0.1),
                    AnimationFrame(26, 0.1)
                ]);
                break;
            case PlayerAnimationState.PEELOUT_CHARGED:
                sequence = AnimationSequence("PeeloutCharged", AnimationSequenceType.LOOP, [
                    AnimationFrame(23, 0.1),
                    AnimationFrame(24, 0.1),
                    AnimationFrame(25, 0.1),
                    AnimationFrame(26, 0.1)
                ]);
                break;
            case PlayerAnimationState.LOOKUP:
                sequence = AnimationSequence("LookUp", AnimationSequenceType.LOOP, [
                    AnimationFrame(18, 0.1)
                ]);
                break;
            case PlayerAnimationState.LOOKDOWN:
                sequence = AnimationSequence("LookDown", AnimationSequenceType.LOOP, [
                    AnimationFrame(65, 0.1)
                ]);
                break;
            case PlayerAnimationState.PUSH:
                sequence = AnimationSequence("Push", AnimationSequenceType.LOOP, [
                    AnimationFrame(47, 0.2),
                    AnimationFrame(48, 0.2),
                    AnimationFrame(49, 0.2),
                    AnimationFrame(50, 0.2)
                ]);
                break;
            case PlayerAnimationState.WOBBLEFRONT:
                sequence = AnimationSequence("WobbleFront", AnimationSequenceType.LOOP, [
                    AnimationFrame(37, 0.2),
                    AnimationFrame(38, 0.2),
                    AnimationFrame(39, 0.2),
                    AnimationFrame(40, 0.2)
                ]);
                break;
            case PlayerAnimationState.WOBBLEBACK:
                sequence = AnimationSequence("WobbleBack", AnimationSequenceType.LOOP, [
                    AnimationFrame(41, 0.2),
                    AnimationFrame(42, 0.2),
                    AnimationFrame(43, 0.2),
                    AnimationFrame(44, 0.2)
                ]);
                break;
            case PlayerAnimationState.SPRING_1:
                sequence = AnimationSequence("Spring1", AnimationSequenceType.LOOP, [
                    AnimationFrame(66, 0.2),
                    AnimationFrame(67, 0.2)
                ]);
                break;
            case PlayerAnimationState.SPRING_2:
                sequence = AnimationSequence("Spring2", AnimationSequenceType.LOOP, [
                    AnimationFrame(68, 0.2),
                    AnimationFrame(69, 0.2),
                    AnimationFrame(70, 0.2),
                    AnimationFrame(71, 0.2),
                    AnimationFrame(72, 0.2),
                    AnimationFrame(73, 0.2),
                    AnimationFrame(74, 0.2),
                    AnimationFrame(75, 0.2)
                ]);
                break;
            case PlayerAnimationState.HURT:
                sequence = AnimationSequence("Hurt", AnimationSequenceType.LOOP, [
                    AnimationFrame(87, 0.2)
                ]);
                break;
            case PlayerAnimationState.DIE:
                sequence = AnimationSequence("Die", AnimationSequenceType.LOOP, [
                    AnimationFrame(76, 0.2)
                ]);
                break;
            case PlayerAnimationState.BURN:
                sequence = AnimationSequence("Burn", AnimationSequenceType.LOOP, [
                    AnimationFrame(77, 0.2)
                ]);
                break;
            case PlayerAnimationState.DROWN:
                sequence = AnimationSequence("Drown", AnimationSequenceType.LOOP, [
                    AnimationFrame(77, 0.2)
                ]);
                break;
            case PlayerAnimationState.FANSPIN:
                sequence = AnimationSequence("FanSpin", AnimationSequenceType.LOOP, [
                    AnimationFrame(78, 0.2),
                    AnimationFrame(79, 0.2),
                    AnimationFrame(80, 0.2),
                    AnimationFrame(81, 0.2),
                    AnimationFrame(82, 0.2),
                    AnimationFrame(83, 0.2)
                ]);
                break;
            case PlayerAnimationState.MONKEYBARS:
                sequence = AnimationSequence("MonkeyBars", AnimationSequenceType.LOOP, [
                    AnimationFrame(92, 0.2),
                    AnimationFrame(93, 0.2),
                    AnimationFrame(94, 0.2)
                ]);
                break;
            case PlayerAnimationState.MONKEYBARSMOVE:
                sequence = AnimationSequence("MonkeyBarsMove", AnimationSequenceType.LOOP, [
                    AnimationFrame(95, 0.2),
                    AnimationFrame(96, 0.2),
                    AnimationFrame(97, 0.2),
                    AnimationFrame(98, 0.2),
                    AnimationFrame(99, 0.2),
                    AnimationFrame(60, 0.2) 
                ]);
                break;
            case PlayerAnimationState.TAUNT:
                sequence = AnimationSequence("Taunt", AnimationSequenceType.LOOP, [
                    AnimationFrame(90, 0.2),
                    AnimationFrame(91, 0.2)
                ]);
                break;
            case PlayerAnimationState.CELEBRATE:
                sequence = AnimationSequence("Celebrate", AnimationSequenceType.LOOP, [
                    AnimationFrame(101, 0.2),
                    AnimationFrame(102, 0.2)
                ]);
                break;
            case PlayerAnimationState.SURPRISED:
                sequence = AnimationSequence("Surprised", AnimationSequenceType.LOOP, [
                    AnimationFrame(84, 0.2),
                    AnimationFrame(85, 0.2),
                    AnimationFrame(86, 0.2)
                ]);
                break;
            default:
                writeln("Unhandled animation state: ", state);
                return;
        }

    writeln("Setting animation sequence: ", sequence.name, " with frames: ", sequence.frames.map!(f => f.frameIndex).array);
    setAnimationState(sequence);
    }

    void render(Vector2 position) {
        // Assuming the Animator provides a way to get the current frame index
        int frameIndex = animator.currentFrame.frameIndex;

        // Get the texture and frame rectangle from AnimationManager
        Texture2D texture = animationManager.getTexture();
        Rectangle frameRect = animationManager.getFrameRectangle(frameIndex);

        // Only draw if a valid animation and frame are set
        if (texture.id != 0 && frameRect.width > 0 && frameRect.height > 0) {
            DrawTextureRec(texture, frameRect, position, Colors.WHITE);
        }
    }
}