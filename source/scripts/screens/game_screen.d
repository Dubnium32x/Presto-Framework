module screens.game_screen;

import raylib;

import std.stdio;
import std.algorithm;
import std.array;
import std.conv;
import std.math;
import std.string;

import world.audio_manager;
import world.screen_manager;
import world.screen_state;
import world.input_manager;
import world.memory_manager;
import sprite.sprite_manager;
import entity.sprite_object;
import entity.player.player;
import sprite.sprite_fonts;
import world.level_list;
import utils.level_loader;

import game.hud;
import game.title_card;

GameState currentState;

enum GameState {
    TITLECARDMOVEIN,
    TITLECARDHOLD,
    TITLECARDFADEOUT,
    PLAYING,
    PAUSED,
    ACTCLEAR,
    GAMEOVER
};

class GameScreen : IScreen {
    HUD hud;
    TitleCard titleCard;

    int score, rings, lives;

    float titleCardTimer = 0.0f;
    this() {
        hud = new HUD();
        titleCard = new TitleCard("ZONE NAME", 1); // TODO: Replace with actual zone/act
        currentState = GameState.TITLECARDMOVEIN;
        titleCardTimer = 0.0f;
    }

    void initialize() {
        // Play music (debug)
        AudioManager.getInstance().playMusic("resources/sound/music/01. Sonic World.mp3");
    }

    void update(float deltaTime) {
    // Update HUD timer and values
    hud.update(deltaTime); // Always update timer (HUD manages when active)
    hud.updateValues(score, rings, lives);

        // Always update title card until bgAlpha is 0
        if (currentState == GameState.TITLECARDMOVEIN || currentState == GameState.TITLECARDHOLD || currentState == GameState.TITLECARDFADEOUT) {
            titleCard.update(deltaTime);
            // Debug: print state and title card info
            writeln("[DEBUG] State: ", currentState, " | Alpha: ", titleCard.alpha, " | AnimatingIn: ", titleCard.animatingIn, " | bgAlpha: ", titleCard.bgAlpha);
            // Transition to TITLECARDHOLD when animatingIn becomes false
            if (currentState == GameState.TITLECARDMOVEIN && !titleCard.animatingIn) {
                currentState = GameState.TITLECARDHOLD;
                writeln("[DEBUG] Transition to TITLECARDHOLD");
            }
            // Transition to FADEOUT after hold
            if (currentState == GameState.TITLECARDHOLD && titleCard.rectHoldTimer > 2.0f) {
                currentState = GameState.TITLECARDFADEOUT;
                writeln("[DEBUG] Transition to TITLECARDFADEOUT");
            }
            // Transition to PLAYING only after both bgAlpha and alpha are 0
            if (currentState == GameState.TITLECARDFADEOUT && titleCard.bgAlpha == 0 && titleCard.alpha == 0.0f) {
                currentState = GameState.PLAYING;
                hud.startTimer(); // Start HUD timer when gameplay begins
                writeln("[DEBUG] Transition to PLAYING");
            }
        }
    }

    void draw() {
        // ...draw game...
        hud.draw();

        // Draw title card if in title card state
        ClearBackground(Colors.DARKGRAY);
        if (currentState == GameState.TITLECARDMOVEIN || currentState == GameState.TITLECARDHOLD || currentState == GameState.TITLECARDFADEOUT) {
            titleCard.draw();
        }
    }

    void unload() {
        // ...cleanup...
    }
}



