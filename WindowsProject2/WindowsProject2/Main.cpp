// WindowsProject2.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "Main.h"
#include "Systems/Window.h"

#define MAX_LOADSTRING 100

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // TODO: Place code here.

	// 윈도우 생성할 때 쓰일 것... 전역으로~~
	D3DDesc desc;
	desc.AppName = L"D3D Game";
	desc.Instance = hInstance;
	desc.bFullScreen = false;
	desc.bVsync = false;
	desc.Handle = NULL;
	desc.Width = 1280;
	desc.Height = 720;
	D3D::SetDesc(desc);

	Window* window = new Window();
	WPARAM wParam = window->Run();	// 게임루프 걸림
	SAFE_DELETE(window);

	return (int)wParam;
}
