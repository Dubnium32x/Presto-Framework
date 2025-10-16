![Presto-Framework Logo](res/image/logos/logo.jpg)

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

### Requirements
- GCC with C23 support (GCC 14+ recommended)
- Raylib graphics library
- Make build system

### Installation

#### Linux
1. Install required dependencies:
    ```bash
    sudo apt-get install build-essential gcc-14 g++-14 libraylib-dev mingw-w64
    ```
2. Clone the repository:
    ```bash
    git clone https://github.com/Dubnium32x/Presto-Framework.git
    cd Presto-Framework
    ```
3. Clone raylib if not installed:
    ```bash
    cd ~
    git clone https://github.com/raysan5/raylib.git
    ```
4. Build raylib:
    ```bash
    cd raylib/src
    make PLATFORM=PLATFORM_DESKTOP
    sudo make install
    ```
5. Return to Presto Framework directory:
    ```bash
    cd ~/Presto-Framework
    ```
6. Build the project:
    ```bash
    make
    ```
7. Run the demo:
    ```bash
    make run
    ```

#### Windows
1. Install [MinGW-w64](http://mingw-w64.org/doku.php) and ensure `gcc` and `g++` are in your PATH.
2. Install [Raylib for Windows](https://github.com/raysan5/raylib/releases).
3. Clone the repository:
    ```bash
    git clone https://github.com/Dubnium32x/Presto-Framework.git
    ```
4. Open a terminal in the Presto Framework directory.
5. Build the project:
    ```bash
    make
    ```
6. Run the demo:
    ```bash
    make run
    ```
##### You can also use Cygwin, WSL, or a Linux VM for a more consistent development environment.

### Demo Controls
- **Arrow Keys**: Move Sonic left/right
- **Z/X/C**: Jump, Roll, Spin Dash
- **Enter**: Start/Restart/Pause
- **P**: Toggle debug overlay
- **ESC**: Exit

### Build Options
```bash
make           # Check raylib, build release version
make all       # Builds all versions
make debug     # Builds debug version
make run       # Runs the game
make clean     # Cleans build files
make help      # Shows all targets
```

## Documentation
Comprehensive documentation is available in the [docs](docs) directory, covering framework architecture, API reference, and usage examples.

We've also included the Sonic Physics Guide in markdown format for reference. Feel free to explore it [here](SPG/Sonic%20Physics%20Guide%20[PERSONAL].md).

## Contributing
Contributions are welcome! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

##### Presto Framework is an open-source project and is not affiliated with SEGA or the Sonic the Hedgehog franchise. Please do not confuse this project with official Sonic games or products.