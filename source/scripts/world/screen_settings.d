module screen_settings;

import raylib;
import std.stdio;
import std.string;
import std.file;
import std.algorithm;
import std.conv;
import std.array;

import parser.csv_tile_loader; // Import the CSV tile loader
import screen_states;
import screen_manager;

class ScreenSettings {
    int screenWidth;
    int screenHeight;
    int virtualWidth;
    int virtualHeight;
    int screenScale;
    bool fullscreen;
    bool vsync;

    this(int screenWidth, int screenHeight, int virtualWidth, int virtualHeight) {
        this.screenWidth = screenWidth;
        this.screenHeight = screenHeight;
        this.virtualWidth = virtualWidth;
        this.virtualHeight = virtualHeight;
        this.screenScale = 1; // Default scale
        this.fullscreen = false;
        this.vsync = false;
    }

    void setScreenSize(int width, int height) {
        this.screenWidth = width;
        this.screenHeight = height;
        SetWindowSize(width, height);
    }

    void setVirtualSize(int width, int height) {
        this.virtualWidth = width;
        this.virtualHeight = height;
    }

    void setScreenScale(int scale) {
        this.screenScale = scale;
    }
}

