project "Engine"
    kind "StaticLib"
    language "C++"
    cppdialect "C++20"
    staticruntime "off"

    targetdir ("%{wks.location}/" .. outputdir .. "/%{prj.name}")
    objdir ("%{wks.location}/" .. outputdir .. "/%{prj.name}")

    pchheader "lmpch.h"
    pchsource "Source/lmpch.cpp"

    files
    {
        "Source/**.h",
        "Source/**.cpp"
    }
    
    -- Vendor roots
    local VendorDir    = path.getabsolute("%{wks.location}/Engine/Vendor")
    local SDL3Include  = VendorDir .. "/SDL3/include"
    local SDL3LibDir   = VendorDir .. "/SDL3/lib"
    if not os.isdir(SDL3LibDir) and os.isdir(VendorDir .. "/SDL3/lib64") then
        SDL3LibDir = VendorDir .. "/SDL3/lib64"
    end
    local ImGuiDir     = VendorDir .. "/imgui"
    local SpdlogDir    = VendorDir .. "/spdlog"
    local DoctestDir   = VendorDir .. "/doctest"

    -- Try to detect the correct SDL3 static lib name on the current host
    local SDL3LibName = nil
    if os.isfile(SDL3LibDir .. "/SDL3-static.lib") then
        SDL3LibName = "SDL3-static"
    elseif os.isfile(SDL3LibDir .. "/SDL3.lib") then
        SDL3LibName = "SDL3"
    elseif os.isfile(SDL3LibDir .. "/libSDL3.a") then
        SDL3LibName = "SDL3"
    end

    includedirs
    {
        "Source",
        SDL3Include,
        ImGuiDir,
        SpdlogDir,
        DoctestDir,
        -- Vendor root to resolve headers like <nlohmann/json.hpp> and <glm/glm.hpp>
        VendorDir
    }

    -- Do not link SDL or system libs here; this is a static library.
    -- Executables (Sandbox/Test) will link SDL3 and required system libs.

    filter "system:windows"
        systemversion "latest"
        defines
        {
            "LM_PLATFORM_WINDOWS",
        }
        buildoptions { "/utf-8" }

    filter "system:linux"
        pic "On"
        systemversion "latest"
        defines
        {
            "LM_PLATFORM_LINUX"
        }
        links { "pthread", "dl" }

    filter "system:macosx"
        systemversion "latest"
        defines
        {
            "LM_PLATFORM_MAC"
        }
        links { "pthread" }
        links { "SDL3" }
        -- Common frameworks required by SDL on macOS
        filter { "system:macosx" }
            links {
                "Cocoa.framework",
                "IOKit.framework",
                "CoreVideo.framework",
                "Metal.framework",
                "GameController.framework",
                "AVFoundation.framework",
                "CoreHaptics.framework",
                "AudioToolbox.framework"
            }

    filter "configurations:Debug"
        defines { "LM_DEBUG", "SPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_TRACE" }
        runtime "Debug"
        symbols "on"

    filter "configurations:Release"
        defines { "LM_RELEASE", "SPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_INFO" }
        runtime "Release"
        optimize "on"

    filter "configurations:Dist"
        defines { "LM_DIST", "SPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_INFO" }
        runtime "Release"
        optimize "on"
