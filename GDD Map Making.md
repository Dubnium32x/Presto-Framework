# Presto Framework Design Document Map Making
## Overview
This document outlines the design and implementation of map-making features within the Presto framework. It focuses on tools and systems that allow developers to create, edit, and manage game maps effectively.

## Using CSV
### CSV Format
- **Structure**: Each point in an array of a CSV file should be represented as a tile, whereas each tile could have a different heightmap. 
- **Tile Representation**: Each tile can be represented by a unique identifier, which corresponds to a specific tile type or asset in the game.
- **Heightmap**: Gathering information about a tile's heightmap is crucial, but it is not necessary to include this information in the CSV file. Instead, heightmap data can be managed separately or generated dynamically based on tile properties. Work towards either generating the heightmaps and angle of each tile individually or use a system that calculates it based on regression analysis of the tile's neighbors.

### CSV Parsing
- **Loading CSV Files**: Implement a parser that reads CSV files and converts them into a structured format that the game engine can understand. This may involve creating a data structure to hold tile information, such as tile type, position, and any additional properties.
- **Error Handling**: Ensure that the parser can handle errors gracefully, such as missing data or incorrect formatting. Provide clear error messages to help developers identify and fix issues in their CSV files.

## Level Management
### Level Structure
- **Level Definition**: Each level should be labeled as "Level_" + a unique identifier (e.g., "Level_1", "Level_2"). This helps in organizing levels and makes it easier to reference them in the code.
### Acts Versus Zones
- **Zones**: Zones are big areas that can contain multiple acts. They are used to group related levels together, providing a broader context for gameplay.
- **Acts**: Acts are smaller segments within a zone, typically representing a single level or a series of closely related levels. They allow for more granular control over gameplay pacing and progression.
- **Transitioning**: Implement a system for transitioning between acts and zones, ensuring that players can move seamlessly from one area to another. This may involve loading new assets, updating the game state, and     providing visual or audio cues for transitions.

### Level Loading
- **Dynamic Loading**: Implement a system that allows levels to be loaded dynamically based on player progress or game state. This can help manage memory usage and improve performance by only loading necessary assets.
- **Preloading**: Consider preloading assets for upcoming levels to reduce loading times during gameplay. This can be done in the background while the player is engaged in other activities, such as exploring a previous level or interacting with the game world. It may be good to consider putting together a cache system that stores frequently used assets in memory, allowing for quick access when needed.

## Useful Tools
### Map Editor
- **Tile Palette**: Provide a tile palette that allows developers to select and place tiles on the map. This should include options for different tile types, such as terrain, obstacles, and decorative elements. One such tool is Tiled, which is a free and open-source map editor that supports tile-based maps and can export to various formats, including CSV.
- **Layer Management**: Implement a system for managing multiple layers within a map, allowing developers to organize tiles and objects more effectively. This can include features such as layer visibility toggling, layer locking, and the ability to group related tiles together.

### Layer Management
- **Layer Types**: Define different types of layers, such as background, foreground, and collision layers. Each layer can have its own properties and behaviors, allowing for more complex map designs. Don't forget to refer to the Sonic Physics Guide for details about collision layers and layer transitions.
- **Layer Interactions**: Implement a system that allows layers to interact with each other, such as enabling or disabling collision detection based on the active layer. This can help streamline gameplay mechanics and improve performance by reducing unnecessary calculations.

### Object Placement
- **Object Types**: Allow developers to place various objects on the map, such as enemies, collectibles, and interactive elements. Each object should have properties that can be configured, such as position, size, and behavior.
- **Object Templates**: Provide a system for creating and managing object templates, allowing developers to reuse common object configurations across multiple levels. This can help maintain consistency and reduce development time when creating similar objects.
- **Object Scripting**: Implement a scripting system that allows developers to define custom behaviors for objects, such as movement patterns, animations, and interactions with other game elements.

### Exporting Maps
- **Export Formats**: Support exporting maps in various formats, such as CSV, JSON, or custom binary formats. This allows for flexibility in how maps are stored and loaded within the game. As long as it contains a tile array, it should be fine.
