#include "lmpch.h"
#include "Core/SDLManager.h"
#include "Core/Log.h"

namespace Limitless {

    SDLManager& SDLManager::Get() {
        static SDLManager instance;
        return instance;
    }

    bool SDLManager::Initialize(SDLSubsystem subsystems) {
        std::scoped_lock lock(mutex_);
        uint32_t mask = static_cast<uint32_t>(subsystems);
        if (refCount_ == 0) {
            ApplyRecommendedHints();
            if (!SDL_Init(mask)) {
                LM_CORE_LOG_ERROR("SDL_Init failed: {}", GetLastError());
                return false;
            }
            initMask_ = mask;
        } else {
            // Add any new subsystems requested after initial init
            uint32_t newMask = mask & ~initMask_;
            if (newMask) {
                if (!SDL_InitSubSystem(newMask)) {
                    LM_CORE_LOG_ERROR("SDL_InitSubSystem failed: {}", GetLastError());
                    return false;
                }
                initMask_ |= newMask;
                LM_CORE_LOG_INFO("SDL subsystems extended. InitMask=0x{:X}", initMask_);
            }
        }
        ++refCount_;
        return true;
    }

    void SDLManager::Shutdown() {
        std::scoped_lock lock(mutex_);
        if (refCount_ == 0) return;
        --refCount_;
        if (refCount_ == 0) {
            SDL_Quit();
            LM_CORE_LOG_INFO("SDL shut down");
            initMask_ = 0;
        }
    }

    std::string SDLManager::GetLastError() {
        const char* err = SDL_GetError();
        return err ? std::string(err) : std::string();
    }

    void SDLManager::ApplyRecommendedHints() const {
        // Rendering backend selection can be applied by the engine later if needed
        // Here we set sane defaults for a game engine
        SDL_SetHint("SDL_MOUSE_FOCUS_CLICKTHROUGH", "1");
        SDL_SetHint("SDL_WINDOWS_DPI_AWARENESS", "permonitorv2");
        SDL_SetHint("SDL_IME_SHOW_UI", "1");
        SDL_SetHint("SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS", "1");
    }

    SDLManager::~SDLManager() {
        // Ensure shutdown even if user forgot
        while (refCount_ > 0) {
            --refCount_;
        }
        if (initMask_ != 0) {
            SDL_Quit();
        }
    }
}


