module screens.level_test_screen;

import raylib;
import std.stdio;
import std.format;
import std.string : toStringz;
import world.screen_manager;
import world.input_manager;
import world.level;
import world.level_list;
import utils.level_loader;

/**
 * Level Test Screen for Presto Framework
 * 
 * Demonstrates the level loading and rendering system.
 * Allows testing of tile layers, object placement, and collision detection.
 */
class LevelTestScreen : IScreen {
    private static LevelTestScreen _instance;
    
    // Managers
    private InputManager inputManager;
    private Level levelManager;
    
    // Test state
    private LevelNumber currentLevelNum = LevelNumber.LEVEL0;
    private ActNumber currentActNum = ActNumber.ACT1;
    private bool showInstructions = true;
    
    private this() {
        inputManager = InputManager.getInstance();
        levelManager = Level.getInstance();
    }
    
    static LevelTestScreen getInstance() {
        if (_instance is null) {
            _instance = new LevelTestScreen();
        }
        return _instance;
    }
    
    void initialize() {
        writeln("LevelTestScreen initialized - Level Loading Demo");
        
        // Try to load the first level
        if (!levelManager.loadLevel(currentLevelNum, currentActNum)) {
            writeln("Warning: Could not load default level, creating empty level for demo");
        }
        
        writeln("LevelTestScreen: Use number keys to load different levels");
        writeln("LevelTestScreen: Use WASD to move camera, F1 to toggle collision view");
    }
    
    void update(float deltaTime) {
        // Handle level switching
        if (IsKeyPressed(KeyboardKey.KEY_ONE)) {
            switchLevel(LevelNumber.LEVEL0, ActNumber.ACT1);
        }
        if (IsKeyPressed(KeyboardKey.KEY_TWO)) {
            switchLevel(LevelNumber.LEVEL1, ActNumber.ACT1);
        }
        if (IsKeyPressed(KeyboardKey.KEY_THREE)) {
            switchLevel(LevelNumber.LEVEL2, ActNumber.ACT1);
        }
        if (IsKeyPressed(KeyboardKey.KEY_FOUR)) {
            switchLevel(LevelNumber.LEVEL3, ActNumber.ACT1);
        }
        
        // Handle act switching
        if (IsKeyPressed(KeyboardKey.KEY_Q)) {
            switchLevel(currentLevelNum, ActNumber.ACT1);
        }
        if (IsKeyPressed(KeyboardKey.KEY_E)) {
            switchLevel(currentLevelNum, ActNumber.ACT2);
        }
        if (IsKeyPressed(KeyboardKey.KEY_R)) {
            switchLevel(currentLevelNum, ActNumber.ACT3);
        }
        
        // Toggle instructions
        if (IsKeyPressed(KeyboardKey.KEY_H)) {
            showInstructions = !showInstructions;
        }
        
        // Return to palette swap test screen
        if (IsKeyPressed(KeyboardKey.KEY_ESCAPE)) {
            import world.screen_manager;
            import world.screen_state;
            ScreenManager.getInstance().changeState(ScreenState.PALETTE_SWAP_TEST);
            return;
        }
        
        // Convert CSV to RVW
        if (IsKeyPressed(KeyboardKey.KEY_C)) {
            convertCurrentLevelToRVW();
        }
        
        // Update level
        levelManager.update(deltaTime);
        
        // Test collision detection at mouse position
        static bool showMouseCollision = false;
        if (IsKeyPressed(KeyboardKey.KEY_M)) {
            showMouseCollision = !showMouseCollision;
        }
        
        if (showMouseCollision) {
            Vector2 mousePos = GetMousePosition();
            // Convert screen mouse to world position (simplified)
            Camera2D camera = levelManager.getCamera();
            float worldX = mousePos.x + camera.target.x - camera.offset.x;
            float worldY = mousePos.y + camera.target.y - camera.offset.y;
            
            bool isSolid = levelManager.isSolidAtPosition(worldX, worldY);
            if (isSolid) {
                writeln("Mouse collision detected at world pos: (", worldX, ", ", worldY, ")");
            }
        }
    }
    
    void draw() {
        // Clear background
        ClearBackground(Color(20, 20, 40, 255)); // Dark blue background
        
        if (levelManager.isLoaded()) {
            // Draw the level
            levelManager.draw();
        } else {
            // Show level loading error
            DrawText("No Level Loaded", 400 - 80, 224 - 10, 20, Colors.RED);
            DrawText("Try pressing 1-4 to load test levels", 400 - 120, 224 + 15, 16, Colors.WHITE);
        }
        
        // Draw UI overlay
        drawUI();
    }
    
    private void drawUI() {
        // Semi-transparent background for UI
        DrawRectangle(0, 0, 800, 60, Color(0, 0, 0, 150));
        
        // Current level info
        string levelInfo = format("Level %d-%d", cast(int)currentLevelNum + 1, cast(int)currentActNum);
        DrawText(levelInfo.toStringz, 10, 10, 20, Colors.WHITE);
        
        if (levelManager.isLoaded()) {
            LevelData level = levelManager.getCurrentLevel();
            string detailInfo = format("Size: %dx%d, Objects: %d", 
                                     level.width, level.height, level.objects.length);
            DrawText(detailInfo.toStringz, 10, 35, 14, Colors.LIGHTGRAY);
        }
        
        // Level loading status
        string statusText = levelManager.isLoaded() ? "LOADED" : "NOT LOADED";
        Color statusColor = levelManager.isLoaded() ? Colors.GREEN : Colors.RED;
        DrawText(statusText.toStringz, 200, 10, 16, statusColor);
        
        // Instructions
        if (showInstructions) {
            drawInstructions();
        } else {
            DrawText("Press H for help", 700, 10, 12, Colors.YELLOW);
        }
    }
    
    private void drawInstructions() {
        // Instructions background
        DrawRectangle(0, 70, 800, 180, Color(0, 0, 0, 180));
        
        int y = 80;
        int lineHeight = 18;
        
        DrawText("LEVEL TEST CONTROLS:", 10, y, 16, Colors.YELLOW);
        y += lineHeight + 5;
        
        DrawText("1-4: Load Level 1-4", 10, y, 14, Colors.WHITE);
        y += lineHeight;
        
        DrawText("Q/E/R: Switch to Act 1/2/3", 10, y, 14, Colors.WHITE);
        y += lineHeight;
        
        DrawText("WASD: Move Camera", 10, y, 14, Colors.WHITE);
        y += lineHeight;
        
        DrawText("F1: Toggle Collision View", 10, y, 14, Colors.WHITE);
        y += lineHeight;
        
        DrawText("M: Toggle Mouse Collision Test", 10, y, 14, Colors.WHITE);
        y += lineHeight;
        
        DrawText("H: Toggle Help", 10, y, 14, Colors.WHITE);
        y += lineHeight;
        
        DrawText("C: Convert current level CSV to RVW", 10, y, 14, Colors.WHITE);
        y += lineHeight;
        
        DrawText("ESC: Return to Palette Test", 10, y, 14, Colors.WHITE);
        y += lineHeight;
        
        // Level system info
        DrawText("LEVEL SYSTEM INFO:", 400, 80, 16, Colors.YELLOW);
        y = 105;
        
        DrawText("- Supports multiple tile layers", 400, y, 12, Colors.LIGHTGRAY);
        y += 15;
        
        DrawText("- CSV-based level data", 400, y, 12, Colors.LIGHTGRAY);
        y += 15;
        
        DrawText("- Object placement system", 400, y, 12, Colors.LIGHTGRAY);
        y += 15;
        
        DrawText("- Collision detection", 400, y, 12, Colors.LIGHTGRAY);
        y += 15;
        
        DrawText("- Level caching for performance", 400, y, 12, Colors.LIGHTGRAY);
        y += 15;
    }
    
    private void switchLevel(LevelNumber levelNum, ActNumber actNum) {
        currentLevelNum = levelNum;
        currentActNum = actNum;
        
        writeln("Attempting to load Level ", cast(int)levelNum + 1, "-", cast(int)actNum);
        
        if (levelManager.loadLevel(levelNum, actNum)) {
            writeln("Successfully loaded Level ", cast(int)levelNum + 1, "-", cast(int)actNum);
        } else {
            writeln("Failed to load Level ", cast(int)levelNum + 1, "-", cast(int)actNum);
            writeln("Note: This is expected if level files don't exist yet");
        }
    }
    
    private void convertCurrentLevelToRVW() {
        import utils.csv_converter;
        import std.string : toStringz;
        import std.file : mkdirRecurse;
        
        string levelFolder = format("LEVEL_%d", cast(int)currentLevelNum);
        
        // Create build/levels directory if it doesn't exist
        mkdirRecurse("build/levels");
        
        string rvwFileName = format("build/levels/%s.rvw", levelFolder);
        
        writeln("Converting ", levelFolder, " to RVW format...");
        writeln("Output file: ", rvwFileName);
        
        bool success = ConvertCSV2RVW(rvwFileName.toStringz, 0, levelFolder);
        
        if (success) {
            writeln("Successfully converted ", levelFolder, " to RVW format!");
            writeln("RVW file created: ", rvwFileName);
        } else {
            writeln("Failed to convert ", levelFolder, " to RVW format");
        }
    }
    
    void unload() {
        levelManager.unloadLevel();
        writeln("LevelTestScreen unloaded");
    }
}
