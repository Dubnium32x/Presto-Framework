import raylib;

import screen_manager;
import screen_settings;
import screen_states;
import player.player;
import player.var;

import std.stdio : writeln;
import std.string;
import std.file;
import std.algorithm;
import std.format;
import std.conv;
import std.math;

// Add a toString function for PlayerState enum to support UI
string toString(PlayerState state) {
    final switch(state) {
        case PlayerState.IDLE: return "IDLE";
        case PlayerState.WALK: return "WALK";
        case PlayerState.RUN: return "RUN";
        case PlayerState.DASHING: return "DASHING";
        case PlayerState.JUMPING: return "JUMPING";
        case PlayerState.FALLING: return "FALLING";
        case PlayerState.ROLLING: return "ROLLING";
        case PlayerState.SPINDASHING: return "SPINDASHING";
        case PlayerState.PEELING: return "PEELING";
        case PlayerState.SPINNING: return "SPINNING";
        case PlayerState.CLIMBING: return "CLIMBING";
        case PlayerState.HURT: return "HURT";
        case PlayerState.DEAD: return "DEAD";
    }
}

// initialize the screen
ScreenSettings screenSettings;
ScreenManager screenManager;

// Player instance
Player playerInstance;

// Physics test mode - simple platforms for testing physics
Rectangle[] testPlatforms;
Camera2D camera;
bool physicsTestMode = true;

void main() {
    // Initialize the screen settings to the target window size and virtual resolution
    InitWindow(1280, 720, "Presto Framework - Sonic Physics Demo");
    screenSettings = new ScreenSettings(1280, 720, 640, 360); // Window: 1280x720, Virtual: 640x360
    SetTargetFPS(60); // Set the target frames per second
    
    // Pass the configured screenSettings to the ScreenManager
    // ScreenManager.instance will be created here if null, or use existing if already set up
    // Ensure ScreenManager uses these settings, especially for virtual resolution
    if (ScreenManager.instance is null) {
        screenManager = new ScreenManager(screenSettings);
    } else {
        screenManager = ScreenManager.instance;
        screenManager.setScreenSettings(screenSettings); // Apply new settings
    }
    
    // Initialize our player physics system
    if (physicsTestMode) {
        initializePhysicsTest();
    } else {
        screenManager.initialize(); // Initialize the screen manager
    }

    // Main game loop
    writeln("Starting main loop...");
    while (!WindowShouldClose()) {
        // If in physics test mode, update and draw our test environment
        if (physicsTestMode) {
            updatePhysicsTest();
            drawPhysicsTest();
        } else {
            // Update and draw the current screen via ScreenManager
            screenManager.update();
            screenManager.draw();
        }
    }

    // Clean up resources
    if (physicsTestMode && playerInstance !is null) {
        destroy(playerInstance);
    }

    // Close the window and clean up resources
    writeln("Closing window...");
    CloseWindow();
}

// Initialize the physics test environment
void initializePhysicsTest() {
    // Create player instance
    playerInstance = new Player();
    
    // Set initial position
    Var.x = 100;
    Var.y = 100;
    
    // Create test platforms
    testPlatforms ~= Rectangle(0, 300, 800, 100);    // Ground platform (index 0)
    testPlatforms ~= Rectangle(200, 200, 150, 20);   // First platform (index 1)
    testPlatforms ~= Rectangle(400, 150, 200, 20);   // Second platform (index 2)
    testPlatforms ~= Rectangle(100, 250, 80, 20);    // Small platform (index 3)
    
    // Create slope platforms (implemented as horizontal surfaces at different heights)
    // Left-to-right upward slope (index 4)
    testPlatforms ~= Rectangle(600, 300, 150, 20);
    
    // Add some more complex testing platforms
    testPlatforms ~= Rectangle(800, 280, 150, 20);   // Slight downward slope (index 5)
    testPlatforms ~= Rectangle(1000, 310, 100, 20);  // Hill (index 6)
    testPlatforms ~= Rectangle(1150, 290, 100, 20);  // Loop approach (index 7)
    
    // Add sloped platforms with more dramatic angles (note: these are still rectangular for simplicity)
    // For a steep upward slope, we create two adjacent platforms at different heights
    testPlatforms ~= Rectangle(1300, 300, 70, 20);   // Start of steep slope (index 8)
    testPlatforms ~= Rectangle(1370, 280, 70, 20);   // Middle of steep slope (index 9)
    testPlatforms ~= Rectangle(1440, 260, 70, 20);   // End of steep slope (index 10)
    
    // Loop structure (simplified)
    testPlatforms ~= Rectangle(1550, 300, 50, 20);   // Loop entrance (index 11)
    testPlatforms ~= Rectangle(1600, 280, 50, 20);   // Loop rise (index 12) 
    testPlatforms ~= Rectangle(1650, 250, 50, 20);   // Loop top (index 13)
    testPlatforms ~= Rectangle(1700, 280, 50, 20);   // Loop descent (index 14)
    testPlatforms ~= Rectangle(1750, 300, 50, 20);   // Loop exit (index 15)
    
    // Initialize camera
    camera.target = Vector2(Var.x, Var.y);
    camera.offset = Vector2(screenSettings.virtualWidth / 2.0f, screenSettings.virtualHeight / 2.0f);
    camera.rotation = 0.0f;
    camera.zoom = 1.0f;
    
    writeln("Physics test environment initialized");
}

// Update the physics test environment
void updatePhysicsTest() {
    // FAIL-SAFE JUMP MECHANISM: Direct application at the highest program level
    // This should work even if other parts of the code are failing
    if ((IsKeyPressed(KeyboardKey.KEY_Z) || IsKeyPressed(KeyboardKey.KEY_SPACE)) && Var.grounded) {
        writeln("######## FAIL-SAFE JUMP ACTIVATED AT APPLICATION LEVEL ########");
        
        // IMPROVED SEQUENCE with more gradual jumping: First apply forces, then change state flags
        
        // Step 1: Apply moderate vertical impulse first for more gradual jump
        Var.yspeed = -8.0f; // Reduced from -16.0f for a much more natural, gradual jump
        
        // Step 2: Maintain horizontal momentum with a very slight boost
        Var.xspeed = Var.groundspeed * 1.02f;  // 2% speed boost (reduced from 5%)
        
        // Step 3: Change flags AFTER force application to avoid race conditions
        Var.grounded = false;
        playerInstance.state = PlayerState.JUMPING;
        
        // Step 4: Force player height above ground to ensure leaving the ground
        Var.y -= 1.5f;  // Reduced from 3.0f pixels for more gradual takeoff
        
        writeln("FAILSAFE JUMP VALUES - yspeed: ", Var.yspeed, ", xspeed: ", Var.xspeed);
    }
    
    // Update player
    playerInstance.update(GetFrameTime());
    
    // Reset player if R is pressed
    if (IsKeyPressed(KeyboardKey.KEY_R)) {
        Var.x = 100;
        Var.y = 100;
        Var.xspeed = 0;
        Var.yspeed = 0;
        Var.groundspeed = 0;
    }
    
    // Update camera to follow player
    camera.target = Vector2(Var.x, Var.y);
}

// Draw the physics test environment
void drawPhysicsTest() {
    BeginDrawing();
    
    ClearBackground(Color(40, 40, 80, 255)); // Dark blue background
    
    BeginMode2D(camera);
    
    // Draw platforms
    foreach (size_t i, platform; testPlatforms) {
        // Use different colors for different platform types
        Color platformColor;
        
        // Assign colors based on platform indices
        if (i == 0) {
            platformColor = Color(0, 100, 0, 255);       // Ground (Dark Green)
        } else if (i == 4) {
            platformColor = Color(128, 0, 128, 255);     // Upward slope (Purple)
        } else if (i == 5) {
            platformColor = Color(0, 0, 255, 255);       // Downward slope (Blue)
        } else if (i >= 6) {
            platformColor = Color(255, 140, 0, 255);     // Hills and loops (Orange)
        } else {
            platformColor = Color(0, 255, 0, 255);       // Regular platforms (Green)
        }
        
        DrawRectangleRec(platform, platformColor);
        
        // Draw platform index for debugging
        DrawText(TextFormat("%d", i), 
            cast(int)(platform.x + 5), 
            cast(int)(platform.y + 5), 
            12, Color(255, 255, 255, 255));
    }
    
    // Draw player
    playerInstance.draw();
    
    EndMode2D();
    
    // Draw UI
    Color whiteColor = Color(255, 255, 255, 255); // White
    DrawText(TextFormat("GROUND SPEED: %.2f", Var.groundspeed), 10, 10, 20, whiteColor);
    DrawText(TextFormat("X/Y SPEED: %.2f, %.2f", Var.xspeed, Var.yspeed), 10, 40, 20, whiteColor); 
    // Make grounded status very visible with color
    DrawText(TextFormat("GROUNDED: %d", Var.grounded ? 1 : 0), 10, 70, 20, 
        Var.grounded ? Color(0, 255, 0, 255) : Color(255, 0, 0, 255));
    DrawText(TextFormat("POSITION: %.0f, %.0f", Var.x, Var.y), 10, 100, 20, whiteColor);
    DrawText(TextFormat("GROUND ANGLE: %d (%.2f)", 
        cast(int)Var.groundangle,
        (Var.groundangle/128.0f) * 180.0f), 10, 130, 20, whiteColor);
    
    // Display key states prominently
    Color redColor = Color(255, 0, 0, 255);
    Color greenColor = Color(0, 255, 0, 255);
    Color jumpStateColor = Color(255, 255, 0, 255);  // Yellow for jump state
    DrawText("KEY STATES:", 10, 160, 20, whiteColor);
    
    // Enhanced Z key display with more visible state
    bool zKeyPressed = IsKeyDown(KeyboardKey.KEY_Z);
    string zKeyState = zKeyPressed ? "PRESSED" : "RELEASED";
    DrawRectangle(10, 180, 20, 20, zKeyPressed ? greenColor : redColor); // Visual indicator box
    DrawText(TextFormat("Z (JUMP): %s", zKeyState.ptr), 
        35, 180, 20, zKeyPressed ? greenColor : redColor);
    
    // Add jump state info
    DrawText(TextFormat("PLAYER STATE: %s", toString(playerInstance.state).ptr), 
        10, 200, 20, 
        playerInstance.state == PlayerState.JUMPING ? jumpStateColor : whiteColor);
        
    // Fixed version for LEFT/RIGHT keys
    string leftState = IsKeyDown(KeyboardKey.KEY_LEFT) ? "PRESSED" : "RELEASED";
    string rightState = IsKeyDown(KeyboardKey.KEY_RIGHT) ? "PRESSED" : "RELEASED";
    DrawText(TextFormat("LEFT: %s  RIGHT: %s", leftState.ptr, rightState.ptr), 
        10, 220, 20, whiteColor);
        
    // Show jump-related forces
    DrawText(TextFormat("JUMP FORCE: %.2f", Var.jumpforce), 
        10, 240, 20, whiteColor);
    
    // Instructions
    // Reuse colors defined above
    Color orangeColor = Color(255, 165, 0, 255); // Orange
    
    // Use hard-coded strings to avoid issues with TextFormat
    DrawText("LEFT/RIGHT: Move | Z: Jump | X: Action | DOWN+X: Spindash", 
        10, screenSettings.virtualHeight - 60, 16, jumpStateColor);
    DrawText("DOWN+SPEED: Roll | R: Reset | TAB: Show Debug", 
        10, screenSettings.virtualHeight - 40, 16, jumpStateColor);
    DrawText("SPACE: EMERGENCY JUMP (if Z key doesn't work)", 
        10, screenSettings.virtualHeight - 20, 16, orangeColor);
    
    EndDrawing();
}