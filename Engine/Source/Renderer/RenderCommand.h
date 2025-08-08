#pragma once

#include "lmpch.h"
#include "Renderer/RenderAPI.h"

namespace Limitless {

    class RenderCommand {
    public:
        static void Init(RenderAPI* api) { s_RenderAPI = api; }
        static RenderAPI* GetAPI() { return s_RenderAPI; }

        static void SetClearColor(float r, float g, float b, float a) {
            if (s_RenderAPI) s_RenderAPI->SetClearColor(r, g, b, a);
        }

        static void Clear() {
            if (s_RenderAPI) s_RenderAPI->Clear();
        }

        static void Present() {
            if (s_RenderAPI) s_RenderAPI->Present();
        }

    private:
        static inline RenderAPI* s_RenderAPI = nullptr;
    };
}


