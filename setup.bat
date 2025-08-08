@echo off
echo Setting up Limitless project...

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is required to run this setup.
    echo Please install PowerShell and try again.
    pause
    exit /b 1
)

REM Run the PowerShell script to download Premake
echo Downloading Premake...
powershell -ExecutionPolicy Bypass -File "scripts\download_premake.ps1"

if %errorlevel% neq 0 (
    echo Error: Failed to download Premake.
    pause
    exit /b 1
)

REM Install dependencies
echo Installing dependencies (SDL3, ImGui, doctest)...
powershell -ExecutionPolicy Bypass -File "scripts\install_deps.ps1"

REM Generate Visual Studio project files
echo Generating Visual Studio project files...
tools\premake5.exe vs2022

if %errorlevel% neq 0 (
    echo Error: Failed to generate project files.
    pause
    exit /b 1
)

REM Build the project using MSBuild
echo Building the project...
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" (
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" Limitless.sln /p:Configuration=Debug /p:Platform=x64
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" (
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" Limitless.sln /p:Configuration=Debug /p:Platform=x64
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" Limitless.sln /p:Configuration=Debug /p:Platform=x64
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe" (
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe" Limitless.sln /p:Configuration=Debug /p:Platform=x64
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe" (
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe" Limitless.sln /p:Configuration=Debug /p:Platform=x64
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe" Limitless.sln /p:Configuration=Debug /p:Platform=x64
) else (
    echo Warning: MSBuild not found. Please build the project manually using Visual Studio.
    echo Open Limitless.sln in Visual Studio and build the solution.
    echo.
    echo Setup completed! Project files generated successfully.
    echo.
    echo To build manually:
    echo 1. Open Limitless.sln in Visual Studio
    echo 2. Build the solution (Ctrl+Shift+B)
    echo 3. Run the executables from bin\Debug-x64\
    echo.
    pause
    exit /b 0
)

if %errorlevel% neq 0 (
    echo Error: Failed to build the project.
    echo Please check the build output above for errors.
    pause
    exit /b 1
)

echo.
echo Setup completed successfully!
echo.
echo Build completed!
echo.
echo To run the client application:
echo   bin\Debug-x64\Client.exe
echo.
echo To run the tests:
echo   bin\Debug-x64\Tests.exe
echo.
pause
