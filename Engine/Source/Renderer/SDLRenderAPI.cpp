#include "lmpch.h"
#include "Renderer/SDLRenderAPI.h"
#include "Core/Log.h"

namespace Limitless {

    void SDLRenderAPI::Initialize(Window& window) {
        if (sdlRenderer_) return;

        SDL_Window* sdlWindow = window.GetNativeHandle();
        sdlRenderer_ = SDL_CreateRenderer(sdlWindow, nullptr);
        if (!sdlRenderer_) {
            LM_CORE_LOG_ERROR("SDL_CreateRenderer failed: {}", SDL_GetError());
            throw std::runtime_error("SDL_CreateRenderer failed");
        }

        // Apply initial clear color
        SetClearColor(clearR_, clearG_, clearB_, clearA_);
    }

    void SDLRenderAPI::Shutdown() {
        if (sdlRenderer_) {
            SDL_DestroyRenderer(sdlRenderer_);
            sdlRenderer_ = nullptr;
        }
    }

    void SDLRenderAPI::SetClearColor(float r, float g, float b, float a) {
        clearR_ = r; clearG_ = g; clearB_ = b; clearA_ = a;
        if (sdlRenderer_) {
            SDL_SetRenderDrawColorFloat(sdlRenderer_, r, g, b, a);
        }
    }

    void SDLRenderAPI::Clear() {
        if (!sdlRenderer_) return;
        // Ensure draw color is synced
        SDL_SetRenderDrawColorFloat(sdlRenderer_, clearR_, clearG_, clearB_, clearA_);
        SDL_RenderClear(sdlRenderer_);
    }

    void SDLRenderAPI::Present() {
        if (!sdlRenderer_) return;
        SDL_RenderPresent(sdlRenderer_);
    }
}


