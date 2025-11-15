// Level loader implementation
#include "level_loader.h"
#include <math.h>

bool levelInitialized = false;
LevelData currentLevel;

// Tile creation helpers
Tile CreateEmptyTile(void)
{
    Tile tile = {0};
    tile.tileId = 0;
    tile.isSolid = false;
    tile.isPlatform = false;
    tile.isHazard = false;
    tile.flipFlags = 0;
    return tile;
}

Tile CreateTileFromId(int tileId)
{
    Tile tile = CreateEmptyTile();

    // Handle -1 and 0 as empty tiles
    if (tileId == 0)
        return tile;

    tile.tileId = tileId; // Keep raw gid-relative (1-based within tileset) for drawing/collision mapping
    // Collision and height profiles are looked up via TileCollision using tileset metadata; flags default false.

    return tile;
}

// Layer management
Tile **InitializeLayer(int width, int height)
{
    Tile **layer = malloc(sizeof(Tile *) * height);
    for (int y = 0; y < height; y++)
    {
        layer[y] = malloc(sizeof(Tile) * width);
        for (int x = 0; x < width; x++)
        {
            layer[y][x] = CreateEmptyTile();
        }
    }
    return layer;
}

Tile **GetLayerByName(LevelData *level, const char *layerName)
{
    if (strcmp(layerName, "Ground_1") == 0 || strcmp(layerName, "Ground_1_Collision") == 0)
    {
        return level->groundLayer1;
    }
    else if (strcmp(layerName, "Ground_2") == 0 || strcmp(layerName, "Ground_2_Collision") == 0)
    {
        return level->groundLayer2;
    }
    else if (strcmp(layerName, "Ground_3") == 0 || strcmp(layerName, "Ground_3_Collision") == 0)
    {
        return level->groundLayer3;
    }
    else if (strcmp(layerName, "SemiSolid_1") == 0 || strcmp(layerName, "SemiSolids_1") == 0 ||
             strcmp(layerName, "SemiSolids_1_Collision") == 0)
    {
        return level->semiSolidLayer1;
    }
    else if (strcmp(layerName, "SemiSolid_2") == 0 || strcmp(layerName, "SemiSolids_2") == 0 ||
             strcmp(layerName, "SemiSolids_2_Collision") == 0)
    {
        return level->semiSolidLayer2;
    }
    else if (strcmp(layerName, "SemiSolid_3") == 0 || strcmp(layerName, "SemiSolids_3") == 0 ||
             strcmp(layerName, "SemiSolids_3_Collision") == 0)
    {
        return level->semiSolidLayer3;
    }
    else if (strcmp(layerName, "Collision") == 0)
    {
        return level->collisionLayer;
    }
    else if (strcmp(layerName, "Hazard") == 0)
    {
        return level->hazardLayer;
    }

    printf("[WARNING] Unknown layer name: %s\n", layerName);
    return NULL;
}

// Load a single tile layer from CSV
Tile **LoadTileLayer(const char *csvPath, int *outWidth, int *outHeight)
{
    FILE *file = fopen(csvPath, "r");
    if (!file)
    {
        printf("Layer file not found: %s (using empty layer)\n", csvPath);
        return NULL;
    }

    // First pass: count dimensions and detect CSV style (-1 empty with 0-based local ids)
    int width = 0, height = 0;
    bool hasMinusOne = false;
    char line[8192];

    // Count first line for width using a robust parser
    if (fgets(line, sizeof(line), file))
    {
        // Check for -1 in the first line
        if (strstr(line, "-1") != NULL)
            hasMinusOne = true;
        const char *p = line;
        int tokens = 0;
        while (*p && *p != '\n' && *p != '\r')
        {
            // Skip non-number leading separators
            while (*p == ' ' || *p == '\t' || *p == ',')
                p++;
            if (*p == '\0' || *p == '\n' || *p == '\r')
                break;
            // Parse integer
            char *endp;
            (void)strtol(p, &endp, 10);
            if (endp == p)
                break; // no progress
            tokens++;
            p = endp;
            // Skip trailing spaces and comma
            while (*p == ' ' || *p == '\t')
                p++;
            if (*p == ',')
                p++;
        }
        width = tokens;
        height = 1;
    }

    // Count remaining lines for height
    while (fgets(line, sizeof(line), file))
    {
        height++;
        if (!hasMinusOne && strstr(line, "-1") != NULL)
            hasMinusOne = true;
    }

    if (width == 0 || height == 0)
    {
        fclose(file);
        return NULL;
    }

    // Second pass: load data
    rewind(file);
    Tile **tiles = InitializeLayer(width, height);

    int y = 0;
    while (fgets(line, sizeof(line), file) && y < height)
    {
        const char *p = line;
        int x = 0;
        while (*p && *p != '\n' && *p != '\r' && x < width)
        {
            // Skip separators
            while (*p == ' ' || *p == '\t' || *p == ',')
                p++;
            if (*p == '\0' || *p == '\n' || *p == '\r')
                break;
            char *endp;
            long val = strtol(p, &endp, 10);
            if (endp == p)
                break;
            p = endp;
            int tileId = 0;
            if (val == -1)
            {
                tileId = 0;
            }
            else if (val < 0)
            {
                tileId = (int)val;
            }
            else if (hasMinusOne)
            {
                // Local zero-based index exported: add +1 to make it 1-based local
                tileId = (int)val + 1;
            }
            else
            {
                // Global gid encoding from TMX export: mask flip flags, keep gid
                uint32_t gid = (uint32_t)val & 0x1FFFFFFFu;
                tileId = (gid == 0) ? 0 : (int)gid;
            }
            tiles[y][x] = CreateTileFromId(tileId);
            // Move past optional spaces and comma
            while (*p == ' ' || *p == '\t')
                p++;
            if (*p == ',')
                p++;
            x++;
        }
        y++;
    }

    fclose(file);
    if (outWidth)
        *outWidth = width;
    if (outHeight)
        *outHeight = height;
    printf("Loaded tile layer: %s (%dx%d)\n", csvPath, width, height);
    return tiles;
}

// Load level objects from CSV
LevelObject *LoadLevelObjects(const char *csvPath, int *outCount)
{
    FILE *file = fopen(csvPath, "r");
    if (!file)
    {
        printf("Objects file not found: %s\n", csvPath);
        *outCount = 0;
        return NULL;
    }

    // Count lines first
    int lineCount = 0;
    char line[1024];
    while (fgets(line, sizeof(line), file))
    {
        lineCount++;
    }

    if (lineCount == 0)
    {
        fclose(file);
        *outCount = 0;
        return NULL;
    }

    // Allocate and load objects
    LevelObject *objects = malloc(sizeof(LevelObject) * lineCount);
    rewind(file);

    int objCount = 0;
    while (fgets(line, sizeof(line), file) && objCount < lineCount)
    {
        char *tokens[10]; // Max 10 tokens per line
        int tokenCount = 0;

        // Tokenize the line
        char *token = strtok(line, ",");
        while (token && tokenCount < 10)
        {
            tokens[tokenCount++] = token;
            token = strtok(NULL, ",");
        }

        if (tokenCount >= 4)
        {
            LevelObject *obj = &objects[objCount];
            obj->objectId = atoi(tokens[0]);
            obj->x = (float)atof(tokens[1]);
            obj->y = (float)atof(tokens[2]);
            obj->objectType = atoi(tokens[3]);

            // Store additional properties
            obj->propertiesCount = tokenCount - 4;
            if (obj->propertiesCount > 0)
            {
                obj->properties = malloc(sizeof(char *) * obj->propertiesCount);
                for (int i = 0; i < obj->propertiesCount; i++)
                {
                    obj->properties[i] = strdup(tokens[4 + i]);
                }
            }
            else
            {
                obj->properties = NULL;
            }

            objCount++;
        }
    }

    fclose(file);
    *outCount = objCount;
    printf("Loaded %d objects\n", objCount);
    return objects;
}

// Calculate level dimensions from all layers
void CalculateLevelDimensions(LevelData *level)
{
    // TODO: Store actual parsed width/height when loading CSVs
    // For now, set reasonable defaults so we can render in the demo
    if (level->width <= 0)
        level->width = 64;
    if (level->height <= 0)
        level->height = 32;
}

// Get tile at specific position in a layer
Tile GetTileAtPosition(Tile **layer, int x, int y, int width, int height)
{
    if (!layer || y < 0 || y >= height || x < 0 || x >= width)
    {
        return CreateEmptyTile();
    }
    return layer[y][x];
}

// Check if position has solid collision (checks multiple layers)
bool IsSolidAtPosition(const LevelData *level, float worldX, float worldY, int tileSize)
{
    int tileX = (int)(worldX / tileSize);
    int tileY = (int)(worldY / tileSize);

    // Check collision layer first
    if (level->collisionLayer)
    {
        Tile collisionTile = GetTileAtPosition(level->collisionLayer, tileX, tileY, level->width, level->height);
        if (collisionTile.tileId > 0)
        {
            return IsTileSolidAtLocalPosition(collisionTile.tileId, worldX, worldY, tileX, tileY, tileSize, "Collision", level);
        }
    }

    // Check ground layers
    if (level->groundLayer1)
    {
        Tile groundTile = GetTileAtPosition(level->groundLayer1, tileX, tileY, level->width, level->height);
        if (groundTile.tileId > 0)
        {
            return IsTileSolidAtLocalPosition(groundTile.tileId, worldX, worldY, tileX, tileY, tileSize, "Ground_1", level);
        }
    }

    if (level->groundLayer2)
    {
        Tile groundTile = GetTileAtPosition(level->groundLayer2, tileX, tileY, level->width, level->height);
        if (groundTile.tileId > 0)
        {
            return IsTileSolidAtLocalPosition(groundTile.tileId, worldX, worldY, tileX, tileY, tileSize, "Ground_2", level);
        }
    }

    return false;
}

// Check if a specific tile position is solid at the given world coordinates
bool IsTileSolidAtLocalPosition(int tileId, float worldX, float worldY, int tileX, int tileY,
                                int tileSize, const char *layerName, const LevelData *level)
{
    (void)worldY;
    (void)tileY; // Unused parameters
    // Get the local position within the tile (0-15)
    int localX = (int)(worldX - tileX * tileSize);
    if (localX < 0)
        localX = 0;
    if (localX >= tileSize)
        localX = tileSize - 1;

    // Get tile profile (using simplified TileProfile which contains an aggregate groundHeight)
    TileProfile profile = Tile_GetProfile(tileId);
    // For now use the aggregated groundHeight to determine solidity
    return profile.groundHeight > 0;
}

// Main loading function
LevelData LoadCompleteLevel(const char *levelPath)
{
    return LoadCompleteLevelWithFormat(levelPath, false); // Default to CSV
}

LevelData LoadCompleteLevelWithFormat(const char *levelPath, bool useJSON)
{
    // Initialize everything to NULL/0 to prevent double frees
    LevelData level;
    memset(&level, 0, sizeof(LevelData));

    // Set defaults
    level.levelName = strdup("Unnamed Level");
    level.tilesetName = strdup("default");
    level.playerSpawnPoint = (Vector2){100, 100};
    level.backgroundColor = (Color){135, 206, 235, 255}; // Sky blue
    level.timeLimit = 0;
    level.firstgid = 1;

    if (useJSON)
    {
        // JSON loading would go here - for now fall back to CSV
        printf("[WARNING] JSON loading not implemented, falling back to CSV\n");
    }

    // Prefer TMX if present: parse embedded CSV from <data encoding="csv"> and map attributes
    char tmxPath[512];
    snprintf(tmxPath, sizeof(tmxPath), "%s/LEVEL_0.tmx", levelPath);
    FILE *tmx = fopen(tmxPath, "r");
    if (tmx)
    {
        // Read entire file into memory (simple parser for attributes and one CSV layer)
        fseek(tmx, 0, SEEK_END);
        long fsize = ftell(tmx);
        rewind(tmx);
        char *xml = malloc((size_t)fsize + 1);
        size_t nread = fread(xml, 1, (size_t)fsize, tmx);
        xml[nread] = '\0';
        fclose(tmx);

        // Extract map width/height and tilewidth/tileheight
        int mapW = 0, mapH = 0, tileW = 0, tileH = 0;
        sscanf(strstr(xml, "<map"), "<map%*[^w]width=\"%d\"%*[^h]height=\"%d\"%*[^t]tilewidth=\"%d\"%*[^h]tileheight=\"%d", &mapW, &mapH, &tileW, &tileH);
        if (mapW > 0 && mapH > 0)
        {
            level.width = mapW;
            level.height = mapH;
        }

        // Extract tileset firstgid if present
        int firstgid = 1;
        const char *tsxTag = strstr(xml, "<tileset");
        if (tsxTag)
        {
            sscanf(tsxTag, "<tileset%*[^f]firstgid=\"%d", &firstgid);
        }
        level.firstgid = firstgid;

        // Find the first layer <data encoding="csv"> and parse into groundLayer1
        const char *layerTag = strstr(xml, "<layer ");
        if (layerTag)
        {
            const char *dataStart = strstr(layerTag, "<data");
            if (dataStart)
            {
                const char *enc = strstr(dataStart, "encoding=\"csv\"");
                if (enc)
                {
                    const char *csvStart = strstr(dataStart, ">");
                    const char *csvEnd = strstr(dataStart, "</data>");
                    if (csvStart && csvEnd && csvEnd > csvStart)
                    {
                        csvStart++; // move past '>'
                        // Duplicate CSV segment and feed through a CSV reader pipeline
                        size_t csvLen = (size_t)(csvEnd - csvStart);
                        char *csvBuf = malloc(csvLen + 1);
                        memcpy(csvBuf, csvStart, csvLen);
                        csvBuf[csvLen] = '\0';

                        // We need to parse like LoadTileLayer but from memory. We'll write to a temp file to reuse code.
                        char tmpPath[512];
                        snprintf(tmpPath, sizeof(tmpPath), "%s/.tmx_embedded_layer.csv", levelPath);
                        FILE *tmp = fopen(tmpPath, "w");
                        if (tmp)
                        {
                            fwrite(csvBuf, 1, csvLen, tmp);
                            fclose(tmp);
                            int w = 0, h = 0;
                            level.groundLayer1 = LoadTileLayer(tmpPath, &w, &h);
                            if (w > 0 && h > 0)
                            {
                                level.width = w;
                                level.height = h;
                            }
                            remove(tmpPath);
                        }
                        else
                        {
                            // Fallback: no write access, attempt line-by-line parsing in-memory
                            int w = 0, h = 0;
                            // First pass compute width/height
                            {
                                const char *p = csvBuf;
                                while (*p)
                                {
                                    // count tokens until newline
                                    int rowW = 0;
                                    while (*p && *p != '\n' && *p != '\r')
                                    {
                                        // scan number
                                        // token separated by ','
                                        rowW++;
                                        const char *comma = strchr(p, ',');
                                        const char *nl = strpbrk(p, "\r\n");
                                        if (!comma || (nl && nl < comma))
                                        {
                                            p = nl ? nl : p + strlen(p);
                                            break;
                                        }
                                        p = comma + 1;
                                    }
                                    if (rowW > 0)
                                    {
                                        h++;
                                        if (rowW > w)
                                            w = rowW;
                                    }
                                    while (*p == '\r' || *p == '\n')
                                        p++;
                                }
                            }
                            if (w > 0 && h > 0)
                            {
                                level.groundLayer1 = InitializeLayer(w, h);
                                const char *p = csvBuf;
                                int y = 0;
                                while (*p && y < h)
                                {
                                    int x = 0;
                                    while (*p && *p != '\n' && *p != '\r' && x < w)
                                    {
                                        long val = strtol(p, (char **)&p, 10);
                                        int tileId = (int)val;
                                        if (tileId <= 0)
                                            tileId = 0;
                                        else
                                            tileId = tileId - firstgid + 1;
                                        level.groundLayer1[y][x] = CreateTileFromId(tileId);
                                        if (*p == ',')
                                            p++;
                                        x++;
                                    }
                                    while (*p == '\r' || *p == '\n')
                                        p++;
                                    y++;
                                }
                                level.width = w;
                                level.height = h;
                            }
                        }
                        free(csvBuf);
                    }
                }
            }
        }

        free(xml);
    }

    // If no TMX or couldn't parse, first try single exported CSV, then legacy per-layer CSV naming
    if (!level.groundLayer1)
    {
        char layerPath[512];
        int w = 0, h = 0;
        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0.csv", levelPath);
        level.groundLayer1 = LoadTileLayer(layerPath, &w, &h);
        if (w > 0 && h > 0)
        {
            level.width = w;
            level.height = h;
        }
    }

    if (!level.groundLayer1)
    {
        char layerPath[512];
        int w = 0, h = 0;
        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0_Ground_1.csv", levelPath);
        level.groundLayer1 = LoadTileLayer(layerPath, &w, &h);
        if (w > 0 && h > 0)
        {
            level.width = w;
            level.height = h;
        }

        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0_Ground_2.csv", levelPath);
        level.groundLayer2 = LoadTileLayer(layerPath, NULL, NULL);

        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0_Ground_3.csv", levelPath);
        level.groundLayer3 = LoadTileLayer(layerPath, NULL, NULL);

        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0_SemiSolid_1.csv", levelPath);
        level.semiSolidLayer1 = LoadTileLayer(layerPath, NULL, NULL);

        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0_SemiSolid_2.csv", levelPath);
        level.semiSolidLayer2 = LoadTileLayer(layerPath, NULL, NULL);

        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0_SemiSolid_3.csv", levelPath);
        level.semiSolidLayer3 = LoadTileLayer(layerPath, NULL, NULL);

        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0_Collision.csv", levelPath);
        level.collisionLayer = LoadTileLayer(layerPath, NULL, NULL);

        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0_Hazard.csv", levelPath);
        level.hazardLayer = LoadTileLayer(layerPath, NULL, NULL);

        // Load objects
        snprintf(layerPath, sizeof(layerPath), "%s/LEVEL_0_Objects_1.csv", levelPath);
        level.objects = LoadLevelObjects(layerPath, &level.objectCount);
    }

    // Set up tileset info for collision system
    level.tilesetCount = 1;
    level.tilesets = malloc(sizeof(TilesetInfo));
    level.tilesets[0].firstgid = 1;
    level.tilesets[0].nameCandidates = malloc(sizeof(char *) * 2);
    // Default to the level's tileset name; generated TILESET_NAME symbols were made internal.
    level.tilesets[0].nameCandidates[0] = strdup(level.tilesetName);
    level.tilesets[0].nameCandidates[1] = NULL;

    // Calculate dimensions and precompute profiles
    CalculateLevelDimensions(&level);
    PrecomputeTileProfiles(&level);

    printf("Level loaded: %s (%dx%d)\n", level.levelName, level.width, level.height);
    return level;
}

// Memory cleanup
void FreeLevelData(LevelData *level)
{
    if (!level)
        return;

    // Free strings
    free(level->levelName);
    free(level->tilesetName);

    // Free layers
    if (level->groundLayer1)
    {
        for (int y = 0; y < level->height; y++)
        {
            free(level->groundLayer1[y]);
        }
        free(level->groundLayer1);
    }

    // Similar cleanup for other layers...
    // (Add similar blocks for groundLayer2, groundLayer3, etc.)

    // Free objects
    if (level->objects)
    {
        for (int i = 0; i < level->objectCount; i++)
        {
            if (level->objects[i].properties)
            {
                for (int j = 0; j < level->objects[i].propertiesCount; j++)
                {
                    free(level->objects[i].properties[j]);
                }
                free(level->objects[i].properties);
            }
        }
        free(level->objects);
    }

    // Free tilesets
    if (level->tilesets)
    {
        for (int i = 0; i < level->tilesetCount; i++)
        {
            if (level->tilesets[i].nameCandidates)
            {
                for (int j = 0; level->tilesets[i].nameCandidates[j]; j++)
                {
                    free((char *)level->tilesets[i].nameCandidates[j]);
                }
                free(level->tilesets[i].nameCandidates);
            }
        }
        free(level->tilesets);
    }

    // Free profile cache
    if (level->profileKeys)
    {
        for (int i = 0; i < level->profileCount; i++)
        {
            free(level->profileKeys[i]);
        }
        free(level->profileKeys);
    }
    free(level->profileValues);

    memset(level, 0, sizeof(LevelData));
}