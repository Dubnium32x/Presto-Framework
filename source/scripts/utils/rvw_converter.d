module utils.rvw_converter;
// we probably need to get rid of a lot of this code ngl - Birb64
import raylib;
import std.stdio;
//import std.fstream;
import std.string;
import core.memory;
import core.stdc.stdlib;
import utils.level_loader;
import std.conv : to;
//import std.vector;
//import std.cstdio;
//import std.cstdlib;

string LevelConverts = "build/levels/";

// "Really Versitile World" file ".rvw" just say it out loud and it kind of sounds like "level"
string TempLevel = "resources/data/levels/temp.rvw";
string baseLevelPath = "resources/data/levels/";

struct uncompressedLevelData{
    string levelName;
    int width;
    int height;
    
    // Multiple tile layers
    //Tile[][] groundLayer1;
        int[][] tileIdGroundLayer1;
        bool[][] isSolidGroundLayer1 = [];
        bool[][] isPlatformGroundLayer1 = [];
        bool[][] isHazardGroundLayer1 = [];
        int[][] heightProfileGroundLayer1 = [];
        ubyte[][] flipFlagsGroundLayer1 = [];
    //Tile[][] groundLayer2;
        int[][] tileIdGroundLayer2;
        bool[][] isSolidGroundLayer2 = [];
        bool[][] isPlatformGroundLayer2 = [];
        bool[][] isHazardGroundLayer2 = [];
        int[][] heightProfileGroundLayer2 = [];
        ubyte[][] flipFlagsGroundLayer2 = [];
    //Tile[][] groundLayer3;
        int[][] tileIdGroundLayer3;
        bool[][] isSolidGroundLayer3 = [];
        bool[][] isPlatformGroundLayer3 = [];
        bool[][] isHazardGroundLayer3 = [];
        int[][] heightProfileGroundLayer3 = [];
        ubyte[][] flipFlagsGroundLayer3 = [];
    //Tile[][] semiSolidLayer1;
        int[][] tileIdSemiSolidLayer1;
        bool[][] isSolidSemiSolidLayer1 = [];
        bool[][] isPlatformSemiSolidLayer1 = [];
        bool[][] isHazardSemiSolidLayer1 = [];
        int[][] heightProfileSemiSolidLayer1 = [];
        ubyte[][] flipFlagsSemiSolidLayer1 = [];
    //Tile[][] semiSolidLayer2;
        int[][] tileIdSemiSolidLayer2;
        bool[][] isSolidSemiSolidLayer2 = [];
        bool[][] isPlatformSemiSolidLayer2 = [];
        bool[][] isHazardSemiSolidLayer2 = [];
        int[][] heightProfileSemiSolidLayer2 = [];
        ubyte[][] flipFlagsSemiSolidLayer2 = [];
    //Tile[][] semiSolidLayer3;
        int[][] tileIdSemiSolidLayer3;
        bool[][] isSolidSemiSolidLayer3 = [];
        bool[][] isPlatformSemiSolidLayer3 = [];
        bool[][] isHazardSemiSolidLayer3 = [];
        int[][] heightProfileSemiSolidLayer3 = [];
        ubyte[][] flipFlagsSemiSolidLayer3 = [];
    //Tile[][] collisionLayer;
        int[][] tileIdCollisionLayer;
        bool[][] isSolidCollisionLayer = [];
        bool[][] isPlatformCollisionLayer = [];
        bool[][] isHazardCollisionLayer = [];
        int[][] heightProfileCollisionLayer = [];
        ubyte[][] flipFlagsCollisionLayer = [];
    //Tile[][] hazardLayer;
        int[][] tileIdHazardLayer;
        bool[][] isSolidHazardLayer = [];
        bool[][] isPlatformHazardLayer = [];
        bool[][] isHazardHazardLayer = [];
        int[][] heightProfileHazardLayer = [];
        ubyte[][] flipFlagsHazardLayer = [];

    // Object data (separate from tiles)
        //LevelObject[] objects;
        int[] objectId;
        float[] x, y;
        int[] objectType; // Enemy, item, trigger, etc.
        string[][] properties; // Additional properties as strings

    // Level metadata
        Vector2 playerSpawnPoint;
        string tilesetName;
        Color backgroundColor;
        int timeLimit; // In seconds, 0 = no limit

}
// fileName is where we will save the converted level, 
// position kind of works like an index(mulitple levels can be stored in one file),
// lvlName is the name of the level we are converting
bool ConvertJSON2RVW(const char *fileName, uint position, string lvlPath, string lvlMetadata)
{
    LevelData value = loadLevelFromJSON(lvlPath);
    value.levelName = loadLevelMetadata(lvlMetadata).levelName;
    value.backgroundColor = loadLevelMetadata(lvlMetadata).backgroundColor;
    value.tilesetName = loadLevelMetadata(lvlMetadata).tilesetName;
    value.playerSpawnPoint = loadLevelMetadata(lvlMetadata).playerSpawnPoint;

    // Debug output after all declarations
    writeln("[RVW-DEBUG] Saving level:");
    writeln("  Name: ", value.levelName);
    writeln("  Size: ", value.width, "x", value.height);
    writeln("  groundLayer1 rows: ", value.groundLayer1.length, ", cols: ", (value.groundLayer1.length > 0 ? value.groundLayer1[0].length : 0));

    auto f = File(to!string(fileName), "wb");

    // Write levelName
    auto nameBytes = cast(ubyte[])value.levelName;
    int nameLen = cast(int)nameBytes.length;
    f.write(nameLen);
    f.write(nameBytes);

    // Write width and height
    f.write(value.width);
    f.write(value.height);

    // Write groundLayer1 as 2D array of ints (row-major)
    int rows = cast(int)value.groundLayer1.length;
    int cols = rows > 0 ? cast(int)value.groundLayer1[0].length : 0;
    f.write(rows);
    f.write(cols);
    foreach (row; value.groundLayer1) {
        foreach (tile; row) {
            f.write(tile.tileId);
        }
    }

    f.close();
    return true;
}

LevelData LoadRVW(const char *fileName, uint position)
{
    LevelData value = LevelData();
    auto f = File(to!string(fileName), "rb");

    // Read levelName
    int nameLen = 0;
    f.rawRead([nameLen]);
    ubyte[] nameBytes = new ubyte[nameLen];
    f.rawRead(nameBytes);
    value.levelName = cast(string)nameBytes;

    // Read width and height
    f.rawRead([value.width]);
    f.rawRead([value.height]);

    // Read groundLayer1
    int rows = 0, cols = 0;
    f.rawRead([rows]);
    f.rawRead([cols]);
    value.groundLayer1 = new Tile[][](rows, cols);
    foreach (i; 0 .. rows) {
        foreach (j; 0 .. cols) {
            int tileId = 0;
            f.rawRead([tileId]);
            value.groundLayer1[i][j] = Tile(tileId, false, false, false, 0, 0);
        }
    }
    f.close();

    // Debug output after all declarations
    writeln("[RVW-DEBUG] Loading level from RVW:");
    writeln("  Name: ", value.levelName);
    writeln("  Size: ", value.width, "x", value.height);
    writeln("  groundLayer1 rows: ", value.groundLayer1.length, ", cols: ", (value.groundLayer1.length > 0 ? value.groundLayer1[0].length : 0));
    return value;
}