module prestoframework.screen_settings;

import raylib;
import std.stdio : writeln;

class ScreenSettings {
    private int screenWidth;
    private int screenHeight;
    private int virtualWidth;
    private int virtualHeight;
    private float scaleX;
    private float scaleY;

    this(int width = 1280, int height = 720, int virtualWidth = 3480, int virtualHeight = 2160) {
        screenWidth = width;
        screenHeight = height;
        this.virtualWidth = virtualWidth;
        this.virtualHeight = virtualHeight;

        InitWindow(screenWidth, screenHeight, "Presto Framework (WIP)");
        writeln("Screen initialized with resolution: ", screenWidth, "x", screenHeight);
        writeln("Virtual resolution set to: ", virtualWidth, "x", virtualHeight);
    }

    void setResolution(int width, int height) {
        screenWidth = width;
        screenHeight = height;
        SetWindowSize(screenWidth, screenHeight);
        updateScale();
        writeln("Resolution changed to: ", screenWidth, "x", screenHeight);
    }

    void updateScale() {
        scaleX = cast(float)screenWidth / virtualWidth;
        scaleY = cast(float)screenHeight / virtualHeight;
        writeln("Scale updated: scaleX = ", scaleX, ", scaleY = ", scaleY);
    }

    void applyVirtualResolution() {
        BeginDrawing();
        ClearBackground(Colors.BLACK);
        BeginMode2D((Camera2D)(Vector2(0, 0), Vector2(0, 0), 0.0, 1.0));
        rlPushMatrix();
        rlScalef(scaleX, scaleY, 1.0); // Apply scaling based on the virtual resolution
    }

    void endVirtualResolution() {
        rlPopMatrix();
        EndMode2D();
        EndDrawing();
    }

    int getVirtualWidth() { return virtualWidth; }
    int getVirtualHeight() { return virtualHeight; }
    int getScreenWidth() { return screenWidth; }     // Added getter
    int getScreenHeight() { return screenHeight; }    // Added getter
}