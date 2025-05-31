module world.tileset_manager;

import raylib; // Assuming raylib is used for Texture2D, Vector2, Rectangle, etc.
import std.stdio;
import std.string;
import std.conv;
import std.path;
import std.file;
import core.stdc.config; // For C's `size_t` if needed by Raylib-D bindings

// Placeholder for LayerType if it's defined elsewhere or needs to be defined
// enum LayerType { Ground, SemiSolid, Objects, Hazards, ... }

class TilesetManager {
    // We'll need a way to store the loaded textures.
    // A dictionary mapping a tileset name or ID to a Texture2D might work.
    private Texture2D[string] tilesetImages;

    // Tile dimensions (in pixels)
    private int tileWidth;
    private int tileHeight;

    this(int tw, int th) {
        this.tileWidth = tw;
        this.tileHeight = th;
        this.tilesetImages = typeof(this.tilesetImages).init; // D idiomatic way to initialize
        writeln("TilesetManager initialized with tile dimensions: ", tw, "x", th, "px.");
    }

    // Method to load a tileset image
    // tilesetName could be "ground", "objects", etc.
    // filePath would be the path to the image file.
    void loadTileset(string tilesetName, string filePath) {
        if (!std.file.exists(filePath)) {
            stderr.writeln("TilesetManager Error: File not found - ", filePath);
            // Optionally, load a default "missing" texture here
            return;
        }
        Texture2D texture = LoadTexture(filePath.toStringz);
        if (texture.id == 0) { // Check if loading failed (Raylib textures have id > 0 on success)
            stderr.writeln("TilesetManager Error: Failed to load texture - ", filePath);
            // Again, handle missing texture
        } else {
            tilesetImages[tilesetName] = texture;
            writeln("TilesetManager: Loaded tileset '", tilesetName, "' from '", filePath, "' (ID: ", texture.id, ", W: ", texture.width, ", H: ", texture.height, ")");
        }
    }

    // Method to get a specific tile's source rectangle from a tileset
    // This will depend heavily on how tile IDs are mapped.
    // For a simple grid layout:
    // Assumes tileset textures are organized in a grid, e.g., a 256x224px texture for 16x16px tiles would be 16 tiles wide, 14 tiles tall.
    Rectangle getTileSourceRect(string tilesetName, int tileId) {
        if (tilesetName !in tilesetImages) {
            stderr.writeln("TilesetManager Error: Tileset '", tilesetName, "' not loaded.");
            return Rectangle(0, 0, cast(float)tileWidth, cast(float)tileHeight); // Default/error rect
        }

        Texture2D tileset = tilesetImages[tilesetName];
        int tilesPerRow = tileset.width / tileWidth;
        // int tilesPerCol = tileset.height / tileHeight; // Not strictly needed for this calculation

        if (tilesPerRow == 0) { // Avoid division by zero if tileWidth > texture.width
             stderr.writeln("TilesetManager Error: tileWidth is greater than texture width for '", tilesetName, "'.");
             return Rectangle(0, 0, cast(float)tileWidth, cast(float)tileHeight);
        }

        int tileX = (tileId % tilesPerRow) * tileWidth;
        int tileY = (tileId / tilesPerRow) * tileHeight; // Integer division gives the row index

        return Rectangle(cast(float)tileX, cast(float)tileY, cast(float)tileWidth, cast(float)tileHeight);
    }

    // Method to draw a specific tile from a loaded tileset at a given screen position
    void drawTile(string tilesetName, int tileIndex, float x, float y, bool flipHorizontal, bool flipVertical) {
        if (tileIndex < 0) return; // Do not draw negative indices (e.g. empty tiles)

        if (tilesetName !in tilesetImages) {
            // stderr.writeln("TilesetManager Error: Attempted to draw from unloaded tileset: ", tilesetName);
            return;
        }

        Texture2D textureToDraw = tilesetImages[tilesetName];
        if (textureToDraw.id == 0) { // Check if texture is valid
            // stderr.writeln("TilesetManager Error: Texture not valid for tileset: ", tilesetName);
            return;
        }

        int tilesPerRow = textureToDraw.width / this.tileWidth;
        // int tilesPerCol = tsInfo.texture.height / this.tileHeight; // Not strictly needed for this calculation

        if (tilesPerRow == 0) { // Avoid division by zero if texture width is less than tileWidth
             stderr.writeln("TilesetManager Error: tilesPerRow is 0 for tileset '", tilesetName, "'. Texture width: ", textureToDraw.width, ", Tile width: ", this.tileWidth);
             return;
        }

        int tileX = (tileIndex % tilesPerRow) * this.tileWidth;
        int tileY = (tileIndex / tilesPerRow) * this.tileHeight;

        Rectangle sourceRec;
        sourceRec.x = cast(float)tileX;
        sourceRec.y = cast(float)tileY;
        sourceRec.width = cast(float)this.tileWidth;
        sourceRec.height = cast(float)this.tileHeight;

        // Apply flips by negating sourceRec width/height
        if (flipHorizontal) {
            sourceRec.width = -sourceRec.width;
        }
        if (flipVertical) {
            sourceRec.height = -sourceRec.height;
        }

        Rectangle destRec;
        destRec.x = x;
        destRec.y = y;
        destRec.width = cast(float)this.tileWidth;
        destRec.height = cast(float)this.tileHeight;
        
        // writeln("Drawing tile from '", tilesetName, "' index ", tileIndex, " at ", x, ",", y, " HFlip: ", flipHorizontal, " VFlip: ", flipVertical);
        // writeln("SourceRec: x=", sourceRec.x, " y=", sourceRec.y, " w=", sourceRec.width, " h=", sourceRec.height);
        // writeln("DestRec: x=", destRec.x, " y=", destRec.y, " w=", destRec.width, " h=", destRec.height);


        DrawTexturePro(textureToDraw, sourceRec, destRec, Vector2(0, 0), 0.0f, Colors.WHITE);
    }

    // Method to unload all textures when the game closes or level changes
    void unloadAllTilesets() {
        foreach (name, texture; tilesetImages) {
            UnloadTexture(texture);
            writeln("TilesetManager: Unloaded tileset '", name, "'");
        }
        tilesetImages = typeof(tilesetImages).init; // D idiomatic way to clear/reinitialize
    }

    // Destructor to ensure textures are unloaded
    ~this() {
        writeln("TilesetManager being destroyed. Unloading all tilesets.");
        unloadAllTilesets();
    }
}

// Example usage (would typically be in your game's main loop or level loading logic)
/*
void main() {
    InitWindow(800, 600, "TilesetManager Test");
    SetTargetFPS(60);

    // Initialize TilesetManager with tile dimensions (e.g., 16x16 pixels)
    auto tm = new TilesetManager(16, 16);

    // Load tilesets - paths would be relative to your executable or absolute
    // Adjust paths as necessary.
    // tm.loadTileset("ground", "path/to/your/ground_tiles.png");
    // tm.loadTileset("objects", "path/to/your/objects_tiles.png");

    // Example: Load a test texture (replace with your actual tileset)
    // Create a dummy texture: 16 tiles wide, 14 tiles tall, 16x16px tiles = 256x224px
    Image checkedImage = GenImageChecked(256, 224, 16, 16, Colors.RED, Colors.GREEN);
    Texture2D testTexture = LoadTextureFromImage(checkedImage);
    UnloadImage(checkedImage);
    tm.tilesetImages["test"] = testTexture; // Manually add for this example

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(Colors.RAYWHITE);

        // Draw some test tiles
        if ("test" in tm.tilesetImages) {
            tm.drawTile("test", 0, Vector2(50, 50));    // Tile ID 0
            tm.drawTile("test", 1, Vector2(70, 50));    // Tile ID 1
            tm.drawTile("test", 15, Vector2(90, 50));   // Tile ID 15 (last tile in the first row of a 16-tile wide tileset)
            tm.drawTile("test", 16, Vector2(50, 70));   // Tile ID 16 (first tile in the second row)
            tm.drawTile("test", -1, Vector2(110, 50));  // This tile should not be drawn
        } else {
            DrawText("Failed to load/find 'test' tileset", 10, 10, 20, Colors.RED);
        }


        DrawFPS(GetScreenWidth() - 100, 10);
        EndDrawing();
    }

    tm.unloadAllTilesets(); // Clean up
    CloseWindow();
}
*/

// Helper to convert D string to char* for Raylib functions
private char* toStringz(string s) {
    return cast(char*)s.ptr;
}

