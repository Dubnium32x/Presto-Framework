# Makefile for Presto Framework - Sonic C23 Game Engine

# Compiler and flags
CC = gcc

# Try to detect raylib using pkg-config first
RAYLIB_PKG := $(shell pkg-config --exists raylib 2>/dev/null && echo "yes" || echo "no")

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

# Final compiler flags
CFLAGS = -Wall -Wextra -std=c2x -O2 $(RAYLIB_CFLAGS) -Isrc
DEBUG_CFLAGS = -Wall -Wextra -std=c2x -g -DDEBUG $(RAYLIB_CFLAGS) -Isrc
LDFLAGS = $(RAYLIB_LDFLAGS)

# Directories
SRCDIR = src
OBJDIR = obj
BINDIR = bin

# Source files
MAIN_SRC = $(SRCDIR)/main.c
FRAMEWORK_SRCS = $(wildcard $(SRCDIR)/presto/*.c)

# Output targets
MAIN_OUT = $(BINDIR)/presto_demo
DEBUG_OUT = $(BINDIR)/presto_demo_debug

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

# Default target
all: check-raylib directories $(MAIN_OUT)

# Create necessary directories
directories:
	@mkdir -p $(OBJDIR) $(BINDIR)

# Build main demo (release)
$(MAIN_OUT): $(MAIN_SRC)
	$(CC) $(CFLAGS) $(MAIN_SRC) -o $(MAIN_OUT) $(LDFLAGS)

# Build main demo (debug)
debug: directories $(DEBUG_OUT)

$(DEBUG_OUT): $(MAIN_SRC)
	$(CC) $(DEBUG_CFLAGS) $(MAIN_SRC) -o $(DEBUG_OUT) $(LDFLAGS)

# Run the demo
run: $(MAIN_OUT)
	./$(MAIN_OUT)

# Run debug version
run-debug: $(DEBUG_OUT)
	./$(DEBUG_OUT)

# Clean build artifacts
clean:
	rm -rf $(OBJDIR) $(BINDIR)

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
	@echo "  framework    - Framework development (WIP)"
	@echo "  help         - Show this help message"

.PHONY: all debug run run-debug clean directories framework install-raylib check-raylib help