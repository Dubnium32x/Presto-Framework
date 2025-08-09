module utils.csv_converter;
// we probably need to get rid of a lot of this code ngl - Birb64
import raylib;
import std.stdio;
//import std.fstream;
import std.string;
import core.memory;
import core.stdc.stdlib;
import utils.csv_loader;
import utils.level_loader;
//import std.vector;
//import std.cstdio;
//import std.cstdlib;

string LevelConverts = "build/levels/";

// "Really Versitile World" file ".rvw" just say it out loud and it kind of sounds like "level"
string TempLevel = "temp.rvw";
string baseLevelPath = "resources/data/levels/";

LevelData loadLevelcsv(string levelKey) {
        
        writeln("Loading new level: ", levelKey);
        int levelNum = 0; // temporary, will be set by the level properties later
        int actNum = 0; // temporary, will be set by the level properties later
        // Load level metadata
        auto metadata = levelManager.getLevelMetadata(cast(int)levelNum);
        string levelPath = baseLevelPath ~ levelKey ~ "/";
        
        // Initialize level data with temporary size - will be updated when loading tiles
        LevelData level = LevelData(levelKey, cast(int)levelNum, cast(int)actNum, 40, 20); // Initial size
        
        // Load each layer and update level size based on actual data
        loadTileLayer(level.groundLayer1, levelPath ~ levelKey ~ "_Ground_1.csv", TileType.SOLID);
        if (level.groundLayer1.length > 0) {
            level.height = cast(int)level.groundLayer1.length;
            level.width = cast(int)level.groundLayer1[0].length;
        }
        
        loadTileLayer(level.groundLayer2, levelPath ~ levelKey ~ "_Ground_2.csv", TileType.SOLID);
        loadTileLayer(level.semiSolidLayer1, levelPath ~ levelKey ~ "_SemiSolid_1.csv", TileType.SEMI_SOLID);
        loadTileLayer(level.semiSolidLayer2, levelPath ~ levelKey ~ "_SemiSolid_2.csv", TileType.SEMI_SOLID);
        loadTileLayer(level.collisionLayer, levelPath ~ levelKey ~ "_Collision.csv", TileType.SOLID);
        
        // Load objects - skipping for now
        //loadObjectLayer(level.objects, levelPath ~ levelKey ~ "_Objects_1.csv");
        
        // Load level properties from metadata file if it exists - skipping for now
        //loadLevelProperties(level, levelPath ~ levelKey ~ "_Properties.csv");
        
        // Cache the level - no need to cache for conversion
        //levelCache[levelKey] = level;
        
        writeln("Successfully loaded level: ", levelKey);
        return level;
    }
    
// fileName is where we will save the converted level, 
// position kind of works like an index(mulitple levels can be stored in one file),
// lvlName is the name of the level we are converting
bool ConvertCSV2RVW(const char *fileName, uint position, string lvlName)
{
    bool success = false;
    int dataSize = 0;
    uint newDataSize = 0;
    char *fileData = cast(char *)LoadFileData(fileName, &dataSize);
    char *newFileData = null;
    
    LevelData value = loadLevelcsv(lvlName);

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