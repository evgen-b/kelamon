#include "stdafx.h"
#include "resource.h"

#include "MainDlg.h"
#include "WindowsThemeColorApi.h"
#include <string>
//#include <atlstr.h>
//#include <atlctrls.h>

#pragma warning(disable : 4996)

// TODO говнокостыли из WindowsThemeColorApi.cpp и klarr.cpp
extern DWORD winver_major, winver_minor, winver_build;
extern const wchar_t *cwKeyboardLayoutPreload;
extern const wchar_t *cwRegKilomaster;
extern const wchar_t *cwPrimary;
extern const wchar_t *cwOther;

COLORREF ComputeTxtColor(COLORREF bg)
{
	//return (bg ^ 0xFFFFFF);
	// 0xFF RED
	// 0xFF00 GREEN
	// 0xFF0000 BLUE
	int y=int(0.2126f*GetRValue(bg) + 0.7152f*GetGValue(bg) + 0.0722f*GetBValue(bg));
	if (y<128) { return 0xFFFFFF; }
	return 0;
}

bool CMainDlg::IsAutorun(HKEY hkey) // HKEY_LOCAL_MACHINE HKEY_CURRENT_USER
{
	DWORD regError;
	CRegKey key;
	
	regError = key.Open(hkey, szwRegAutorun, KEY_READ | KEY_WOW64_64KEY); //64-bit fix
	if(regError != ERROR_SUCCESS) { return false; }

	wchar_t wt[2]; // MAX_PATH
	DWORD readed=2; // number of characters, not bytes?
	regError = key.QueryStringValue(szwKeyAutorun, wt, &readed); //If the method returns ERROR_MORE_DATA, pnChars equals zero, not the required buffer size in bytes.
	key.Close();

	if(regError == ERROR_SUCCESS || regError == ERROR_MORE_DATA) { return true; }
	return false;
} //IsAdminAutorun

BOOL CMainDlg::OnInitDialog(CWindow wndFocus, LPARAM lInitParam)
{
	// Center the dialog on the screen
	CenterWindow();

	InitIcons();

	SetWindowText(szwWinTitle);

	// Init colors
	GetDefaultColors();

	RegLoadSettings();

	colorbuttonDWM.SubclassWindow(GetDlgItem(IDC_DWM_BTN));
	colorbuttonDWM_RUS.SubclassWindow(GetDlgItem(IDC_DWM_BTN_RUS));
	colorbuttonACCENT.SubclassWindow(GetDlgItem(IDC_ACCENT_BTN));
	colorbuttonACCENT_RUS.SubclassWindow(GetDlgItem(IDC_ACCENT_BTN_RUS));

	colbutCustomDWM.SubclassWindow(GetDlgItem(IDC_DWM_CUST));
	colbutCustomACCENT.SubclassWindow(GetDlgItem(IDC_ACCENT_CUST));

	LayComboBoxFill(true);

	// Init controls
	RefreshControls();

	SetTimer(TIMER1, 70);

	return TRUE;
}

void CMainDlg::OnAppAbout(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	if( ::GetKeyState(VK_CONTROL) & 0x8000 )
	{
		isDebugInfoVisible = !isDebugInfoVisible;
		RefreshControls();
	}
	else
	{
		CSimpleDialog<IDD_ABOUTBOX, FALSE> dlg;
		//CStatic(dlg.GetDlgItem(IDC_STATIC_ABOUT)).SetWindowText(L"bla-bla");
		dlg.DoModal();
	}
}

void CMainDlg::OnOK(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	RegSaveSettings();
	SetColors();
	CButton(GetDlgItem(IDOK)).EnableWindow(FALSE);
	CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(FALSE);
}

void CMainDlg::OnBnClickedUndoBtn(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	RegLoadSettings();
	SetColors();
	RefreshControls();

	int ind = CComboBox(GetDlgItem(IDC_COMBO1)).GetCurSel();
	ind = ComboBoxIndex2AtlIndex(ind);
	if (ind == -1) { ind=LayComboBoxSelAuto(); }
	LayCustomFill(ind);
}


void CMainDlg::OnCancel(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	// EndDialog(nID);
	ShowWindow(SW_MINIMIZE);
	ShowWindow(SW_HIDE);
}

void CMainDlg::OnDwmBtnClick(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	CColorDialog colorDlg(PrimaryScheme.ColorDWM, CC_FULLOPEN);
	if(colorDlg.DoModal() == IDOK)
	{
		PrimaryScheme.ColorDWM = colorDlg.GetColor();
		colorbuttonDWM.SetBkColor(PrimaryScheme.ColorDWM);
		colorbuttonDWM.SetTextColor(ComputeTxtColor(PrimaryScheme.ColorDWM));
		CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
		CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
	}
}

void CMainDlg::OnBnClickedDwmBtnRus(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	CColorDialog colorDlg(OtherScheme.ColorDWM, CC_FULLOPEN);
	if(colorDlg.DoModal() == IDOK)
	{
		OtherScheme.ColorDWM = colorDlg.GetColor();
		colorbuttonDWM_RUS.SetBkColor(OtherScheme.ColorDWM);
		colorbuttonDWM_RUS.SetTextColor(ComputeTxtColor(OtherScheme.ColorDWM));
		CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
		CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
	}
}

void CMainDlg::OnAccentBtnClick(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	CColorDialog colorDlg(PrimaryScheme.ColorAccent, CC_FULLOPEN);
	if(colorDlg.DoModal() == IDOK)
	{
		PrimaryScheme.ColorAccent = colorDlg.GetColor();
		colorbuttonACCENT.SetBkColor(PrimaryScheme.ColorAccent);
		colorbuttonACCENT.SetTextColor(ComputeTxtColor(PrimaryScheme.ColorAccent));
		CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
		CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
	}
}

void CMainDlg::OnBnClickedAccentBtnRus(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	CColorDialog colorDlg(OtherScheme.ColorAccent, CC_FULLOPEN);
	if(colorDlg.DoModal() == IDOK)
	{
		OtherScheme.ColorAccent = colorDlg.GetColor();
		colorbuttonACCENT_RUS.SetBkColor(OtherScheme.ColorAccent);
		colorbuttonACCENT_RUS.SetTextColor(ComputeTxtColor(OtherScheme.ColorAccent));
		CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
		CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
	}
}

void CMainDlg::OnAccentNewAlgoClick(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	m_newAccentAlgo = IsDlgButtonChecked(IDC_ACCENT_NO_NEW_ALGO) == BST_UNCHECKED;
	CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
	CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
}

void CMainDlg::OnBnClickedUseDwmcolor(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	PrimaryScheme.bUseDWM = IsDlgButtonChecked(IDC_USE_DWMCOLOR) == BST_CHECKED;
	CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
	CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
}

void CMainDlg::OnBnClickedUseAccentcolor(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	PrimaryScheme.bUseAccent = IsDlgButtonChecked(IDC_USE_ACCENTCOLOR) == BST_CHECKED;
	CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
	CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
}

void CMainDlg::OnBnClickedAutorun(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	m_Autorun = IsDlgButtonChecked(IDC_AUTORUN) == BST_CHECKED;
	CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
	CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
}

bool isFirstPreloadKeyboardLayout(LPARAM lang)
// TRUE, если совпадает с языком ввода по умолчанию в "Языки и службы текстового ввода"
{
	DWORD regError;

	CRegKey key;
	regError = key.Open(HKEY_CURRENT_USER, cwKeyboardLayoutPreload, KEY_READ);
	if(regError != ERROR_SUCCESS)
	{
		CStringW teststr;
		teststr.Format(L"Can't open for reading: HKCU\\Keyboard Layout\\Preload\\1 with Error=0x%X (dec=%d)", regError, regError);
		MessageBoxW(NULL, teststr, L"=FAIL1=", MB_OK);
		key.Close(); return false;
	}

	wchar_t szwPrimaryLCID[KL_NAMELENGTH+1] = { 0 };
	DWORD readed=KL_NAMELENGTH; // number of characters, not bytes?
	regError = key.QueryStringValue(L"1", szwPrimaryLCID, &readed); //If the method returns ERROR_MORE_DATA, pnChars equals zero, not the required buffer size in bytes.
	key.Close();
	if(regError != ERROR_SUCCESS)
	{
		CStringW teststr;
		teststr.Format(L"Can't read key: HKCU\\Keyboard Layout\\Preload\\1 with Error=0x%X (dec=%d)", regError, regError);
		MessageBoxW(NULL, teststr, L"=FAIL2=", MB_OK);
		return false;
	}

	char* p; char c[KL_NAMELENGTH+1] = { 0 };
	wcstombs(c, szwPrimaryLCID, KL_NAMELENGTH); //<stdlib.h> C4996
	c[KL_NAMELENGTH] = 0;
	DWORD nPrimaryLCID = std::strtol(c, &p, 16);
	if ( *p != 0 )
	{
		CStringW teststr;
		teststr.Format(L"Can't convert HEX-STR to INT: HKCU\\Keyboard Layout\\Preload\\1 (=%ls) with Error=0x%X (dec=%d)", szwPrimaryLCID, regError, regError);
		MessageBoxW(NULL, teststr, L"=FAIL3=", MB_OK);
		return false;
	}

	DWORD currentLCID = LOWORD(lang);
	bool eq = (currentLCID == nPrimaryLCID);

	/*
	CStringW teststr;
	teststr.Format(L"MSG=%X LOWORD(MSG)=%X [PRIMARY=%X] eq=%d", lang, currentLCID, nPrimaryLCID, eq);
	::MessageBoxW(NULL, teststr, L"=MSG=", MB_OK);
	*/

	return eq;
}

LRESULT CMainDlg::OnLanguageChanged(UINT uNotifyCode, WPARAM wParam, LPARAM lParam)
{
	// lParam 04090409
	// lParam 04190419
	if (lParam == h_CurrLang) return TRUE;
	h_CurrLang=lParam;

	LayCustomFill(LayComboBoxSelAuto());

	isLangENU = isFirstPreloadKeyboardLayout(lParam);
	SetColors();
    
    return TRUE;
}

LRESULT CMainDlg::OnTrayIcon(UINT uNotifyCode, WPARAM wParam, LPARAM lParam)
{
	//POINT pt;
	switch(lParam)
	{
		case WM_LBUTTONDBLCLK:
			if (IsWindowVisible())
			{
				ShowWindow(SW_MINIMIZE);
				ShowWindow(SW_HIDE);
			}
			else
			{
				m_visible=TRUE;
				ShowWindow(SW_SHOW);
				ShowWindow(SW_RESTORE);					
				CenterWindow();
			}
			break;

		case WM_RBUTTONDOWN:	// нажатие на иконку правой кнопкой мыши
			//GetCursorPos(&pt);	//вычисляем текущее положение курсора
			//HandlePopupMenu (m_hWnd, pt);  //рисуем меню от координат курсора
			//::MessageBox(NULL, L"Правая кнопка мыши", L"Сообщение от иконки", MB_OK);
			break;

		default:
			break;
	}
    
    return TRUE;
}

LRESULT CMainDlg::OnShowCommand(UINT uNotifyCode, WPARAM wParam, LPARAM lParam)
{// API with RULE34
	if (wParam==42 && lParam==42)
	{
		m_visible=TRUE;
		ShowWindow(SW_SHOW);
		ShowWindow(SW_RESTORE);					
		CenterWindow();
		return 0;
	}
	else if (wParam==34 && lParam==34)
	{
		ShowWindow(SW_MINIMIZE);
		ShowWindow(SW_HIDE);
		return 0;
	}
	return TRUE;
}

LRESULT CMainDlg::OnSetupColorCommand(UINT uNotifyCode, WPARAM wParam, LPARAM lParam)
{// API
	switch(wParam)
	{
		case 1:
			SetDwmColorizationColor((COLORREF)lParam);
			return 0;
		case 2:
			SetAccentColor((COLORREF)lParam);
			return 0;
		default:
			break;
	}

	return TRUE;
}

void CMainDlg::RegLoadSettings()
{
	// PrimaryScheme.bUseDWM и PrimaryScheme.bUseAccent используются сразу для управления двумя цветовыми схемами раскладок - "основной" (primary) и "всех остальных" (other)
	CStringW sKey = CStringW(cwRegKilomaster) + L"\\" + CStringW(cwOther);
	RegReadColors(sKey, OtherScheme.ColorDWM, OtherScheme.ColorAccent, /*dummy*/ OtherScheme.bUseDWM, /*dummy*/ OtherScheme.bUseAccent);

	sKey = CStringW(cwRegKilomaster) + L"\\" + CStringW(cwPrimary);
	RegReadColors(sKey, PrimaryScheme.ColorDWM, PrimaryScheme.ColorAccent, PrimaryScheme.bUseDWM, PrimaryScheme.bUseAccent);

	m_newAccentAlgo = IsNewAutoColorAccentAlgorithm();
	m_Autorun=IsAutorun(HKEY_CURRENT_USER);

	// загружаем цветовые схемы для кастомных раскладок, привязанных к конкретным языкам.
	// по умолчанию цвета берутся из дефолтных (primary/other) схем
	InstLay.LoadLayouts (PrimaryScheme.ColorDWM, PrimaryScheme.ColorAccent, OtherScheme.ColorDWM, OtherScheme.ColorAccent, true);
}

void CMainDlg::RegSaveSettings()
{
	CStringW sKey = CStringW(cwRegKilomaster) + L"\\" + CStringW(cwOther);
	RegSaveColors(sKey, OtherScheme.ColorDWM, OtherScheme.ColorAccent, /*dummy*/ false, /*dummy*/ false);

	sKey = CStringW(cwRegKilomaster) + L"\\" + CStringW(cwPrimary);
	RegSaveColors(sKey, PrimaryScheme.ColorDWM, PrimaryScheme.ColorAccent, PrimaryScheme.bUseDWM, PrimaryScheme.bUseAccent);

	SetAutoColorAccentAlgorithm(m_newAccentAlgo);
	RegSetAutorun();

	InstLay.SaveLayouts();
}

void CMainDlg::GetDefaultColors()
{
	PrimaryScheme.ColorDWM	= GetDwmColorizationColor();
	OtherScheme.ColorDWM	= PrimaryScheme.ColorDWM;

	if (::winver_build >= 10240)
		{ PrimaryScheme.ColorAccent = GetAccentColor(); }
	else
		{ PrimaryScheme.ColorAccent	= PrimaryScheme.ColorDWM; }
	OtherScheme.ColorAccent = PrimaryScheme.ColorAccent;
}

void CMainDlg::SetColors()
{
	COLORREF dwmColor, accentColor;
	bool bUseDWM_loc, bUseAccent_loc;

	// сначала заполняем настройками из цветовых схем primary/other
	if (isLangENU)
	{
		dwmColor	= PrimaryScheme.ColorDWM;
		accentColor = PrimaryScheme.ColorAccent;
	}
	else
	{
		dwmColor	= OtherScheme.ColorDWM;
		accentColor = OtherScheme.ColorAccent;
	}

	bUseDWM_loc=PrimaryScheme.bUseDWM;
	bUseAccent_loc=PrimaryScheme.bUseAccent;

	// кастомные настройки цветовой схемы раскладки имеют наивысший приоритет
	int customind=LCID2AtlIndex(h_CurrLang & 0xFFFF);
	if (customind != -1)
	{
		if (InstLay[customind].bUseDWM)
		{
			dwmColor=InstLay[customind].ColorDWM;
			bUseDWM_loc=true;
		}

		if (InstLay[customind].bUseAccent)
		{
			accentColor=InstLay[customind].ColorAccent;
			bUseAccent_loc=true;
		}
	}


	//                 :::ORIGINAL:::
	/*
	// The function calls below seem excessive, but that's a combination that
	// works, unlike a more intuitive one.
	// Without setting the DWM color before the Accent color,
	// or without setting the Accent color twice with different colors,
	// or without using a delay, the new accent algorithm doesn't apply.
	// Windows 10 Anniversary Update resets the DWM color while setting the
	// Accent color, therefore it's necessary to set it again.

	// Set DWM color.
	SetDwmColorizationColor(dwmColor);

	// Set Accent algorithm and color.
	SetAutoColorAccentAlgorithm(m_newAccentAlgo);

	// The similar color and the delay are necessary to apply the new accent algorithm.
	COLORREF similarToNewAccentColor = RGB(
		GetRValue(accentColor) + (GetRValue(accentColor) > 0x7F ? -1 : 1),
		GetGValue(accentColor),
		GetBValue(accentColor));

	SetAccentColor(similarToNewAccentColor);
	Sleep(100);

	SetAccentColor(m_accentColor, !m_newAccentAlgo);

	// Set DWM color again.
	SetDwmColorizationColor(dwmColor);
	*/


	if (bUseDWM_loc)
	{
		SetDwmColorizationColor(dwmColor);
	}
	
	if (bUseAccent_loc)
	{
		COLORREF similarToNewAccentColor = RGB(
			GetRValue(accentColor) + (GetRValue(accentColor) > 0x7F ? -1 : 1),
			GetGValue(accentColor),
			GetBValue(accentColor));
		if (::winver_build >= 10240) { SetAccentColor(similarToNewAccentColor); }
	}

}

void CMainDlg::RefreshControls()
{
	// Reload the new settings.

	CheckDlgButton(IDC_USE_DWMCOLOR, PrimaryScheme.bUseDWM ? BST_CHECKED : BST_UNCHECKED);

	if (::winver_build >= 10240)
	{
		CheckDlgButton(IDC_USE_ACCENTCOLOR, PrimaryScheme.bUseAccent ? BST_CHECKED : BST_UNCHECKED);
		CheckDlgButton(IDC_ACCENT_NO_NEW_ALGO, m_newAccentAlgo ? BST_UNCHECKED : BST_CHECKED);
	}
	else
	{
		CButton(GetDlgItem(IDC_USE_ACCENTCOLOR)).EnableWindow(FALSE);
		//CButton(GetDlgItem(IDC_USE_ACCENTCOLOR)).SetWindowText(L"none");
		CheckDlgButton(IDC_USE_ACCENTCOLOR, BST_UNCHECKED);

		CButton(GetDlgItem(IDC_ACCENT_NO_NEW_ALGO)).EnableWindow(FALSE);
		//CButton(GetDlgItem(IDC_ACCENT_NO_NEW_ALGO)).SetWindowText(L"none");
		CheckDlgButton(IDC_ACCENT_NO_NEW_ALGO, BST_UNCHECKED);
	}

	CButton(GetDlgItem(IDOK)).EnableWindow(FALSE);
	CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(FALSE);

	colorbuttonDWM.SetBkColor(PrimaryScheme.ColorDWM);
	colorbuttonDWM.SetTextColor(ComputeTxtColor(PrimaryScheme.ColorDWM));

	colorbuttonDWM_RUS.SetBkColor(OtherScheme.ColorDWM);
	colorbuttonDWM_RUS.SetTextColor(ComputeTxtColor(OtherScheme.ColorDWM));

	if (::winver_build >= 10240)
	{
		colorbuttonACCENT.SetBkColor(PrimaryScheme.ColorAccent);
		colorbuttonACCENT.SetTextColor(ComputeTxtColor(PrimaryScheme.ColorAccent));

		colorbuttonACCENT_RUS.SetBkColor(OtherScheme.ColorAccent);
		colorbuttonACCENT_RUS.SetTextColor(ComputeTxtColor(OtherScheme.ColorAccent));
	}
	else
	{
		CButton(GetDlgItem(IDC_ACCENT_BTN)).EnableWindow(FALSE);
		CButton(GetDlgItem(IDC_ACCENT_BTN_RUS)).EnableWindow(FALSE);
	}

	//colorbuttonDWM.SetWindowText(L"PRIMARY DWM");
	//colorbuttonDWM_RUS.SetWindowText(L"OTHER DWM");
	//colorbuttonACCENT.SetWindowText(L"PRIMARY ACCENT");
	//colorbuttonACCENT_RUS.SetWindowText(L"OTHER ACCENT");

	if (IsAutorun(HKEY_LOCAL_MACHINE))
	{
		CButton(GetDlgItem(IDC_AUTORUN)).EnableWindow(FALSE);
		CButton(GetDlgItem(IDC_AUTORUN)).SetWindowText(L"Autorun by Administrator");
		CheckDlgButton(IDC_AUTORUN, BST_CHECKED);
	}
	else
	{
		CButton(GetDlgItem(IDC_AUTORUN)).EnableWindow(TRUE);
		CButton(GetDlgItem(IDC_AUTORUN)).SetWindowText(L"Autorun");
		CheckDlgButton(IDC_AUTORUN, m_Autorun ? BST_CHECKED : BST_UNCHECKED);
	}

	if (isDebugInfoVisible)
		{ CStatic(GetDlgItem(IDC_STATIC_DBGINFO)).ShowWindow(SW_SHOW); }
	else
		{ CStatic(GetDlgItem(IDC_STATIC_DBGINFO)).ShowWindow(SW_HIDE); }

}

void CMainDlg::SetStatusIcon(HICON hStatusIcon)
{
	if (hStatusIcon)
	{
		memset(&TrayIcon, 0, sizeof(NOTIFYICONDATA));
		TrayIcon.cbSize = sizeof(NOTIFYICONDATA);
		TrayIcon.hWnd = m_hWnd;
		TrayIcon.uID = 1;
		TrayIcon.uFlags = NIF_MESSAGE|NIF_ICON|NIF_TIP;
		TrayIcon.uCallbackMessage = WM_NOTIFYICONMSG;
		TrayIcon.hIcon = hStatusIcon;
		lstrcpyn(TrayIcon.szTip, szwWinTitle, sizeof(TrayIcon.szTip));
		Shell_NotifyIcon( NIM_ADD, &TrayIcon );
	}
	else
	{
		Shell_NotifyIcon( NIM_DELETE, &TrayIcon );
	}
}

void CMainDlg::OnFinalMessage(_In_ HWND /*hWnd*/)
{
	KillTimer(TIMER1);

	SetStatusIcon(NULL);

    ::PostQuitMessage(0);
}

LRESULT CMainDlg::OnWMSize(UINT uNotifyCode, WPARAM wParam, LPARAM lParam)
{
	if(wParam == SIZE_MINIMIZED)
	{
		ShowWindow(SW_HIDE);
	}
	return 0;
}

void CMainDlg::InitWindowText(wchar_t* title)
{
	szwWinTitle=title;
}

void CMainDlg::OnWindowPosChanging(WINDOWPOS FAR* lpwndpos) 
{
	bool firstinvisible = (lpwndpos->flags & SWP_SHOWWINDOW) && !m_visible;

    if (!m_visible)
        lpwndpos->flags &= ~SWP_SHOWWINDOW;
	// Хоть теперь окно и не будет видно при первом запуске, но клавиатура все равно с ним связана и
	// невидимое окно на нее реагирует! С этим надо что-то делать...
	// Поэтому ставим в очередь сообщений еще одно, которое его свернет понастоящему
	if (firstinvisible) PostMessageW(WM_SHOWWINDOW, FALSE, SW_OTHERZOOM);
}

void CMainDlg::CreateDialogVisible(BOOL bVisible)
{
	m_visible=bVisible;
}

CMainDlg::CMainDlg():m_visible(TRUE)
{
	szwRegAutorun=REGAUTORUN;
	szwKeyAutorun=KEYAUTORUN;
	m_Autorun=false;
	isDebugInfoVisible=false;
}

void CMainDlg::InitIcons()
{
	// Set icons

	/*
	HICON hIcon = AtlLoadIconImage(IDR_MAINFRAME, LR_DEFAULTCOLOR, ::GetSystemMetrics(SM_CXICON), ::GetSystemMetrics(SM_CYICON));
	SetIcon(hIcon, TRUE);
	HICON hIconSmall = AtlLoadIconImage(IDR_MAINFRAME, LR_DEFAULTCOLOR, ::GetSystemMetrics(SM_CXSMICON), ::GetSystemMetrics(SM_CYSMICON));
	SetIcon(hIconSmall, FALSE);
	*/

	HMODULE hMod = GetModuleHandle(L"SHELL32.dll");
	if (!hMod) ::MessageBoxW(NULL, L"GetModuleHandle SHELL32.dll fail", L"InitIcons", MB_OK);
	HICON hIcon = (HICON) ::LoadImage(hMod, MAKEINTRESOURCE(239), IMAGE_ICON, ::GetSystemMetrics(SM_CXICON), ::GetSystemMetrics(SM_CYICON), LR_SHARED);
	//HICON hIcon = (HICON) ::LoadImage(hMod, L"#239", IMAGE_ICON, ::GetSystemMetrics(SM_CXICON), ::GetSystemMetrics(SM_CYICON), LR_SHARED);
	SetIcon(hIcon, TRUE);

	HICON hIconSmall = (HICON) ::LoadImage(hMod, MAKEINTRESOURCE(239), IMAGE_ICON, ::GetSystemMetrics(SM_CXSMICON), ::GetSystemMetrics(SM_CYSMICON), LR_SHARED);
	//HICON hIconSmall = (HICON) ::LoadImage(hMod, L"#239", IMAGE_ICON, ::GetSystemMetrics(SM_CXSMICON), ::GetSystemMetrics(SM_CYSMICON), LR_SHARED);
	SetIcon(hIconSmall, FALSE);

	if (RegTrayHide(cwRegKilomaster)) return;
	SetStatusIcon(hIconSmall);
	if (!hIconSmall) ::MessageBoxW(NULL, L"LoadImage SHELL32 #239 fail", L"InitIcons", MB_OK);
}

void CMainDlg::RegSetAutorun()
{

	DWORD dwError;
	CRegKey key;
	dwError = key.Create(HKEY_CURRENT_USER, szwRegAutorun);
	ATLENSURE_SUCCEEDED(AtlHresultFromWin32(dwError));

	if(m_Autorun)
	{
		wchar_t szwAppPath[MAX_PATH] = L"";
		GetModuleFileNameW(NULL, szwAppPath, MAX_PATH-1);
		CStringW cswCmdline = L"\"" + CStringW(szwAppPath) + L"\"";

		dwError = key.SetStringValue(szwKeyAutorun, cswCmdline);
		ATLENSURE_SUCCEEDED(AtlHresultFromWin32(dwError));
	}
	else
	{
		dwError = key.DeleteValue(szwKeyAutorun);
		if(dwError != ERROR_FILE_NOT_FOUND && dwError != ERROR_PATH_NOT_FOUND)
		{
			ATLENSURE_SUCCEEDED(AtlHresultFromWin32(dwError));
		}
	}
	key.Close();
}

#define classnamebufmax 20
void CMainDlg::OnTimer(UINT_PTR nIDEvent)
{

		HWND hwnd;
		DWORD threadID;
		const DWORD lParam = GetKeybLay (winver_build, /*debug*/ hwnd, /*debug*/ threadID);


		if (isDebugInfoVisible)
		{
			CStringW teststr;
			teststr.Format(L" HW=0x%08X   TH=%d   KL=0x%08X", hwnd, threadID, lParam);
			CStatic(GetDlgItem(IDC_STATIC_DBGINFO)).SetWindowText(teststr);
		}

		if (lParam == -1) return;

		// lParam 04090409
		// lParam 04190419
		if (lParam == h_CurrLang) return;
		h_CurrLang=lParam;

		LayCustomFill(LayComboBoxSelAuto());

		//isLangENU = !isLangENU;
		isLangENU = isFirstPreloadKeyboardLayout(lParam);
		SetColors();

}

void CMainDlg::OnCbnSelchangeCombo1(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	int ind = CComboBox(GetDlgItem(IDC_COMBO1)).GetCurSel();
	ind = ComboBoxIndex2AtlIndex(ind);
	if (ind != -1) { LayCustomFill(ind); }
}

void CMainDlg::LayComboBoxFill(bool Reset)
{
	// когда пользователь тыкает на выпадающий список комбобокса с раскладками,
	// предполагаем, что пользователь перед этим мог добавить/удалить новую раскладку
	// поэтому каждый раз будет вызываться эта подпрограмма

	InstLay.LoadLayouts(PrimaryScheme.ColorDWM, PrimaryScheme.ColorAccent, OtherScheme.ColorDWM, OtherScheme.ColorAccent, Reset);

	CComboBox(GetDlgItem(IDC_COMBO1)).ResetContent();
	for (int i=0; i<InstLay.GetSize(); i++)
	{
		CComboBox(GetDlgItem(IDC_COMBO1)).AddString( InstLay[i].sName );
	}
}

void CMainDlg::OnCbnDropDownCombo1(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	LayComboBoxFill(false); // обновим список языков, может пользователь _добавил_ новые раскладки
}

void CMainDlg::OnCbnSelEndCancelCombo1(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	//если пользователь открыл список языков в комбобоксе, но отказался от выбора,
	//ставим автоматическое значение, которое соответствует текущей раскладке

	LayComboBoxFill(false); // обновим список языков, может пользователь _добавил_ новые раскладки

	int ind=LayComboBoxSelAuto();
	LayCustomFill(ind);

	// SetCurSel из CBN_SELENDCANCEL не работает, выкручиваеся и ставим в очередь событие CB_SETCURSEL
	CComboBox(GetDlgItem(IDC_COMBO1)).PostMessageW(CB_SETCURSEL, AtlIndex2ComboBoxIndex(ind), 0);
}

int CMainDlg::AtlIndex2ComboBoxIndex(int ind)
{
	// здесь сопостовляем индекс в массиве InstLay с индексом в комбобоксе
	return CComboBox(GetDlgItem(IDC_COMBO1)).FindStringExact(-1, InstLay[ind].sName); // индекс - в строку и поиск строки в списке combobox
}

int CMainDlg::ComboBoxIndex2AtlIndex(int ind)
{
	//индекс в комбобоксе сопоставляем с индексом в массиве InstLay
	CStringW strIndex;
	CComboBox(GetDlgItem(IDC_COMBO1)).GetLBText(ind, strIndex);

	for(int i=0; i<InstLay.GetSize(); i++)
	{
		if( wcscmp(strIndex, InstLay[i].sName) == 0) { return i; }
	}
	return -1;
}

int CMainDlg::LCID2AtlIndex(int ind)
{
	// поиск ID языка ввода в массиве InstLay, возвращаем индекс в массиве
	for(int i=0; i<InstLay.GetSize(); i++)
	{
		if(InstLay[i].dwID == ind) { return i; }
	}
	return -1;
}


int CMainDlg::LayComboBoxSelAuto()
{
	// здесь автоматически вибирается язык в комбобоксе в зависимости от текущего h_CurrLang
	// возвращаем индекс для InstLay, соответствующий текущему h_CurrLang

	for (int i=0; i<InstLay.GetSize(); i++)
	{
		if(InstLay[i].dwID == (h_CurrLang & 0xFFFF)) // находим индекс i, который соответсвует текущему ID раскладки
		{
			int indx = AtlIndex2ComboBoxIndex(i);
			if (CB_ERR != indx)
			{
				CComboBox(GetDlgItem(IDC_COMBO1)).SetCurSel(indx);
				return i;
			}
		}

	}//for
	return 0;
}//LayComboBoxSelAuto

void CMainDlg::LayCustomFill(int nID)
{
// заполняем элементы, относящиеся к настройке Custom-раскладки

	CheckDlgButton(IDC_USE_DWM_CUST, InstLay[nID].bUseDWM ? BST_CHECKED : BST_UNCHECKED);

	if (::winver_build >= 10240)
	{
		CheckDlgButton(IDC_USE_ACCENT_CUST, InstLay[nID].bUseAccent ? BST_CHECKED : BST_UNCHECKED);
	}
	else
	{
		CButton(GetDlgItem(IDC_USE_ACCENT_CUST)).EnableWindow(FALSE);
		CheckDlgButton(IDC_USE_ACCENT_CUST, BST_UNCHECKED);

	}

	colbutCustomDWM.SetBkColor(InstLay[nID].ColorDWM);
	colbutCustomDWM.SetTextColor(ComputeTxtColor(InstLay[nID].ColorDWM));

	if (::winver_build >= 10240)
	{
		colbutCustomACCENT.SetBkColor(InstLay[nID].ColorAccent);
		colbutCustomACCENT.SetTextColor(ComputeTxtColor(InstLay[nID].ColorAccent));
	}
	else
	{
		CButton(GetDlgItem(IDC_ACCENT_CUST)).EnableWindow(FALSE);
	}
}//LayCustomFill

void CMainDlg::OnBnClickedDwmBtnCustom(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	int ind = CComboBox(GetDlgItem(IDC_COMBO1)).GetCurSel();
	ind = ComboBoxIndex2AtlIndex(ind);
	if (ind != -1)
	{
		CColorDialog colorDlg(InstLay[ind].ColorDWM, CC_FULLOPEN);
		if(colorDlg.DoModal() == IDOK)
		{
			InstLay[ind].ColorDWM = colorDlg.GetColor();
			colbutCustomDWM.SetBkColor(InstLay[ind].ColorDWM);
			colbutCustomDWM.SetTextColor(ComputeTxtColor(InstLay[ind].ColorDWM));
			CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
			CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
		}
	}
}//OnBnClickedDwmBtnCustom

void CMainDlg::OnBnClickedAccentBtnCustom(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	int ind = CComboBox(GetDlgItem(IDC_COMBO1)).GetCurSel();
	ind = ComboBoxIndex2AtlIndex(ind);
	if (ind != -1)
	{
		CColorDialog colorDlg(InstLay[ind].ColorAccent, CC_FULLOPEN);
		if(colorDlg.DoModal() == IDOK)
		{
			InstLay[ind].ColorAccent = colorDlg.GetColor();
			colbutCustomACCENT.SetBkColor(InstLay[ind].ColorAccent);
			colbutCustomACCENT.SetTextColor(ComputeTxtColor(InstLay[ind].ColorAccent));
			CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
			CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
		}
	}
}//OnBnClickedAccentBtnCustom

void CMainDlg::OnBnClickedUseDwmCustom(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	int ind = CComboBox(GetDlgItem(IDC_COMBO1)).GetCurSel();
	ind = ComboBoxIndex2AtlIndex(ind);
	if (ind != -1)
	{
		InstLay[ind].bUseDWM = IsDlgButtonChecked(IDC_USE_DWM_CUST) == BST_CHECKED;
		CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
		CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
	}
}//OnBnClickedUseDwmCustom

void CMainDlg::OnBnClickedUseAccentCustom(UINT uNotifyCode, int nID, CWindow wndCtl)
{
	int ind = CComboBox(GetDlgItem(IDC_COMBO1)).GetCurSel();
	ind = ComboBoxIndex2AtlIndex(ind);
	if (ind != -1)
	{
		InstLay[ind].bUseAccent = IsDlgButtonChecked(IDC_USE_ACCENT_CUST) == BST_CHECKED;
		CButton(GetDlgItem(IDOK)).EnableWindow(TRUE);
		CButton(GetDlgItem(ID_UNDO_BTN)).EnableWindow(TRUE);
	}
}//OnBnClickedUseAccentCustom


//CStringW teststr;
//teststr.Format(L"MSG=%X LOWORD(MSG)=%X [PRIMARY=%X] eq=%d", lang, currentLCID, nPrimaryLCID, eq);
//::MessageBoxW(NULL, teststr, L"=MSG=", MB_OK);
