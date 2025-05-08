# Presto-Framework
 
Presto-Framework is a 2D game framework inspired by Sonic the Hedgehog, built using [raylib-d](https://github.com/schveiguy/raylib-d), a D language binding for the raylib library.

#### THIS PROJECT IS A WORK IN PROGRESS. ALL FILES ARE SUBJECT TO CHANGE.

## Features
- High-speed 2D platforming mechanics.
- Physics system tailored for Sonic-style gameplay.
- Level design tools for creating intricate stages.
- Modular and extensible architecture.

## Getting Started
1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/Presto-Framework.git
    ```
2. Install [raylib-d](https://github.com/schveiguy/raylib-d) dependencies.
3. Build and run the project:
    ```bash
    dub run
    ```

## Contributing
Contributions are welcome! Feel free to submit issues or pull requests to improve the framework.

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.

## Documentation

### Project Structure and Components

Here's a breakdown of the key directories and files in Presto-Framework:

*   **`source/app.d`**: The main entry point of the application. It initializes the game window and manages the main game loop.
*   **`source/scripts/`**: This directory contains the core gameplay logic.
    *   **`player/player.d`**: Handles the player character's logic, including movement, abilities, and interactions.
    *   **`world/`**: Contains scripts related to the game world, levels, and screen management.
        *   **`level.d`**: Manages loading, storing, and accessing level data.
        *   **`level_list.d`**: Defines the list of available levels and acts within the game.
        *   **`memory_manager.d`**: Responsible for managing game assets, loading and unloading resources to optimize memory usage.
        *   **`screen_manager.d`**: Controls the different game screens (e.g., title screen, game screen, settings) and transitions between them.
        *   **`screen_settings.d`**: Manages display settings like resolution, virtual resolution, scaling, and fullscreen mode.
        *   **`screen_states.d`**: Defines various states for screens and gameplay (e.g., playing, paused, game over).
*   **`resources/`**: This directory holds all game assets.
    *   **`data/levels/`**: Contains CSV files defining the layout and objects for each game level.
    *   **`image/`**: Stores images used in the game, such as spritesheets and tilemaps.
*   **`dub.json`**: The DUB package manager file. It defines project dependencies, build configurations, and other project metadata.
*   **`options.txt`**: (Likely to be `options.json` as seen in `memory_manager.d`) Stores user-configurable game settings.
*   **`README.md`**: This file, providing an overview of the project.
*   **`LICENSE`**: Contains the licensing information for the project (MIT License).

### Creating Levels with CSV and Tiled

Levels in Presto-Framework are defined using CSV (Comma Separated Values) files, which can be generated from the [Tiled Map Editor](https://www.mapeditor.org/). Here's a general workflow:

1.  **Design in Tiled**:
    *   Create your level in Tiled using tile layers.
    *   Each layer in Tiled will correspond to a specific CSV file (e.g., `LEVEL_0_Ground_1.csv`, `LEVEL_0_Objects_1.csv`).
    *   Ensure your tile dimensions and level layout match the game's requirements.
2.  **Export Layers as CSV**:
    *   For each layer in your Tiled map, use the "Export As" functionality and choose the CSV format.
    *   Name your files according to the convention expected by the `LevelManager` (e.g., `[LevelName]_[LayerName]_[ActNumber].csv`). Refer to `level_list.d` for `LayerNames` and `ActNumber` enums.
    *   Place these CSV files into the `resources/data/levels/[LevelName]/` directory. For example, for `LEVEL_0` and `ActNumber.ACT_1`, the path would be `resources/data/levels/LEVEL_0/`.
3.  **Define in `level_list.d`**:
    *   Ensure the `LevelList` enum in `source/scripts/world/level_list.d` includes an entry for your new level.
4.  **Loading in Game**:
    *   The `LevelManager` (`source/scripts/world/level.d`) will automatically attempt to load the CSV files based on the `LevelList` and `LayerNames` when a level is selected.
    *   The CSV data is parsed by `parser/csv_tile_loader.d` (Note: the actual parser is `csv_tile_loader.d` at the root of `source/`, not in a `parser/` subdirectory based on the provided file structure).

**CSV File Structure:**

Each CSV file represents a grid of tiles.
*   Each row in the CSV corresponds to a row of tiles in the game world.
*   Each comma-separated value in a row represents a tile ID.
*   A `-1` or an empty value typically signifies an empty tile. Other integer values correspond to specific tile types defined in your tileset and game logic.
    *   Alternatively, a `0` is usually where Sonic or a character will spawn.

Make sure your tilesets are correctly referenced and that the tile IDs in your CSV files match the intended tiles.


