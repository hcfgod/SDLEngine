workspace "Limitless"
    startproject "Sandbox"

    configurations
    {
        "Debug",
        "Release",
        "Dist"
    }

    platforms
    {
        "x64",
        "ARM64"
    }

    filter "platforms:x64"
        architecture "x64"

    filter "platforms:ARM64"
        architecture "ARM64"

    -- Output directory format matches CI/CD expectations
    -- Format: Build/Debug-windows-x64/, Build/Release-linux-x64/, etc.
    outputdir = "Build/%{cfg.shortname}-%{cfg.system}-%{cfg.platform}"

    -- Global configuration settings
    filter "configurations:Debug"
        runtime "Debug"
        symbols "on"
        optimize "off"
        flags { "MultiProcessorCompile" }

    filter "configurations:Release"
        runtime "Release"
        optimize "speed"
        symbols "off"
        flags { "MultiProcessorCompile" }

    filter "configurations:Dist"
        runtime "Release"
        optimize "speed"
        symbols "off"
        systemversion "latest"
        flags { "MultiProcessorCompile" }

    -- Global compiler flags
    filter "system:windows"
        buildoptions { "/utf-8" }
    
    filter "system:linux"
        buildoptions { "-finput-charset=UTF-8", "-fexec-charset=UTF-8" }
    
    filter "system:macosx"
        buildoptions { "-finput-charset=UTF-8", "-fexec-charset=UTF-8" }

-- Include sub-projects
group "dependencies"
include "Engine/Vendor/imgui/premake5.lua"
group ""
include "Engine"
include "Sandbox"
include "Test"