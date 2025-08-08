#pragma once

#include "lmpch.h"
#include "Core/Window.h"

namespace Limitless {

    enum class RendererBackend {
        None = 0,
        SDLRenderer2D,
        SDLGPU
    };

    class RenderAPI {
    public:
        virtual ~RenderAPI() = default;

        virtual void Initialize(Window& window) = 0;
        virtual void Shutdown() = 0;

        virtual void SetClearColor(float r, float g, float b, float a) = 0;
        virtual void Clear() = 0;
        virtual void Present() = 0;
    };
}


