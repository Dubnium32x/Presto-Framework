module utils.csv_loader;

import std.stdio;
import std.file;
import std.string;
import std.array;
import std.conv : to;
import std.algorithm;

// Structure to hold level metadata
struct LevelMetadata {
    string levelName;
    string[] layerNames;
    int entryId;
    string world;
}

// CSV Loader utility class
class CSVLoader {
    
    // Load a CSV file and return a 2D array of integers
    static int[][] loadCSVInt(string filePath) {
        if (!exists(filePath)) {
            writeln("[ERROR] CSV file not found: ", filePath);
            return [];
        }
        
        try {
            string content = readText(filePath);
            int[][] result;
            
            foreach (line; content.splitLines()) {
                if (line.strip().length == 0) continue; // Skip empty lines
                
                int[] row;
                foreach (cell; line.split(",")) {
                    string trimmedCell = cell.strip();
                    if (trimmedCell.length > 0) {
                        try {
                            row ~= trimmedCell.to!int;
                        } catch (Exception e) {
                            writeln("[WARNING] Could not convert '", trimmedCell, "' to integer, using 0");
                            row ~= 0;
                        }
                    }
                }
                if (row.length > 0) {
                    result ~= row;
                }
            }
            
            writeln("[INFO] Successfully loaded CSV with ", result.length, " rows: ", filePath);
            return result;
            
        } catch (Exception e) {
            writeln("[ERROR] Failed to read CSV file: ", filePath, " - ", e.msg);
            return [];
        }
    }
    
    // Load a CSV file and return a 2D array of strings (for mixed data types)
    static string[][] loadCSVString(string filePath) {
        if (!exists(filePath)) {
            writeln("[ERROR] CSV file not found: ", filePath);
            return [];
        }
        
        try {
            string content = readText(filePath);
            string[][] result;
            
            foreach (line; content.splitLines()) {
                if (line.strip().length == 0) continue; // Skip empty lines
                
                string[] row;
                foreach (cell; line.split(",")) {
                    row ~= cell.strip();
                }
                if (row.length > 0) {
                    result ~= row;
                }
            }
            
            writeln("[INFO] Successfully loaded CSV with ", result.length, " rows: ", filePath);
            return result;
            
        } catch (Exception e) {
            writeln("[ERROR] Failed to read CSV file: ", filePath, " - ", e.msg);
            return [];
        }
    }
    
    // Load multiple CSV files as level layers
    static int[][][string] loadLevelLayers(string levelPath, string[] layerNames) {
        int[][][string] layers;
        
        foreach (layerName; layerNames) {
            string filePath = levelPath ~ "/" ~ layerName ~ ".csv";
            if (exists(filePath)) {
                layers[layerName] = loadCSVInt(filePath);
                writeln("Loaded layer: ", layerName, " from ", filePath);
            } else {
                writeln("Warning: Layer file not found: ", filePath);
                layers[layerName] = []; // Empty layer if file doesn't exist
            }
        }
        
        return layers;
    }
}

// Level manager for handling level metadata and loading
class LevelManager {
    private LevelMetadata[] levelList;
    
    this() {
        // Initialize with example levels - update this based on your actual levels
        for (int i = 0; i < 10; i++) {
            levelList ~= LevelMetadata(
                "LEVEL_" ~ i.to!string,
                ["Ground_1", "SemiSolid_1", "Objects_1"],
                i,
                "World_1"
            );
        }
        writeln("[DEBUG] Level list loaded with ", levelList.length, " levels.");
    }
    
    // Get level metadata by index
    LevelMetadata getLevelMetadata(int index) {
        if (index >= 0 && index < levelList.length) {
            return levelList[index];
        }
        writeln("[ERROR] Invalid level index: ", index);
        return LevelMetadata();
    }
    
    // Load all layers for a specific level
    int[][][string] loadLevel(int levelIndex, string basePath = "resources/data/levels/") {
        auto metadata = getLevelMetadata(levelIndex);
        if (metadata.levelName.length == 0) {
            return null;
        }
        
        string levelPath = basePath ~ metadata.levelName;
        return CSVLoader.loadLevelLayers(levelPath, metadata.layerNames);
    }
    
    // Get total number of levels
    size_t getLevelCount() {
        return levelList.length;
    }
    
    // Add a new level to the list
    void addLevel(LevelMetadata level) {
        levelList ~= level;
    }
}
