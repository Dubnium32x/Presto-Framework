module screens.animation_test;

import raylib;

import std.stdio;
import std.string;
import std.array;
import std.math;
import std.algorithm : min, max;
import std.conv : to;

import sprite.sprite_manager;
import sprite.animator;
import entity.entity_manager;
import entity.sprite_object;
import world.screen_manager; // Import IScreen interface
import entity.player.animations; // Import PlayerAnimations
import world.input_manager;

// Define missing constants
enum RAYWHITE = Color(245, 245, 245, 255);
enum WHITE = Color(255, 255, 255, 255);

class AnimationTestScreen : IScreen {
    private static AnimationTestScreen _instance;
    private SpriteManager spriteManager;
    private Animator animator;
    private SpriteObject sonicSprite;
    private bool initialized = false;
    private float frameDuration = 0.1f; // Animation speed (seconds per frame)
    private PlayerAnimations playerAnimations; // Add PlayerAnimations instance

    static AnimationTestScreen getInstance() {
        if (_instance is null) {
            _instance = new AnimationTestScreen();
        }
        return _instance;
    }

    void initialize() {
        if (initialized) return;
        spriteManager = SpriteManager.getInstance();
        spriteManager.loadSprite("sonic", "resources/image/spritesheet/Sonic_spritemap.png", 64, 64);
        sonicSprite = spriteManager.getSprite("sonic");
        playerAnimations = new PlayerAnimations(); // Initialize PlayerAnimations
        playerAnimations.setTexture(sonicSprite.texture); // Set the texture for animations
        playerAnimations.setPlayerAnimationState(PlayerAnimationState.IDLE); // Set default animation
        initialized = true;
    }

    void addRunAnimation() {
        animator.addAnimation("run", sonicSprite.texture, [0, 1, 2, 3, 4, 5], frameDuration);
    }

    void update(float deltaTime) {
        // Adjust animation speed with UP/DOWN keys via InputManager
        if (InputManager.getInstance().wasPressed(InputBit.UP)) {
            frameDuration = max(0.01f, frameDuration - 0.01f); // Faster, min 0.01s
        }
        if (InputManager.getInstance().wasPressed(InputBit.DOWN)) {
            frameDuration = min(1.0f, frameDuration + 0.01f); // Slower, max 1s
        }

        // Switch animation states with LEFT/RIGHT keys
        if (InputManager.getInstance().wasPressed(InputBit.LEFT)) {
            playerAnimations.setPlayerAnimationState(PlayerAnimationState.FANSPIN); // Example state
        }
        if (InputManager.getInstance().wasPressed(InputBit.RIGHT)) {
            playerAnimations.setPlayerAnimationState(PlayerAnimationState.DIE); // Example state
        }

        playerAnimations.update(deltaTime); // Update PlayerAnimations
    }

    void draw() {
        ClearBackground(RAYWHITE);
        Vector2 drawPos = Vector2(200, 112); // Center of the screen (half of 400,300 for 800x448)
        playerAnimations.render(drawPos); // Use render method to draw animation
        DrawText(("Frame Duration: " ~ frameDuration.to!string ~ "s (UP/DOWN to change)").toStringz, 5, 20, 10, Color(0,0,0,255));
    }

    void unload() {
        if (spriteManager !is null) {
            spriteManager.unloadAll();
        }
        initialized = false;
    }
}

void runAnimationTest() {
    // Initialize Raylib
    const int screenWidth = 800;
    const int screenHeight = 600;
    InitWindow(screenWidth, screenHeight, "Animation Test Screen");
    SetTargetFPS(60);

    // Load resources
    SpriteManager spriteManager;
    Animator animator;

    // Example: Load a sprite and its animations
    string spritePath = "resources/image/spritesheet/Sonic_spritemap.png";
    spriteManager.loadSprite("sonic", spritePath, 64, 64); // Assuming 64x64 frames
    SpriteObject sonicSprite = spriteManager.getSprite("sonic");
    animator.addAnimation("run", sonicSprite.texture, [0, 1, 2, 3, 4, 5], 10.0f); // Example animation

    // Start the animation
    animator.play("run");

    // Main game loop
    while (!WindowShouldClose()) {
        // Update
        animator.update(GetFrameTime());

        // Draw
        BeginDrawing();
        ClearBackground(RAYWHITE);

        // Render the current frame of the animation
        float scale = 1.0f;
        Rectangle frameRect = animator.getCurrentFrameRectangle();
        Texture2D texture = animator.getCurrentTexture();
        // The sprite is centered in each 64x64 frame, so set the origin to the center
        Vector2 origin = Vector2(frameRect.width * scale / 2, frameRect.height * scale / 2);
        Vector2 drawPos = Vector2(400, 300); // Center of the screen
        DrawTexturePro(
            texture,
            frameRect,
            Rectangle(drawPos.x - origin.x, drawPos.y - origin.y, frameRect.width * scale, frameRect.height * scale),
            Vector2(0, 0),
            0.0f,
            Colors.WHITE
        );

        EndDrawing();
    }

    // Unload resources
    spriteManager.unloadAll();
    CloseWindow();
}

