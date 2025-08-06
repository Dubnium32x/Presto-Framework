module screens.test_screen;

import raylib;
import std.stdio;
import std.string;
import std.conv : to;
import world.screen_state;
import world.screen_manager : IScreen;
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
            // Example: Transition to another screen
            //ScreenManager.getInstance().transitionToState(ScreenState.ANOTHER_SCREEN, TransitionType.FADE, 1.0f);
        }
    }
    
    void draw() {
        // Drawing logic for the test screen
        DrawText("This is the Test Screen", 100, 100, 20, Colors.RAYWHITE);
        DrawText("Press SPACE to print a message", 100, 150, 20, Colors.RAYWHITE);
        
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