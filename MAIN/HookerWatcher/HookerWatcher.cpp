
#include <windows.h>
#include <atlstr.h>

static void (*SetHook)(wchar_t*, DWORD);
static void (*UnHook)(void);

int wmain(int argc, wchar_t* argv[])
{
		wchar_t szwAppPath[MAX_PATH] = L"";
		GetModuleFileNameW(NULL, szwAppPath, MAX_PATH-1);
		PathRemoveFileSpecW(szwAppPath);
		CStringW cswPath = CStringW (szwAppPath);
		cswPath += L"\\Hooker.dll";

		if(argc != 2) return 0;
		DWORD WM = _wtoi(argv[1]);

		HMODULE hHooker = LoadLibraryW(cswPath);
		if (hHooker)
		{
			(FARPROC &)SetHook = GetProcAddress(hHooker, "SetHook");
			(FARPROC &)UnHook = GetProcAddress(hHooker, "UnHook");
			if (SetHook && UnHook)
			{
				SetHook(argv[0], WM);
				while(true)
				{
					Sleep(10*1000);
					if (FindWindowW(0, argv[0]) == NULL)
					{
						UnHook();
						break;
					}
				}//while
			}
			else
			{
				MessageBoxW(NULL, L"Can't GetProcAddress SetHook/UnHook", L"HookerWatcher", MB_OK);
			}
			FreeLibrary(hHooker);
		}
		else
		{
			MessageBoxW(NULL, cswPath, L"HookerWatcher can't load Library:", MB_OK);
		}

}//wmain
