@ECHO OFF

FOR /f "skip=1 tokens=1-6" %%a IN ('WMIC.exe Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
SET "_day=00%%a" & SET "_hour=%%b" & SET "_minute=00%%c" & SET "_month=00%%d" & SET "_second=00%%e" & SET "_year=%%f" & GOTO m11_skip1)
:m11_skip1

IF "*%_day%"=="*" (
    SET "_year=%date:~6,4%"
    SET "_month=%date:~3,2%"
    SET "_day=%date:~0,2%"

    SET "_hour=%time:~0,2%"
    SET "_minute=%time:~3,2%"
    SET "_second=%time:~6,2%"
    )
    REM избавляемся от пробела перед часами, если использовали time
    SET /A _hour=%_hour% + 0
    SET "_hour=00%_hour%"

SET "_month=%_month:~-2%"
SET "_day=%_day:~-2%"
SET "_hour=%_hour:~-2%"
SET "_minute=%_minute:~-2%"
SET "_second=%_second:~-2%"

reg.exe export HKCU\SOFTWARE\KeyboardLayoutMonitor "usersettings %_year%.%_month%.%_day% %_hour%-%_minute%-%_second%.reg" /y
