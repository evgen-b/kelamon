#include "Windows.h"

// Global and static member variables that are not shared.

HOOKPROC pHookCatcher;
HMODULE hLib;
HHOOK hHook = NULL;


// This is the most important statement of all
// Ideally you can set this in the projects linker tab, but I never could get 
// that to work.  I stumbled across this in a discussion board response from 
// Todd Jeffreys.  This tells the linker to generate the shared data segment.  
// It does not tell it what variables are shared, the other statements do that,
// but it does direct the linker to make provisions for the shared data segment.
#pragma comment(linker, "/section:SHARED,RWS")

#pragma data_seg("SHARED")  // Begin the shared data segment.
// Define simple variables
// Integers, char[] arrays and pointers
// Do not define classes that require 'deep' copy constructors.
static wchar_t szwTitle[256] = {0};
static DWORD dwWinMsg = NULL;
#pragma data_seg()          // End the shared data segment and default back to 
                            // the normal data segment behavior.

extern "C" __declspec(dllexport) void SetHook(wchar_t* title, DWORD wm)
{
	if (hHook) return;
	if (!title) return;
	if (!wm) return;
	dwWinMsg=wm;
	wcscpy_s(szwTitle, _countof(szwTitle), title);

	hLib=LoadLibrary("Hooker");
	pHookCatcher=(HOOKPROC)GetProcAddress(hLib,"CallWndProc");
	hHook=SetWindowsHookEx(WH_SHELL, pHookCatcher, hLib, 0);
	if (hHook == NULL)
	{
		throw;
	}
}

extern "C" __declspec(dllexport) void UnHook(void)
{
	UnhookWindowsHookEx(hHook);
	hHook = 0;
}

extern "C" __declspec(dllexport) int CallWndProc(int nCode, WPARAM wParam, LPARAM lParam)
{
	if(nCode < 0)
		return CallNextHookEx(0, nCode, wParam, lParam);

	if (nCode == HSHELL_LANGUAGE)
	{
		HWND window = FindWindowW(0, szwTitle);
		PostMessage(window, dwWinMsg, 0, lParam);
	}

	return CallNextHookEx(0,nCode,wParam, lParam);
}