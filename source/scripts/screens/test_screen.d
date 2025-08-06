module screens.test_screen;

import raylib;
import std.stdio;
import std.string;
import std.conv : to;
import world.screen_state;
import world.screen_manager : IScreen;
import utils.csv_loader;
import app;

class TestScreen : IScreen {
    private static TestScreen _instance;
    
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
    }
    
    void update(float deltaTime) {
        // Update logic for the test screen
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
    }
    
    void draw() {
        // Drawing logic for the test screen
        DrawText("This is the Test Screen", 100, 100, 20, Colors.RAYWHITE);
        DrawText("Press SPACE to test CSV loading", 100, 150, 20, Colors.RAYWHITE);
        DrawText("Press L to test level layer loading", 100, 170, 20, Colors.RAYWHITE);
        
        // Example: Draw a rectangle
        DrawRectangle(200, 200, 50, 50, Colors.RED);
        
        // Get mouse position in virtual coordinates
        Vector2 mousePos = GetMousePositionVirtual();
        DrawText(toStringz("Mouse X: " ~ to!string(mousePos.x)), 10, 30, 20, Colors.GREEN);
        DrawText(toStringz("Mouse Y: " ~ to!string(mousePos.y)), 10, 50, 20, Colors.GREEN);
    }
    
    void unload() {
        writeln("TestScreen unloaded");
    }
}