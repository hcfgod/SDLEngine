Limitless Engine
=================

Cross-platform C++ game engine scaffold using SDL3, Dear ImGui, spdlog, doctest, and Premake.

Build locally
-------------

- Windows (PowerShell):
  - Run `./setup.bat`.

- Linux/macOS (bash):
  - Run `chmod +x ./setup.sh && ./setup.sh`.

CI/CD
-----

GitHub Actions build the project on Windows, Linux, and macOS:

- `.github/workflows/ci-windows.yml`: uses MSBuild and VS2022 generator
- `.github/workflows/ci-linux.yml`: installs deps, generates gmake2, builds `config=debug_x64`
- `.github/workflows/ci-macos.yml`: similar to Linux, targeted to macOS runners

Artifacts for each platform are uploaded from the `Build/Debug-<os>-x64/` directory.


