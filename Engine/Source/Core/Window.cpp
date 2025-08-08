#include "lmpch.h"
#include "Core/Window.h"
#include "Core/SDLManager.h"
#include "Core/Log.h"

namespace Limitless {

    static uint32_t BuildWindowFlags(const WindowDesc& desc) {
        uint32_t flags = SDL_WINDOW_HIDDEN; // start hidden until Show()
        flags |= SDL_WINDOW_HIGH_PIXEL_DENSITY;
        if (desc.resizable) flags |= SDL_WINDOW_RESIZABLE;
        if (desc.highDPI)   flags |= SDL_WINDOW_HIGH_PIXEL_DENSITY;
        if (desc.fullscreen) flags |= SDL_WINDOW_FULLSCREEN;
        return flags;
    }

    Window::Window(const WindowDesc& desc) {
        if (!SDLManager::Get().Initialize(SDLSubsystem::Video | SDLSubsystem::Events)) {
            throw std::runtime_error("Failed to initialize SDL for windowing");
        }
        Create(desc);
        if (desc.visible) Show();
    }

    Window::~Window() {
        Destroy();
        SDLManager::Get().Shutdown();
    }

    void Window::Create(const WindowDesc& desc) {
        Destroy();

        uint32_t flags = BuildWindowFlags(desc);
        window_ = SDL_CreateWindow(desc.title.c_str(), desc.width, desc.height, flags);
        if (!window_) {
            auto err = SDLManager::GetLastError();
            LM_CORE_LOG_ERROR("SDL_CreateWindow failed: {}", err);
            throw std::runtime_error("SDL_CreateWindow failed: " + err);
        }
        width_ = desc.width;
        height_ = desc.height;
    }

    void Window::Destroy() {
        if (window_) {
            SDL_DestroyWindow(window_);
            window_ = nullptr;
        }
    }

    void Window::SetTitle(const std::string& title) {
        if (window_) SDL_SetWindowTitle(window_, title.c_str());
    }

    void Window::Resize(int width, int height) {
        width_ = width; height_ = height;
        if (window_) SDL_SetWindowSize(window_, width, height);
    }

    void Window::Show() {
        if (window_) SDL_ShowWindow(window_);
    }

    void Window::Hide() {
        if (window_) SDL_HideWindow(window_);
    }

    void Window::SetFullscreen(bool enabled) {
        if (!window_) return;
        SDL_SetWindowFullscreen(window_, enabled);
    }

    bool Window::PollEvents() {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_EVENT_QUIT) {
                return false;
            }
            if (e.type == SDL_EVENT_WINDOW_RESIZED && e.window.windowID == SDL_GetWindowID(window_)) {
                width_ = e.window.data1;
                height_ = e.window.data2;
            }
        }
        return true;
    }
}


