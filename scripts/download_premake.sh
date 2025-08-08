#!/bin/bash

# Linux/macOS script to download and setup Premake
# This script downloads the latest version of Premake and sets it up for the project

# Default values
VERSION=${1:-"5.0.0-beta2"}
PLATFORM=${2:-"linux"}

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

echo "Setting up Premake for $PLATFORM..."

# Create scripts directory if it doesn't exist
if [ ! -d "scripts" ]; then
    mkdir -p scripts
fi

# Create tools directory if it doesn't exist
if [ ! -d "tools" ]; then
    mkdir -p tools
fi

# Check if premake5 already exists
if [ -f "tools/premake5" ]; then
    echo "Premake5 already exists in tools directory. Skipping download."
    echo "You can now run: ./tools/premake5 [action]"
    exit 0
fi

# Determine the correct Premake version and platform
PREMAKE_VERSION=$VERSION
PREMAKE_PLATFORM=$PLATFORM

# Download URL for Premake
if [ "$PLATFORM" = "macos" ]; then
    DOWNLOAD_URL="https://github.com/premake/premake-core/releases/download/v$PREMAKE_VERSION/premake-$PREMAKE_VERSION-macos.tar.gz"
    ARCHIVE_PATH="tools/premake-$PREMAKE_VERSION-macos.tar.gz"
    EXTRACT_PATH="tools/premake"
else
    DOWNLOAD_URL="https://github.com/premake/premake-core/releases/download/v$PREMAKE_VERSION/premake-$PREMAKE_VERSION-linux.tar.gz"
    ARCHIVE_PATH="tools/premake-$PREMAKE_VERSION-linux.tar.gz"
    EXTRACT_PATH="tools/premake"
fi

echo "Downloading Premake v$PREMAKE_VERSION for $PLATFORM..."

# Download Premake
if command -v curl &> /dev/null; then
    curl -L -o "$ARCHIVE_PATH" "$DOWNLOAD_URL"
elif command -v wget &> /dev/null; then
    wget -O "$ARCHIVE_PATH" "$DOWNLOAD_URL"
else
    echo "Error: Neither curl nor wget is installed. Please install one of them."
    exit 1
fi

if [ $? -ne 0 ]; then
    echo "Failed to download Premake!"
    exit 1
fi

echo "Download completed successfully!"

# Extract the archive
echo "Extracting Premake..."
mkdir -p "$EXTRACT_PATH"
tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_PATH"

if [ $? -ne 0 ]; then
    echo "Failed to extract Premake!"
    exit 1
fi

echo "Extraction completed!"

# Move premake5 to tools directory
PREMAKE_BIN="$EXTRACT_PATH/premake5"
if [ -f "$PREMAKE_BIN" ]; then
    cp "$PREMAKE_BIN" "tools/premake5"
    chmod +x "tools/premake5"
    echo "Premake5 copied to tools directory!"
else
    echo "Premake5 not found in extracted files!"
    exit 1
fi

# Clean up
rm -f "$ARCHIVE_PATH"
rm -rf "$EXTRACT_PATH"

echo "Premake setup completed successfully!"
echo "You can now run: ./tools/premake5 [action]"
