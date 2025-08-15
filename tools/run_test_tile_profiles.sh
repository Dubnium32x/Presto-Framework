#!/usr/bin/env bash
set -euo pipefail

# Compile and run the tile profile smoke test harness.
# Usage: ./tools/run_test_tile_profiles.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v dmd >/dev/null 2>&1; then
  echo "dmd not found. Install DMD or use dub."
  exit 1
fi

echo "Compiling test harness with dmd..."
dmd -Isource/scripts -I. tools/test_tile_profiles.d \
    source/scripts/world/tileset_map.d \
    source/scripts/world/generated_heightmaps.d \
    source/scripts/world/tile_collision.d \
    -of=tools/test_tile_profiles

echo "Running test..."
./tools/test_tile_profiles
