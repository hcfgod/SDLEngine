#pragma once

#include "Renderer/RenderAPI.h"
#include <SDL3/SDL.h>

namespace Limitless {

    class SDLRenderAPI final : public RenderAPI {
    public:
        SDLRenderAPI() = default;
        ~SDLRenderAPI() override = default;

        void Initialize(Window& window) override;
        void Shutdown() override;

        void SetClearColor(float r, float g, float b, float a) override;
        void Clear() override;
        void Present() override;

        SDL_Renderer* GetSDLRenderer() const { return sdlRenderer_; }

    private:
        SDL_Renderer* sdlRenderer_ = nullptr;
        float clearR_ = 0.1f, clearG_ = 0.1f, clearB_ = 0.1f, clearA_ = 1.0f;
    };
}


