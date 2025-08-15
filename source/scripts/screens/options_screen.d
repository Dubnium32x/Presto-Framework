module screens.options_screen;

import raylib;
import std.stdio;
import std.file;
import std.string;
import std.algorithm;

import world.screen_manager;
import world.screen_state;
import world.audio_manager;
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
    bool showFullscreenNote = false;
    float fullscreenNoteTimer = 0.0f;
    enum OptionsScreenState {
        FADE_IN,
        ACTIVE,
        FADE_OUT
    }
    OptionsScreenState state = OptionsScreenState.FADE_IN;
    float transitionAlpha = 255.0f;
    float transitionDuration = 1.2f;
    float transitionTimer = 0.0f;
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
        cameraOffset = 0;
        loadOptions(); // Always reload from options.ini
        AudioManager.getInstance().fadeOutMusic(0.5f);
        state = OptionsScreenState.FADE_IN;
        transitionAlpha = 255.0f;
        transitionTimer = 0.0f;
    }

    void loadOptions() {
        options = [];
        bool fullscreenEnabled = false;
        if (exists(iniPath)) {
            foreach (line; File(iniPath).byLine()) {
                auto parts = line.idup.split("=");
                if (parts.length == 2) {
                    string key = parts[0].strip;
                    string value = parts[1].strip;
                    // Strip quotes from value if present
                    if (value.length > 1 && value[0] == '"' && value[$-1] == '"') {
                        value = value[1 .. $-1];
                    }
                    // Remove colorSwapMethod option
                    if (key == "colorswapmethod") continue;
                    if (key == "fullscreenEnabled" && value == "true") {
                        fullscreenEnabled = true;
                    }
                    // Clamp windowSize to allowed values
                    if (key == "windowSize") {
                        string[] allowedSizes = ["1", "2", "3", "4"];
                        if (allowedSizes.count(value) == 0) {
                            value = allowedSizes[0];
                        }
                    }
                    options ~= new OptionItem(key, value);
                }
            }
        } else {
            options ~= new OptionItem("No options.ini found!", "");
        }
        if (fullscreenEnabled && !IsWindowFullscreen()) {
            ToggleFullscreen();
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
        switch (state) {
            case OptionsScreenState.FADE_IN:
                transitionTimer += deltaTime;
                transitionAlpha = 255.0f - min(transitionTimer / transitionDuration, 1.0f) * 255.0f;
                if (transitionTimer >= transitionDuration) {
                    state = OptionsScreenState.ACTIVE;
                }
                break;
            case OptionsScreenState.ACTIVE:
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
                // Toggle/cycle option with left/right
                if (IsKeyPressed(KeyboardKey.KEY_LEFT) || IsKeyPressed(KeyboardKey.KEY_RIGHT)) {
                    auto opt = options[selectedOption];
                    bool left = IsKeyPressed(KeyboardKey.KEY_LEFT);
                    bool right = IsKeyPressed(KeyboardKey.KEY_RIGHT);
                    // Boolean toggle
                    if (opt.isBool) {
                        opt.toggle();
                        if (opt.key == "sfxEnabled") {
                            AudioManager.getInstance().setSFXEnabled(opt.value == "true");
                        }
                        if (opt.key == "musicEnabled") {
                            AudioManager.getInstance().setMusicEnabled(opt.value == "true");
                        }
                    } else {
                        string[] values;
                        if (opt.key == "cameraType") {
                            values = ["Genesis", "CD", "Pocket"];
                        } else if (opt.key == "levelLoadType") {
                            values = ["JSON", "Binary", "CSV"];
                        } else if (opt.key == "windowSize") {
                            values = ["1", "2", "3", "4"];
                        }
                        if (values.length > 0) {
                            string currentValue = opt.value.strip;
                            // Remove quotes if present
                            if (currentValue.length > 1 && currentValue[0] == '"' && currentValue[$-1] == '"') {
                                currentValue = currentValue[1 .. $-1];
                            }
                            int idx = 0;
                            bool found = false;
                            foreach (i, v; values) {
                                if (v == currentValue) {
                                    idx = cast(int)i;
                                    found = true;
                                    break;
                                }
                            }
                            if (!found) idx = 0;
                            if (left) idx = (idx == 0) ? cast(int)(values.length - 1) : idx - 1;
                            if (right) idx = cast(int)((cast(uint)(idx + 1) % values.length));
                            opt.value = values[idx];
                            // Immediately save valid windowSize to options.ini
                            if (opt.key == "windowSize") {
                                saveOptions();
                            }
                        }
                    }
                    AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic World Sounds/004.wav");
                }
                // Accept: S key (save changes)
                if (IsKeyPressed(KeyboardKey.KEY_S)) {
                    bool fullscreenChanged = false;
                    foreach (opt; options) {
                        if (opt.key == "fullscreen") {
                            static string lastFullscreenValue = "";
                            if (lastFullscreenValue != opt.value) {
                                fullscreenChanged = true;
                                lastFullscreenValue = opt.value;
                            }
                        }
                    }
                    saveOptions();
                    if (fullscreenChanged) {
                        showFullscreenNote = true;
                        fullscreenNoteTimer = 3.0f; // Show for 3 seconds
                    }
                    AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic World Sounds/022.wav");
                }
        // Timer for fullscreen note
        if (showFullscreenNote) {
            fullscreenNoteTimer -= deltaTime;
            if (fullscreenNoteTimer <= 0) {
                showFullscreenNote = false;
            }
        }
                // Back: A key
                if (IsKeyPressed(KeyboardKey.KEY_A)) {
                    AudioManager.getInstance().playSFX("resources/sound/sfx/Sonic World Sounds/002.wav");
                    state = OptionsScreenState.FADE_OUT;
                    transitionAlpha = 0.0f;
                    transitionTimer = 0.0f;
                }
                break;
            case OptionsScreenState.FADE_OUT:
                transitionTimer += deltaTime;
                transitionAlpha = min(transitionTimer / transitionDuration, 1.0f) * 255.0f;
                if (transitionTimer >= transitionDuration) {
                    import world.screen_manager;
                    import world.screen_state;
                    ScreenManager.getInstance().changeState(ScreenState.TITLE);
                }
                break;
            default:
                writeln("ERROR: Unexpected OptionsScreenState: ", state);
                break;
        }
    }

    void draw() {
        ClearBackground(Colors.DARKGRAY);
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
        import sprite.sprite_fonts;
        // Draw title using DiscoveryFont
        string title = "OPTIONS";
        string titleUpper = title.toUpper();
        int titleWidth = 0;
        foreach (ch; titleUpper) {
            if (ch >= 'A' && ch <= 'Z') {
                int idx = ch - 'A';
                titleWidth += discoveryFont.glyphs[idx].width;
            } else if (ch == ' ') {
                titleWidth += 8;
            }
        }
        float titleX = (VIRTUAL_SCREEN_WIDTH - titleWidth) / 2.0f;
        drawDiscoveryText(titleUpper, cast(int)titleX, 20, Colors.WHITE);
        // Draw camera viewport
        DrawRectangle(cast(int)(startX - 12), cast(int)(startY - 4), cast(int)(maxWidth + 24), cast(int)(visibleOptions * lineHeight), Color(220, 220, 220, 40));
        for (int i = cameraOffset; i < cameraOffset + visibleOptions && i < options.length; ++i) {
            string display;
            if (options[i].key == "windowSize") {
                string[] allowedSizes = ["1", "2", "3", "4"];
                string value = options[i].value;
                if (allowedSizes.count(value) == 0) value = allowedSizes[0];
                int shownValue = 1;
                import std.conv : to;
                try {
                    shownValue = to!int(value) - 1;
                } catch (Exception) {
                    shownValue = 1;
                }
                display = options[i].key ~ ": " ~ shownValue.to!string;
            } else {
                display = options[i].key ~ ": " ~ options[i].value;
            }
            // Use smallSonicFont, convert to uppercase for compatibility
            string displayUpper = display.toUpper();
            int textWidth = cast(int)displayUpper.length * smallSonicFont.glyphWidth;
            float textX = (VIRTUAL_SCREEN_WIDTH - textWidth) / 2.0f;
            float textY = startY + (i - cameraOffset) * lineHeight;
            if (i == selectedOption) {
                int highlightPadding = 4;
                int highlightWidth = textWidth + highlightPadding * 2;
                int highlightX = cast(int)(textX - highlightPadding);
                DrawRectangle(highlightX, cast(int)(textY - 2), highlightWidth, cast(int)(lineHeight), Color(220, 220, 40, 120));
            }
            drawSpriteText(smallSonicFont, displayUpper, cast(int)textX, cast(int)textY, (i == selectedOption) ? Colors.WHITE : Colors.BLUE);
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
    DrawTextEx(fontFamily[2], help.toStringz(), Vector2((VIRTUAL_SCREEN_WIDTH - helpWidth) / 2, VIRTUAL_SCREEN_HEIGHT - 12), fontSize, 1.0f, Colors.LIGHTGRAY);

    // Show fullscreen note only if recently changed
    if (showFullscreenNote) {
        string fullscreenNote = "* FULLSCREEN WILL BE APPLIED UPON NEXT RESET";
        float noteWidth = MeasureTextEx(fontFamily[2], fullscreenNote.toStringz(), fontSize, 1.0f).x;
        DrawTextEx(fontFamily[2], fullscreenNote.toStringz(), Vector2((VIRTUAL_SCREEN_WIDTH - noteWidth) / 2, VIRTUAL_SCREEN_HEIGHT - 28), fontSize, 1.0f, Colors.YELLOW);
    }
        // Draw Saturn-style white fade transition
        if (state == OptionsScreenState.FADE_IN || state == OptionsScreenState.FADE_OUT) {
            DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, Color(255, 255, 255, cast(ubyte)transitionAlpha));
        }
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

