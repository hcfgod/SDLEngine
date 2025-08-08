#pragma once
#include "Application.h"

extern Limitless::Application* Limitless::CreateApplication();

int main(int argc, char** argv)
{
    Limitless::Application* app = Limitless::CreateApplication();
    app->Run();
    delete app;

    return 0;
}