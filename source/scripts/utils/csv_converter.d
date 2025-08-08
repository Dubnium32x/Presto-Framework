module utils.csv_converter;
// we probably need to get rid of a lot of this code ngl - Birb64
import raylib;
import std.stdio;
//import std.fstream;
import std.string;
import core.memory;
import core.stdc.stdlib;
import utils.csv_loader;
//import std.vector;
//import std.cstdio;
//import std.cstdlib;

string LevelConverts = "build/levels/";

// "Really Versitile World" file ".rvw" just say it out loud and it kind of sounds like "level"
string TempLevel = "temp.rvw";

struct Vector3int{

    int x; // X pos
    int y; // Y pos
    int z; // Z pos

};

///
//
//      Created by Birb64 2024
//      Reading and writing functionalities here
//
///
// THE save float data function.
void SaveFloat(const char* fileName, float data, int where){
    // Create a value to point at the file with
    FILE *fileFinger;

    // Point the finger at the file with "wb" meaning to write bytes
    fileFinger = fopen(fileName, "wb");

    // Change position of finger slightly to go where we want to see
    fseek(fileFinger, where * float.sizeof, SEEK_SET);

    // Turn that finger into a pen and write the data
    fwrite(&data, float.sizeof, 1, fileFinger);

    // It is now safe to close the file
    fclose(fileFinger);

}

// More of a shorthand purpose than anything, just made to write many floats at once.
void SaveMultipleFloat(const char* fileName, float *data, int where, int howMany){
    // Create a value to point at the file with
    FILE *fileFinger;

    // Point the finger at the file with "wb" to write bytes
    fileFinger = fopen(fileName, "wb");

    // Change position of finger slightly to writer where we want
    fseek(fileFinger, where * (howMany*float.sizeof), SEEK_SET);

    // Write the bytes we want written
    fwrite(data, float.sizeof, howMany, fileFinger);

    // It is now safe to close the file.
    fclose(fileFinger);
}

// Save Vector3 values(not really, but you see why)
void SaveVector3(const char* fileName, Vector3 data, int where){
    // Allocate memory to allow for three floats to be placed in one area
    float *saveThis = cast(float*)malloc(3*float.sizeof);

    /* A really rough way of making this work while making sense.
    float alsoSaveThis[3] = {data.x, data.y, data.z};

    // Inside this for function applies the values from alsoSaveThis to saveThis without changing the malloc size
    for(int i=0; i <= 2; i++){
        // See?
        saveThis[i] = alsoSaveThis[i];
    }
    */

   saveThis[0] = data.x;
   saveThis[1] = data.y;
   saveThis[2] = data.z;
    // That shorthand function really comes in handy when you want to save floats like this.
    SaveMultipleFloat(fileName, saveThis, where, 3);

    // Free the data from malloc to avoid data leaks.
    free(saveThis);
}

// Loads floats like we want it to
float *LoadFloat(const char* fileName, int where){
    // Like the save function, creates a value to use as a finger to point at the file with
    FILE *fileFinger;

    // A variable that will help us out later
    float *data;

    // Put the finger on the file with "rb" which means read bytes
    fileFinger = fopen(fileName, "rb");
    
    // Reposition finger to where we want to read
    fseek(fileFinger, where*float.sizeof,SEEK_SET);

    // This line changes two variables
    // 1. result is how large the read was. AKA how many bytes it took up
    // 2. Changes the data of `data` to become what we wanted to read from the file
    size_t result = fread(data, float.sizeof, 1, fileFinger);
    
    // If the data is less than we thought
    if(result < 1){
        printf("threw read error: not large enough at [%d] in [%s]", where, fileName);
        return null;
    }
    
    // It is now safe to close the file
    fclose(fileFinger);

    // Return the data
    // NOTE: You must free the data outside of this function.
    return data;
}

// Load multiple floats. The specific reason for it being a pointer is because I can add
// values just like an array on the whim
float *LoadMultipleFloat(const char* fileName, int where, int howMany){
    // Create a finger to point at the file, by now you should get it
    FILE *fileFinger;

    // The data like last time, only now it's a float so that it can be an array or a single float(which now thinking of it
    // it might be better just to use this function than the singular one)
    float *data;

    // Point the finger at the file
    fileFinger = fopen(fileName, "rb");
    
    // Open the memory to allow the amount of floats we want from the file
    data = cast(float *)malloc(howMany*float.sizeof);

    // Move the finger across the page to the place we want it to be
    // NOTE: it moves based on how many floats you want selected too, be warned of that.
    fseek(fileFinger, where*(howMany*float.sizeof),SEEK_SET);

    // This changes two values
    // 1. result is set to the amount of bytes read from the fread function
    // 2. almost like taping off hair from someone's chest, the data reads the binary of the file as an array of floats.
    size_t result = fread(data, float.sizeof, howMany, fileFinger);    

    // Error
    if(result < howMany*float.sizeof){
        printf("threw read error: not large enough");
        return null;
    }

    // It is now safe to close the file
    fclose(fileFinger);

    // Return the data as the value of the function
    // DO NOT FORGET TO FREE DATA!
    return data;
}

// The most simple looking code I could have ever come up. It loads the Vector3
Vector3 LoadVector3(const char* fileName, int where){
    // Creates a pointer to go back to
    float *pointThis = LoadMultipleFloat(fileName, where, 3);

    // creates a Vector3 to return(this is done to allow the pointThis to be freed)
    Vector3 returnthis = {pointThis[0], pointThis[1], pointThis[2]};

    // We can now free the data from LoadMultipleFloat entirely
    free(pointThis);

    // We return the function
    return returnthis;
}


//void SaveDataFile(const char* fileName){
//    SaveFileData();
//}

/// !! STOLEN CODE !!
/// Let's please renew this with our own tech literature.
bool SaveStorageValue(const char *fileName, uint position, Vector3 value)
{
    bool success = false;
    int dataSize = 0;
    uint newDataSize = 0;
    char *fileData = cast(char *)LoadFileData(fileName, &dataSize);
    char *newFileData = null;

    if (fileData != null)
    {
        if (dataSize <= (position*Vector3.sizeof))
        {
            // Increase data size up to position and store value
            newDataSize = cast(uint)(position*Vector3.sizeof);
            newFileData = cast(char *)realloc(fileData, newDataSize);

            if (newFileData != null)
            {
                // realloc succeded
                Vector3 *dataPtr = cast(Vector3 *)newFileData;
                dataPtr[position] = value;
            }
            else
            {
                // realloc failed
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
            Vector3 *dataPtr = cast(Vector3 *)newFileData;
            dataPtr[position] = value;
        }

        success = SaveFileData(fileName, newFileData, newDataSize);
        free(newFileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Saved storage value: %i", fileName, value);
    }
    else
    {
        //TraceLog(LOG_INFO, "FILEIO: [%s] File created successfully", fileName);

        dataSize = cast(int)((position + 1)*(Vector3.sizeof));
        fileData = cast(char *)malloc(dataSize);
        Vector3 *dataPtr = cast(Vector3 *)fileData;
        dataPtr[position] = value;

        success = SaveFileData(fileName, fileData, dataSize);
        UnloadFileData(cast(ubyte *)fileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Saved storage value: %i", fileName, value);
    }

    return success;
}

Vector3 LoadStorageValue(const char *fileName, uint position)
{
    Vector3 value = {};
    int dataSize = 0;
    char *fileData = cast(char *)LoadFileData(fileName, &dataSize);

    if (fileData != null)
    {
        //if (dataSize < ((int)(position*4))) TraceLog(LOG_WARNING, "FILEIO: [%s] Failed to find storage position: %i", fileName, position);
        //else
        //{
            Vector3 *dataPtr = cast(Vector3 *)fileData;
            value = dataPtr[position];
        //}

        UnloadFileData(cast(ubyte *)fileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Loaded storage value: %i", fileName, value);
    }

    return value;
}
bool SaveVector3int(const char *fileName, uint position, Vector3int value)
{
    bool success = false;
    int dataSize = 0;
    uint newDataSize = 0;
    char *fileData = cast(char *)LoadFileData(fileName, &dataSize);
    char *newFileData = null;

    if (fileData != null)
    {
        if (dataSize <= (position*(Vector3int.sizeof)))
        {
            // Increase data size up to position and store value
            newDataSize = cast(uint)(position*Vector3int.sizeof);
            newFileData = cast(char *)realloc(fileData, newDataSize);

            if (newFileData != null)
            {
                // RL_REALLOC succeded
                Vector3int *dataPtr = cast(Vector3int *)newFileData;
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
            Vector3int *dataPtr = cast(Vector3int *)newFileData;
            dataPtr[position] = value;
        }

        success = SaveFileData(fileName, newFileData, newDataSize);
        free(newFileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Saved storage value: %i", fileName, value);
    }
    else
    {
        //TraceLog(LOG_INFO, "FILEIO: [%s] File created successfully", fileName);

        dataSize = cast(int)((position + 1)*(Vector3int.sizeof));
        fileData = cast(char *)malloc(dataSize);
        Vector3int *dataPtr = cast(Vector3int *)fileData;
        dataPtr[position] = value;

        success = SaveFileData(fileName, fileData, dataSize);
        UnloadFileData(cast(ubyte *)fileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Saved storage value: %i", fileName, value);
    }

    return success;
}

Vector3int LoadVector3int(const char *fileName, uint position)
{
    Vector3int value = {};
    int dataSize = 0;
    char *fileData = cast(char *)LoadFileData(fileName, &dataSize);

    if (fileData != null)
    {
        //if (dataSize < ((int)(position*4))) TraceLog(LOG_WARNING, "FILEIO: [%s] Failed to find storage position: %i", fileName, position);
        //else
        //{
            Vector3int *dataPtr = cast(Vector3int *)fileData;
            value = dataPtr[position];
        //}

        UnloadFileData(cast(ubyte *)fileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Loaded storage value: %i", fileName, value);
    }

    return value;
}

bool ConvertCSV2RVW(const char *fileName, uint position, string csvFileName)
{
    bool success = false;
    int dataSize = 0;
    uint newDataSize = 0;
    char *fileData = cast(char *)LoadFileData(fileName, &dataSize);
    char *newFileData = null;
    int[][] value = CSVLoader.loadCSVInt(csvFileName);

    if (fileData != null)
    {
        if (dataSize <= (position*(int[][].sizeof)))
        {
            // Increase data size up to position and store value
            newDataSize = cast(uint)(position*int[][].sizeof);
            newFileData = cast(char *)realloc(fileData, newDataSize);

            if (newFileData != null)
            {
                // RL_REALLOC succeded
                int[][] *dataPtr = cast(int[][] *)newFileData;
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
            int[][] *dataPtr = cast(int[][] *)newFileData;
            dataPtr[position] = value;
        }

        success = SaveFileData(fileName, newFileData, newDataSize);
        free(newFileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Saved storage value: %i", fileName, value);
    }
    else
    {
        //TraceLog(LOG_INFO, "FILEIO: [%s] File created successfully", fileName);

        dataSize = cast(int)((position + 1)*(int[][].sizeof));
        fileData = cast(char *)malloc(dataSize);
        int[][] *dataPtr = cast(int[][] *)fileData;
        dataPtr[position] = value;

        success = SaveFileData(fileName, fileData, dataSize);
        UnloadFileData(cast(ubyte *)fileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Saved storage value: %i", fileName, value);
    }

    return success;
}

int[][] LoadRVW(const char *fileName, uint position)
{
    int[][] value = [];
    int dataSize = 0;
    char *fileData = cast(char *)LoadFileData(fileName, &dataSize);

    if (fileData != null)
    {
        if (dataSize >= ((int)(position*4))) /*TraceLog(LOG_WARNING, "FILEIO: [%s] Failed to find storage position: %i", fileName, position);
        else
        {*/
        {
            int[][] *dataPtr = cast(int[][] *)fileData;
            value = dataPtr[position];
        }
        //}

        UnloadFileData(cast(ubyte *)fileData);

        //TraceLog(LOG_INFO, "FILEIO: [%s] Loaded storage value: %i", fileName, value);
    }

    return value;
}