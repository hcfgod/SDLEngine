#!/bin/bash

echo "Setting up Limitless project..."

# Check if the download script exists
if [ ! -f "scripts/download_premake.sh" ]; then
    echo "Error: download_premake.sh not found!"
    exit 1
fi

# Make the download script executable
chmod +x scripts/download_premake.sh

# Run the download script
echo "Downloading Premake..."
./scripts/download_premake.sh

if [ $? -ne 0 ]; then
    echo "Error: Failed to download Premake."
    exit 1
fi

# Make premake5 executable
chmod +x tools/premake5

# Install dependencies
echo "Installing dependencies (SDL3, ImGui, doctest)..."
chmod +x scripts/install_deps.sh
./scripts/install_deps.sh

# Generate Makefiles
echo "Generating Makefiles..."
./tools/premake5 gmake2

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate project files."
    exit 1
fi

# Build the project automatically (use root Makefile, select proper config and parallel jobs)
echo "Building the project..."

# Determine platform suffix for premake/gmake (x64 or ARM64)
UNAME_M=$(uname -m 2>/dev/null || echo "")
PLATFORM="x64"
case "$UNAME_M" in
  aarch64|arm64) PLATFORM="ARM64" ;;
esac

# Default configuration to build
DEFAULT_CONFIG="debug_${PLATFORM}"

# Determine parallel jobs
if command -v nproc >/dev/null 2>&1; then
  JOBS=$(nproc)
elif command -v sysctl >/dev/null 2>&1; then
  JOBS=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
else
  JOBS=4
fi

make config=${DEFAULT_CONFIG} -j${JOBS}

if [ $? -ne 0 ]; then
    echo "Error: Failed to build the project."
    exit 1
fi

echo ""
echo "Setup completed successfully!"
echo ""
echo "Build completed!"
echo ""
echo "To run the sandbox application (example for Linux x64):"
echo "  ./Build/debug-linux-x64/Sandbox/Sandbox"
echo ""
echo "To run the tests (example for Linux x64):"
echo "  ./Build/Debug-linux-x64/Test/Test"
echo ""
echo "Note: On Linux and macOS, executables don't have .exe extensions."
echo ""
