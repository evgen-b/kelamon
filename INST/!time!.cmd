cls
_ @echo off

set ttii="20.12.1987 0:0:3"
set "nircmd=%cd%\nircmdc.exe"
set setftm="%cd%\setfilefoldertime.cmd"

echo %nircmd%
echo %setftm%
echo %ttii%

"%cd%\setfilefoldertime.cmd" %1

pause
