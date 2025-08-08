#pragma once

#include "lmpch.h"
#include <SDL3/SDL.h>
#include <mutex>

namespace Limitless {

    enum class SDLSubsystem : uint32_t {
        None      = 0,
        Audio     = SDL_INIT_AUDIO,
        Video     = SDL_INIT_VIDEO,
        Joystick  = SDL_INIT_JOYSTICK,
        Haptic    = SDL_INIT_HAPTIC,
        Gamepad   = SDL_INIT_GAMEPAD,
        Events    = SDL_INIT_EVENTS,
        Sensor    = SDL_INIT_SENSOR
    };

    inline SDLSubsystem operator|(SDLSubsystem a, SDLSubsystem b) {
        return static_cast<SDLSubsystem>(static_cast<uint32_t>(a) | static_cast<uint32_t>(b));
    }

    inline SDLSubsystem& operator|=(SDLSubsystem& a, SDLSubsystem b) {
        a = a | b;
        return a;
    }

    // SDLManager initializes and shuts down SDL subsystems safely.
    // It is safe to call Initialize multiple times; Shutdown will
    // only tear down once the internal reference count hits zero.
    class SDLManager {
    public:
        static SDLManager& Get();

        // Initialize requested subsystems. Returns true if SDL is initialized.
        bool Initialize(SDLSubsystem subsystems);

        // Decrement reference count and quit SDL when zero.
        void Shutdown();
        // Error helper
        static std::string GetLastError();

        // Hint helpers commonly useful for engines
        void ApplyRecommendedHints() const;

    private:
        SDLManager() = default;
        ~SDLManager();
        SDLManager(const SDLManager&) = delete;
        SDLManager& operator=(const SDLManager&) = delete;

    private:
        std::mutex mutex_;
        uint32_t initMask_ = 0; // OR of initialized subsystems when applicable
        uint32_t refCount_ = 0;
    };
}