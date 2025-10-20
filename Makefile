# Makefile for Presto Framework - Sonic C23 Game Engine

# Compiler and flags
CC = gcc

# Try to detect raylib using pkg-config first
RAYLIB_PKG := $(shell pkg-config --exists raylib 2>/dev/null && echo "yes" || echo "no")
MIKMOD_PKG := $(shell pkg-config --exists libmikmod 2>/dev/null && echo "yes" || echo "no")

ifeq ($(RAYLIB_PKG),yes)
    # Use pkg-config if available
    RAYLIB_CFLAGS := $(shell pkg-config --cflags raylib)
    RAYLIB_LDFLAGS := $(shell pkg-config --libs raylib)
else
    # Fallback: try common installation paths
    RAYLIB_PATHS := /usr/local/include /usr/include /opt/raylib/include ~/raylib/src ./raylib/src
    RAYLIB_LIB_PATHS := /usr/local/lib /usr/lib /opt/raylib/lib ~/raylib/src ./raylib/src
    
    # Find raylib header and library (prefer same directory)
    RAYLIB_FOUND_PATH := $(shell for path in $(RAYLIB_PATHS); do \
        if [ -f "$$path/raylib.h" ]; then \
            echo "$$path"; \
            break; \
        fi \
    done)
    
    # Set include path
    RAYLIB_INCLUDE := $(if $(RAYLIB_FOUND_PATH),-I$(RAYLIB_FOUND_PATH),)
    
    # Try to find library in the same directory as header first, then in standard lib paths
    RAYLIB_LIBDIR := $(shell \
        if [ -n "$(RAYLIB_FOUND_PATH)" ] && [ -f "$(RAYLIB_FOUND_PATH)/libraylib.a" -o -f "$(RAYLIB_FOUND_PATH)/libraylib.so" ]; then \
            echo "-L$(RAYLIB_FOUND_PATH)"; \
        else \
            for path in $(RAYLIB_LIB_PATHS); do \
                if [ -f "$$path/libraylib.a" ] || [ -f "$$path/libraylib.so" ]; then \
                    echo "-L$$path"; \
                    break; \
                fi \
            done; \
        fi)
    
    RAYLIB_CFLAGS := $(RAYLIB_INCLUDE)
    RAYLIB_LDFLAGS := $(RAYLIB_LIBDIR) -lraylib -lm -lpthread -ldl -lrt -lX11
endif

# Handle libmikmod detection
ifeq ($(MIKMOD_PKG),yes)
    # Use pkg-config if available
    MIKMOD_CFLAGS := $(shell pkg-config --cflags libmikmod)
    MIKMOD_LDFLAGS := $(shell pkg-config --libs libmikmod)
else ifeq ($(shell uname),Darwin)
    # macOS-specific paths (check Homebrew)
    ifneq ($(wildcard /opt/homebrew/include/mikmod.h),)
        # Apple Silicon Homebrew
        MIKMOD_CFLAGS := -I/opt/homebrew/include
        MIKMOD_LDFLAGS := -L/opt/homebrew/lib -lmikmod
    else ifneq ($(wildcard /usr/local/include/mikmod.h),)
        # Intel Mac Homebrew
        MIKMOD_CFLAGS := -I/usr/local/include
        MIKMOD_LDFLAGS := -L/usr/local/lib -lmikmod
    else
        # macOS fallback paths
        ifneq ($(wildcard /usr/include/mikmod.h),)
            MIKMOD_CFLAGS := -I/usr/include
            MIKMOD_LDFLAGS := -lmikmod
        endif
    endif
else
    # Default paths for other systems
    ifneq ($(wildcard /usr/include/mikmod.h),)
        MIKMOD_CFLAGS := -I/usr/include
        MIKMOD_LDFLAGS := -lmikmod
    endif
endif

# Final compiler flags
CFLAGS = -Wall -Wextra -std=c2x -O2 $(RAYLIB_CFLAGS) $(MIKMOD_CFLAGS) -Isrc
DEBUG_CFLAGS = -Wall -Wextra -std=c2x -g -DDEBUG $(RAYLIB_CFLAGS) $(MIKMOD_CFLAGS) -Isrc
LDFLAGS = $(RAYLIB_LDFLAGS) $(MIKMOD_LDFLAGS)

# Directories
SRCDIR = src
OBJDIR = obj
BINDIR = bin

# Source files
MAIN_SRC = $(SRCDIR)/main.c
FRAMEWORK_SRCS = $(wildcard $(SRCDIR)/*/*.c) $(wildcard $(SRCDIR)/*/*/*.c)
ALL_SRCS = $(MAIN_SRC) $(FRAMEWORK_SRCS)

# Output targets
MAIN_OUT = $(BINDIR)/presto-framework
DEBUG_OUT = $(BINDIR)/presto-framework-debug

# Windows cross-build output
WINDOWS_OUT = $(BINDIR)/presto-framework.exe

# Check if raylib is available
check-raylib:
	@echo "Checking for raylib..."
ifeq ($(RAYLIB_PKG),yes)
	@echo "✓ Found raylib via pkg-config"
	@echo "  CFLAGS: $(RAYLIB_CFLAGS)"
	@echo "  LDFLAGS: $(RAYLIB_LDFLAGS)"
else ifneq ($(RAYLIB_CFLAGS),)
	@echo "✓ Found raylib at: $(RAYLIB_CFLAGS)"
	@echo "  LDFLAGS: $(RAYLIB_LDFLAGS)"
else
	@echo "✗ raylib not found!"
	@echo ""
	@echo "Please install raylib using one of these methods:"
	@echo "1. Package manager: sudo apt install libraylib-dev (Ubuntu/Debian)"
	@echo "2. From source: make install-raylib"
	@echo "3. Place raylib in one of these directories:"
	@echo "   - /usr/local/include and /usr/local/lib"
	@echo "   - ~/raylib/src"
	@echo "   - ./raylib/src"
	@false
endif
	@echo ""
	@echo "Checking for libmikmod..."
ifeq ($(MIKMOD_PKG),yes)
	@echo "✓ Found libmikmod via pkg-config"
	@echo "  CFLAGS: $(MIKMOD_CFLAGS)"
	@echo "  LDFLAGS: $(MIKMOD_LDFLAGS)"
else ifneq ($(MIKMOD_INCLUDE),)
	@echo "✓ Found libmikmod at: $(MIKMOD_FOUND_PATH)"
	@echo "  CFLAGS: $(MIKMOD_CFLAGS)"
	@echo "  LDFLAGS: $(MIKMOD_LDFLAGS)"
else
	@echo "✗ libmikmod not found!"
	@echo ""
	@echo "Please install libmikmod:"
	@if [ "$(shell uname)" = "Darwin" ]; then \
		echo "On macOS:"; \
		echo "  brew install libmikmod"; \
	else \
		echo "Ubuntu/Debian: sudo apt install libmikmod-dev"; \
		echo "CentOS/RHEL:  sudo yum install libmikmod-devel"; \
		echo "Arch Linux:   sudo pacman -S libmikmod"; \
	fi
endif

# Default goal: build directly when running `make`
.DEFAULT_GOAL := build

# 'all' runs environment checks then builds (keeps previous behavior for CI/doctor runs)
all: check-raylib build

# Create necessary directories
directories:
	@mkdir -p $(OBJDIR) $(BINDIR)

# Build main demo (release) - builds both Linux and Windows versions
build: directories $(MAIN_OUT) $(WINDOWS_OUT)

$(MAIN_OUT): $(ALL_SRCS)
	$(CC) $(CFLAGS) $(ALL_SRCS) -o $(MAIN_OUT) $(LDFLAGS)

# Build main demo (debug)
debug: directories $(DEBUG_OUT)

$(DEBUG_OUT): $(ALL_SRCS)
	$(CC) $(DEBUG_CFLAGS) $(ALL_SRCS) -o $(DEBUG_OUT) $(LDFLAGS)

# Run the demo
run: $(MAIN_OUT)
	./$(MAIN_OUT)

# Run debug version
run-debug: $(DEBUG_OUT)
	./$(DEBUG_OUT)

# Clean build artifacts
clean:
	rm -rf $(OBJDIR) $(BINDIR) *.missing

# Framework development targets
framework: directories
	@echo "Framework compilation targets will be added here"

# Install raylib from source
install-raylib:
	@echo "Installing raylib from source..."
	@if [ ! -d "$(HOME)/raylib" ]; then \
		echo "Cloning raylib..."; \
		git clone https://github.com/raysan5/raylib.git $(HOME)/raylib; \
	else \
		echo "raylib directory exists, updating..."; \
		cd $(HOME)/raylib && git pull; \
	fi
	@echo "Building raylib..."
	@cd $(HOME)/raylib/src && make PLATFORM=PLATFORM_DESKTOP
	@echo "✓ raylib installed to $(HOME)/raylib"
	@echo "  You can now run 'make' to build the project"

# Install libmikmod for module music support
install-mikmod:
	@echo "Installing libmikmod..."
	@if command -v apt >/dev/null 2>&1; then \
		echo "Using apt to install libmikmod..."; \
		sudo apt update && sudo apt install libmikmod-dev libmikmod3; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "Using yum to install libmikmod..."; \
		sudo yum install libmikmod-devel; \
	elif command -v pacman >/dev/null 2>&1; then \
		echo "Using pacman to install libmikmod..."; \
		sudo pacman -S libmikmod; \
	else \
		echo "Package manager not detected. Please install libmikmod manually."; \
		echo "Ubuntu/Debian: sudo apt install libmikmod-dev libmikmod3"; \
		echo "CentOS/RHEL: sudo yum install libmikmod-devel"; \
		echo "Arch: sudo pacman -S libmikmod"; \
	fi
	@echo "✓ libmikmod installation completed"

# Environment diagnostics (checks raylib and prints detected flags)
doctor: check-raylib

# Alias for convenience
raylib-check: check-raylib

# Help target
help:
	@echo "Presto Framework - Sonic C23 Game Engine"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build the Sonic demo (default)"
	@echo "  debug        - Build debug version"
	@echo "  run          - Build and run the Sonic demo"
	@echo "  run-debug    - Build and run debug version"
	@echo "  clean        - Remove build artifacts"
	@echo "  check-raylib - Check raylib installation"
	@echo "  install-raylib - Install raylib from source"
	@echo "  install-mikmod - Install libmikmod for module music support"
	@echo "  framework    - Framework development (WIP)"
	@echo "  mac          - Build macOS binary (uses clang/frameworks)"
	@echo "  help         - Show this help message"
	@echo "  doctor       - Run environment checks (raylib detection)"
	@echo "  raylib-check - Alias for check-raylib"

.PHONY: all debug run run-debug clean directories framework install-raylib install-mikmod check-raylib help

# -----------------------------
# Cross-compile for Windows
# -----------------------------
# Configure cross-compiler (change if you have a different toolchain)
MINGW_CC ?= x86_64-w64-mingw32-gcc
MINGW_CFLAGS ?= -O2 -std=c2x -Wall -Wextra -I/usr/x86_64-w64-mingw32/include -Isrc
MINGW_LDFLAGS ?= -L/usr/x86_64-w64-mingw32/lib -lraylib -lopengl32 -lgdi32 -lwinmm -lws2_32 -lwinpthread

.PHONY: windows
windows: directories $(WINDOWS_OUT)

$(WINDOWS_OUT): $(ALL_SRCS)
	@if command -v $(MINGW_CC) >/dev/null 2>&1; then \
		echo "Building Windows version..."; \
		if echo '#include "raylib.h"' | $(MINGW_CC) $(MINGW_CFLAGS) -E - >/dev/null 2>&1; then \
			$(MINGW_CC) $(MINGW_CFLAGS) $(ALL_SRCS) -o $(WINDOWS_OUT) $(MINGW_LDFLAGS); \
		else \
			echo "Warning: raylib headers not found for Windows cross-compilation."; \
			echo "Install raylib for MinGW or build raylib for Windows cross-compilation."; \
			touch $(WINDOWS_OUT).missing; \
		fi; \
	else \
		echo "Warning: Cross-compiler '$(MINGW_CC)' not found. Skipping Windows build."; \
		echo "Install mingw-w64 to enable Windows builds: sudo apt install mingw-w64"; \
		touch $(WINDOWS_OUT).missing; \
	fi



# -----------------------------
# Mac OS build target
# -----------------------------
# Provide a convenient `make mac` target for building on macOS or from a macOS
# host. This uses `clang` by default and links common macOS frameworks needed by
# SDL/OpenGL/raylib builds. If raylib is available via pkg-config the detected
# flags will be used; otherwise fallback framework flags are appended.

MAC_CC ?= clang
# Add Homebrew include paths for Apple Silicon and Intel Macs
MAC_EXTRA_INCLUDES = -I/opt/homebrew/include -I/usr/local/include
MAC_EXTRA_LIBDIRS = -L/opt/homebrew/lib -L/usr/local/lib

MAC_CFLAGS ?= -O2 -std=c2x -Wall -Wextra $(RAYLIB_CFLAGS) $(MIKMOD_CFLAGS) $(MAC_EXTRA_INCLUDES) -Isrc
MAC_LDFLAGS ?= $(MAC_EXTRA_LIBDIRS) $(RAYLIB_LDFLAGS) $(MIKMOD_LDFLAGS) -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo -lm

MAC_OUT = $(BINDIR)/presto-framework-mac

.PHONY: mac
mac: directories $(MAC_OUT)

$(MAC_OUT): $(ALL_SRCS)
	@if [ "$(shell uname)" != "Darwin" ]; then \
		echo "Note: You're not on macOS; building for macOS may fail unless cross-tools are available."; \
	fi; \
	if command -v $(MAC_CC) >/dev/null 2>&1; then \
		echo "Building macOS binary with $(MAC_CC)..."; \
		$(MAC_CC) $(MAC_CFLAGS) $(ALL_SRCS) -o $(MAC_OUT) $(MAC_LDFLAGS); \
	else \
		echo "Error: '$(MAC_CC)' not found. Install clang or set MAC_CC to an available compiler."; \
		exit 1; \
	fi

# Build a macOS .app bundle containing the executable and resources so resources
# load correctly when double-clicking the app. Creates `bin/presto-framework.app`.
MAC_APP = $(BINDIR)/presto-framework.app

.PHONY: macapp
macapp: mac
	@echo "Creating macOS .app bundle..."
	@rm -rf $(MAC_APP)
	@mkdir -p $(MAC_APP)/Contents/MacOS
	@mkdir -p $(MAC_APP)/Contents/Resources
	# Copy the built mac binary
	@cp $(MAC_OUT) $(MAC_APP)/Contents/MacOS/presto-framework
	@chmod +x $(MAC_APP)/Contents/MacOS/presto-framework
	# Create a minimal Info.plist
	@printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' > $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '<plist version="1.0">' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '<dict>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <key>CFBundleName</key>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <string>Presto Framework</string>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <key>CFBundleDisplayName</key>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <string>Presto Framework</string>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <key>CFBundleExecutable</key>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <string>presto-framework</string>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <key>CFBundleIdentifier</key>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <string>com.dubnium32x.presto-framework</string>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <key>CFBundleVersion</key>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <string>1.0</string>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <key>CFBundlePackageType</key>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <string>APPL</string>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <key>LSMinimumSystemVersion</key>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '  <string>10.10</string>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '</dict>' >> $(MAC_APP)/Contents/Info.plist
	@printf '%s\n' '</plist>' >> $(MAC_APP)/Contents/Info.plist
	# PkgInfo
	@echo 'APPL????' > $(MAC_APP)/Contents/PkgInfo
	# Copy resources (images, audio, data) into Resources
	@echo "Copying resources to app bundle..."
	@if [ -d res ]; then \
		mkdir -p $(MAC_APP)/Contents/Resources/res && \
		cp -Rv res/* $(MAC_APP)/Contents/Resources/res/ || true; \
	else \
		echo "Warning: res directory not found"; \
	fi
	@echo "Copying options.ini to app bundle..."
	@if [ -f options.ini ]; then \
		cp -v options.ini $(MAC_APP)/Contents/Resources/ || true; \
	else \
		echo "Warning: options.ini not found"; \
	fi
	@echo ".app bundle created at $(MAC_APP)"
	@echo "Resource path structure:"
	@ls -R $(MAC_APP)/Contents/Resources/

