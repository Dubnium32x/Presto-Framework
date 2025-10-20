![Presto-Framework Logo](res/image/logos/logo.jpg)

A high-performance, extensible Sonic-style game framework in C23, focusing on fast-paced platformer mechanics, physics, and modularity for rapid prototyping and development.

##### This is a public pre-alpha release. Expect bugs, incomplete features, and breaking changes.
#### Current Version: 0.1.2

## Features
- High-speed running, acceleration, deceleration, jumping, rolling, and momentum-based physics.
- Loop-de-loops, slopes, springs, platforms, and interactive objects.
- Modular enemy behaviors, collision detection, damage, and invincibility frames.
- Rings, power-ups, shields, and score tracking.
- Smooth camera following, dynamic zoom, and parallax backgrounds.
- Entity Component System (ECS) for flexible game object management.
- Level loading, transitions, and state handling.
- **Module Music Player**: Built-in support for XM, IT, S3M, MOD, and other tracker formats via libmikmod.
- Efficient handling of textures, sounds, and assets.
- Optional scripting for rapid prototyping (Lua or similar).
- In-game debug overlay, profiling, and logging.
- Cross-platform support: Windows, Linux, macOS.

## Getting Started
##### Presto Framework requires a C23 compatible compiler and the Raylib graphics library, and prefers Linux for development.

### Requirements
- GCC with C23 support (GCC 14+ recommended)
- Raylib graphics library
- libmikmod (for module music support)
- Make build system

### Installation

#### Linux
1. Install required dependencies:
    ```bash
    sudo apt-get install build-essential gcc-14 g++-14 libraylib-dev libmikmod-dev mingw-w64
    ```
    Or use the automated installer:
    ```bash
    make install-mikmod  # Installs libmikmod for module music support
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
1. Install [MSYS2](https://www.msys2.org/) and set up the environment.
2. Install Raylib and MikMod via pacman:
    ```bash
    pacman -Syu
    pacman -S mingw-w64-x86_64-libmikmod
    pacman -S mingw-w64-x86_64-raylib
    ```

##### Be sure to restart the MSYS2 terminal after updating the package database!
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


#### Mac
1. Install Raylib - You can install via Homebrew
    ```bash
    brew install raylib
    ```
2. Install MikMod - Can also be installed via Homebrew
    ```bash
    brew install mikmod
    ```
2. Clone the repository:
    ```bash
    git clone https://github.com/Dubnium32x/Presto-Framework.git
    ```
3. Open the terminal app via spotlight (⌘space) and change your directory to the cloned git
4. Build the project:
    ```bash
    make macapp
    ```
5. The project should be built by then. check the bin folder or type the following command:
    ```bash
    make run
    ```
#### For both Windows and Mac, you can also use Cygwin, WSL, or a Linux VM for a more consistent development environment.
##### It is definitely a better idea to create a hackintosh or VM of one than it is to run this project from a real Mac.

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

We've also included the Sonic Physics Guide in markdown format for reference. Feel free to explore it [here](docs/SPG/Sonic%20Physics%20Guide%20[PERSONAL].md).

## Contributing
Contributions are welcome! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

##### Presto Framework is an open-source project and is not affiliated with SEGA or the Sonic the Hedgehog franchise. Please do not confuse this project with official Sonic games or products.
