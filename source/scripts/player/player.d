module prestoframework.player;

import raylib;

import std.stdio : writeln;
import std.string;
import std.conv : to; // Import 'to' for string conversion
import std.math;

import prestoframework.screen_manager;
import prestoframework.screen_states;
import prestoframework.screen_settings;
import parser.csv_tile_loader;
import prestoframework.player_states;

class Player {
    Vector2 position;
    Vector2 velocity;
    Rectangle bounds;
    PlayerState state;
    float speed = 2.0f;
    Texture2D spriteSheet; // Add texture member
    Rectangle currentFrameRec; // Rectangle for the current sprite frame
    bool facingRight = true; // Track player direction
    int frameWidth = 64; // Store sprite dimensions
    int frameHeight = 64;

    int collisionWidth = 20; // New width
    int collisionHeight = 40; // New height
    int collisionOffsetY = -12; // Vertical offset (negative moves box up)
    int collisionOffsetX = 2; // Horizontal offset (positive moves box right)

    // Physics constants
    float gravity = 0.5f; // Adjust as needed
    float maxFallSpeed = 10.0f; // Optional: Limit max fall speed

    this(Vector2 startPos) {
        position = startPos;
        velocity = Vector2(0, 0);
        // Use new collision dimensions and offsets
        bounds = Rectangle(position.x - collisionWidth / 2.0f + collisionOffsetX, position.y - collisionHeight + collisionOffsetY, collisionWidth, collisionHeight);
        state = PlayerState.IDLE;
        // Define the initial frame (first idle frame, 64x64)
        currentFrameRec = Rectangle(0, 0, frameWidth, frameHeight);
        writeln("Player initialized at: ", position);
    }

    void load() {
        writeln("Player loading assets...");
        spriteSheet = LoadTexture("source/res/image/spritesheet/Sonic_spritemap.png");
        if (spriteSheet.id == 0) { // Check if texture loading failed
            writeln("Error: Failed to load player spritesheet!");
        }
    }

    void unload() {
        writeln("Player unloading assets...");
        UnloadTexture(spriteSheet);
    }

    void update() {
        // Basic horizontal movement
        velocity.x = 0;
        if (IsKeyDown(KeyboardKey.KEY_LEFT)) { // Removed KEY_A for now to avoid conflict with camera
            velocity.x = -speed;
            facingRight = false;
        }
        if (IsKeyDown(KeyboardKey.KEY_RIGHT)) { // Removed KEY_D for now
            velocity.x = speed;
            facingRight = true;
        }

        // Apply gravity
        velocity.y += gravity;

        // Optional: Clamp fall speed
        if (velocity.y > maxFallSpeed) {
            velocity.y = maxFallSpeed;
        }

        // Apply velocity
        position.x += velocity.x;
        position.y += velocity.y; // Gravity is now applied here

        // Update bounds position (apply offsets)
        bounds.x = position.x - bounds.width / 2.0f + collisionOffsetX; // Use bounds.width (collisionWidth) and X offset
        bounds.y = position.y - bounds.height + collisionOffsetY; // Use bounds.height (collisionHeight) and Y offset

        // Update state and animation frame (very basic)
        if (velocity.x != 0) {
            state = PlayerState.WALK;
            // Add basic walking animation logic here later
            // Example: switch to the next frame in the sheet (assuming horizontal layout)
            currentFrameRec.x = frameWidth; // Use frameWidth for offset
        } else {
            state = PlayerState.IDLE;
            currentFrameRec.x = 0; // Back to idle frame
        }

        // Flip sprite based on direction - REMOVED from here
        // currentFrameRec.width = facingRight ? frameWidth : -frameWidth;
    }

    void draw() {
        // Draw the current sprite frame
        if (spriteSheet.id != 0) { // Only draw if texture loaded
            // 1. Define source rectangle based on animation frame
            Rectangle sourceRec = Rectangle(currentFrameRec.x, currentFrameRec.y, frameWidth, frameHeight);

            // 2. Define draw position based on bottom-center pivot
            Vector2 drawPos = Vector2(position.x - frameWidth / 2.0f, position.y - frameHeight);

            // 3. If facing left, make source width negative to flip the texture
            if (!facingRight) {
                sourceRec.width = -frameWidth;
            }

            // 4. Draw the texture
            DrawTexturePro(
                spriteSheet,
                sourceRec,
                // Destination rectangle uses sprite dimensions for drawing, centered horizontally, bottom aligned
                Rectangle(position.x - frameWidth / 2.0f, position.y - frameHeight, frameWidth, frameHeight),
                Vector2(0, 0), // Origin (top-left for DrawTexturePro)
                0.0f, // Rotation
                Colors.WHITE
            );

            // --- DEBUG: Draw Collision Box ---
            DrawRectangleLinesEx(bounds, 1, Colors.LIME);
            // --- END DEBUG ---
        }
        else {
             // Draw placeholder if texture failed
             DrawRectangleRec(bounds, Colors.BLUE);
        }

        // Draw state text for debugging
        // Use .stringof instead of to!string for enum member name
        DrawText(state.stringof.ptr, cast(int)position.x - 20, cast(int)position.y - 50, 10, Colors.WHITE);
    }
}

