#pragma once

#include "lmpch.h"
#include <SDL3/SDL.h>
#include <functional>

namespace Limitless {

    struct WindowDesc {
        std::string title = "Limitless";
        int width = 1280;
        int height = 720;
        bool resizable = true;
        bool highDPI = true;
        bool visible = true;
        bool fullscreen = false;
    };

    class Window {
    public:
        explicit Window(const WindowDesc& desc = {});
        ~Window();

        Window(const Window&) = delete;
        Window& operator=(const Window&) = delete;

        void SetTitle(const std::string& title);
        void Resize(int width, int height);
        void Show();
        void Hide();
        void SetFullscreen(bool enabled);

        bool PollEvents(); // Returns false if a quit event is received

        SDL_Window* GetNativeHandle() const { return window_; }
        int GetWidth() const { return width_; }
        int GetHeight() const { return height_; }

    private:
        void Create(const WindowDesc& desc);
        void Destroy();

    private:
        SDL_Window* window_ = nullptr;
        int width_ = 0;
        int height_ = 0;
    };
}


