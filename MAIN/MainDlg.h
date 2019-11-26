// MainDlg.h : interface of the CMainDlg class
//
/////////////////////////////////////////////////////////////////////////////

#pragma once

#define WM_LANGUAGE_CHANGED WM_USER+7
#define WM_NOTIFYICONMSG    WM_USER+6
#define WM_SHOWAPPWINDOW    WM_USER+5
#define WM_SETUPDWMCOLORS   WM_USER+4

#define TIMER1				1

// Hiding an MFC dialog box (at application start)
// https://stackoverflow.com/questions/8255106/hiding-an-mfc-dialog-box
// Эффективное использование WTL 2 Алексей Ширшов 03.04.2004
// https://rsdn.org/article/wtl/wtluse2.xml
//Как реализовать, чтобы по DoModal появлялся скрытый диалог?
//https://forum.sources.ru/index.php?showtopic=208142

// atlcrack.h
// void OnWindowPosChanging(LPWINDOWPOS lpWndPos)
#define MSG_WM_WINDOWPOSCHANGING(func) \
	if (uMsg == WM_WINDOWPOSCHANGING) \
	{ \
		this->SetMsgHandled(TRUE); \
		func((LPWINDOWPOS)lParam); \
		lResult = 0; \
		if(this->IsMsgHandled()) \
			return TRUE; \
	}

#include "ColoredControls\ColoredControls.h"
#include "klarr.h"

class CMainDlg : public CDialogImpl<CMainDlg>
{
public:
	enum { IDD = IDD_MAINDLG };

	BEGIN_MSG_MAP_EX(CMainDlg)
		MSG_WM_INITDIALOG(OnInitDialog)
		//MSG_WM_CTLCOLORSTATIC(OnCtlColorStatic)
		COMMAND_ID_HANDLER_EX(ID_APP_ABOUT, OnAppAbout)
		COMMAND_ID_HANDLER_EX(IDOK, OnOK)
		COMMAND_ID_HANDLER_EX(IDCANCEL, OnCancel)
		COMMAND_ID_HANDLER_EX(ID_UNDO_BTN, OnBnClickedUndoBtn)
		COMMAND_ID_HANDLER_EX(IDC_DWM_BTN, OnDwmBtnClick)
		COMMAND_ID_HANDLER_EX(IDC_ACCENT_BTN, OnAccentBtnClick)
		COMMAND_HANDLER_EX(IDC_ACCENT_NO_NEW_ALGO, BN_CLICKED, OnAccentNewAlgoClick)

		COMMAND_HANDLER_EX(IDC_USE_DWMCOLOR, BN_CLICKED, OnBnClickedUseDwmcolor)
		COMMAND_HANDLER_EX(IDC_USE_ACCENTCOLOR, BN_CLICKED, OnBnClickedUseAccentcolor)
		COMMAND_HANDLER_EX(IDC_AUTORUN, BN_CLICKED, OnBnClickedAutorun)

		COMMAND_HANDLER_EX(IDC_DWM_BTN_RUS, BN_CLICKED, OnBnClickedDwmBtnRus)
		COMMAND_HANDLER_EX(IDC_ACCENT_BTN_RUS, BN_CLICKED, OnBnClickedAccentBtnRus)

		COMMAND_HANDLER_EX(IDC_COMBO1, CBN_SELCHANGE, OnCbnSelchangeCombo1)
		COMMAND_HANDLER_EX(IDC_COMBO1, CBN_DROPDOWN, OnCbnDropDownCombo1)
		COMMAND_HANDLER_EX(IDC_COMBO1, CBN_SELENDCANCEL, OnCbnSelEndCancelCombo1)
		COMMAND_HANDLER_EX(IDC_USE_DWM_CUST, BN_CLICKED, OnBnClickedUseDwmCustom)
		COMMAND_HANDLER_EX(IDC_USE_ACCENT_CUST, BN_CLICKED, OnBnClickedUseAccentCustom)
		COMMAND_HANDLER_EX(IDC_DWM_CUST, BN_CLICKED, OnBnClickedDwmBtnCustom)
		COMMAND_HANDLER_EX(IDC_ACCENT_CUST, BN_CLICKED, OnBnClickedAccentBtnCustom)

		MESSAGE_HANDLER_EX(WM_LANGUAGE_CHANGED, OnLanguageChanged)
		MESSAGE_HANDLER_EX(WM_NOTIFYICONMSG, OnTrayIcon)
		MESSAGE_HANDLER_EX(WM_SHOWAPPWINDOW, OnShowCommand)
		MESSAGE_HANDLER_EX(WM_SETUPDWMCOLORS, OnSetupColorCommand)
		MESSAGE_HANDLER_EX(WM_SIZE, OnWMSize)

		MSG_WM_WINDOWPOSCHANGING(OnWindowPosChanging)
		MSG_WM_TIMER(OnTimer)
		REFLECT_NOTIFICATIONS() // Colored Control
	END_MSG_MAP()

	BOOL OnInitDialog(CWindow wndFocus, LPARAM lInitParam);
	//HBRUSH OnCtlColorStatic(CDCHandle dc, CStatic wndStatic);
	LRESULT OnDwmColorizationColorChanged(UINT uMsg, WPARAM wParam, LPARAM lParam);
	void OnAppAbout(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnOK(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnCancel(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnBnClickedUndoBtn(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnDwmBtnClick(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnAccentBtnClick(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnAccentNewAlgoClick(UINT uNotifyCode, int nID, CWindow wndCtl);

	void OnBnClickedUseDwmcolor(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnBnClickedUseAccentcolor(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnBnClickedAutorun(UINT uNotifyCode, int nID, CWindow wndCtl);

	void OnBnClickedDwmBtnRus(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnBnClickedAccentBtnRus(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnCbnSelchangeCombo1(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnCbnDropDownCombo1(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnCbnSelEndCancelCombo1(UINT uNotifyCode, int nID, CWindow wndCtl);

	LRESULT OnLanguageChanged(UINT uNotifyCode, WPARAM wParam, LPARAM lParam);
	LRESULT OnTrayIcon(UINT uNotifyCode, WPARAM wParam, LPARAM lParam);
	LRESULT OnShowCommand(UINT uNotifyCode, WPARAM wParam, LPARAM lParam); // API
	LRESULT OnSetupColorCommand(UINT uNotifyCode, WPARAM wParam, LPARAM lParam); // API
	LRESULT OnWMSize(UINT uNotifyCode, WPARAM wParam, LPARAM lParam);

	void InitWindowText(wchar_t* title);
	void CreateDialogVisible(BOOL bVisible=TRUE);
	CMainDlg();

private:

	CLayoutColor PrimaryScheme, OtherScheme;


	//COLORREF m_dwmColor, m_accentColor;
	//COLORREF m_dwmColor_rus, m_accentColor_rus;
	//bool m_useDWM;
	//bool m_useACCENT;

	wchar_t* szwWinTitle;
	wchar_t* szwRegAutorun;
	wchar_t* szwKeyAutorun;

	bool m_newAccentAlgo;
	bool m_Autorun;

	bool isLangENU;
	DWORD h_CurrLang;

	void GetDefaultColors();
	void RefreshControls();
	void SetColors();

	void RegLoadSettings();
	void RegSaveSettings();
	bool IsAutorun(HKEY hkey);
	void RegSetAutorun();

	virtual void OnFinalMessage(_In_ HWND /*hWnd*/);

	NOTIFYICONDATA TrayIcon;
	void SetStatusIcon(HICON hStatusIcon);

	BOOL m_visible; // force DoModal creates a hide window
	void OnWindowPosChanging(WINDOWPOS FAR* lpwndpos);

	void InitIcons();

	CColoredButtonCtrl colorbuttonDWM;
	CColoredButtonCtrl colorbuttonDWM_RUS;
	CColoredButtonCtrl colorbuttonACCENT;
	CColoredButtonCtrl colorbuttonACCENT_RUS;

	void OnTimer(UINT_PTR nIDEvent);
	bool isDebugInfoVisible;

	CColoredButtonCtrl colbutCustomDWM;
	CColoredButtonCtrl colbutCustomACCENT;

	CInstalledLayouts InstLay;
	int AtlIndex2ComboBoxIndex(int ind);
	int ComboBoxIndex2AtlIndex(int ind);
	int LCID2AtlIndex(int ind);
	void LayComboBoxFill(bool Reset);
	int LayComboBoxSelAuto();
	void LayCustomFill(int nID);

	void OnBnClickedDwmBtnCustom(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnBnClickedAccentBtnCustom(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnBnClickedUseDwmCustom(UINT uNotifyCode, int nID, CWindow wndCtl);
	void OnBnClickedUseAccentCustom(UINT uNotifyCode, int nID, CWindow wndCtl);

};
