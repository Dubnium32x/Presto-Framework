module player.var;

import std.stdio;

import level;

class Var {
    public static float x = 0;
    public static float y = 0;
    public static float xspeed, yspeed = 0;
    public static float groundspeed = 0;
    public static float groundangle = 0;
    public static float widthrad = 9;
    public static float heightrad = 19;
    public static float jumpforce = 5.5f;  // Adjusted for better jump height with reduced gravity
    public static float pushradius = 10;

    public static bool grounded = false;

    public static int rings = 0;
    public static int lives = 3;
    public static int score = 0;
    public static int timemicroseconds = 0;
    public static int timeseconds = 0;
    public static int timeminutes = 0;

    public static int checkpoint = 0;

    public static bool damageinvincibility = false;
    public static bool invincibility = false;
    public static bool speedshoes = false;
    public static bool dead = false;

    public static float framesNotGrounded = 0;
    public static int GROUND_DEBOUNCE_FRAMES = 3;
    public static float GROUND_SNAP_TOLERANCE = 4.0f;
    public static float HIGH_SPEED_SNAP_TOLERANCE = 12.0f;
    public static float MIN_SLOPE_HEIGHT = 1.0f;

    public enum ShieldState {
        SHIELD_NONE,
        SHIELD_FIRE,
        SHIELD_LIGHTNING,
        SHIELD_BUBBLE,
        SHIELD_HONEY
    }

    public static ShieldState shield = ShieldState.SHIELD_NONE;
}

public class GamePhysics : Var {
    public static string groundmode = "floor"; // four modes: floor, rightwall, leftwall, ceiling
    public static float acceleration = 0.06f;    // Slightly increased for more responsive feel
    public static float deceleration = 0.08f;    // Reduced deceleration for smoother direction changes
    public static float friction = 0.046875f;    // Greatly reduced friction for much smoother natural slowdown
    public static float topspeed = 6.0f;         // Normal maximum speed
    public static float maxspeed = 8.5f;         // Increased to allow for better air momentum
    public static float gravity = 0.26f;         // Reduced gravity (from 0.32f) for lighter feel
    public static float maxFallSpeed = 14.0f;    // Reduced from 16.0f for less heavy falls

    public static int[] sincoslist = [
        0, 6, 12, 18, 25, 31, 37, 43, 49, 56, 62, 68, 74, 80, 86, 92, 97, 103, 109, 115, 120, 126, 131, 136, 142, 147, 152, 157, 162, 167, 171, 176, 181, 185, 189, 193, 197, 201, 205, 209, 212, 216, 219, 222, 225, 228, 231, 234, 236, 238, 241, 243, 244, 246, 248, 249, 251, 252, 253, 254, 254, 255, 255, 255,
        256, 255, 255, 255, 254, 254, 253, 252, 251, 249, 248, 246, 244, 243, 241, 238, 236, 234, 231, 228, 225, 222, 219, 216, 212, 209, 205, 201, 197, 193, 189, 185, 181, 176, 171, 167, 162, 157, 152, 147, 142, 136, 131, 126, 120, 115, 109, 103, 97, 92, 86, 80, 74, 68, 62, 56, 49, 43, 37, 31, 25, 18, 12, 6,
        0, -6, -12, -18, -25, -31, -37, -43, -49, -56, -62, -68, -74, -80, -86, -92, -97, -103, -109, -115, -120, -126, -131, -136, -142, -147, -152, -157, -162, -167, -171, -176, -181, -185, -189, -193, -197, -201, -205, -209, -212, -216, -219, -222, -225, -228, -231, -234, -236, -238, -241, -243, -244, -246, -248, -249, -251, -252, -253, -254, -254, -255, -255, -255,
        -256, -255, -255, -255, -254, -254, -253, -252, -251, -249, -248, -246, -244, -243, -241, -238, -236, -234, -231, -228, -225, -222, -219, -216, -212, -209, -205, -201, -197, -193, -189, -185, -181, -176, -171, -167, -162, -157, -152, -147, -142, -136, -131, -126, -120, -115, -109, -103, -97, -92, -86, -80, -74, -68, -62, -56, -49, -43, -37, -31, -25, -18, -12, -6
    ];

    public static int[] anglelist = [
        0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 32, 32, 32, 32, 32, 32, 32, 0
    ];

    public static int angleHexSin(int hex_ang) {
        int list_index = hex_ang % 256;
        return sincoslist[list_index];
    }

    public static int angleHexCos(int hex_ang) {
        int list_index = (hex_ang + 64) % 256;
        return sincoslist[list_index];
    }

    public static int angleHexPointDirection(float xdist, float ydist) {
        // default
        if (xdist == 0 && ydist == 0) {
            return 64;
        }

        // force positive
        import std.math : abs;
        float xx = abs(xdist);
        float yy = abs(ydist);

        // get initial angle
        int angle;
        if (ydist >= xx) {
            int compare = cast(int)((xx*256)/yy);
            angle = 64 - anglelist[compare];
        }
        else {
            int compare = cast(int)((yy*256)/xx);
            angle = anglelist[compare];
        }

        // check angle
        if (xdist <= 0) {
            angle = 128 - angle;
        }
        if (ydist <= 0) {
            angle = 256 - angle;
        }

        // return angle
        return angle;
    }

    // angle conversion
    public int angleHexToDegrees(int hex_ang) {
        return cast(int)(((256 - hex_ang) / 256) * 360);
    }

    public int angleDegreesToHex(int degrees) {
        return cast(int)(((360 - degrees) / 360) * 256);
    }
}