project "Sandbox"
    kind "ConsoleApp"
    language "C++"
    cppdialect "C++20"
    staticruntime "off"

    -- Vendor roots (used to detect proper SDL3 lib name)
    local VendorDir    = path.getabsolute("%{wks.location}/Engine/Vendor")
    local SDL3Include  = VendorDir .. "/SDL3/include"
    local SDL3LibDir   = VendorDir .. "/SDL3/lib"
    if not os.isdir(SDL3LibDir) and os.isdir(VendorDir .. "/SDL3/lib64") then
        SDL3LibDir = VendorDir .. "/SDL3/lib64"
    end
    local SDL3LibName = nil
    if os.isfile(SDL3LibDir .. "/SDL3-static.lib") then
        SDL3LibName = "SDL3-static"
    elseif os.isfile(SDL3LibDir .. "/SDL3.lib") then
        SDL3LibName = "SDL3"
    elseif os.isfile(SDL3LibDir .. "/libSDL3.a") then
        -- MinGW archive; MSVC can't use this, but keep a fallback name for non-MSVC toolchains
        SDL3LibName = "SDL3"
    else
        -- Default to SDL3; installer should ensure SDL3-static.lib exists on Windows CI
        SDL3LibName = "SDL3"
    end

    targetdir ("%{wks.location}/" .. outputdir .. "/%{prj.name}")
    objdir ("%{wks.location}/" .. outputdir .. "/%{prj.name}")

    files
    {
        "Source/**.h",
        "Source/**.cpp"
    }

    includedirs
    {
        "%{wks.location}/Engine/Source",
        "%{wks.location}/Engine/Vendor",
        "%{wks.location}/Engine/Vendor/doctest",
        "%{wks.location}/Engine/Vendor/spdlog",
        "%{wks.location}/Engine/Vendor/imgui",
        SDL3Include,
    }

    libdirs
    {
        "%{wks.location}/Engine/Vendor/SDL3/lib",
        "%{wks.location}/Engine/Vendor/SDL3/lib64",
        -- VS generators sometimes place libs under a config subdir
        "%{wks.location}/Engine/Vendor/SDL3/lib/Release"
    }

    links
    {
        "Engine",
        "ImGui",
        -- Ensure SDL3-static is linked explicitly on Windows
        -- (Linux/macOS link via system libs in platform filters below)
        
    }

    filter "system:windows"
        systemversion "latest"
        defines
        {
            "LM_PLATFORM_WINDOWS",
        }
        links { SDL3LibName, "user32", "gdi32", "winmm", "imm32", "setupapi", "version", "ole32", "oleaut32", "uuid", "shell32", "advapi32" }
        buildoptions { "/utf-8" }

    filter "system:linux"
        pic "On"
        systemversion "latest"
        defines
        {
            "LM_PLATFORM_LINUX"
        }
        -- Link SDL3 and required POSIX libs
        links { "SDL3", "pthread", "dl", "m" }

    filter "system:macosx"
        systemversion "latest"
        defines
        {
            "LM_PLATFORM_MAC"
        }
        links { "pthread", "SDL3" }
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
