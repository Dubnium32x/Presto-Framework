module prestoframework.player_states;

import raylib;
import std.stdio : writeln;
import std.string;

enum PlayerState {
    IDLE,
    WALK,
    RUN,
    JUMP,
    ROLL,
    FALL,
    SPINDASH,
    PEELOUT,
    HURT,
    DEAD
}

class Player {
    private PlayerState state;
    private Vector2 position;
    private Vector2 velocity;
    private float speed;
    private float jumpForce;
    private bool isGrounded;

    this() {
        state = PlayerState.IDLE;
        position = Vector2(0, 0);
        velocity = Vector2(0, 0);
        speed = 5.0f;
        jumpForce = 10.0f;
        isGrounded = false;
    }

    void update() {
        // Handle input and update player state
        if (IsKeyDown(KEY_RIGHT)) {
            state = PlayerState.WALK;
            position.x += speed * GetFrameTime();
        } else if (IsKeyDown(KEY_LEFT)) {
            state = PlayerState.WALK;
            position.x -= speed * GetFrameTime();
        } else {
            state = PlayerState.IDLE;
        }

        if (IsKeyPressed(KEY_SPACE) && isGrounded) {
            state = PlayerState.JUMP;
            velocity.y = -jumpForce;
            isGrounded = false;
        }

        // Update position based on velocity
        position.y += velocity.y * GetFrameTime();
        velocity.y += 9.81f * GetFrameTime(); // Gravity

        // Check for ground collision
        if (position.y >= 400) { // Assuming ground level is at y=400
            position.y = 400;
            isGrounded = true;
            velocity.y = 0;
            state = PlayerState.IDLE; // Reset to idle when grounded
        }
    }

    void draw() {
        DrawRectangle(position, 20, Colors.BLUE); // Draw player as a rectangle FOR NOW
    }
}