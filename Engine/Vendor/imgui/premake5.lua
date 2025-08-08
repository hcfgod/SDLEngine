project "ImGui"
    kind "StaticLib"
    language "C++"
    cppdialect "C++17"
    staticruntime "off"

    targetdir ("%{wks.location}/" .. outputdir .. "/%{prj.name}")
    objdir ("%{wks.location}/" .. outputdir .. "/%{prj.name}")
    
    -- Do not use precompiled headers for this vendor lib
    flags { "NoPCH" }

    files
    {
        "%{wks.location}/Engine/Vendor/imgui/imgui.cpp",
        "%{wks.location}/Engine/Vendor/imgui/imgui_draw.cpp",
        "%{wks.location}/Engine/Vendor/imgui/imgui_tables.cpp",
        "%{wks.location}/Engine/Vendor/imgui/imgui_widgets.cpp",
        "%{wks.location}/Engine/Vendor/imgui/imgui_demo.cpp",
        "%{wks.location}/Engine/Vendor/imgui/imconfig.h",
        "%{wks.location}/Engine/Vendor/imgui/imgui.h",
        "%{wks.location}/Engine/Vendor/imgui/imgui_internal.h",
        "%{wks.location}/Engine/Vendor/imgui/imstb_rectpack.h",
        "%{wks.location}/Engine/Vendor/imgui/imstb_textedit.h",
        "%{wks.location}/Engine/Vendor/imgui/imstb_truetype.h"
    }

    includedirs
    {
        "%{wks.location}/Engine/Vendor/imgui"
    }

    filter "system:windows"
        systemversion "latest"
        buildoptions { "/utf-8" }

    filter "system:linux"
        pic "On"
        systemversion "latest"

    filter "system:macosx"
        systemversion "latest"

    filter "configurations:Debug"
        runtime "Debug"
        symbols "on"

    filter "configurations:Release"
        runtime "Release"
        optimize "on"

    filter "configurations:Dist"
        runtime "Release"
        optimize "on"


