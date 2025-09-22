module world.input_manager;

import raylib;

import std.stdio;
import std.traits;
import std.array;
import std.conv;

/*
  InputManager: 16-bit bitfield based input system tailored for KoF-style controls.

  Logical inputs (bit positions):
    0 - UP
    1 - DOWN
    2 - LEFT
    3 - RIGHT
    4 - A (face down)
    5 - B (face right)
    6 - X (face left)
    7 - Y (face up)
    8 - RB (right bumper)
    9 - LB (left bumper)
   10 - RT (right trigger extra)
   11 - LT (left trigger extra)
   12 - START
   13..15 - reserved   
*/

alias ushort Mask;

enum InputBit : ubyte {
    UP = 0,
    DOWN = 1,
    LEFT = 2,
    RIGHT = 3,
    A = 4,
    B = 5,
    X = 6,
    Y = 7,
    RB = 8,
    LB = 9,
   RT = 10,
   LT = 11,
   START = 12
}

// Helper to get a mask for a bit
Mask mask(InputBit b) {
            return cast(ushort)(1 << cast(int)b);
}

class InputManager {
	private __gshared InputManager _instance;

	// current and previous states as bitfields
	private Mask prevState = 0;
	private Mask curState = 0;

	// computed edge masks
	private Mask pressedMask = 0;
	private Mask releasedMask = 0;

	// hold timers in seconds per bit
	private float[16] holdTimers;

	// repeat timers (optional future use)
	private float[16] repeatTimers;

	// Gamepad id to poll
	private int gamepadId = 0;
	private bool useGamepad = false;

	this() {
		foreach (i; 0 .. holdTimers.length) { holdTimers[i] = 0.0f; repeatTimers[i] = 0.0f; }
	}

	static InputManager getInstance() {
		if (_instance is null) {
			synchronized {
				if (_instance is null) {
					_instance = new InputManager();
				}
			}
		}
		return _instance;
	}

	void initialize() {
		useGamepad = IsGamepadAvailable(gamepadId);
		writeln("InputManager initialized - Gamepad available: ", useGamepad);
	}

	// Public update — call once per frame with deltaTime
	void update(float dt) {
		prevState = curState;
		curState = 0;

		// Directions (keyboard + dpad/stick)
		if (IsKeyDown(KeyboardKey.KEY_UP)) curState |= mask(InputBit.UP);
		if (IsKeyDown(KeyboardKey.KEY_DOWN)) curState |= mask(InputBit.DOWN);
		if (IsKeyDown(KeyboardKey.KEY_LEFT)) curState |= mask(InputBit.LEFT);
		if (IsKeyDown(KeyboardKey.KEY_RIGHT)) curState |= mask(InputBit.RIGHT);

		// Face buttons default keyboard mapping
		if (IsKeyDown(KeyboardKey.KEY_Z)) curState |= mask(InputBit.A); // A
		if (IsKeyDown(KeyboardKey.KEY_X)) curState |= mask(InputBit.B); // B
		if (IsKeyDown(KeyboardKey.KEY_C)) curState |= mask(InputBit.X); // X
		if (IsKeyDown(KeyboardKey.KEY_V)) curState |= mask(InputBit.Y); // Y

		// Bumpers / shoulder keys
		if (IsKeyDown(KeyboardKey.KEY_RIGHT_SHIFT)) curState |= mask(InputBit.RB);
		if (IsKeyDown(KeyboardKey.KEY_LEFT_SHIFT)) curState |= mask(InputBit.LB);

		// Triggers mapped to Q/E by default
		if (IsKeyDown(KeyboardKey.KEY_Q)) curState |= mask(InputBit.LT);
		if (IsKeyDown(KeyboardKey.KEY_E)) curState |= mask(InputBit.RT);

		// Start
		if (IsKeyDown(KeyboardKey.KEY_ENTER) || IsKeyDown(KeyboardKey.KEY_SPACE)) curState |= mask(InputBit.START);

		// Gamepad input blends in if available
		if (IsGamepadAvailable(gamepadId)) {
			// D-pad and left stick
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_UP)) curState |= mask(InputBit.UP);
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_DOWN)) curState |= mask(InputBit.DOWN);
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_LEFT)) curState |= mask(InputBit.LEFT);
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) curState |= mask(InputBit.RIGHT);

			// Left stick deadzone
			float lx = GetGamepadAxisMovement(gamepadId, GamepadAxis.GAMEPAD_AXIS_LEFT_X);
			float ly = GetGamepadAxisMovement(gamepadId, GamepadAxis.GAMEPAD_AXIS_LEFT_Y);
			const float dead = 0.4f;
			if (lx < -dead) curState |= mask(InputBit.LEFT);
			if (lx > dead) curState |= mask(InputBit.RIGHT);
			if (ly < -dead) curState |= mask(InputBit.UP);
			if (ly > dead) curState |= mask(InputBit.DOWN);

			// Face buttons (right face)
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN)) curState |= mask(InputBit.A);
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT)) curState |= mask(InputBit.B);
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_LEFT)) curState |= mask(InputBit.X);
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_UP)) curState |= mask(InputBit.Y);

			// Bumpers/triggers
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_TRIGGER_1)) curState |= mask(InputBit.RB);
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_TRIGGER_1)) curState |= mask(InputBit.LB);
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_RIGHT_TRIGGER_2)) curState |= mask(InputBit.RT);
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_LEFT_TRIGGER_2)) curState |= mask(InputBit.LT);

			// Start / pause
			if (IsGamepadButtonDown(gamepadId, GamepadButton.GAMEPAD_BUTTON_MIDDLE_RIGHT)) curState |= mask(InputBit.START);
		}

		// Edge detection
		pressedMask = curState & ~prevState;
		releasedMask = prevState & ~curState;

		// Update hold timers
		foreach (i; 0 .. 16) {
			auto m = cast(Mask)1 << i;
			if ((curState & m) != 0) {
				holdTimers[i] += dt;
			} else {
				holdTimers[i] = 0.0f;
				repeatTimers[i] = 0.0f;
			}
		}
	}

	// Queries
	bool isDown(InputBit b) {
		return (curState & mask(b)) != 0;
	}

	bool wasPressed(InputBit b) {
		return (pressedMask & mask(b)) != 0;
	}

	bool wasReleased(InputBit b) {
		return (releasedMask & mask(b)) != 0;
	}

	float holdTime(InputBit b) {
		return holdTimers[cast(size_t)b];
	}

	// Convenience getters for common groups
	Mask getCurrentMask() { return curState; }
	Mask getPressedMask() { return pressedMask; }
	Mask getReleasedMask() { return releasedMask; }

	// Remap support (simple setters)
	void setGamepadId(int id) { gamepadId = id; useGamepad = IsGamepadAvailable(gamepadId); }
}

