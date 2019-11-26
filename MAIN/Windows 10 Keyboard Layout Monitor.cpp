// main source file

#include "stdafx.h"
#include "resource.h"
#include "WindowsThemeColorApi.h"
#include "MainDlg.h"
#include <atlstr.h>

CAppModule _Module;
wchar_t* APPLICATIONTITLE = APPTITLE;

namespace
{
	bool GetCmdLineParam(const WCHAR *pParam, COLORREF *pColor=NULL);
	void RunHookerWatcher();
	bool isFirstAppInstance();
}

int WINAPI _tWinMain(HINSTANCE hInstance, HINSTANCE /*hPrevInstance*/, LPTSTR /*lpstrCmdLine*/, int /*nCmdShow*/)
{
	HRESULT hRes = ::CoInitialize(NULL);
// If you are running on NT 4.0 or higher you can use the following call instead to 
// make the EXE free threaded. This means that calls come in on a random RPC thread.
//	HRESULT hRes = ::CoInitializeEx(NULL, COINIT_MULTITHREADED);
	ATLASSERT(SUCCEEDED(hRes));

	// this resolves ATL window thunking problem when Microsoft Layer for Unicode (MSLU) is used
	::DefWindowProc(NULL, 0, 0, 0L);

	AtlInitCommonControls(0);	// add flags to support other controls

	hRes = _Module.Init(NULL, hInstance);
	ATLASSERT(SUCCEEDED(hRes));

	InitWindowsThemeColorApi();

	int nRet = 0;

	COLORREF dwmColor;
	bool dwmColorValid = GetCmdLineParam(L"-dwm_color", &dwmColor);
	COLORREF accentColor;
	bool accentColorValid = GetCmdLineParam(L"-accent_color", &accentColor);
	
	if(dwmColorValid || accentColorValid)
	{
		if(accentColorValid)
		{
			SetAccentColor(accentColor);
		}

		if(dwmColorValid)
		{
			SetDwmColorizationColor(dwmColor);
		}
	}
	else if (GetCmdLineParam(L"-show"))
	{
		HWND window = FindWindow(0, APPLICATIONTITLE);
		if (window) PostMessage(window, WM_SHOWAPPWINDOW, 42, 42);
	}
	else if (GetCmdLineParam(L"-hide"))
	{
		HWND window = FindWindow(0, APPLICATIONTITLE);
		if (window) PostMessage(window, WM_SHOWAPPWINDOW, 34, 34);
	}
	else if (GetCmdLineParam(L"-quit"))
	{
		HWND window = FindWindow(0, APPLICATIONTITLE);
		if (window) PostMessage(window, WM_QUIT, NULL, NULL);
	}
	else // BLOCK: Run application
	{
		CMainDlg dlgMain;
		dlgMain.InitWindowText(APPLICATIONTITLE);
		bool cmdauto=GetCmdLineParam(L"-auto");

		if (isFirstAppInstance())
		{
			RunHookerWatcher();
			dlgMain.CreateDialogVisible(cmdauto);
			nRet = dlgMain.DoModal();
		}
		else if (cmdauto)
		{
			HWND window = FindWindow(0, APPLICATIONTITLE);
			PostMessage(window, WM_SHOWAPPWINDOW, 42, 42);
		}
	}

	_Module.Term();
	::CoUninitialize();

	return nRet;
}

namespace
{
	bool GetCmdLineParam(const WCHAR *pParam, COLORREF *pColor)
	{
		int maxarg = pColor ? __argc - 1 : __argc;
		for(int i = 1; i < maxarg; i++)
		{
			if(_wcsicmp(__wargv[i], pParam) == 0)
			{
				if (!pColor) return true; // опция командной строки без параметров
				DWORD dwParamValue = wcstoul(__wargv[i + 1], NULL, 16);
				COLORREF retReversed = dwParamValue & 0x00FFFFFF;
				*pColor = RGB(GetBValue(retReversed), GetGValue(retReversed), GetRValue(retReversed));
				return true;
			}
		}

		return false;
	}

	////

	void RunHookerWatcher()
	{
		STARTUPINFO si;
		PROCESS_INFORMATION pi;

		wchar_t szwAppPath[MAX_PATH] = L"";
		GetModuleFileNameW(NULL, szwAppPath, MAX_PATH-1);
		PathRemoveFileSpecW(szwAppPath);

		CStringW cswCmdline;
		cswCmdline.Format(L"\"%s\" %d", APPLICATIONTITLE, WM_LANGUAGE_CHANGED);

		CStringW cswPath = CStringW (szwAppPath);
		cswPath += L"\\x86\\HookerWatcher.exe";

		memset(&si, 0, sizeof(si));
		si.cb = sizeof(si);
		memset(&pi, 0, sizeof(pi));
		CreateProcessW(cswPath, (LPWSTR)(LPCWSTR)cswCmdline,     NULL, NULL,     FALSE, CREATE_NO_WINDOW,     NULL, NULL, &si, &pi);

		cswPath = CStringW (szwAppPath);
		cswPath += L"\\x64\\HookerWatcher.exe";

		memset(&si, 0, sizeof(si));
		si.cb = sizeof(si);
		memset(&pi, 0, sizeof(pi));
		CreateProcessW(cswPath, (LPWSTR)(LPCWSTR)cswCmdline,     NULL, NULL,     FALSE, CREATE_NO_WINDOW,     NULL, NULL, &si, &pi);
	}

	////

	bool isFirstAppInstance()
	{
		CreateMutexA(0, FALSE, "Local\\VerySuspiciousKeyboardLayoutMonitor_v00");
		if(GetLastError() == ERROR_ALREADY_EXISTS) return false;
		return true;
	}

	////

}
