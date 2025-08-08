#include "lmpch.h"
#include "Application.h"
#include "Core/SDLManager.h"
#include "Core/Log.h"
#include "Renderer/RenderCommand.h"
#include "Renderer/SDLRenderAPI.h"

namespace Limitless {

    Application* Application::s_Instance = nullptr;

    Application::Application(const std::string& name)
        : m_Name(name)
    {
        s_Instance = this;
        Log::Init(m_Name);
        LM_CORE_LOG_INFO("Creating Application (Name: {}) ", m_Name);
    }

    Application::~Application()
    {
        LM_CORE_LOG_INFO("Application destroyed (Name: {})", m_Name);
        Log::Shutdown();
    }

    void Application::Run()
    {
        LM_CORE_LOG_INFO("Running application (Name: {})", m_Name);

        // Ensure SDL is initialized for windowing/events at least once here
        if (!SDLManager::Get().Initialize(SDLSubsystem::Video | SDLSubsystem::Events)) {
            throw std::runtime_error("Failed to initialize SDL in Application::Run");
        }

        // Create primary window before client Initialize so they can query it
        m_Window = std::make_unique<Window>(GetDefaultWindowDesc());

        // Initialize default renderer (SDL 2D for now)
        m_RenderAPI = std::make_unique<SDLRenderAPI>();
        m_RenderAPI->Initialize(*m_Window);
        RenderCommand::Init(m_RenderAPI.get());

        Initialize();

        while (m_Running)
        {
            // Drive events; if window requests quit, stop running
            if (!m_Window->PollEvents()) {
                m_Running = false;
                break;
            }

            // Simple clear/present cycle for now
            RenderCommand::Clear();
            RenderCommand::Present();
        }

        Shutdown();

        // Explicitly reset renderer and window before SDL shutdown
        if (m_RenderAPI) {
            m_RenderAPI->Shutdown();
            m_RenderAPI.reset();
        }
        // Explicitly reset window before SDL shutdown to destroy native window
        m_Window.reset();
        SDLManager::Get().Shutdown();
    }
}