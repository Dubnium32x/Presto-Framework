module screens.test_screen;

import raylib;
import std.stdio;
import std.string;
import std.conv : to;
import world.screen_state;
import world.screen_manager : IScreen;
import utils.csv_loader;
import entity.player.player;
import app;

class TestScreen : IScreen {
    private static TestScreen _instance;
    private Player player;
    
    private this() {
        // Private constructor to enforce singleton pattern
    }
    
    public static TestScreen getInstance() {
        if (_instance is null) {
            _instance = new TestScreen();
        }
        return _instance;
    }
    
    void initialize() {
        writeln("TestScreen initialized");
        
        // Initialize player at center of screen
        player = Player.create(400, 300);
        player.initialize(400, 300);
    }
    
    void update(float deltaTime) {
        // Update player
        player.update(deltaTime);
        
        // Simple ground collision for testing
        if (!player.vars.isGrounded && player.vars.yPosition >= 400) {
            player.vars.yPosition = 400;
            player.vars.isGrounded = true;
            player.vars.updateGroundSpeedFromSpeeds();
        }
        
        // Debug controls
        if (IsKeyPressed(KeyboardKey.KEY_SPACE)) {
            writeln("Space key pressed in TestScreen!");
            // Example: Test CSV loading
            auto testData = CSVLoader.loadCSVInt("resources/data/levels/LEVEL_0/LEVEL_0_Ground_1.csv");
            if (testData.length > 0) {
                writeln("Loaded CSV with ", cast(int)testData.length, " rows and ", cast(int)testData[0].length, " columns");
                writeln("First few values: ", testData[0][0], ", ", testData[0][1], ", ", testData[0][2]);
            }
        }
        
        // Test level layers loading
        if (IsKeyPressed(KeyboardKey.KEY_C)) {
            writeln("C key pressed - Testing CSV loader...");
            auto testData = CSVLoader.loadCSVInt("resources/data/levels/LEVEL_0/LEVEL_0_Ground_1.csv");
            if (testData.length > 0) {
                writeln("CSV loaded successfully! Data size: ", testData.length, " rows");
                if (testData[0].length > 0) {
                  writeln("    First row has ", cast(int)testData[0].length, " columns");
                  writeln("    First few values: ", testData[0][0..3]);
                }
            }
        }

        if (IsKeyPressed(KeyboardKey.KEY_L)) {
            writeln("L key pressed - Testing level layer loading...");
            string[] layerNames = ["LEVEL_0_Ground_1", "LEVEL_0_SemiSolid_1", "LEVEL_0_Objects_1"];
            auto levelLayers = CSVLoader.loadLevelLayers("resources/data/levels/LEVEL_0", layerNames);
            writeln("Loaded ", levelLayers.length, " layers");
            foreach (layerName, layerData; levelLayers) {
                writeln("  Layer '", layerName, "' has ", layerData.length, " rows");
            }
        }
        
        // Debug player info
        if (IsKeyPressed(KeyboardKey.KEY_P)) {
            player.debugPrint();
        }
    }
    
    void draw() {
        // Drawing logic for the test screen
        DrawText("This is the Test Screen", 100, 100, 20, Colors.RAYWHITE);
        DrawText("Press SPACE to test CSV loading", 100, 150, 20, Colors.RAYWHITE);
        DrawText("Press P to print player debug info", 100, 170, 20, Colors.RAYWHITE);
        DrawText("Use ARROW KEYS or WASD to move player", 100, 190, 20, Colors.RAYWHITE);
        
        // Draw ground line
        DrawLine(0, 400, 800, 400, Colors.WHITE);
        
        // Draw player
        player.draw();
        
        // Example: Draw a rectangle
        DrawRectangle(200, 200, 50, 50, Colors.RED);
        
        // Get mouse position in virtual coordinates
        Vector2 mousePos = GetMousePositionVirtual();
        DrawText(toStringz("Mouse X: " ~ to!string(mousePos.x)), 10, 30, 20, Colors.GREEN);
        DrawText(toStringz("Mouse Y: " ~ to!string(mousePos.y)), 10, 50, 20, Colors.GREEN);
        
        // Draw player info
        DrawText(toStringz("Player State: " ~ to!string(player.state)), 10, 70, 20, Colors.YELLOW);
        DrawText(toStringz("Position: (" ~ to!string(cast(int)player.vars.xPosition) ~ ", " ~ to!string(cast(int)player.vars.yPosition) ~ ")"), 10, 90, 20, Colors.YELLOW);
        DrawText(toStringz("Speed: (" ~ to!string(player.vars.xSpeed) ~ ", " ~ to!string(player.vars.ySpeed) ~ ")"), 10, 110, 20, Colors.YELLOW);
        DrawText(toStringz("Ground Speed: " ~ to!string(player.vars.groundSpeed)), 10, 130, 20, Colors.YELLOW);
        DrawText(toStringz("Grounded: " ~ to!string(player.vars.isGrounded)), 10, 150, 20, Colors.YELLOW);
    }
    
    void unload() {
        writeln("TestScreen unloaded");
    }
}