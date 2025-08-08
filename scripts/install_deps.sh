#!/usr/bin/env bash

set -euo pipefail

# Cross-platform dependency installer for:
#  - doctest (header-only)
#  - dear imgui (docking branch)
#  - SDL3 (via package manager when available, otherwise from source)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Engine/Vendor"
TOOLS_DIR="$ROOT_DIR/tools"
TMP_DIR="${TMPDIR:-/tmp}/limitless_deps"

DOCTEST_VERSION="v2.4.12"
SDL3_VERSION="release-3.2.20"
SPDLOG_VERSION="v1.15.3"
NLOHMANN_VERSION="v3.12.0"
GLM_VERSION="1.0.1"

mkdir -p "$VENDOR_DIR" "$TOOLS_DIR" "$TMP_DIR"

log() { echo "[install_deps] $*"; }
err() { echo "[install_deps][ERROR] $*" >&2; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

download() {
  local url="$1" dst="$2"
  if have_cmd curl; then
    curl -L --fail --retry 3 -o "$dst" "$url"
  elif have_cmd wget; then
    wget -O "$dst" "$url"
  else
    err "Neither curl nor wget is available"
    return 1
  fi
}

install_doctest() {
  local dst_dir="$VENDOR_DIR/doctest"
  local hdr="$dst_dir/doctest.h"
  if [[ -f "$hdr" ]]; then
    log "doctest already present → $hdr"
    return 0
  fi
  log "Installing doctest ($DOCTEST_VERSION)"
  mkdir -p "$dst_dir"
  local url="https://raw.githubusercontent.com/doctest/doctest/${DOCTEST_VERSION}/doctest/doctest.h"
  download "$url" "$hdr"
  log "doctest installed → $hdr"
}

install_spdlog() {
  local dst_dir="$VENDOR_DIR/spdlog"
  local hdr="$dst_dir/spdlog.h"
  if [[ -f "$hdr" ]]; then
    log "spdlog already present → $hdr"
    return 0
  fi
  log "Installing spdlog ($SPDLOG_VERSION)"
  mkdir -p "$dst_dir"
  
  # Download and extract spdlog
  local zip="$TMP_DIR/spdlog.zip"
  download "https://github.com/gabime/spdlog/archive/refs/tags/${SPDLOG_VERSION}.zip" "$zip"
  
  local extract_dir="$TMP_DIR/spdlog-extract"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"
  
  if have_cmd unzip; then
    unzip -q "$zip" -d "$extract_dir"
  elif have_cmd tar; then
    tar -xf "$zip" -C "$extract_dir"
  else
    err "No unzip or tar available"
    return 1
  fi
  
  # Find the extracted directory (it might be named differently)
  local extracted_dir
  # Avoid matching the extraction root directory itself (named spdlog-extract)
  # by requiring at least one level of depth.
  extracted_dir="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d -name 'spdlog-*' | head -n1)"
  if [[ -z "$extracted_dir" || ! -d "$extracted_dir" ]]; then
    log "Available directories in extract: $(ls -la "$extract_dir")"
    err "Failed to find spdlog extracted directory"
    return 1
  fi
  
  local include_path="$extracted_dir/include/spdlog"
  if [[ -d "$include_path" ]]; then
    cp -r "$include_path" "$dst_dir/"
    log "spdlog installed → $dst_dir"
  else
    log "Include path not found: $include_path"
    log "Available in extracted dir: $(find "$extracted_dir" -type f | head -10)"
    err "Failed to find spdlog include directory"
    return 1
  fi
}

install_imgui_docking() {
  local dst_dir="$VENDOR_DIR/imgui"
  if [[ -d "$dst_dir" ]]; then
    log "imgui (docking) already present → $dst_dir"
    return 0
  fi
  log "Installing dear imgui (docking branch)"
  local zip="$TMP_DIR/imgui-docking.zip"
  download "https://codeload.github.com/ocornut/imgui/zip/refs/heads/docking" "$zip"
  unzip -q "$zip" -d "$TMP_DIR"
  # Extracted folder is typically imgui-docking
  local src_dir
  src_dir="$(find "$TMP_DIR" -maxdepth 1 -type d -name 'imgui-*' | head -n1)"
  if [[ -z "$src_dir" || ! -d "$src_dir" ]]; then
    err "Failed to locate extracted imgui directory"
    return 1
  fi
  mv "$src_dir" "$dst_dir"
  log "imgui (docking) installed → $dst_dir"
}

install_nlohmann_json() {
  local hdr="$VENDOR_DIR/nlohmann/json.hpp"
  if [[ -f "$hdr" ]]; then
    log "nlohmann/json already present → $hdr"
    return 0
  fi
  log "Installing nlohmann/json ($NLOHMANN_VERSION)"

  local zip="$TMP_DIR/nlohmann-json.zip"
  download "https://github.com/nlohmann/json/archive/refs/tags/${NLOHMANN_VERSION}.zip" "$zip"

  local extract_dir="$TMP_DIR/nlohmann-json-extract"
  rm -rf "$extract_dir" && mkdir -p "$extract_dir"
  if have_cmd unzip; then
    unzip -q "$zip" -d "$extract_dir"
  elif have_cmd tar; then
    tar -xf "$zip" -C "$extract_dir"
  else
    err "No unzip or tar available"
    return 1
  fi

  local extracted_dir
  extracted_dir="$(find "$extract_dir" -maxdepth 1 -type d -name 'json-*' | head -n1)"
  if [[ -z "$extracted_dir" || ! -d "$extracted_dir" ]]; then
    err "Failed to extract nlohmann/json archive"
    return 1
  fi

  local single_include="$extracted_dir/single_include/nlohmann"
  local full_include="$extracted_dir/include/nlohmann"
  if [[ -d "$single_include" ]]; then
    cp -r "$single_include" "$VENDOR_DIR/"
  elif [[ -d "$full_include" ]]; then
    cp -r "$full_include" "$VENDOR_DIR/"
  else
    err "nlohmann/json headers not found in extracted archive"
    return 1
  fi
  log "nlohmann/json installed → $VENDOR_DIR/nlohmann"
}

install_glm() {
  local hdr="$VENDOR_DIR/glm/glm.hpp"
  if [[ -f "$hdr" ]]; then
    log "glm already present → $hdr"
    return 0
  fi
  log "Installing GLM ($GLM_VERSION)"

  local zip="$TMP_DIR/glm.zip"
  download "https://github.com/g-truc/glm/archive/refs/tags/${GLM_VERSION}.zip" "$zip"

  local extract_dir="$TMP_DIR/glm-extract"
  rm -rf "$extract_dir" && mkdir -p "$extract_dir"
  if have_cmd unzip; then
    unzip -q "$zip" -d "$extract_dir"
  elif have_cmd tar; then
    tar -xf "$zip" -C "$extract_dir"
  else
    err "No unzip or tar available"
    return 1
  fi

  local extracted_dir
  extracted_dir="$(find "$extract_dir" -maxdepth 1 -type d -name 'glm-*' | head -n1)"
  if [[ -z "$extracted_dir" || ! -d "$extracted_dir" ]]; then
    err "Failed to extract GLM archive"
    return 1
  fi

  local include_dir="$extracted_dir/glm"
  if [[ -d "$include_dir" ]]; then
    cp -r "$include_dir" "$VENDOR_DIR/"
  else
    err "GLM include directory not found in extracted archive"
    return 1
  fi
  log "GLM installed → $VENDOR_DIR/glm"
}

build_sdl3_from_source() {
  local install_prefix="$VENDOR_DIR/SDL3"
  # Only skip if headers and at least one library file exist
  if [[ -d "$install_prefix/include/SDL3" ]]; then
    if [[ -f "$install_prefix/lib/SDL3-static.lib" || -f "$install_prefix/lib/SDL3.lib" || -f "$install_prefix/lib/libSDL3.a" || -f "$install_prefix/lib/libSDL3.so" || -f "$install_prefix/lib/libSDL3.dylib" ]]; then
      log "SDL3 headers and libraries already present"
      return 0
    fi
  fi

  log "Building SDL3 from source ($SDL3_VERSION)"
  local tar="$TMP_DIR/SDL-${SDL3_VERSION}.tar.gz"
  download "https://github.com/libsdl-org/SDL/archive/refs/tags/${SDL3_VERSION}.tar.gz" "$tar"
  mkdir -p "$TMP_DIR/SDL3-src"
  tar -xzf "$tar" -C "$TMP_DIR/SDL3-src"
  local src_dir
  src_dir="$(find "$TMP_DIR/SDL3-src" -maxdepth 1 -type d -name 'SDL-*' | head -n1)"
  if [[ -z "$src_dir" ]]; then
    err "Failed to unpack SDL3 sources"
    return 1
  fi

  if ! have_cmd cmake; then
    err "CMake is required to build SDL3 from source"
    return 1
  fi

  local build_dir="$TMP_DIR/SDL3-build"
  rm -rf "$build_dir"
  mkdir -p "$build_dir"

  cmake -S "$src_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DSDL_SHARED=OFF \
    -DSDL_STATIC=ON \
    -DSDL_TEST=OFF \
    "-DCMAKE_INSTALL_PREFIX:PATH=$install_prefix"

  cmake --build "$build_dir" --config Release --parallel
  cmake --install "$build_dir" --config Release
  log "SDL3 installed locally → $install_prefix"
}

install_sdl3() {
  log "Building SDL3 from source (static)"
  build_sdl3_from_source
}

main() {
  log "Installing dependencies into $VENDOR_DIR"
  install_doctest
  install_spdlog
  install_imgui_docking
  install_sdl3
  install_nlohmann_json
  install_glm
  log "All dependencies installed"
}

main "$@"


