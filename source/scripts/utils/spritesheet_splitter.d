module utils.spritesheet_splitter;

import raylib;

import std.array;
import std.range;
import std.algorithm;
import std.conv;
import std.stdio : writeln;

// This module provides utilities for splitting spritesheets into individual frames
class SpriteSheetSplitter {
    // Splits a spritesheet texture into individual frames based on the specified frame size
    static Texture2D[] split(Texture2D spritesheet, int frameWidth, int frameHeight) {
        if (spritesheet.width <= 0 || spritesheet.height <= 0) {
            writeln("[ERROR] Invalid spritesheet dimensions: ", spritesheet.width, "x", spritesheet.height);
            return [];
        }

        int cols = spritesheet.width / frameWidth;
        int rows = spritesheet.height / frameHeight;

        Texture2D[] frames = new Texture2D[cols * rows];
        for (int y = 0; y < rows; y++) {
            for (int x = 0; x < cols; x++) {
                Rectangle sourceRec = Rectangle(
                    x * frameWidth, y * frameHeight,
                    frameWidth, frameHeight
                );
                // Extract sub-image using ImageFromImage and load as texture
                Image sheetImage = LoadImageFromTexture(spritesheet);
                Image frameImage = ImageFromImage(sheetImage, sourceRec);
                frames[y * cols + x] = LoadTextureFromImage(frameImage);
                UnloadImage(frameImage);
                UnloadImage(sheetImage);
            }
        }
        return frames;
    }
}