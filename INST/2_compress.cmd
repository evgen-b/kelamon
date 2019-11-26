
IF NOT EXIST "C:\Program Files\7-Zip\7z.exe" GOTO :fail

"C:\Program Files\7-Zip\7z.exe" a  -t7z -ssw -slt -mx=9 -myx=9 -ms=256m "%1" -r ".\%1\*.*"

PAUSE
GOTO :EOF

:fail
ECHO.7-zip not found...
PAUSE
