#include <atlcoll.h>
#include <string>

//typedef struct
//{} MyLayout, *pMyLayout;


class CLayoutColor
{
public:
	wchar_t sName[LOCALE_NAME_MAX_LENGTH+1]; // название раскладки EN-US
	DWORD dwID;					// ее идентификатор 0x409 0x419
	COLORREF ColorDWM;			// св€занный с ней цвет DWM
	COLORREF ColorAccent;		// св€занный с ней цвет Accent
	bool bUseDWM, bUseAccent;	// примен€ютс€ ли эти цвета при активации раскладки

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

