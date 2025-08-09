
module screens.palette_swap_test_screen;

import raylib;
import std.stdio;
import std.string : toStringz;
import std.conv : to;
import world.screen_state;
import world.screen_manager;
import world.input_manager;
import sprite.sprite_manager;
import entity.sprite_object;
import palette.palette_manager;

class PaletteSwapTestScreen : IScreen {
    private static PaletteSwapTestScreen _instance;
    private SpriteObject originalSprite;
    private SpriteObject swappedSprite;
    private int currentColumn = 0; // 0 = original, others = palette columns
    private int numColumns = 1;
    private Texture2D paletteTexture;
    private bool initialized = false;

    static PaletteSwapTestScreen getInstance() {
        if (_instance is null) {
            _instance = new PaletteSwapTestScreen();
        }
        return _instance;
    }

    void initialize() {
        if (initialized) return;
        writeln("PaletteSwapTestScreen initialized");
        import std.string : toStringz;
        // Load Sonic sprite (original)
        Texture2D sonicTex = LoadTexture("resources/image/spritesheet/Sonic.png".toStringz);
        originalSprite = SpriteObject(sonicTex, Vector2(400, 180), 0, "Sonic", SpriteObjectType.PLAYER);
        originalSprite.setScale(4.0f);
        originalSprite.setPosition(Vector2(400, 180));
        originalSprite.setVisible(true);

        // Create a swapped sprite (copy of original)
        swappedSprite = SpriteObject(sonicTex, Vector2(400, 180), 1, "SonicSwapped", SpriteObjectType.PLAYER);
        swappedSprite.setScale(4.0f);
        swappedSprite.setPosition(Vector2(400, 180));
        swappedSprite.setVisible(true);

        // Load palette image for display
        paletteTexture = LoadTexture("resources/image/palette/Sonic_palette.png".toStringz);
        // Calculate number of columns (palette width = number of columns)
        numColumns = paletteTexture.width;
        writefln("Detected %d palette columns", numColumns);
        initialized = true;
        // Ensure swappedSprite starts as a copy of the original
        resetSwappedSprite();
    }

    void resetSwappedSprite() {
        // Unload previous swapped texture if needed
        if (swappedSprite.texture.id != 0 && swappedSprite.texture.id != originalSprite.texture.id) {
            UnloadTexture(swappedSprite.texture);
        }
        // Reload from original
        import std.string : toStringz;
        Texture2D sonicTex = LoadTexture("resources/image/spritesheet/Sonic.png".toStringz);
        swappedSprite.texture = sonicTex;
    }

    void update(float deltaTime) {
        bool changed = false;
        int newColumn = currentColumn;
        
        // Check number keys 0-9 for direct column selection
        if (IsKeyPressed(KeyboardKey.KEY_ZERO)) {
            newColumn = 0;
        } else if (IsKeyPressed(KeyboardKey.KEY_ONE)) {
            newColumn = 1;
        } else if (IsKeyPressed(KeyboardKey.KEY_TWO)) {
            newColumn = 2;
        } else if (IsKeyPressed(KeyboardKey.KEY_THREE)) {
            newColumn = 3;
        } else if (IsKeyPressed(KeyboardKey.KEY_FOUR)) {
            newColumn = 4;
        } else if (IsKeyPressed(KeyboardKey.KEY_FIVE)) {
            newColumn = 5;
        } else if (IsKeyPressed(KeyboardKey.KEY_SIX)) {
            newColumn = 6;
        } else if (IsKeyPressed(KeyboardKey.KEY_SEVEN)) {
            newColumn = 7;
        } else if (IsKeyPressed(KeyboardKey.KEY_EIGHT)) {
            newColumn = 8;
        } else if (IsKeyPressed(KeyboardKey.KEY_NINE)) {
            newColumn = 9;
        }
        
        // Keep left/right arrow functionality for convenience
        if (IsKeyPressed(KeyboardKey.KEY_LEFT) || IsKeyPressed(KeyboardKey.KEY_A)) {
            if (currentColumn > 0) {
                newColumn = currentColumn - 1;
            }
        }
        if (IsKeyPressed(KeyboardKey.KEY_RIGHT) || IsKeyPressed(KeyboardKey.KEY_D)) {
            if (currentColumn < numColumns - 1) {
                newColumn = currentColumn + 1;
            }
        }
        
        // Only change if the new column is valid and different
        if (newColumn != currentColumn && newColumn >= 0 && newColumn < numColumns) {
            writefln("Changing from column %d to %d", currentColumn, newColumn);
            currentColumn = newColumn;
            changed = true;
        }
        
        // Check for level test screen switch
        if (IsKeyPressed(KeyboardKey.KEY_L)) {
            import world.screen_manager;
            import world.screen_state;
            ScreenManager.getInstance().changeState(ScreenState.LEVEL_TEST);
            return;
        }
        
        if (changed) {
            if (currentColumn == 0) {
                // Restore original
                resetSwappedSprite();
            } else {
                // Apply palette swap for selected column
                resetSwappedSprite();
                PaletteManager paletteManager = PaletteManager.getInstance();
                paletteManager.loadPaletteImage("resources/image/palette/Sonic_palette.png");
                paletteManager.applyPalette(&swappedSprite, currentColumn); // Pass column index
            }
        }
    }

    void draw() {
        ClearBackground(Color(30,30,30,255));
        DrawText("Palette Swap Test", 10, 10, 24, Colors.WHITE);
        DrawText("Press number keys 0-9 to select palette column", 10, 40, 16, Colors.LIGHTGRAY);
        DrawText("Or use LEFT/A and RIGHT/D to navigate", 10, 60, 16, Colors.LIGHTGRAY);
        DrawText("Press L to switch to Level Test Screen", 10, 80, 16, Colors.LIGHTGRAY);
        DrawText(("Current Palette Column: " ~ currentColumn.to!string ~ " / " ~ (numColumns-1).to!string).toStringz, 10, 110, 16, Colors.YELLOW);

        // Draw palette image with highlight for active column
        DrawText("Palette Image:", 10, 140, 16, Colors.LIGHTGRAY);
        DrawTextureEx(paletteTexture, Vector2(10, 160), 0.0f, 4.0f, Colors.WHITE);
        // Draw highlight box around active column (1px per column, 4x scale)
        int highlightX = 10 + currentColumn * 4; // 1px per column, 4x scale
        DrawRectangleLines(highlightX, 160, 4, paletteTexture.height * 4, Colors.YELLOW);

        // Draw Sonic sprite (original or palette swapped)
        if (currentColumn == 0) {
            originalSprite.draw();
        } else {
            swappedSprite.draw();
        }

        // Draw info
        DrawText("Number Keys 0-9: Direct Column | Left/Right: Navigate | 0 = Original", 10, 400, 18, Colors.LIGHTGRAY);
    }

    void unload() {
        writeln("PaletteSwapTestScreen unloaded");
        if (paletteTexture.id != 0) {
            UnloadTexture(paletteTexture);
        }
        if (originalSprite.texture.id != 0) {
            UnloadTexture(originalSprite.texture);
        }
        if (swappedSprite.texture.id != 0 && swappedSprite.texture.id != originalSprite.texture.id) {
            UnloadTexture(swappedSprite.texture);
        }
        initialized = false;
    }
}