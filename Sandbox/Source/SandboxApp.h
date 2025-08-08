#pragma once

#include "Limitless.h"

class SandboxApp : public Limitless::Application
{
public:
    SandboxApp();
    ~SandboxApp();

	void Initialize() override;
	void Shutdown() override;
};