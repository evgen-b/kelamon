#include "stdafx.h"
#include "klarr.h"
#pragma warning(disable : 4996)

const wchar_t *cwKeyboardLayoutPreload = REGKLPRELOAD;
const wchar_t *cwRegKilomaster = REGKILOMASTER;
const wchar_t *cwPrimary = APRIMARY;
const wchar_t *cwOther = AOTHER;

void RegReadColors(LPCWSTR sRegPath, COLORREF &DWM, COLORREF &Accent, bool &bUseDWM, bool &bUseAccent)
{
	//если ключа в реестре нет, то функци€ ничего не мен€ет.
	//если переменной в ключе реестра нет, то соответствующа€ переменна€ не мен€етс€
	//поэтому перед вызовом функции необходимо проинициализировать по умолчанию все ее аргументы

	DWORD r,g,b;
	LONG err1, err2, err3;
	CRegKey key;
	if (key.Open(HKEY_CURRENT_USER, sRegPath, KEY_READ) == ERROR_SUCCESS)
	{
		err1=key.QueryDWORDValue(L"DWM_R", r);
		err2=key.QueryDWORDValue(L"DWM_G", g);
		err3=key.QueryDWORDValue(L"DWM_B", b);
		if( (err1 | err2 | err3) == ERROR_SUCCESS ) DWM=RGB(r,g,b);

		err1=key.QueryDWORDValue(L"ACCENT_R", r);
		err2=key.QueryDWORDValue(L"ACCENT_G", g);
		err3=key.QueryDWORDValue(L"ACCENT_B", b);
		if( (err1 | err2 | err3) == ERROR_SUCCESS ) Accent=RGB(r,g,b);

		err1=key.QueryDWORDValue(L"USE_DWM_COLOR", r);
		err2=key.QueryDWORDValue(L"USE_ACCENT_COLOR", g);
		if( err1 == ERROR_SUCCESS ) bUseDWM = (r != 0);
		if( err2 == ERROR_SUCCESS ) bUseAccent = (g != 0);
	}
	key.Close();
}//RegReadColors

void RegSaveColors(LPCWSTR sRegPath, COLORREF DWM, COLORREF Accent, bool bUseDWM, bool bUseAccent)
{
	CRegKey key;
	if (key.Create(HKEY_CURRENT_USER, sRegPath) == ERROR_SUCCESS)
	{
		key.SetDWORDValue(L"DWM_R", GetRValue(DWM));
		key.SetDWORDValue(L"DWM_G", GetGValue(DWM));
		key.SetDWORDValue(L"DWM_B", GetBValue(DWM));

		key.SetDWORDValue(L"ACCENT_R", GetRValue(Accent));
		key.SetDWORDValue(L"ACCENT_G", GetGValue(Accent));
		key.SetDWORDValue(L"ACCENT_B", GetBValue(Accent));

		key.SetDWORDValue(L"USE_DWM_COLOR", bUseDWM);
		key.SetDWORDValue(L"USE_ACCENT_COLOR", bUseAccent);
	}
	key.Close();
}

bool RegTrayHide(LPCWSTR sRegPath)
{
	DWORD hide;
	LONG err1;
	CRegKey key;
	if (key.Open(HKEY_CURRENT_USER, sRegPath, KEY_READ) == ERROR_SUCCESS)
		{ err1=key.QueryDWORDValue(L"TrayHide", hide); }
	key.Close();
	if( err1 == ERROR_SUCCESS ) { return (hide != 0); }
	return false;
}

CLayoutColor::CLayoutColor(LPCWSTR Name, DWORD ID, COLORREF DWM, COLORREF Accent, bool UseDWM, bool UseAccent)
{
	dwID=ID; ColorDWM=DWM; ColorAccent=Accent; bUseDWM=UseDWM; bUseAccent=UseAccent;
	memset(sName, 0, sizeof(sName)); //<stdlib.h> C4996
	wcsncpy(sName, Name, LOCALE_NAME_MAX_LENGTH);
}

CLayoutColor::CLayoutColor()
{
	dwID=0; ColorDWM=0; ColorAccent=0; bUseDWM=false; bUseAccent=false;
	memset(sName, 0, sizeof(sName));
}

void CInstalledLayouts::LoadLayouts (COLORREF DefaultPrimaryDWM, COLORREF DefaultPrimaryAccent, COLORREF DefaultOtherDWM, COLORREF DefaultOtherAccent, bool reset)
{
	// перечисл€ем из реестра все раскладки
	// и подгружаем к каждой раскладке еЄ цветовые настройки программы
	// если цветовые настройки не определены, то используем дефолтные

	// между вызовами этой подпрограммы пользователь мог какие-то раскладки добавить, и какие-то удалить.
	// если reset=false, то только читаем и добавл€ем новые раскладки, которые пользователь мог добавить в Windows, а цветовые настройки уже загруженных раскладок не трогаем
	// если reset=true, то перечитываем всЄ заново, удаленные в Windows пользователем раскладки пропадут из списка, а настройки существующих перепишутс€ сохраненными значени€ми из реестра

	if (reset) { RemoveAll(); }

	CRegKey key;
	if(ERROR_SUCCESS != key.Open(HKEY_CURRENT_USER, cwKeyboardLayoutPreload, KEY_READ)) return;

	wchar_t sLCID[LOCALE_NAME_MAX_LENGTH+1] = { 0 };
	wchar_t sValName[KL_NAMELENGTH+1] = { 0 };
	DWORD readed=KL_NAMELENGTH; // number of characters, not bytes?

	DWORD dwIndex = 0;
	while (ERROR_SUCCESS == RegEnumValueW(key, dwIndex++, sValName, &readed, NULL, NULL, NULL, NULL))
	{
		readed=KL_NAMELENGTH;
		if (ERROR_SUCCESS == key.QueryStringValue(sValName, sLCID, &readed)) //If the method returns ERROR_MORE_DATA, pnChars equals zero, not the required buffer size in bytes.
		{
			char* p; char c[KL_NAMELENGTH+1] = { 0 };
			wcstombs(c, sLCID, KL_NAMELENGTH); //<stdlib.h> C4996
			c[KL_NAMELENGTH] = 0;
			DWORD dwLCID = std::strtol(c, &p, 16);

			if ( *p == 0 ) // dwLCID is OK
			{
				//при обновлении noremove=true, только добавл€ем новые раскладки, цветовые настройки существующих не трогаем
				bool ispresent=false;
				for (int i=0; i<GetSize(); i++)
				{
					if (operator[](i).dwID == dwLCID) { ispresent=true; }
				}

				if (!ispresent)
				{
					//сначала грузим дефолтные настройки
					COLORREF TmpDWM, TmpAccent;
					if(_wcsicmp(sValName, L"1") == 0)
						{ TmpDWM=DefaultPrimaryDWM; TmpAccent=DefaultPrimaryAccent; }
					else
						{ TmpDWM=DefaultOtherDWM; TmpAccent=DefaultOtherAccent;}
					bool TmpUseDWM=false; bool TmpUseAccent=false;
			
					//потом поверх из реестра, если они есть
					CStringW sKeyCustom = CStringW(cwRegKilomaster) + L"\\" + CStringW(sLCID);
					RegReadColors (sKeyCustom, TmpDWM, TmpAccent, TmpUseDWM, TmpUseAccent);

					//GetLocaleInfoW(dwLCID, LOCALE_SENGLANGUAGE, sLCID, LOCALE_NAME_MAX_LENGTH);
					GetLocaleInfoW(dwLCID, LOCALE_SLANGUAGE, sLCID, LOCALE_NAME_MAX_LENGTH);
					Add(CLayoutColor(sLCID, dwLCID, TmpDWM, TmpAccent, TmpUseDWM, TmpUseAccent));
				}
			}


		}
	}//while
	key.Close();
}//LoadLayouts

//
// Legacy labels for the locale name values
//
//#define LOCALE_SLANGUAGE              0x00000002   // localized name of locale, eg "German (Germany)" in UI language
//#define LOCALE_SLANGDISPLAYNAME       0x0000006f   // Language Display Name for a language, eg "German" in UI language
//#define LOCALE_SENGLANGUAGE           0x00001001   // English name of language, eg "German"
//#define LOCALE_SNATIVELANGNAME        0x00000004   // native name of language, eg "Deutsch"
//#define LOCALE_SCOUNTRY               0x00000006   // localized name of country, eg "Germany" in UI language
//#define LOCALE_SENGCOUNTRY            0x00001002   // English name of country, eg "Germany"
//#define LOCALE_SNATIVECTRYNAME        0x00000008   // native name of country, eg "Deutschland"


void CInstalledLayouts::SaveLayouts(void)
{
	CStringW sKeyCustom;
	for (int i=0; i<GetSize(); i++)
	{
		sKeyCustom.Format(L"%s\\%08X", cwRegKilomaster, operator[](i).dwID);
		RegSaveColors(sKeyCustom, operator[](i).ColorDWM, operator[](i).ColorAccent, operator[](i).bUseDWM, operator[](i).bUseAccent);

	}
}

#define classnamebufmax 20
DWORD GetKeybLay (DWORD winver, /*debug*/ HWND &hwnd, /*debug*/ DWORD &threadID)
{
	DWORD lParam=-1;

	wchar_t buf[classnamebufmax+1];
	memset(&buf, 0, sizeof(buf));
	hwnd = GetForegroundWindow();
	GetClassNameW(hwnd, buf, classnamebufmax);

	if (wcscmp(buf, L"ConsoleWindowClass") == 0)
	{
		// дл€ cmd.exe и консольных окон
		// --- hookerwatcher ---

		//DWORD dwPID, dwTID;
		//dwTID=GetWindowThreadProcessId (hwnd, &dwPID);
		//CStringW teststr;
		//teststr.Format(L"hwnd=%d pid=%d tid=%d", hwnd, dwPID, dwTID);
		//::MessageBoxW(NULL, teststr, L"=ConsoleWindowClass=", MB_OK);

		;;;
	}
	else
	{
		// дл€ UWP-приложений получить раскладку можно только использу€ GetGUIThreadInfo
		// дл€ win32 приложений - без разницы GetForegroundWindow или GetGUIThreadInfo
		GUITHREADINFO gti;
		memset(&gti, 0, sizeof(GUITHREADINFO));
		gti.cbSize=sizeof(GUITHREADINFO);
		GetGUIThreadInfo(NULL, &gti);
		hwnd = gti.hwndFocus; // handle to the window that has the keyboard focus (msdn), worked with UWP

		if (hwnd)
		{
			//const HKL CurrentLayout = ::GetKeyboardLayout(threadID);
			//LONG_PTR lParam = (unsigned int)CurrentLayout & 0x0000FFFF;
			threadID = GetWindowThreadProcessId(hwnd, NULL);
			lParam = (DWORD) GetKeyboardLayout(threadID);

		}


	}





	return lParam;
}//GetKeybLay
