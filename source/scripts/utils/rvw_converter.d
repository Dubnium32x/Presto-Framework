module utils.rvw_converter;
// we probably need to get rid of a lot of this code ngl - Birb64
import raylib;
import std.stdio;
//import std.fstream;
import std.string;
import core.memory;
import core.stdc.stdlib;
import utils.level_loader;
//import std.vector;
//import std.cstdio;
//import std.cstdlib;

string LevelConverts = "build/levels/";

// "Really Versitile World" file ".rvw" just say it out loud and it kind of sounds like "level"
string TempLevel = "temp.rvw";
string baseLevelPath = "resources/data/levels/";

struct uncompressedLevelData{
    string levelName;
    int width;
    int height;
    
    // Multiple tile layers
    //Tile[][] groundLayer1;
        int[][] tileIdGroundLayer1;
        bool[][] isSolidGroundLayer1 = false;
        bool[][] isPlatformGroundLayer1 = false;
        bool[][] isHazardGroundLayer1 = false;
        int[][] heightProfileGroundLayer1 = 0;
        ubyte[][] flipFlagsGroundLayer1 = 0;
    //Tile[][] groundLayer2;
        int[][] tileIdGroundLayer2;
        bool[][] isSolidGroundLayer2 = false;
        bool[][] isPlatformGroundLayer2 = false;
        bool[][] isHazardGroundLayer2 = false;
        int[][] heightProfileGroundLayer2 = 0;
        ubyte[][] flipFlagsGroundLayer2 = 0;
    //Tile[][] groundLayer3;
        int[][] tileIdGroundLayer3;
        bool[][] isSolidGroundLayer3 = false;
        bool[][] isPlatformGroundLayer3 = false;
        bool[][] isHazardGroundLayer3 = false;
        int[][] heightProfileGroundLayer3 = 0;
        ubyte[][] flipFlagsGroundLayer3 = 0;
    //Tile[][] semiSolidLayer1;
        int[][] tileIdSemiSolidLayer1;
        bool[][] isSolidSemiSolidLayer1 = false;
        bool[][] isPlatformSemiSolidLayer1 = false;
        bool[][] isHazardSemiSolidLayer1 = false;
        int[][] heightProfileSemiSolidLayer1 = 0;
        ubyte[][] flipFlagsSemiSolidLayer1 = 0;
    //Tile[][] semiSolidLayer2;
        int[][] tileIdSemiSolidLayer2;
        bool[][] isSolidSemiSolidLayer2 = false;
        bool[][] isPlatformSemiSolidLayer2 = false;
        bool[][] isHazardSemiSolidLayer2 = false;
        int[][] heightProfileSemiSolidLayer2 = 0;
        ubyte[][] flipFlagsSemiSolidLayer2 = 0;
    //Tile[][] semiSolidLayer3;
        int[][] tileIdSemiSolidLayer3;
        bool[][] isSolidSemiSolidLayer3 = false;
        bool[][] isPlatformSemiSolidLayer3 = false;
        bool[][] isHazardSemiSolidLayer3 = false;
        int[][] heightProfileSemiSolidLayer3 = 0;
        ubyte[][] flipFlagsSemiSolidLayer3 = 0;
    //Tile[][] collisionLayer;
        int[][] tileIdCollisionLayer;
        bool[][] isSolidCollisionLayer = false;
        bool[][] isPlatformCollisionLayer = false;
        bool[][] isHazardCollisionLayer = false;
        int[][] heightProfileCollisionLayer = 0;
        ubyte[][] flipFlagsCollisionLayer = 0;
    //Tile[][] hazardLayer;
        int[][] tileIdHazardLayer;
        bool[][] isSolidHazardLayer = false;
        bool[][] isPlatformHazardLayer = false;
        bool[][] isHazardHazardLayer = false;
        int[][] heightProfileHazardLayer = 0;
        ubyte[][] flipFlagsHazardLayer = 0;

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
    bool success = false;
    int dataSize = 0;
    uint newDataSize = 0;
    char *fileData = cast(char *)LoadFileData(fileName, &dataSize);
    char *newFileData = null;
    
    LevelData value = loadLevelFromJSON(lvlPath);

    value.levelName = loadLevelMetadata(lvlMetadata).levelName;
    value.backgroundColor = loadLevelMetadata(lvlMetadata).backgroundColor; // Sky blue
    value.tilesetName = loadLevelMetadata(lvlMetadata).tilesetName;
    value.playerSpawnPoint = loadLevelMetadata(lvlMetadata).playerSpawnPoint;

    if (fileData != null)
    {
        if (dataSize <= (position*(LevelData.sizeof)))
        {
            // Increase data size up to position and store value
            newDataSize = cast(uint)(position*LevelData.sizeof);
            newFileData = cast(char *)realloc(fileData, newDataSize);

            if (newFileData != null)
            {
                // RL_REALLOC succeded
                LevelData *dataPtr = cast(LevelData *)newFileData;
                dataPtr[position] = value;
            }
            else
            {
                // RL_REALLOC failed
                //TraceLog(LOG_WARNING, "FILEIO: [%s] Failed to realloc data (%u), position in bytes (%u) bigger than actual file size", fileName, dataSize, position*GC.sizeOf(int));

                // We store the old size of the file
                newFileData = fileData;
                newDataSize = dataSize;
            }
        }
        else
        {
            // Store the old size of the file
            newFileData = fileData;
            newDataSize = dataSize;

            // Replace value on selected position
            LevelData *dataPtr = cast(LevelData *)newFileData;
            dataPtr[position] = value;
        }

        success = SaveFileData(fileName, newFileData, newDataSize);
        free(newFileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Saved storage value: %i", fileName, value);
    }
    else
    {
        //TraceLog(LOG_INFO, "FILEIO: [%s] File created successfully", fileName);

        dataSize = cast(int)((position + 1)*(LevelData.sizeof));
        fileData = cast(char *)malloc(dataSize);
        LevelData *dataPtr = cast(LevelData *)fileData;
        dataPtr[position] = value;

        success = SaveFileData(fileName, fileData, dataSize);
        UnloadFileData(cast(ubyte *)fileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Saved storage value: %i", fileName, value);
    }

    return success;
}

LevelData LoadRVW(const char *fileName, uint position)
{
    LevelData value = LevelData();
    int dataSize = 0;
    char *fileData = cast(char *)LoadFileData(fileName, &dataSize);

    if (fileData != null)
    {
        if (dataSize >= ((int)(position*4))) /*TraceLog(LOG_WARNING, "FILEIO: [%s] Failed to find storage position: %i", fileName, position);
        else
        {*/
        {
            LevelData *dataPtr = cast(LevelData *)fileData;
            value = dataPtr[position];
        }
        //}

        UnloadFileData(cast(ubyte *)fileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Loaded storage value: %i", fileName, value);
    }

    return value;
}