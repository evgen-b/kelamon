#include <atlcoll.h>
#include <string>

//typedef struct
//{} MyLayout, *pMyLayout;


class CLayoutColor
{
public:
	wchar_t sName[LOCALE_NAME_MAX_LENGTH+1]; // �������� ��������� EN-US
	DWORD dwID;					// �� ������������� 0x409 0x419
	COLORREF ColorDWM;			// ��������� � ��� ���� DWM
	COLORREF ColorAccent;		// ��������� � ��� ���� Accent
	bool bUseDWM, bUseAccent;	// ����������� �� ��� ����� ��� ��������� ���������

	CLayoutColor(LPCWSTR Name, DWORD ID, COLORREF DWM, COLORREF Accent, bool bUseDWM, bool bUseAccent);
	CLayoutColor();
};

typedef CLayoutColor *PCLayoutColor;

void RegReadColors(LPCWSTR sRegPath, COLORREF &DWM, COLORREF &Accent, bool &bUseDWM, bool &bUseAccent);
void RegSaveColors(LPCWSTR sRegPath, COLORREF DWM, COLORREF Accent, bool bUseDWM, bool bUseAccent);
bool RegTrayHide(LPCWSTR sRegPath);


class CInstalledLayouts : public CSimpleArray<CLayoutColor>
{
public:
    void LoadLayouts (COLORREF DefaultPrimaryDWM, COLORREF DefaultPrimaryAccent, COLORREF DefaultOtherDWM, COLORREF DefaultOtherAccent, bool reset);
	void SaveLayouts(void);
};

DWORD GetKeybLay (DWORD winver, /*debug*/ HWND &hwnd, /*debug*/ DWORD &threadID);

