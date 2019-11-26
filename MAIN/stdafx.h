// stdafx.h : include file for standard system include files,
//  or project specific include files that are used frequently, but
//  are changed infrequently
//

#pragma once

// Change these values to use different versions
#define WINVER		0x0600
#define _WIN32_WINNT	0x0600
#define _WIN32_IE	0x0600
#define _RICHEDIT_VER	0x0600

#define REGKILOMASTER L"Software\\KeyboardLayoutMonitor"
#define APPTITLE L"Very Suspicious Keyboard Layout Monitor"
#define REGAUTORUN L"Software\\Microsoft\\Windows\\CurrentVersion\\Run"
#define KEYAUTORUN L"KeyboardLayoutMonitor"
#define REGKLPRELOAD L"Keyboard Layout\\Preload"
#define APRIMARY L"PRIMARY"
#define AOTHER L"OTHER"

#include <atlbase.h>
//#include <atlstr.h>
//#include <atlutil.h>

#include <atlapp.h>

extern CAppModule _Module;

#include <atlwin.h>

#include <atlcrack.h>
//#include <atlframe.h>
#include <atlstr.h> //first!
#include <atlctrls.h> //second! GetLBText
#include <atldlgs.h>

#if defined _M_IX86
  #pragma comment(linker, "/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='x86' publicKeyToken='6595b64144ccf1df' language='*'\"")
#elif defined _M_IA64
  #pragma comment(linker, "/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='ia64' publicKeyToken='6595b64144ccf1df' language='*'\"")
#elif defined _M_X64
  #pragma comment(linker, "/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='amd64' publicKeyToken='6595b64144ccf1df' language='*'\"")
#else
  #pragma comment(linker, "/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")
#endif
