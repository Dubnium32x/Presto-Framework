module screens.options_screen;

import raylib;
import std.stdio;
import std.file;
import std.string;

import world.screen_manager;
import world.screen_state;
import app;
import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT;

class OptionItem {
    string key;
    string value;
    bool isBool;
    this(string k, string v) {
        key = k;
        value = v;
        isBool = (v == "true" || v == "false");
    }
    void toggle() {
        if (isBool) value = (value == "true") ? "false" : "true";
    }
}

class OptionsScreen : IScreen {
    OptionItem[] options;
    int selectedOption = 0;
    string iniPath = "options.ini";

    int cameraOffset = 0;
    int visibleOptions = 8;

    Sound moveSound;
    Sound acceptSound;

    this() {
        loadOptions();
        moveSound = LoadSound("resources/sound/sfx/Sonic World Sounds/004.wav");
        acceptSound = LoadSound("resources/sound/sfx/Sonic World Sounds/022.wav");
    }

    void initialize() {
        selectedOption = 0;
        loadOptions();
    }

    void loadOptions() {
        options = [];
        if (exists(iniPath)) {
            foreach (line; File(iniPath).byLine()) {
                auto parts = line.idup.split("=");
                if (parts.length == 2) {
                    options ~= new OptionItem(parts[0].strip, parts[1].strip);
                }
            }
        } else {
            options ~= new OptionItem("No options.ini found!", "");
        }
    }

    void saveOptions() {
        auto file = File(iniPath, "w");
        foreach (opt; options) {
            file.writefln("%s=%s", opt.key, opt.value);
        }
        file.close();
    }

    void update(float deltaTime) {
        import world.audio_manager;
        if (IsKeyPressed(KeyboardKey.KEY_DOWN)) {
            selectedOption = cast(int)((selectedOption + 1) % options.length);
            if (selectedOption - cameraOffset >= visibleOptions) {
                cameraOffset = selectedOption - visibleOptions + 1;
            } else if (selectedOption == 0) {
                cameraOffset = 0;
            }
            AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic World Sounds/004.wav");
        } else if (IsKeyPressed(KeyboardKey.KEY_UP)) {
            selectedOption = cast(int)((selectedOption - 1 + options.length) % options.length);
            if (selectedOption < cameraOffset) {
                cameraOffset = selectedOption;
            } else if (selectedOption == options.length - 1) {
                cameraOffset = cast(int)(options.length - visibleOptions);
                if (cameraOffset < 0) cameraOffset = 0;
            }
            AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic World Sounds/004.wav");
        }
        // Toggle boolean option with left/right
        if (IsKeyPressed(KeyboardKey.KEY_LEFT) || IsKeyPressed(KeyboardKey.KEY_RIGHT)) {
            options[selectedOption].toggle();
            AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic World Sounds/004.wav");
        }
        // Accept: S key (save changes)
        if (IsKeyPressed(KeyboardKey.KEY_S)) {
            saveOptions();
            AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic World Sounds/022.wav");
        }
        // Back: A key
        if (IsKeyPressed(KeyboardKey.KEY_A)) {
            import world.screen_manager;
            import world.screen_state;
            AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic World Sounds/002.wav");
            ScreenManager.getInstance().changeState(ScreenState.TITLE);
        }
    }

    void draw() {
        ClearBackground(Colors.WHITE);
        float fontSize = 12.0f;
        float lineHeight = 18.0f;
        float maxWidth = 0;
        foreach (opt; options) {
            string display = opt.key ~ ": " ~ opt.value;
            float w = MeasureTextEx(fontFamily[2], display.toStringz(), fontSize, 1.0f).x;
            if (w > maxWidth) maxWidth = w;
        }
        float startX = (VIRTUAL_SCREEN_WIDTH - maxWidth) / 2.0f;
        float startY = 60.0f;
        // Draw title
        string title = "OPTIONS";
        float titleWidth = MeasureTextEx(fontFamily[2], title.toStringz(), 18, 1.0f).x;
        DrawTextEx(fontFamily[2], title.toStringz(), Vector2((VIRTUAL_SCREEN_WIDTH - titleWidth) / 2, 20), 18, 1.0f, Colors.BLACK);
        // Draw camera viewport
        DrawRectangle(cast(int)(startX - 12), cast(int)(startY - 4), cast(int)(maxWidth + 24), cast(int)(visibleOptions * lineHeight), Color(220, 220, 220, 40));
        for (int i = cameraOffset; i < cameraOffset + visibleOptions && i < options.length; ++i) {
            string display = options[i].key ~ ": " ~ options[i].value;
            float textWidth = MeasureTextEx(fontFamily[2], display.toStringz(), fontSize, 1.0f).x;
            float textX = startX;
            float textY = startY + (i - cameraOffset) * lineHeight;
            if (i == selectedOption) {
                DrawRectangle(cast(int)(textX - 8), cast(int)(textY - 2), cast(int)(maxWidth + 16), cast(int)(lineHeight), Color(220, 220, 40, 120));
            }
            DrawTextEx(fontFamily[2], display.toStringz(), Vector2(textX, textY), fontSize, 1.0f, (i == selectedOption) ? Colors.BLUE : Colors.BLACK);
        }
        // Draw up/down triangle indicators if more options above/below
        Texture2D triTextureUp = LoadTexture("resources/image/spritesheet/pointerUp.png");
        Texture2D triTextureDown = LoadTexture("resources/image/spritesheet/pointerDown.png");
        float triScale = 1.0f;
        float triX = startX - 24;
        if (cameraOffset > 0) {
            DrawTextureEx(triTextureUp, Vector2(triX, startY), 0.0f, triScale, Colors.WHITE);
        }
        if (cameraOffset + visibleOptions < options.length) {
            DrawTextureEx(triTextureDown, Vector2(triX, startY + visibleOptions * lineHeight), 0.0f, triScale, Colors.WHITE);
        }
        string help = "S: Save   A: Back   Left/Right: Toggle";
        float helpWidth = MeasureTextEx(fontFamily[2], help.toStringz(), fontSize, 1.0f).x;
        DrawTextEx(fontFamily[2], help.toStringz(), Vector2((VIRTUAL_SCREEN_WIDTH - helpWidth) / 2, VIRTUAL_SCREEN_HEIGHT - 12), fontSize, 1.0f, Colors.DARKGRAY);
    }

    void unload() {
        if (moveSound.frameCount != 0) {
            UnloadSound(moveSound);
            moveSound = Sound.init;
        }
        if (acceptSound.frameCount != 0) {
            UnloadSound(acceptSound);
            acceptSound = Sound.init;
        }
    }
}

