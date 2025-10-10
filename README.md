# Presto Framework
![Presto Framework Logo](logo.jpg)

A high-performance, extensible Sonic-style game framework in C23, focusing on fast-paced platformer mechanics, physics, and modularity for rapid prototyping and development.

## Features
- High-speed running, acceleration, deceleration, jumping, rolling, and momentum-based physics.
- Loop-de-loops, slopes, springs, platforms, and interactive objects.
- Modular enemy behaviors, collision detection, damage, and invincibility frames.
- Rings, power-ups, shields, and score tracking.
- Smooth camera following, dynamic zoom, and parallax backgrounds.
- Entity Component System (ECS) for flexible game object management.
- Level loading, transitions, and state handling.
- Efficient handling of textures, sounds, and assets.
- Optional scripting for rapid prototyping (Lua or similar).
- In-game debug overlay, profiling, and logging.
- Cross-platform support: Windows, Linux, macOS.

## Getting Started
##### Presto Framework requires a C23 compatible compiler and the Raylib graphics library, and prefers Linux for development.
1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/presto-framework.git
    cd presto-framework
    ```
2. Install dependencies:
    ```bash
    # Install raylib (and any other dependencies)
    sudo apt-get install libraylib-dev
    ```
3. Build the project:
    ```bash
    mkdir build
    cd build
    cmake ..
    make
    ```
4. Run the example:
    ```bash
    ./example
    ```

## Documentation
Comprehensive documentation is available in the [docs](docs) directory, covering framework architecture, API reference, and usage examples.

We've also included the Sonic Physics Guide in markdown format for reference. Feel free to explore it [here](SPG/Sonic%20Physics%20Guide%20[PERSONAL].md).

## Contributing
Contributions are welcome! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

##### Presto Framework is an open-source project and is not affiliated with SEGA or the Sonic the Hedgehog franchise. Please do not confuse this project with official Sonic games or products.