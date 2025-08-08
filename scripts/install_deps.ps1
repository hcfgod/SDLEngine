Param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Cross-platform dependency installer for Windows (PowerShell):
#  - doctest (header-only)
#  - dear imgui (docking branch)
#  - SDL3 (first using vcpkg/choco/winget if available; otherwise source build via CMake)

function Write-Log {
    Param([string]$Message)
    Write-Host "[install_deps] $Message"
}

function Write-Err {
    Param([string]$Message)
    Write-Host "[install_deps][ERROR] $Message" -ForegroundColor Red
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Resolve-Path (Join-Path $ScriptDir '..')
$VendorDir = Join-Path $RootDir 'Engine/Vendor'
$ToolsDir  = Join-Path $RootDir 'tools'
$TmpDir    = Join-Path $env:TEMP 'limitless_deps'

$DoctestVersion = 'v2.4.12'
$Sdl3Version = 'release-3.2.20'
$SpdlogVersion = 'v1.15.3'
$NlohmannVersion = 'v3.12.0'
$GlmVersion = '1.0.1'

New-Item -ItemType Directory -Force -Path $VendorDir | Out-Null
New-Item -ItemType Directory -Force -Path $ToolsDir  | Out-Null
New-Item -ItemType Directory -Force -Path $TmpDir    | Out-Null

function Test-Cmd {
    Param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Download-File {
    Param([string]$Url, [string]$OutFile)
    # Prefer real curl.exe to avoid PowerShell's curl alias (Invoke-WebRequest)
    $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curlCmd) {
        & $curlCmd.Path -L -f --retry 3 -o $OutFile $Url | Out-Null
        return
    }
    $iwr = Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue
    if ($iwr) {
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $OutFile
        return
    }
    throw 'No downloader available (curl.exe or Invoke-WebRequest)'
}

function Install-Doctest {
    $dstDir = Join-Path $VendorDir 'doctest'
    $hdr    = Join-Path $dstDir 'doctest.h'
    if ((Test-Path $hdr -PathType Leaf) -and (-not $Force)) {
        Write-Log "doctest already present → $hdr"
        return
    }
    Write-Log "Installing doctest ($DoctestVersion)"
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    $url = "https://raw.githubusercontent.com/doctest/doctest/$DoctestVersion/doctest/doctest.h"
    Download-File $url $hdr
    Write-Log "doctest installed → $hdr"
}

function Install-Spdlog {
    $dstDir = Join-Path $VendorDir 'spdlog'
    $hdr    = Join-Path $dstDir 'spdlog.h'
    if ((Test-Path $hdr -PathType Leaf) -and (-not $Force)) {
        Write-Log "spdlog already present → $hdr"
        return
    }
    Write-Log "Installing spdlog ($SpdlogVersion)"
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    
    # Download and extract spdlog
    $zip = Join-Path $TmpDir 'spdlog.zip'
    Download-File "https://github.com/gabime/spdlog/archive/refs/tags/$SpdlogVersion.zip" $zip
    
    $extractDir = Join-Path $TmpDir 'spdlog-extract'
    if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    
    Expand-Archive -Path $zip -DestinationPath $extractDir -Force
    
    # Find the extracted directory (it might be named differently)
    $extractedDirs = Get-ChildItem -Directory $extractDir | Where-Object { $_.Name -like 'spdlog-*' }
    if ($extractedDirs.Count -eq 0) {
        Write-Log "Available directories in extract: $(Get-ChildItem -Directory $extractDir | ForEach-Object { $_.Name })"
        throw 'Failed to find spdlog extracted directory'
    }
    
    $extractedDir = $extractedDirs[0].FullName
    $includePath = Join-Path $extractedDir 'include\spdlog'
    
    if (Test-Path $includePath) {
        Copy-Item -Path $includePath -Destination $dstDir -Recurse -Force
        Write-Log "spdlog installed → $dstDir"
    } else {
        Write-Log "Include path not found: $includePath"
        Write-Log "Available in extracted dir: $(Get-ChildItem -Recurse $extractedDir | ForEach-Object { $_.Name })"
        throw 'Failed to find spdlog include directory'
    }
}

function Install-ImGuiDocking {
    $dstDir = Join-Path $VendorDir 'imgui'
    if ((Test-Path $dstDir) -and (-not $Force)) {
        Write-Log "imgui (docking) already present → $dstDir"
        return
    }
    Write-Log 'Installing dear imgui (docking branch)'
    $zip = Join-Path $TmpDir 'imgui-docking.zip'
    Download-File 'https://codeload.github.com/ocornut/imgui/zip/refs/heads/docking' $zip
    $extractDir = Join-Path $TmpDir 'imgui-docking'
    if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
    Expand-Archive -Path $zip -DestinationPath $TmpDir -Force
    $srcDir = Get-ChildItem -Directory $TmpDir | Where-Object { $_.Name -like 'imgui-*' } | Select-Object -First 1
    if (-not $srcDir) { throw 'Failed to extract imgui docking zip' }
    if (Test-Path $dstDir) { Remove-Item -Recurse -Force $dstDir }
    Move-Item $srcDir.FullName $dstDir
    Write-Log "imgui (docking) installed → $dstDir"

    # Ensure a premake5.lua exists for building ImGui as a static library
    $premakePath = Join-Path $dstDir 'premake5.lua'
    $premakeContent = @'
project "ImGui"
    kind "StaticLib"
    language "C++"
    cppdialect "C++17"
    staticruntime "off"

    targetdir ("%{wks.location}/" .. outputdir .. "/%{prj.name}")
    objdir ("%{wks.location}/" .. outputdir .. "/%{prj.name}")

    files {
        "imgui.cpp",
        "imgui_demo.cpp",
        "imgui_draw.cpp",
        "imgui_tables.cpp",
        "imgui_widgets.cpp",
        "misc/cpp/imgui_stdlib.cpp"
    }

    includedirs { ".", "misc/cpp" }

    filter "system:windows"
        systemversion "latest"
        defines { "_CRT_SECURE_NO_WARNINGS" }
        buildoptions { "/utf-8" }

    filter "configurations:Debug"
        runtime "Debug"
        symbols "on"

    filter "configurations:Release"
        runtime "Release"
        optimize "on"

    filter "configurations:Dist"
        runtime "Release"
        optimize "on"
'@
    Set-Content -LiteralPath $premakePath -Value $premakeContent -Encoding UTF8
    Write-Log "Wrote ImGui premake at $premakePath"
}

function Install-NlohmannJson {
    $hdr    = Join-Path $VendorDir 'nlohmann\json.hpp'
    if ((Test-Path $hdr -PathType Leaf) -and (-not $Force)) {
        Write-Log "nlohmann/json already present → $hdr"
        return
    }
    Write-Log "Installing nlohmann/json ($NlohmannVersion)"

    $zip = Join-Path $TmpDir 'nlohmann-json.zip'
    Download-File "https://github.com/nlohmann/json/archive/refs/tags/$NlohmannVersion.zip" $zip

    $extractDir = Join-Path $TmpDir 'nlohmann-json-extract'
    if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    Expand-Archive -Path $zip -DestinationPath $extractDir -Force

    $extractedDir = Get-ChildItem -Directory $extractDir | Where-Object { $_.Name -like 'json-*' } | Select-Object -First 1
    if (-not $extractedDir) { throw 'Failed to extract nlohmann/json archive' }

    $singleInclude = Join-Path $extractedDir.FullName 'single_include\nlohmann'
    $fullInclude   = Join-Path $extractedDir.FullName 'include\nlohmann'
    if (Test-Path $singleInclude) {
        Copy-Item -Path $singleInclude -Destination $VendorDir -Recurse -Force
    } elseif (Test-Path $fullInclude) {
        Copy-Item -Path $fullInclude -Destination $VendorDir -Recurse -Force
    } else {
        throw 'nlohmann/json headers not found in extracted archive'
    }

    Write-Log ("nlohmann/json installed → {0}" -f (Join-Path $VendorDir 'nlohmann'))
}

function Install-GLM {
    $hdr    = Join-Path $VendorDir 'glm\glm.hpp'
    if ((Test-Path $hdr -PathType Leaf) -and (-not $Force)) {
        Write-Log "glm already present → $hdr"
        return
    }
    Write-Log "Installing GLM ($GlmVersion)"

    $zip = Join-Path $TmpDir 'glm.zip'
    Download-File "https://github.com/g-truc/glm/archive/refs/tags/$GlmVersion.zip" $zip

    $extractDir = Join-Path $TmpDir 'glm-extract'
    if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    Expand-Archive -Path $zip -DestinationPath $extractDir -Force

    $extractedDir = Get-ChildItem -Directory $extractDir | Where-Object { $_.Name -like 'glm-*' } | Select-Object -First 1
    if (-not $extractedDir) { throw 'Failed to extract GLM archive' }

    $includeDir = Join-Path $extractedDir.FullName 'glm'
    if (Test-Path $includeDir) {
        # Copy 'glm' folder directly under Vendor so includes use <glm/...>
        Copy-Item -Path $includeDir -Destination $VendorDir -Recurse -Force
    } else {
        throw 'GLM include directory not found in extracted archive'
    }

    Write-Log ("GLM installed → {0}" -f (Join-Path $VendorDir 'glm'))
}

function Try-Install-SDL3-Package {
    # For consistent static linking across platforms, we skip system package managers on Windows
    return $false
}

function Build-SDL3-FromSource {
    $installPrefix = Join-Path $VendorDir 'SDL3'
    # Only skip if headers AND at least one library file exist
    $headersPresent = Test-Path (Join-Path $installPrefix 'include/SDL3')
    $libDir = Join-Path $installPrefix 'lib'
    $libStatic = Join-Path $libDir 'SDL3-static.lib'
    $libShared = Join-Path $libDir 'SDL3.lib'
    $libAltRelease = Join-Path $installPrefix 'lib\Release\SDL3-static.lib'
    if ($headersPresent -and ((Test-Path $libStatic) -or (Test-Path $libShared) -or (Test-Path $libAltRelease)) -and (-not $Force)) {
        Write-Log 'SDL3 headers and libraries already present'
        return
    }
    if (-not (Test-Cmd cmake)) { throw 'CMake is required to build SDL3 from source' }
    Write-Log "Building SDL3 from source ($Sdl3Version)"
    $tar = Join-Path $TmpDir "SDL-$Sdl3Version.tar.gz"
    Download-File "https://github.com/libsdl-org/SDL/archive/refs/tags/$Sdl3Version.tar.gz" $tar
    $srcRoot = Join-Path $TmpDir 'SDL3-src'
    if (Test-Path $srcRoot) { Remove-Item -Recurse -Force $srcRoot }
    New-Item -ItemType Directory -Force -Path $srcRoot | Out-Null
    tar -xzf $tar -C $srcRoot
    $srcDir = Get-ChildItem -Directory $srcRoot | Where-Object { $_.Name -like 'SDL-*' } | Select-Object -First 1
    if (-not $srcDir) { throw 'Failed to unpack SDL3 sources' }

    $bld = Join-Path $TmpDir 'SDL3-build'
    if (Test-Path $bld) { Remove-Item -Recurse -Force $bld }
    New-Item -ItemType Directory -Force -Path $bld | Out-Null

    $cmakePrefix = ($installPrefix -replace '\\','/')
    # Prefer Ninja on CI for a deterministic x64 build
    $generator = 'Ninja Multi-Config'
    if (-not (Get-Command ninja -ErrorAction SilentlyContinue)) {
        $generator = 'Visual Studio 17 2022'
    }
    $generatorArgs = @()
    if ($generator -eq 'Visual Studio 17 2022') { $generatorArgs += @('-G', 'Visual Studio 17 2022', '-A', 'x64') } else { $generatorArgs += @('-G', $generator) }

    & cmake -S $srcDir.FullName -B $bld `
        @generatorArgs `
        -DBUILD_SHARED_LIBS=OFF `
        -DSDL_SHARED=OFF `
        -DSDL_STATIC=ON `
        -DSDL_TESTS=OFF `
        -DSDL_TEST=OFF `
        -DCMAKE_INSTALL_LIBDIR=lib `
        "-DCMAKE_INSTALL_PREFIX:PATH=$cmakePrefix"
    if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed' }

    if ($generator -eq 'Ninja Multi-Config') {
        & cmake --build $bld --config Release --parallel
    } else {
        & cmake --build $bld --config Release --parallel
    }
    if ($LASTEXITCODE -ne 0) { throw 'CMake build failed' }

    # Try to find built libs in the build tree (Visual Studio generators often place them under $bld/Release)
    $builtLibs = Get-ChildItem -Recurse -ErrorAction SilentlyContinue $bld | Where-Object { $_.Name -match '^SDL3(-static)?\.lib$' -or $_.Name -eq 'SDL3.lib' -or $_.Name -eq 'SDL3-static.lib' }
    if ($builtLibs.Count -gt 0) {
        $libOutDir = Join-Path $installPrefix 'lib'
        New-Item -ItemType Directory -Force -Path $libOutDir | Out-Null
        foreach ($lib in $builtLibs) {
            $dest = Join-Path $libOutDir $lib.Name
            Copy-Item -Path $lib.FullName -Destination $dest -Force
            Write-Log "Copied built lib to $dest"
        }
    }

    & cmake --install $bld --config Release
    if ($LASTEXITCODE -ne 0) { throw 'CMake install failed' }
    Write-Log "SDL3 installed locally → $installPrefix"

    # Flatten library location for MSBuild libdirs expectations
    $libDir = Join-Path $installPrefix 'lib'
    New-Item -ItemType Directory -Force -Path $libDir | Out-Null
    $candidates = @(
        (Join-Path $installPrefix 'lib\SDL3-static.lib'),
        (Join-Path $installPrefix 'lib\SDL3.lib'),
        (Join-Path $installPrefix 'lib\Release\SDL3-static.lib'),
        (Join-Path $installPrefix 'lib64\SDL3-static.lib'),
        (Join-Path $bld 'Release\SDL3-static.lib'),
        (Join-Path $bld 'Release\SDL3.lib')
    )
    $found = $false
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $target = Join-Path $libDir 'SDL3-static.lib'
            Copy-Item -Path $c -Destination $target -Force
            Write-Log "Ensured SDL3-static.lib at $target (from $c)"
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Log 'Warning: SDL3-static.lib not found after install; listing contents'
        Get-ChildItem -Recurse $installPrefix | ForEach-Object { $_.FullName }
    }
}

function Install-SDL3 {
    if (Try-Install-SDL3-Package) {
        Write-Log 'SDL3 set up via package manager'
    } else {
        Write-Log 'Package install not available; falling back to source build'
        Build-SDL3-FromSource
    }
}

Write-Log "Installing dependencies into $VendorDir"
Install-Doctest
Install-Spdlog
Install-ImGuiDocking
Install-SDL3
Install-NlohmannJson
Install-GLM
Write-Log 'All dependencies installed'