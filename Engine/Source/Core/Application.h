#pragma once

#include "lmpch.h"
#include "Core/Window.h"
#include "Renderer/RenderAPI.h"
#include "Renderer/SDLRenderAPI.h"
#include <memory>

namespace Limitless {

    class Application
    {
    public:
        Application(const std::string& name = "Limitless App");
        virtual ~Application();

		virtual void Initialize() = 0;
		virtual void Shutdown() = 0;

        // Optional override to customize initial window creation
        virtual WindowDesc GetDefaultWindowDesc() const { return WindowDesc{}; }

        void Run();

        static Application& Get() { return *s_Instance; }

        // Control
        void Close() { m_Running = false; }

        // Accessors
        Window& GetWindow() { return *m_Window; }
        const Window& GetWindow() const { return *m_Window; }

    private:
        std::string m_Name;
        bool m_Running = true;
        std::unique_ptr<Window> m_Window;
        std::unique_ptr<RenderAPI> m_RenderAPI;

    private:
        static Application* s_Instance;
    };

	// To be defined in the client application
    Application* CreateApplication();
}