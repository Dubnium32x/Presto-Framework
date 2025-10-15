// Tileset map implementation
#include "tileset_map.h"

// Static buffer for normalized names - simple approach for demo
static char normalizedNameBuffer[256];

const char* NormalizeTileSetName(const char* raw) {
    const char* lastSlash = strrchr(raw, '/');
    const char* lastBackslash = strrchr(raw, '\\');
    const char* baseName = raw;
    
    if (lastSlash && (!lastBackslash || lastSlash > lastBackslash)) {
        baseName = lastSlash + 1;
    } else if (lastBackslash) {
        baseName = lastBackslash + 1;
    }
    
    // Copy to our buffer
    strncpy(normalizedNameBuffer, baseName, sizeof(normalizedNameBuffer) - 1);
    normalizedNameBuffer[sizeof(normalizedNameBuffer) - 1] = '\0';
    
    // Remove common extensions
    char* pos;
    if ((pos = strstr(normalizedNameBuffer, ".tsx")) != NULL) *pos = '\0';
    else if ((pos = strstr(normalizedNameBuffer, ".tmx")) != NULL) *pos = '\0';
    else if ((pos = strstr(normalizedNameBuffer, ".png")) != NULL) *pos = '\0';
    else if ((pos = strstr(normalizedNameBuffer, ".jpg")) != NULL) *pos = '\0';
    else if ((pos = strstr(normalizedNameBuffer, ".jpeg")) != NULL) *pos = '\0';
    else if ((pos = strstr(normalizedNameBuffer, ".bmp")) != NULL) *pos = '\0';

    return normalizedNameBuffer;
}

bool ResolveGlobalGid(int gid, TilesetInfo* tilesets, int tilesetCount, TilesetInfo* chosen, int* localIndex) {
    chosen->nameCandidates = NULL;
    chosen->firstgid = 0;
    if (gid <= 0) return false;
    
    // Find the tileset with highest firstgid <= gid
    int bestIdx = -1;
    for (int i = 0; i < tilesetCount; i++) {
        if (tilesets[i].firstgid <= gid) {
            if (bestIdx == -1 || tilesets[i].firstgid > tilesets[bestIdx].firstgid) {
                bestIdx = i;
            }
        }
    }
    
    if (bestIdx == -1) return false;
    
    *chosen = tilesets[bestIdx];
    *localIndex = gid - chosen->firstgid; // zero-based local index
    return true;
}

bool IsTilesetNameMatch(const char* name, TilesetInfo* tileset) {
    if (!tileset->nameCandidates) return false;
    
    for (const char** candidate = tileset->nameCandidates; *candidate != NULL; candidate++) {
        if (strcmp(name, *candidate) == 0) {
            return true;
        }
    }
    return false;
}

bool FindTilesetByName(const char* name, TilesetInfo* tilesets, int tilesetCount, TilesetInfo* found) {
    found->nameCandidates = NULL;
    found->firstgid = 0;
    
    for (int i = 0; i < tilesetCount; i++) {
        if (IsTilesetNameMatch(name, &tilesets[i])) {
            *found = tilesets[i];
            return true;
        }
    }
    return false;
}