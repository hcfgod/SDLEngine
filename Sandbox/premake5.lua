project "Sandbox"
    kind "ConsoleApp"
    language "C++"
    cppdialect "C++20"
    staticruntime "off"

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
        "%{wks.location}/Engine/Vendor/SDL3/include",
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
        -- Link SDL3 (static) and required Windows system libs
        links { "SDL3-static", "user32", "gdi32", "winmm", "imm32", "setupapi", "version", "ole32", "oleaut32", "uuid", "shell32", "advapi32" }
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
