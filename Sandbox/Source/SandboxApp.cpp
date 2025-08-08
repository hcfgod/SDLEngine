#include "SandboxApp.h"
#include "Core/Log.h"
#include "Renderer/RenderCommand.h"

SandboxApp::SandboxApp()
    : Limitless::Application("Sandbox")
{
    LM_LOG_INFO("SandboxApp created!");
}

SandboxApp::~SandboxApp()
{
    LM_LOG_INFO("SandboxApp destroyed!");
}

void SandboxApp::Initialize()
{
	LM_LOG_INFO("SandboxApp initialized!");
    // Set an obvious clear color to verify renderer
    Limitless::RenderCommand::SetClearColor(0.1f, 0.2f, 0.3f, 1.0f);
}

void SandboxApp::Shutdown()
{
	LM_LOG_INFO("SandboxApp shutting down!");
}

Limitless::Application* Limitless::CreateApplication()
{
    return new SandboxApp();
}