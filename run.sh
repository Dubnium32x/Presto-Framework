#!/bin/bash
# This script is used to run the Presto Framework with Sonic physics engine.
# First, we need to activate the dmd environment
source ~/dlang/dmd-2.110.0/activate.sh

# Ensure we're in the correct directory
cd "$(dirname "$0")"
echo "Running from directory: $(pwd)"

# List the tileset files to verify they exist
echo "Checking for tileset files:"
ls -la resources/image/tilemap/

# Run the game
dub run