
IF "%1*" == "*" GOTO :fail

DEL /f /q "%1\32\pf\KeyboardLayoutMonitor\x64\*.*"
DEL /f /q "%1\32\pf\KeyboardLayoutMonitor\x86\*.*"
DEL /f /q "%1\32\pf\KeyboardLayoutMonitor\*.exe"

MOVE /y "..\MAIN\x64\Release\Hooker.dll" "%1\32\pf\KeyboardLayoutMonitor\x64\"
MOVE /y "..\MAIN\x64\Release\HookerWatcher.exe" "%1\32\pf\KeyboardLayoutMonitor\x64\"

MOVE /y "..\MAIN\Release\Hooker.dll" "%1\32\pf\KeyboardLayoutMonitor\x86\"
MOVE /y "..\MAIN\Release\HookerWatcher.exe" "%1\32\pf\KeyboardLayoutMonitor\x86\"

MOVE /y "..\MAIN\Release\KeyboardLayoutMonitor.exe" "%1\32\pf\KeyboardLayoutMonitor\"
MOVE /y "..\MAIN\x64\Release\KeyboardLayoutMonitor.exe" "%1\32\pf\KeyboardLayoutMonitor\KeyboardLayoutMonitor64.exe"

PAUSE
GOTO :EOF

:fail
ECHO.movefiles.cmd "dst_dir"
PAUSE