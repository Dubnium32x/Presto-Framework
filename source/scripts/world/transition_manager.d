module world.transition_manager;

import raylib;
import std.stdio;
import world.screen_state;

enum TransitionType {
    FADE,
    SLIDE,
    WIPE,
    WORMHOLE
}

class TransitionManager {
    private:
    bool _isTransitioning = false;
    ScreenState _fromState;
    ScreenState _toState;
    TransitionType _transitionType;
    float _transitionDuration;
    float _transitionTimer;

    public:
    void startTransition(ScreenState fromState, ScreenState toState, TransitionType transitionType, float duration) {
        _isTransitioning = true;
        _fromState = fromState;
        _toState = toState;
        _transitionType = transitionType;
        _transitionDuration = duration;
        _transitionTimer = 0.0f;
        writeln("Transition started: ", fromState, " -> ", toState);
    }

    void update(float deltaTime) {
        if (_isTransitioning) {
            _transitionTimer += deltaTime;

            if (_transitionTimer >= _transitionDuration) {
                _isTransitioning = false;
                _transitionTimer = 0.0f;
                writeln("Transition finished to state: ", _toState);
            }
        }
    }

    void draw() {
        if (_isTransitioning) {
            // Implement transition drawing logic here based on _transitionType
            switch (_transitionType) {
                case TransitionType.FADE:
                    drawFadeTransition();
                    break;
                case TransitionType.SLIDE:
                    drawSlideTransition();
                    break;
                case TransitionType.WIPE:
                    drawWipeTransition();
                    break;
                case TransitionType.WORMHOLE:
                    drawWormholeTransition();
                    break;
                default:
                    break;
            }
        }
    }

    bool isTransitioning() {
        return _isTransitioning;
    }

    private:
    void drawFadeTransition() {
        float alpha = _transitionTimer / _transitionDuration;
        DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), Fade(Colors.BLACK, alpha));
    }

    void drawSlideTransition() {
        // Implement slide transition drawing logic
    }

    void drawWipeTransition() {
        // Implement wipe transition drawing logic
    }

    void drawWormholeTransition() {
        // Implement wormhole transition drawing logic
    }
}

