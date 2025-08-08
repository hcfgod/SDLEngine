# Windows PowerShell script to download and setup Premake
# This script downloads the latest version of Premake and sets it up for the project

param(
    [string]$Version = "5.0.0-beta2",
    [string]$Platform = "windows"
)

Write-Host "Setting up Premake for Windows..." -ForegroundColor Green

# Create scripts directory if it doesn't exist
$ScriptsDir = "scripts"
if (!(Test-Path $ScriptsDir)) {
    New-Item -ItemType Directory -Path $ScriptsDir | Out-Null
}

# Create tools directory if it doesn't exist
$ToolsDir = "tools"
if (!(Test-Path $ToolsDir)) {
    New-Item -ItemType Directory -Path $ToolsDir | Out-Null
}

# Check if premake5.exe already exists
$PremakeExePath = "$ToolsDir/premake5.exe"
if (Test-Path $PremakeExePath) {
    Write-Host "Premake5.exe already exists in tools directory. Skipping download." -ForegroundColor Yellow
    Write-Host "You can now run: .\tools\premake5.exe [action]" -ForegroundColor Cyan
    exit 0
}

# Determine the correct Premake version and platform
$PremakeVersion = $Version
$PremakePlatform = $Platform

# Download URL for Premake
$DownloadUrl = "https://github.com/premake/premake-core/releases/download/v$PremakeVersion/premake-$PremakeVersion-windows.zip"
$ZipPath = "$ToolsDir/premake-$PremakeVersion-windows.zip"
$ExtractPath = "$ToolsDir/premake"

Write-Host "Downloading Premake v$PremakeVersion for Windows..." -ForegroundColor Yellow

# Download Premake
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing
    Write-Host "Download completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to download Premake: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Extract the zip file
Write-Host "Extracting Premake..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
    Write-Host "Extraction completed!" -ForegroundColor Green
} catch {
    Write-Host "Failed to extract Premake: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Move premake5.exe to tools directory
$PremakeExe = "$ExtractPath/premake5.exe"
if (Test-Path $PremakeExe) {
    Copy-Item $PremakeExe -Destination "$ToolsDir/premake5.exe" -Force
    Write-Host "Premake5.exe copied to tools directory!" -ForegroundColor Green
} else {
    Write-Host "Premake5.exe not found in extracted files!" -ForegroundColor Red
    exit 1
}

# Clean up
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Premake setup completed successfully!" -ForegroundColor Green
Write-Host "You can now run: .\tools\premake5.exe [action]" -ForegroundColor Cyan
