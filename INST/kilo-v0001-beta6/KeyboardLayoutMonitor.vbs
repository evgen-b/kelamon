
Option Explicit

Const ApplicationVersion="0.0.0.0"
Const BuildVersion="0.0.0.1-beta6"
' INSTALL SCRIPT FRAMEWORK VER: 0.0.0.3J


' ===============================================================================================================



' Class clsAllArgumentsHTA
' абстракция аргументов в командной строке,
' класс работает в среде HTA и WSH
' ver. 0.0.0.2
' (copyleft) evgen_b
Class clsAllArgumentsHTA
    Public Arguments, Count
    Public bWscriptShell
    Public ScriptFullName, ScriptName, ScriptPath, ScriptBaseName
    Public StrCommandLine, StrRawArgsOnly, CurrentDirectory
    Public iArgsInVBS, iArgsInSFX
    Public inst_sfx_name, inst_sfx_path



'*******************
    Function SplitArg (ByVal split_char, ByVal itm, ByRef arg, ByRef val)
        Dim j
        arg=itm
        val=""
        j=Instr(itm, split_char)
        If CBool(j) Then
            arg=mid(itm, 1, j-1)
            val=mid(itm,    j+1)
            'MsgBox itm & vbCrLf & "<" & arg & "> " & split_char & " <" & val & ">"
            End If
    End Function 'SplitArg



'*******************
    Function Trm (ByRef arg)
        Dim i
        'clear leading and trailing spaces
        For i=1 To Len (arg)
            If (Mid(arg, i, 1) <> chr(32)) And (Mid(arg, i, 1) <> chr(9)) Then Exit For
        Next 'i
        arg=Mid (arg, i, Len(arg) )
        For i=Len(arg) To 1 Step -1
            If (Mid(arg, i, 1) <> chr(32)) And (Mid(arg, i, 1) <> chr(9)) Then Exit For
        Next 'i
        arg=Mid (arg, 1, i)
        'MsgBox TRIM: >" & arg & "<"
    End Function 'Trm



'*******************
    Public Function Init (cnst_inst_sfx_name, cnst_inst_sfx_path, strHTA_APPLICATION_id)
'предварительный разбор параметров CLI, в том числе и записанных в имени sfx-файла
'подготовка параметров для вызова ParseArgs

' здесь такая идея, что можно указать параметры запуска непосредственно в имени файла, например так:
' "c:\Distrib\programma +key1=value1 +key2=value2.exe"

' в самом общем виде запуск может осуществляться так:
' запускается 7zip-sfx-архив, возможно, с какими-то параметрами, напрмер /param1 /param2.
' при этом он сконфигурирован так, что устанавливает DOS-переменные inst_sfx_name и inst_sfx_path
' следующим образом:
' inst_sfx_name="programma +key1=value1 +key2=value2.exe" - имя sfx-файла
' inst_sfx_path="c:\Distrib" - папка, содержащая данный файл
' необходимо знать inst_sfx_path потому, что в нее можно положить какие-нибудь дополнительные файлы,
' например, регистрационный ключ приложения или файл "RunAfterSetup.cmd"

' после распаковки sfx-модуль согласно своей конфигурации передает управление HTA- или VBS-приложению,
' передавая также и свои параметры командной строки:
' mshta.exe "c:\temp\sfx012340\inst +key0=value0.hta" /param1 /param2

' в имени скрипта также можно указать какие-нибудь параметры, в данном случае это "+key0=value0"

' в общем случае, если имя файла скрипта и sfx-архива содержит пробелы, то
' программа должна попробовать поискать в этих именах какие-нибудь дополнительные
' параметры запуска специально установленного формата.

' поскольку параметры запуска могут перекрывать действия друг друга, то установим следующий порядок
' следования всех возможных ключей запуска:

' сначала идут ключи запуска из имени HTA/VBS-файла, т.е. они имеют самый низкий приоритет:
' +key0=value0
' потом следуют ключи запуска из имени 7zip-SFX-файла:
' +key1=value1 +key2=value2
' самыми последними должны обрабатываться обычные ключи, указанные в командной строке,
' они будут иметь самый высокий приоритет:
' /param1 /param2

' задача - собрать все возможные потенциальные ключи по порядку в один массив,
' чтобы вдальнейшем их последовательно обработать.

' т.к. в HTA нужно интерпретировать строку самим, то сделаем доступной передачу
' параметров с пробелами с помощью двойных кавычек, а также
' передачу двойных кавычек, указывая перед ними обратный слэш - (\")

    Set Arguments = CreateObject ("Scripting.Dictionary")

    Dim i,c,k,argi,openquote,backslash
    On Error Resume Next
    Err=0 : i="" : i=WScript.Version
    Err=0 : bWscriptShell = Not (i = "") 'в HTA нет Wscript, определили среду запуска

    If Not bWscriptShell Then
        StrCommandLine="" & eval (strHTA_APPLICATION_id & ".commandLine") ' HTA:APPLICATION id="objMyApp"
        StrRawArgsOnly=""
        If Mid(StrCommandLine,1,1) = chr(34) Then
            ScriptFullName=Right(StrCommandLine, Len(StrCommandLine)-1)
            ScriptFullName=Left (ScriptFullName, InStr(ScriptFullName, chr(34))-1)
            i=Len(StrCommandLine) - Len(ScriptFullName) - 3
        Else
            For i=1 To Len(StrCommandLine)
            If (Mid(StrCommandLine, i, 1) = chr(32)) Or (Mid(StrCommandLine, i, 1) = chr(9)) Then Exit For
            Next 'i
            ScriptFullName=Mid(StrCommandLine, 1, i-1)
            i=Len(StrCommandLine) - Len(ScriptFullName) - 1
        End If
        If i>0 Then StrRawArgsOnly=Right(StrCommandLine, i)
    Else
    StrCommandLine=""
    StrRawArgsOnly=""
    ScriptFullName=WScript.ScriptFullName
    End If 'bWscriptShell
    
    With CreateObject("Scripting.FileSystemObject")
        ScriptName=.GetFileName(ScriptFullName)
        ScriptPath=.GetParentFolderName(ScriptFullName)
        ScriptBaseName=.GetBaseName(ScriptFullName)
    End With 'Scripting.FileSystemObject
    
    With CreateObject("WScript.Shell")
        CurrentDirectory=.CurrentDirectory
        inst_sfx_name=.Environment("PROCESS")(cnst_inst_sfx_name)
        inst_sfx_path=.Environment("PROCESS")(cnst_inst_sfx_path)
    End With 'WScript.Shell
    
    '--- vbs ---
    argi=split(ScriptBaseName)
    iArgsInVBS=UBound(argi)+1
    For i=0 To iArgsInVBS-1
        Arguments(i)=argi(i)
    Next 'i

    '--- sfx ---
    c=""
    c=Left(inst_sfx_name, Len(inst_sfx_name)-4)
    argi=split(c)
    iArgsInSFX=UBound(argi)+1
    For i=0 To iArgsInSFX
        Arguments(iArgsInVBS+i)=argi(i)
    Next 'i
    
    '--- cli ---
    If bWscriptShell Then
        'разбор CLI из WSH
        For i=0 To WScript.Arguments.Count
            Arguments(iArgsInVBS+iArgsInSFX+i)=WScript.Arguments(i)
            
            k=WScript.Arguments(i)
            If CBool (   InStr(k, chr(32)) + Instr(k, chr(9))   ) Then k=Chr(34) & k & Chr(34)
            StrRawArgsOnly = StrRawArgsOnly & " " & k
        Next 'i
        Count=iArgsInVBS+iArgsInSFX+WScript.Arguments.Count
        
        k=ScriptFullName
        If CBool (   InStr(k, chr(32)) + Instr(k, chr(9))   ) Then k=Chr(34) & k & Chr(34)
        StrCommandLine = k & StrRawArgsOnly
    Else
        'разбор CLI из HTA
        argi="" : openquote=False : backslash=False : k=0
        For i=1 To Len(StrRawArgsOnly)+1
            c=Mid(StrRawArgsOnly & " ", i, 1)
            Select Case c
                Case "\"
                    backslash=True
                Case chr(34)
                    If backslash Then argi=argi & c Else openquote=Not(openquote)
                    backslash=False
                Case chr(32), chr(9)
                    backslash=False
                    If openquote Then
                    argi=argi & c
                    Else
                        If argi<>"" Then Arguments(iArgsInVBS+iArgsInSFX+k)=argi : k=k+1 : argi=""
                    End If
                Case Else
                    If backslash Then argi=argi & "\"
                    backslash=False
                    argi=argi & c
            End Select
        Next 'i
        Count=iArgsInVBS+iArgsInSFX+k-1
    End If 'bWscriptShell
    
    End Function 'Init



'*******************
    Public Function Done
        Set Arguments=Nothing
    End Function 'Done
    
End Class 'clsAllArgumentsHTA



' ===============================================================================================================



' clsSudo64 class
' класс предназначен, чтобы перезапустить скрипт с повышенными привилегиями администратора,
' а также изменить среду выполнения с 32-разрядной в 64-разрядную, или наоборот.
' класс работает в среде WSH (и кое-как в HTA)
' Version 0.0.0.16
' (copyleft) evgen_b

Class clsSudo64
     Public cnst_str_nouac, cnst_str_no864, cnst_ArgSpl
     Public uac_os, x64_os, x64_proc, w2k_os, os_ver
     Public sys32_path, sys64_path, ScriptFullName, bWscriptShell, strHTA_APPLICATION_id
     Public StartVisible, wsh_exe, Arguments, Count
     Public CD, str_CLI_args, n_arg_864, n_arg_uac
     Public is_odmin_proc, is_odmin_group, str_user



'*******************
     Public Function Init (strApp)
        Init=-1
        strHTA_APPLICATION_id=strApp
        cnst_str_nouac="/NOUAC"
        cnst_str_no864="/NO864"
        cnst_ArgSpl="="
        StartVisible=1
        Dim Shell, WshEnv, WshNet

        On Error Resume Next
        Err=0 : str_user="" : str_user=WScript.Version
        Err=0 : bWscriptShell = Not (str_user = "") 'в HTA нет Wscript, определили среду запуска
        On Error Goto 0

        Set WshNet=CreateObject("WScript.Network")
        str_user=WshNet.UserName
        is_odmin_group=amel27_IsAdminGroup(str_user)
        is_odmin_proc=CSI_IsAdmin()
        
        Set Arguments = CreateObject ("Scripting.Dictionary")
        ScanArg
        If bWscriptShell Then
            wsh_exe=WScript.FullName
            wsh_exe=CreateObject("Scripting.FileSystemObject").GetFileName(wsh_exe)
        Else
            wsh_exe="mshta.exe"
        End If 'bWscriptShell
          
        Set Shell = CreateObject("WScript.Shell")

        On Error Resume Next
        Err=0
        os_ver=Shell.RegRead ("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentVersion")
        If CBool(Err) Then Set Shell=Nothing : Exit Function
        On Error Goto 0
        If (Eval(os_ver)  = 5) Then w2k_os=True Else w2k_os=False
        If (Eval(os_ver) >= 6) Then uac_os=True Else uac_os=False

        Set WshEnv = Shell.Environment("PROCESS")
        sys64_path = WshEnv("windir")
        sys32_path = sys64_path
        'Msgbox sys32_path 
        If (WshEnv("PROCESSOR_ARCHITEW6432") <> "") Then
            x64_os=True 'wow64
            x64_proc=False
            sys64_path = sys64_path & "\sysNative"
            sys32_path = sys32_path & "\sysWOW64"
        Else
            If CBool (InStr  (WshEnv("PROCESSOR_ARCHITECTURE"), "64")  ) Then
                x64_os=True 'legacy x64
                x64_proc=True
                sys64_path = sys64_path & "\system32"
                sys32_path = sys32_path & "\sysWOW64"
            Else
                x64_os=False 'legacy 32bit
                x64_proc=False
                sys64_path = ""
                sys32_path = sys32_path & "\system32"
            End If 'PROCESSOR_ARCHITECTURE
        End If 'PROCESSOR_ARCHITEW6432
          
'Msgbox "AMD64 OS:" & chr(9) & x64_os & vbCrLf & "x64 Process:" & chr(9) & x64_proc & vbCrLf & _
'"Admin Group:" & chr(9) & is_odmin_group & vbCrLf & "Admin Proc:" & chr(9) & is_odmin_proc & vbCrLf & _
'"UAC-based OS:" & chr(9) & uac_os & vbCrLf & vbCrLf & _
'"sys32:" & chr(9) & "[" & sys32_path & "]" & vbCrLf & "sys64:" & chr(9) & "[" & sys64_path & "]" & vbCrLf & _
'"Script:" & chr(9) & "[" & wsh_exe & "]" & vbCrLf & "User:" & chr(9) & "[" & str_user & "] " & vbCrLf & _
'"CLI:" & chr(9) & "[" & str_CLI_args & "]" & vbCrLf

        Set WshEnv=Nothing
        Set Shell=Nothing
        Set WshNet=Nothing
     
        Init=0
    End Function 'Init



'*******************
    Public Function SplitArg (itm, ByRef arg, ByRef val)
        Dim j
        arg=itm
        val=""
        j=Instr(itm, cnst_ArgSpl)
        If CBool(j) Then
            arg=mid(itm, 1, j-1)
            val=mid(itm,    j+1)
            'Msgbox itm & vbCrLf & "<" & arg & "> " & cnst.ArgSpl & " <" & val & ">"
            End If
    End Function 'SplitArg



'*******************
    Public Function Done
        Set Arguments=Nothing
    End Function 'Done



'*******************
    Public Function ScanArg()
    Dim StrCommandLine, StrRawArgsOnly
    Dim i,argi,openquote,backslash
    'в отличие от WScript.Arguments, записи в sudo64.Arguments начинаются с индекса 1!

    If bWscriptShell Then
        'для среды WSH
        ScriptFullName=WScript.ScriptFullName
        For i=0 To WScript.Arguments.Count-1
            Arguments(i+1)=WScript.Arguments(i)
        Next 'i
        Count=WScript.Arguments.Count
    Else
        'для среды HTA
        StrCommandLine="" & eval (strHTA_APPLICATION_id & ".commandLine") ' HTA:APPLICATION id="objMyApp"
        StrRawArgsOnly=""
        If Mid(StrCommandLine,1,1) = chr(34) Then
            ScriptFullName=Right(StrCommandLine, Len(StrCommandLine)-1)
            ScriptFullName=Left (ScriptFullName, InStr(ScriptFullName, chr(34))-1)
            i=Len(StrCommandLine) - Len(ScriptFullName) - 3
        Else
            For i=1 To Len(StrCommandLine)
            If (Mid(StrCommandLine, i, 1) = chr(32)) Or (Mid(StrCommandLine, i, 1) = chr(9)) Then Exit For
            Next 'i
            ScriptFullName=Mid(StrCommandLine, 1, i-1)
            i=Len(StrCommandLine) - Len(ScriptFullName) - 1
        End If
        If i>0 Then StrRawArgsOnly=Right(StrCommandLine, i)
        
        argi="" : openquote=False : backslash=False : Count=0
        For i=1 To Len(StrRawArgsOnly)+1
            c=Mid(StrRawArgsOnly & " ", i, 1)
            Select Case c
                Case "\"
                    backslash=True
                Case chr(34)
                    If backslash Then argi=argi & c Else openquote=Not(openquote)
                    backslash=False
                Case chr(32), chr(9)
                    backslash=False
                    If openquote Then
                    argi=argi & c
                    Else
                        If argi<>"" Then Count=Count+1 : Arguments(Count)=argi : argi=""
                    End If
                Case Else
                    If backslash Then argi=argi & "\"
                    backslash=False
                    argi=argi & c
            End Select
        Next 'i
    End If 'bWscriptShell

    'при поднятии прав текущая папка может глюком некоторых систем заменяется на system32. восстанавливаем её.
    'CD - значение в /NO864/NOUAC (передается текущая папка запустившего процесса), если есть
    'str_CLI_args - "чистая" строчка параметров CLI с вырезанным служебными /NO864/NOUAC
    Dim sa, sv
    CD="" : str_CLI_args=CD
    n_arg_864=False
    n_arg_uac=False
    For i=1 To Count
        SplitArg Arguments(i), sa, sv
        Select Case UCase(sa)
        Case cnst_str_nouac
                      If (sv<>"") Then CD=sv
                      n_arg_uac=True
       Case cnst_str_no864
                      If (sv<>"") Then CD=sv
                      n_arg_864=True
       Case Else
                    backslash=""
                    'ставим перед двойными кавычками обратный слэш
                    For argi=1 To Len(Arguments(i))
                        openquote=Mid(Arguments(i),argi,1)
                        If openquote=chr(34) Then backslash=backslash & "\"
                        backslash=backslash & openquote
                    Next 'argi
                    'закавычиваем аргумент CLI, если в нем пробелы или табуляции
                    If CBool (   InStr(backslash, chr(32))   ) Or CBool (   InStr(backslash, chr(9))   ) Then
                        str_CLI_args=str_CLI_args & " " & """" & backslash & """"
                    Else
                        str_CLI_args = str_CLI_args & " " & backslash
                    End If 'Arguments
       End Select 'UCase(sa)
    Next 'i
    End Function 'ScanArg



'*******************
    Function CSI_IsAdmin() ' True, если процесс с полными правами админа в UAC.
    'пытаемся прочитать из реестра что-нибудь, для чего обязательно необходимы права одмина. если успех - они присутствуют.
    'Version 1.32 - "TEMP" no need in some optimised systems like x-wind (evgen_b)
    'Version 1.33 - сервер 2003 - чтение пустых значений также вызывает ошибку - надо читать что-то конкретное
    ' HKEY_USERS\S-1-5-19\Control Panel\International\Locale -  в некоторых переоптимизированных XP удалено :(
    'в общем, из-за того, что чего там только в говносборках XP не удаляли...
    'Version 1.34 - вместо чтения чего-то конкретного просто попробуем перечислить ключи
    '1.35 - неа, у какого-то чувака S-1-5-19 не перечисляется, пробуем конкретнее - S-1-5-19\Software
    '1.38 - попробуем еще fsutil и sfc вызывать - https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights
    'http://csi-windows.com/toolkit/csi-isadmin
    CSI_IsAdmin=False
    On Error Resume Next
    Dim strComputer, objRegistry, arrSubKeys, strSubkey
    strComputer = "."
    Set objRegistry = GetObject("winmgmts:\\" & strComputer & "\root\default:StdRegProv")

    objRegistry.EnumKey &H80000003, "S-1-5-19\Software", arrSubKeys
    'If IsArray(arrSubKeys) Then
    '   MsgBox UBound(arrSubKeys)
    '    For Each strSubkey In arrSubKeys
    '        'MsgBox strSubkey
    '    Next
    'End If
    Set objRegistry = Nothing
    strComputer=IsArray(arrSubKeys)
    If strComputer Then CSI_IsAdmin=True : Exit Function

    'костыли:
    'Windows XP and later
    Dim Shell, retcode
    Set Shell = CreateObject("WScript.Shell")
    retcode=Shell.Run ("CMD.EXE /Cfsutil.exe dirty query %systemdrive%", 0, True)
    If retcode=0 Then CSI_IsAdmin=True : Set Shell = Nothing : Exit Function

    'Windows 2000 and PE
    retcode=Shell.Run ("CMD.EXE /Csfc.exe 2>&1 | find.exe /i ""/SCANNOW"" ", 0, True)
    If retcode=0 Then CSI_IsAdmin=True
    Set Shell = Nothing

    On Error Goto 0
    End Function 'CSI_IsAdmin



'*******************
    Function amel27_IsAdminGroup(username)
    'входит ли пользователь процесса в группу одминов?
    'http://forum.oszone.net/post-1265427.html
        On Error Resume Next
        Dim objWMI, objNet, objREx, objGroup, objItem
        amel27_IsAdminGroup=False
        Set objWMI=GetObject("winmgmts:\\.\root\cimv2")
        Set objNet=CreateObject("WScript.Network")
        Set objREx=CreateObject("VBScript.RegExp")
        objREx.Pattern="^.*\.Domain=""([^""]+)"",Name=""([^""]+)"".*$"
        objREx.IgnoreCase=True
        'проблема - получить строковое имя группы администраторов, т.к. в зависимости от национального
        'языка системы оно меняется, например "Администраторы" и "Administrators"
        'поэтому преобразуем SID-группу в строку имени группы objGroup.Name
        For Each objGroup In objWMI.ExecQuery _
        ("SELECT * FROM Win32_Group WHERE LocalAccount=TRUE And SID='S-1-5-32-544'")
            'Msgbox objNet.ComputerName & " @ " & objGroup.Name
            For Each objItem In objWMI.ExecQuery _
            ("SELECT * FROM Win32_GroupUser WHERE GroupComponent=""Win32_Group.Domain='"& objNet.ComputerName &"',Name='"& objGroup.Name &"'""")
                'Msgbox objREx.Replace(objItem.PartComponent,"$1\$2")
                If username=objREx.Replace(objItem.PartComponent,"$2") Then amel27_IsAdminGroup=True
            Next 'Win32_GroupUser
        Next 'Win32_Group
        Set objWMI=Nothing
        Set objNet=Nothing
        Set objREx=Nothing
        Set objGroup=Nothing
        Set objItem=Nothing
        On Error Goto 0
    End Function 'amel27_IsAdminGroup



'*******************
    Public Function WscriptSleep (intSeconds)
    With CreateObject("Wscript.Shell")
        If uac_os Then
        .Run "%COMSPEC% /c choice /d y /c yn /t " & intSeconds, 0, True
        Else
        .Run "%COMSPEC% /c ping -n " & 1 + intSeconds & " 127.0.0.1", 0, True
        End If
    End With 'Wscript.Shell
    End Function 'WscriptSleep



'*******************
    Public Function x32x64 (f64, uac)
'для 64-битных ОС перезапуск:
' f64= 0   - жестко вызвать перезапуск в среду 32-бита (можно гарантированно поменять wscript<->cscript)
' f64= 1   - жестко вызвать перезапуск в среду 64-бита (если доступно x64, то x32x64=2, иначе x32x64=-2) (можно гарантированно поменять wscript<->cscript)
' f64=-1   - жестко вызвать перезапуск, но оставить среду без изменения (только чтобы поменять wscript<->cscript)
' f64= 2   - перезапукать в 32 только из 64-битной среды, если уже 32 бита, ничего не делать и x32x64=0
' f64= 3   - перезапукать в 64 только из 32-битной среды, если уже 64 бита или не доступно, ничего не делать и x32x64=0
' f64=-2   - совсем пропустить изменение среды x86<->x64
' после Init можно явно переопределить wsh_exe: CScript.exe или WScript.exe
' 0 - просто продолжаем выполнение программы (перезапуски либо были в прошлой жизни, либо не нужны)
' 2 - был вызван перезапуск, нужно выйти
'-2 - был вызван перезапуск, нужно выйти (в 32-битной ОС пытались задать 64-битную среду)
' uac= 1   - даже в XP/2k/2k3 повысить права (вывести диалог - запуск от имени)
' uac=-1   - в UAC повысить права, в XP/2k/2k3 только асинхронно перезапуститься
' uac=-2   - совсем пропустить повышение прав
' уже выполненные шаги при перезапусках передаются в командной строке ключами /NOUAC и /NO864
    Dim App, Shell : Set Shell=CreateObject("WScript.Shell")
    Dim cmd_str, cmd_par, cmd_verb, skip_f64
    skip_f64=False
    On Error Resume Next
    x32x64=-1
    If (CD<>"") And Not w2k_os Then Shell.CurrentDirectory=CD 'в win2k это не работает, но там и перезапусков не нужно
    Select Case f64
        Case 0         
                    x32x64=2
                    cmd_str = """" & sys32_path & "\" & wsh_exe & """"
        Case 1
                    If Not x64_os Then
                        cmd_str = """" & sys32_path & "\" & wsh_exe & """"
                        x32x64=-2
                    Else
                        cmd_str = """" & sys64_path & "\" & wsh_exe & """"
                        x32x64=2
                    End If
        Case 2
                    If x64_proc Then
                        x32x64=2
                        cmd_str = """" & sys32_path & "\" & wsh_exe & """"
                    Else
                        x32x64=0
                        skip_f64=True
                    End If
        Case 3
                    If x64_proc or Not x64_os Then
                        x32x64=0
                        skip_f64=True
                    Else
                        x32x64=2
                        cmd_str = """" & sys64_path & "\" & wsh_exe & """"
                    End If
        Case -1
                    x32x64=2
                    If x64_proc Then
                        'sysNative or system32
                        cmd_str = """" & sys64_path & "\" & wsh_exe & """"
                    Else
                        'wow64 or system32
                        cmd_str = """" & sys32_path & "\" & wsh_exe & """"
                    End If
        Case -2
                    skip_f64=True
        Case Else    : Set Shell = Nothing : Exit Function
    End Select

    If Not skip_f64 And Not CBool(n_arg_864) Then
        cmd_par = """" & ScriptFullName & """" & str_CLI_args & " " & _
                """" & cnst_str_no864 & cnst_ArgSpl & Shell.CurrentDirectory & """"
        If CBool(n_arg_uac) Then cmd_par=cmd_par & " " & cnst_str_nouac
        
        Err=0
        
        If bWscriptShell Then Shell.Run cmd_str & " " & cmd_par, StartVisible, True _
        Else Shell.Run cmd_str & " " & cmd_par, StartVisible, False '!!!!!!!!!!!!!!!!! поменял для HTA!!!!!!!!!

        If CBool(Err) Then x32x64=-1
        Set Shell = Nothing
        Exit Function
    End If 'n_arg_864
       
    If (uac<>-2) And Not CBool(n_arg_uac) Then
        Select Case uac
        Case 1
                        cmd_verb="runas"
        Case -1
                        If Not uac_os Then cmd_verb="open" Else cmd_verb="runas"
        Case Else        : Set Shell = Nothing : Exit Function
        End Select

        If bWscriptShell Then cmd_str = """" & WScript.FullName & """" _
        Else cmd_str = wsh_exe '!!!!! для HTA известно только mshta.exe

        cmd_par = """" & ScriptFullName & """" & str_CLI_args & " " & _
            """" & cnst_str_nouac & cnst_ArgSpl & Shell.CurrentDirectory & """"
        If CBool(n_arg_864) Then cmd_par=cmd_par & " " & cnst_str_no864
        Shell.CurrentDirectory=sys32_path 'убегаем для remove, но совсем не обязательно...
        
        x32x64=2
        Err=0
        Set App=CreateObject("Shell.Application")
        'Msgbox "<" & cmd_str & ">" & vbCrLf & "<" & cmd_par & ">"
        App.ShellExecute cmd_str, cmd_par, Shell.CurrentDirectory, cmd_verb, 1
        'на медленном компе перед удалением App нужно подождать, пока отработается асинхронный запуск, иначе может криво выполниться!
        '(Андросову СМ на заметку)
        If bWscriptShell Then WScript.Sleep(3000) Else WScriptSleep(1)
        'в HTA эмулируем вызов WScript.Sleep, 1 секунды достаточно.

        Set App=Nothing

        If CBool(Err) Then x32x64=-1
        Set Shell = Nothing
        Exit Function
    End If 'n_arg_uac
    On Error Goto 0
    x32x64=0
    Set Shell = Nothing
    End Function 'x32x64

End Class 'clsSudo64



' ===============================================================================================================



' ver. 0.0.0.2
' (copyleft) evgen_b
Class clsZIPHeil

    Public sZipFullName, oZipFile



'*******************
    Public Function Init (zipath)
    Init=-1
    With CreateObject ("Scripting.FileSystemObject")
        sZipFullName=zipath
        'full path for NameSpace of Shell.Application
        sZipFullName=.GetAbsolutePathName(sZipFullName)
        If .GetExtensionName (sZipFullName) = "" Then sZipFullName=sZipFullName & ".zip"
        
        'Create the basis of a zip file.
        If Not .FileExists(sZipFullName) Then
            On Error Resume Next
            Set oZipFile=.CreateTextFile(sZipFullName, True)
            oZipFile.Write "PK" & Chr(5) & Chr(6) & String(18, vbNullChar)
            oZipFile.Close
            Set oZipFile=Nothing
            If CBool (Err) Then Set oZipFile=Nothing : Exit Function
            On Error Goto 0
        End If
    'get ready to add files to zip
    Set oZipFile=CreateObject("Shell.Application").NameSpace(sZipFullName)
    Init=0
    End With 'FileSystemObject
    End Function 'Init



'*******************
    Public Function Done
    On Error Resume Next
        Set oZipFile=Nothing 
    On Error Goto 0
    End Function 'Done



'*******************
    Public Function ToArchiveAsync (pathname)
        'simple zip add implementation on WinXP+/2k3+
        'evgen_b
        'http://forums.techarena.in/windows-server-help/997520.htm
        'если архив создаётся заново, желательно начать с маленького файла
        '(если при добавлении в пустой архив самого первого файла нажать "Отмена", то скрипт повиснет)
        'если файл/папка уже существуют в архиве, то замены не будет и пока работает процесс скрипта, видны кривые предупреждения.

        Const FOF_CREATEPROGRESSDLG = 1044 ':( it's always ignored for zip
        '4        = Do not display a progress dialog box.
        '16        = Respond with "Yes to All" for any dialog box that is displayed.
        '1024    = Do not display a user interface if an error occurs

        'add file
        ToArchiveAsync=-1
        With CreateObject ("Scripting.FileSystemObject")
        pathname=.GetAbsolutePathName(pathname)
        If .FileExists(pathname) Or .FolderExists(pathname) Then
            oZipFile.CopyHere pathname, FOF_CREATEPROGRESSDLG
        Else
            Exit Function
        End If
        End With 'FileSystemObject
        ToArchiveAsync=0
    End Function 'ToArchiveAsync


    
'*******************
    Public Function ToArchiveWait (intTimeOut)
        'для поддержки очень больших файлов нужно добавить немного кода (что не будет эффективно для мелких файлов).
        'ver2 - введен параметр intTimeOut
        'в некоторых кривых говносборках, оказывается, сломан встроенный в Windows ZIP-архиватор,
        'поэтому чтобы не зацикливался процесс, вводим ограничение на время ожидания окончания архивирования (в 1/10 секунды).
        'intTimeOut=0 - бесконечно ожидать, иначе только intTimeOut/10 секунд.
        'ver2 - возвращает значение:
        'True - так и не дождались завершения (вероятно ZIP-архивирование в говносборке сломано)
        'False - за отведенный таймаут архивирование завершилось успешно.
        'evgen_b
        'wait asynchronous
        Dim i
        ToArchiveWait=True
        i=intTimeOut
        Do
            If CBool (oZipFile.Items.Count) Then ToArchiveWait=False : Exit Function
            Wscript.Sleep(100) 'wait for done "ADD" command
            If i>0 Then i=i-1
        Loop Until (intTimeOut>0 And i=0)
    End Function 'ToArchiveWait



'*******************
    Public Function ExtractArchSync (sExtractTo)
        ExtractArchSync=-1
        'simple zip extract implementation on WinXP+/2k3+
        'evgen_b
        'http://maksim.sorokin.dk/it/2010/05/24/extracting-zip-files-with-vbscript/

        Const FOF_CREATEPROGRESSDLG = 1044 ':( it's always ignored for zip

        With CreateObject ("Scripting.FileSystemObject")
            If sExtractTo="" Then sExtractTo=.GetBaseName(sZipFullName)
            'full path for NameSpace of Shell.Application
            sExtractTo=.GetAbsolutePathName(sExtractTo)
            'get ready to extract to
            On Error Resume Next
                If Not .FolderExists(sExtractTo) Then .CreateFolder(sExtractTo)
                If CBool (Err) Then Exit Function
            On Error Goto 0
        End With 'FileSystemObject

        'extract synchronous
        With CreateObject("Shell.Application")
            .NameSpace(sExtractTo).CopyHere(oZipFile.items)
        End With 'Shell.Application
        ExtractArchSync=0
    End Function 'ExtractArchSync



End Class 'clsZIPHeil



' ===============================================================================================================



Class clsEmptyCallBack 'как шаблон отрисовки действий установщика в окне.
    Public Function Draw (N_ActionOf, N_SubOf, B_RetStat)
        'установка разбита на несколько крупных действий - N_ActionOf
        'каждое действие может разбиваться на несколько подзадач N_SubOf
        'при этом каждая подзадача передает статус завершения B_RetStat, 1 - ошибка, 0 - норма, -1 - пропуск
        'при инициализации класса указываем сколько будет "больших" действий и
        'сколько будет подзадач для каждого большого действия
        'также при инициализации указываем названия этих действий.
        'тогда при каждом вызове внутри Draw можно вычислить общий процент завершения установки и
        'процент завершения текущей подзадачи, а также их названия.
        'если количество действий заранее неизвестно, то значения N_ActionOf и N_SubOf меньшие 1.0 (с минусом -1...0) интерпретируются как проценты.
        '===
        'Draw - можно возвращать какие-нибудь значения, например, нажал ли пользователь Cancel во время установки
    End Function
    Function Done
        'do nothing
    End Function 'Done
End Class 'clsEmptyCallBack



' Class clsMrRegister
' более гибкие процедуры для работы с реестром
' пока только удаление понадобилось
' ver. 0.0.0.0
' (copyleft) evgen_b
Class clsMrRegister



    Private strComputer, objRegistry

    Private Sub Class_Initialize
        On Error Resume Next
        strComputer = "."
        Set objRegistry = GetObject("winmgmts:\\" & strComputer & "\root\default:StdRegProv")
        On Error Goto 0
    End Sub 'Class_Initialize



    Private Sub Class_Terminate
        On Error Resume Next
        Set objRegistry = Nothing
        On Error Goto 0
    End Sub 'Class_Terminate
    


'*******************
    Function RegPath2HiveSubkey(ByVal strKeyPath, ByRef iHive, ByRef sSubkey) ' Private?
        Dim s
        const HKCR  = &H80000000 ' HKEY_CLASSES_ROOT    - HKCR
        const HKCU  = &H80000001 ' HKEY_CURRENT_USER    - HKCU
        const HKLM  = &H80000002 ' HKEY_LOCAL_MACHINE   - HKLM
        const HKU   = &H80000003 ' HKEY_USERS           - HKEY_USERS
        const HKCC  = &H80000005 ' HKEY_CURRENT_CONFIG  - HKEY_CURRENT_CONFIG
        If UCase(Left(strKeyPath, 18))="HKEY_CLASSES_ROOT\" Then
            sSubkey=Right(strKeyPath, Len(strKeyPath)-18) : iHive=HKCR
        ElseIf UCase(Left(strKeyPath, 5))="HKCR\" Then
            sSubkey=Right(strKeyPath, Len(strKeyPath)-5) : iHive=HKCR
        ElseIf UCase(Left(strKeyPath, 18))="HKEY_CURRENT_USER\" Then
            sSubkey=Right(strKeyPath, Len(strKeyPath)-18) : iHive=HKCU
        ElseIf UCase(Left(strKeyPath, 5))="HKCU\" Then
            sSubkey=Right(strKeyPath, Len(strKeyPath)-5) : iHive=HKCU
        ElseIf UCase(Left(strKeyPath, 19))="HKEY_LOCAL_MACHINE\" Then
            sSubkey=Right(strKeyPath, Len(strKeyPath)-19) : iHive=HKLM
        ElseIf UCase(Left(strKeyPath, 5))="HKLM\" Then
            sSubkey=Right(strKeyPath, Len(strKeyPath)-5) : iHive=HKLM
        ElseIf UCase(Left(strKeyPath, 11))="HKEY_USERS\" Then
            sSubkey=Right(strKeyPath, Len(strKeyPath)-11) : iHive=HKU
        ElseIf UCase(Left(strKeyPath, 20))="HKEY_CURRENT_CONFIG\" Then
            sSubkey=Right(strKeyPath, Len(strKeyPath)-20) : iHive=HKCC
        Else
            RegPath2HiveSubkey=True : Exit Function
        End If
        RegPath2HiveSubkey=False
    End Function 'RegPath2HiveSubkey



'*******************
    Function DeleteSubkeys(tree, strKeyPath) ' Private?
        Dim arrSubKeys, strSubkey
        objRegistry.EnumKey tree, strKeyPath, arrSubKeys
        If IsArray(arrSubKeys) Then
            For Each strSubkey In arrSubKeys
                DeleteSubkeys tree, strKeyPath & "\" & strSubkey
            Next
        End If
        objRegistry.DeleteKey tree, strKeyPath
    End Function 'DeleteSubkeys



'*******************
    Function DelRegKey(strKeyPath) 'export
        Dim tree, s
        If RegPath2HiveSubkey(strKeyPath, tree, s) Then DelRegKey=True : Exit Function
        'MsgBox "hDefKey=" & Hex(tree) & vbCrLf & "sSubKeyName=" & s & vbCrLf & "[" & strKeyPath & "]"
        DeleteSubkeys tree, s
        DelRegKey=False
    End Function 'DelRegKey



'*******************
    Function DelEmptyRegKey(strKeyPath) 'export
    ' удаление ключа реестра только если он не имеет именованных значений (т.е. кроме неименованного @=...) и не имеет подключей
        Dim tree, s 
        Dim arrValueNames, arrValueTypes, arrSubKeys
        If RegPath2HiveSubkey(strKeyPath, tree, s) Then DelEmptyRegKey=True : Exit Function
        'MsgBox "hDefKey=" & Hex(tree) & vbCrLf & "sSubKeyName=" & s & vbCrLf & "[" & strKeyPath & "]"
        strComputer = "." : Set objRegistry = GetObject("winmgmts:\\" & strComputer & "\root\default:StdRegProv")
        objRegistry.EnumValues tree, s, arrValueNames, arrValueTypes
        objRegistry.EnumKey tree, s, arrSubKeys
        If Not IsArray(arrSubKeys) And Not IsArray(arrValueNames) Then DeleteSubkeys tree, s
        DelEmptyRegKey=False
    End Function 'DelEmptyRegKey



End Class 'clsMrRegister



' ===============================================================================================================



Class StructConst 'cnst

	Public UninstRegPath, UninstRegP864, VerPath, Publisher
	Public icofile, sZipArch, folder
    Public aWscriptexe, aVBS, aForce86, aSilent, aNouac, aNo864, aSkipFW, aSkipFW_NO,  aRemove_force, aFinal, aUninstallString
    Public aZip_vbs, aZip_file, aZip_silentkeys, aUninstSilent, aTask, aDisplayName, aDisplayVersion, aAdvinf_InstDate, aAdvinf_InstUser, aAdvinf_UnLang, aPublisher
    Public sys32_path, sys64_path
    Public intWinVer, strPgmDir, strWinDir, strSys32Dir, strPgmFilesDir
    Public StrTempName
    Public bAdminAfterUAC
    Public sNowDate, sInstUserName 'сохраним также время установки и имя пользователя, производившего установку
    Public strSysLang, bIsWoW64, strHomePath, strLocalAppData



'*******************
	Function Init (s)
		folder			= s ' "KeyboardLayoutMonitor"
        Publisher       = "evgen_b"
		UninstRegPath	= "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\" & folder
        UninstRegP864   = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" & folder
		VerPath			= "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        icofile         = "i.ico"
		sZipArch	    = "uninstall.zip"
        aWscriptexe     = "WScript.exe"
        aVBS            = "vbs"
        aForce86        = "+force86"
        aSkipFW         = "+skipfw=yes"
        aSkipFW_NO      = "+skipfw=no"
        aSilent         = "+silent"
        aNouac          = "/nouac"
        aNo864          = "/no864"
        aTask           = "/task"
        aRemove_force   = "+remove=force"
        aFinal          = "+final"
        aUninstallString= "UninstallString"
        aZip_vbs        = "zip.vbs"
        aZip_file       = "zip.file"
        aZip_silentkeys = "zip.silentkeys"
        aUninstSilent   = "UninstSilent"
        aDisplayName    = "DisplayName"
        aDisplayVersion = "DisplayVersion"
        aAdvinf_InstDate= "advinf.InstDate"
        aAdvinf_InstUser= "advinf.InstUser"
        aAdvinf_UnLang  = "advinf.UninstLang"
        aPublisher      = "Publisher"
        intWinVer       = "unknown" : strPgmDir=intWinVer : strWinDir=intWinVer : strPgmFilesDir=intWinVer
        StrTempName     = intWinVer : sys32_path=intWinVer : sys64_path=intWinVer
        bAdminAfterUAC  = intWinVer : sNowDate=intWinVer : sInstUserName=intWinVer
        strSys32Dir     = intWinVer : bIsWoW64=intWinVer : strHomePath= intWinVer : strLocalAppData= intWinVer

		On Error Resume Next
        strSysLang      = ""
        With CreateObject("WScript.Shell")
        ' LocaleName "ru-RU"
        ' Locale "00000419" (string)
        ' sLanguage "RUS"
        strSysLang = UCase (   .RegRead ("HKCU\Control Panel\International\LocaleName")   ) ' Windows Vista+
        If strSysLang = "" Then strSysLang = UCase (   .RegRead ("HKCU\Control Panel\International\sLanguage")   ) ' Windows XP-
        If strSysLang = "" Then strSysLang = "EN-US"
        End With 'WScript.Shell
		On Error Goto 0


	End Function 'Init
'*******************
	Function Done
		'do nothing
	End Function 'Done
End Class 'StructConst



'*******************
Class StructOpts 'opts

	Public bFillBlue, strComponents
    Public bForceRemove, bResetCFG, bNoZIP, bFinal
    Public bSilent, bAutoIt, intUntimer, bForce86
    Public sGUILang, bSkipFW, bSkipFW_CLI
    Public bNeedReboot, i864Only
    Public bCompact



'*******************
	Function Init
    bFillBlue       = False
    bForceRemove    = False
    bNoZIP          = False

    bSilent         = False
    bFinal          = True ' !!! False - только для твикеров-патчей с полноценным GUI
    bAutoIt         = False
    intUntimer      = 5
    bResetCFG       = False ' при переустановке сбросить конфигурацию по дефолту, False - пытаться сохранить существующую
    bForce86        = False ' если доступны и 32- и 64-битная установка, то попытаться
                            ' в 64-разрядной системе установить 32-разрядную версию, например, winrar. (если не запрещено)
    'bForce86 - кроме того этот флажок нужен и при удалении! можно либо
    'в реестре uninstall доп ключ или логичнее в параметре вызова из uninstall.zip дописать

    strComponents   = ""    'в командной строке можно указать через запятую какие компоненты приложения устанавливать
    sGUILang        = "EN-US"
    bSkipFW         = False ' пропустить изменение встроенного в ОС файрвола при установке или удалении
    bSkipFW_CLI     = False ' довесок, True - если явно задано в командной строке
    bNeedReboot     = False ' сигнализирует, что после установки или удаления необходимо перезагрузить компьютер
    i864Only        = 1     ' опция показывает, что данный дистрибутив 32/64-разрядный
            '32 - 32-разрядный, в x64 тоже будет работать
            '86 - 32-разрядный, но в x64 НЕ УСТАНАВЛИВАЕТСЯ
            '64 - только 64-разрядный, нет 32-разрядной версии
            '00 - есть 32-разрядная версия и 64-разрядная версия дистрибутива, есть поддержка опции bForce86 (т.е. в x64 можно установить как 64-, так и 32-разрядную версию)
            '01 - есть 32-разрядная версия и 64-разрядная версия дистрибутива, но опция bForce86 НЕ ПОДДЕРЖИВАЕТСЯ (в x64 в режиме совместимости 32-разрядная версия не будет работать)
    bCompact        = True  ' устанавливать в сжатый каталог
	End Function 'Init
'*******************
	Function Done
		'do nothing
	End Function 'Done
End Class 'StructOpts



'*******************
Class StructDistr 'distr - опции специфичного дистрибутива выносим отдельно

	Public HKLM_App, HKCU_App
    Public dispname, AppVer, BldVer, cmdfile, regfile
    Public sLnkDir, sLnkParentDir
    Public homepage, URLInfoAbout, URLUpdateInfo, HelpLink


'*******************
	Function Init
    	HKLM_App    = "HKLM\SOFTWARE\?"
        HKCU_App    = "HKCU\Software\KeyboardLayoutMonitor"

'from cnst:
		dispname		= "Very Suspicious Keyboard Layout Monitor"
		AppVer			= ApplicationVersion
        BldVer          = BuildVersion
        cmdfile         = "KeyboardLayoutMonitor.cmd"
        regfile         = "KeyboardLayoutMonitor.reg"
'new:
        sLnkDir         = "Keyboard Layout Monitor"     'папки-подпапки в меню Пуск
        sLnkParentDir   = ""                'обычно не используется - в Пуске обычно только один уровень вложенности папок
' sLnk* можно использовать и вместе или только одну из них (если не пустая строка)
' разница в том, что к имени папки sLnkDir дописывается " x86" или " x64" в зависимости от разрядности установленной программы

        homepage        = "https://habrahabr.ru/post/248919/"
		URLInfoAbout    = homepage
		URLUpdateInfo   = homepage
		HelpLink        = homepage

	End Function 'Init
'*******************
	Function Done
		'do nothing
	End Function 'Done
End Class 'StructDistr



' ===============================================================================================================



Class Setup
' ver 0.0.0.1

	Private objShell, objFSO
    Private oSUDO64, oZIPHell, oFWMan, oReg, oWriteCallBack
	Private cnst, args, opts, distr
	Private strPackageID, intAction, bCanNotZIP_os, b64



'*******************
	Function Init
		On Error Resume Next
		Err=0

		Set objFSO          = CreateObject("Scripting.FileSystemObject")
		Set objShell        = CreateObject("WScript.Shell")
		Set oSUDO64		    = New clsSudo64
		Set oZIPHell        = New clsZIPHeil
		'Set oFWMan          = New FWMan
		Set oReg            = New clsMrRegister
		Set opts	        = New StructOpts 	    : opts.Init
		Set distr	        = New StructDistr 	    : distr.Init

		Set args	        = New clsAllArgumentsHTA   : args.Init "inst_sfx_name", "inst_sfx_path", "none"
		intAction           = 1 '1=inst, 2=uninst
        strPackageID        = args.Arguments(0)

		Set oWriteCallBack  = New EmptyCallBack

		Set cnst	        = New StructConst	    : cnst.Init (strPackageID)
        cnst.strPgmDir      = args.ScriptPath
		Dim WshEnv : Set WshEnv = objShell.Environment("PROCESS")
		cnst.strPgmFilesDir = WshEnv("ProgramFiles")
		cnst.strWinDir      = WshEnv("SystemRoot")
        cnst.sInstUserName  = WshEnv("USERNAME")
        b64                 = WshEnv("PROCESSOR_ARCHITECTURE")="AMD64"
        cnst.bIsWoW64       = WshEnv("PROCESSOR_ARCHITEW6432")="AMD64"

        cnst.strHomePath    = WshEnv("HOMEPATH")
        cnst.strLocalAppData= WshEnv("LOCALAPPDATA")

		Set WshEnv=Nothing
		cnst.strSys32Dir    = objFSO.GetSpecialFolder(1) ' current(32/64) System32 path
		cnst.StrTempName    = objFSO.GetSpecialFolder(2) & "\" & objFSO.GetTempName
		Dim t : t=oSUDO64.Init("none") ': Msgbox t
        cnst.intWinVer      = Eval(oSUDO64.os_ver)
        cnst.sys32_path     = oSUDO64.sys32_path
        cnst.sys64_path     = oSUDO64.sys64_path

        ' на переоптимизированнх XP в CSI_IsAdmin() не всегда бывают ветки реестра для чтения, поэтому по возможности используем amel27_IsAdminGroup()
		If (Eval(oSUDO64.os_ver)  = 5.1) Then cnst.bAdminAfterUAC=oSUDO64.is_odmin_group Else cnst.bAdminAfterUAC=oSUDO64.is_odmin_proc

        cnst.sNowDate       = Y_M_D(Now)

        bCanNotZIP_os=oSUDO64.w2k_os
        'bCanNotZIP_os=True

		Init = CBool (Err) OR CBool (t)
        opts.sGUILang       = cnst.strSysLang

        If distr.sLnkDir<>"" Then
            If b64 Then distr.sLnkDir=distr.sLnkDir & " x64" Else distr.sLnkDir=distr.sLnkDir & " x86"
        End If

        'сохранять ли при переустановке настройки файрвола? (если явно не переопределено в командной строке)
        If GetRegIsOption(cnst.aSkipFW) Then opts.bSkipFW=True

		On Error Goto 0
	End Function 'Init



'*******************
	Function Done
		On Error Resume Next
		Set objShell    = Nothing
		Set objFSO      = Nothing

		oSUDO64.Done    : Set oSUDO64=Nothing
		oZIPHell.Done   : Set oZIPHell=Nothing
		cnst.Done	    : Set cnst=Nothing
		args.Done	    : Set args=Nothing
		opts.Done	    : Set opts=Nothing
		distr.Done	    : Set distr=Nothing

        oWriteCallBack.Done
        Set oWriteCallBack=Nothing

        'Set oFWMan=Nothing
        Set oReg=Nothing

		Done=CBool (Err)
		On Error Goto 0
	End Function 'Done



'*******************
	Function AutoInitAction 'только для патчей_с_GUI (установить-удалить патч)
        If (Check=1) Then intAction=2 Else intAction=1
	End Function 'AutoInitAction



'*******************
	Function GetRemoveOpts
        Dim s
        s = " " & cnst.aRemove_force & " " & cnst.aFinal
        If opts.bForce86 Then s = s & " " & cnst.aForce86
        If opts.bSkipFW  Then s = s & " " & cnst.aSkipFW
        GetRemoveOpts=s
	End Function 'GetRemoveOpts



'*******************
	Function GetRemoveName
        Dim s
        s = strPackageID & GetRemoveOpts() & "." & cnst.aVBS
        GetRemoveName=s
	End Function 'GetRemoveName



'*******************
    Function GetExpVer()
       GetExpVer=distr.AppVer & " Build [" & distr.BldVer & "]"
    End Function 'GetExpVer



'*******************
    Function GetRegIsOption(strKey)
    'использовался ли ключ +SkipFW=Yes при предыдущей установке? (нужно для переустановки)
    'на гране фола он попадет или в s2 или в s1
	On Error Resume Next
    Dim i, s1, s2 : s1="" : s2=""
	s1=objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aZip_vbs) ' GetRemoveName()
	s2=objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aUninstallString)
    i=InStrRev (   UCase(s2), UCase("." & cnst.aVBS & " ")  )
    If i>0 Then s2=Right (s2, Len(s2)-i-4) Else s2=""
    i = InStr(UCase(s1), UCase(strKey)) + InStr(UCase(s2), UCase(strKey))
    GetRegIsOption=CBool(i)
	On Error Goto 0
    End Function 'GetRegIsOption



'*******************
    Function Y_M_D(NowDate) 'упорядоченная дата
        Dim s    
        s = "" & Year(NowDate) & "."
        If Month(NowDate)<10 Then s = s & "0"
        s = s & Month(NowDate) & "."
        If Day(NowDate)<10 Then s = s & "0"
        s = s & Day(NowDate)
        Y_M_D=s
    End Function 'Y_M_D



'*******************
	Function LoadCallBack (objWriteCallBack)
		On Error Resume Next
        oWriteCallBack.Done: Set oWriteCallBack=Nothing
        Set oWriteCallBack=objWriteCallBack
		On Error Goto 0
	End Function 'LoadCallBack



'*******************
	Function ParsArgs
	Dim s, i : i=1
    Dim CLILang : CLILang=""
	While (i < args.Count)
        s=args.Arguments(i)
		Select Case ucase(s)
			Case "+INST"			            intAction       = 1
			Case "+REMOVE"			            intAction       = 2
			Case UCase(cnst.aRemove_force)	    intAction       = 2     : opts.bForceRemove=True
			Case UCase(cnst.aSilent)            opts.bSilent    = True  : opts.bAutoIt=False
			Case "+SMARTRUN"	                AutoInitAction
			Case "+NOZIP"		                opts.bNoZIP     = True
			Case "-HELP"		                intAction       = 4 ' opts.bHelpKey   = True
			'Case "+AUTOIT"		                opts.bAutoIt    = True  : opts.bSilent=False
			'Case UCase(cnst.aFinal)            opts.bFinal	    = True
			'Case "+BLUE"		                opts.bFillBlue  = True
			Case "+INST=RESETCFG"               intAction       = 1     : opts.bResetCFG = True
			'Case UCase(cnst.aSkipFW)            opts.bSkipFW    = True  : opts.bSkipFW_CLI = True
			'Case UCase(cnst.aSkipFW_NO)         opts.bSkipFW    = False : opts.bSkipFW_CLI = True
			Case UCase(cnst.aForce86)           opts.bForce86   = True
            Case "+NOCOMPACT"                   opts.bCompact   = False
			'Case UCase(cnst.aTask)	            opts.bTask      = True  : opts.bSilent = True
            Case Else :
                If      Left (   UCase(s),15   ) = "+SELECTPACKETS=" Then
                                    opts.strComponents=Right(   s,Len(s)-15   )
                ElseIf  Left (   UCase(s),6   ) = "+LANG=" Then
                                    CLILang=Right(   s,Len(s)-6   )
                End If
		End Select
		i=i+1
	Wend

	On Error Resume Next

	'----при использовании графического интерфейса установка или удаление выбирается автоматически
	'----If Not opts.bSilent And Not opts.bAutoIt Then AutoInitAction

    'при удалении берем язык GUI не из системы, а из параметра прежней установки
    'но более высокий преоритет имеет командная строка
    If intAction=2 Then opts.sGUILang=UCase (   objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aAdvinf_UnLang)   )
    If CLILang<>"" Then opts.sGUILang=UCase (   CLILang   )

	End Function 'ParsArgs



'*******************
	Function Check
		'0 - норма
		'1 - уже установлен
		'-------2 - в 64-битной не нужен
		'-------3 - поддерживается только Vista и выше
		'-------4 - редакция не поддерживается
		'-1 - ХЗ
		Dim retcode, cmdstr
		Check=-1
		
		On Error Resume Next
		cmdstr=objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aUninstallString)
		retcode=Err
		On Error Goto 0
		If (retcode = 0) Then
            cmdstr=""
    		On Error Resume Next
			cmdstr=objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aPublisher)
    		On Error Goto 0
            If cmdstr=cnst.Publisher Then Check=1 : Exit Function
        End If
			
		'-------If oSUDO64.x64_os Then		Check=2 : Exit Function
			
		'-------If (cnst.intWinVer < 6) Then Check=3 : Exit Function
		On Error Resume Next
		'cmdstr=objShell.RegRead (cnst.VerPath & "\EditionID")
		'retcode=Err
		'If (retcode <> 0) Then Exit Function
		'If (ucase(cmdstr) <> "ULTIMATE") Then Check=4 : Exit Function
		On Error Goto 0
		
		Check=0
	End Function 'Check



'*******************
	Function GetLangInteger
' Supported Language Packs and Language Interface Packs
' http://technet.microsoft.com/en-us/library/cc722435(v=ws.10).aspx
'English (United States)     en-US
'Dutch (Netherlands)         nl-NL
'French (France)             fr-FR
'German (Germany)            de-DE
'Italian (Italy)             it-IT
'Japanese (Japan)            ja-JP
'Spanish (Spain)             es-ES
'Arabic (Saudi Arabia)       ar-SA
'Chinese (PRC)               zh-CN
'Chinese (Hong Kong S.A.R.)  zh-HK
'Chinese (Taiwan)            zh-TW
'Czech (Czech Republic)      cs-CZ
'Danish (Denmark)            da-DK
'Finnish (Finland)           fi-FI
'Greek (Greece)              el-GR
'Hebrew (Israel)             he-IL
'Hungarian (Hungary)         hu-HU
'Korean (Korea)              ko-KR
'Norwegian, Bokmal (Norway)  nb-NO
'Polish (Poland)             pl-PL
'Portuguese (Brazil)         pt-BR
'Portuguese (Portugal)       pt-PT
'Russian (Russia)            ru-RU
'Swedish (Sweden)            sv-SE
'Turkish (Turkey)            tr-TR
'Bulgarian (Bulgaria)        bg-BG
'Croatian (Croatia)          hr-HR
'Estonian (Estonia)          et-EE
'Latvian (Latvia)            lv-LV
'Lithuanian (Lithuania)      lt-LT
'Romanian (Romania)          ro-RO
'Serbian (Latin, Serbia)     sr-Latn-CS
'Slovak (Slovakia)           sk-SK
'Slovenian (Slovenia)        sl-SI
'Thai (Thailand)             th-TH
'Ukrainian (Ukraine)         uk-UA
'Afrikaans (South Africa)    af-ZA
'Albanian (Albania)          sq-AL
'Amharic (Ethiopia)          am-ET
'Armenian (Armenia)          hy-AM
'Assamese (India)            as-IN
'Azeri (Latin, Azerbaijan)   az-Latn-AZ
'Basque (Basque)             eu-ES
'Belarusian (Belarus)        be-BY
'Bengali (Bangladesh)        bn-BD
'Bengali (India)             bn-IN
'Bosnian (Cyrillic, Bosnia and Herzegovina) bs-Cyrl-BA
'Bosnian (Latin, Bosnia and Herzegovina) bs-Latn-BA
'Catalan (Catalan)           ca-ES
'Filipino (Philippines)      fil-PH
'Galician (Galician)         gl-ES
'Georgian (Georgia)          ka-GE
'Gujarati (India)            gu-IN
'Hausa (Latin, Nigeria)      ha-Latn-NG
'Hindi (India)               hi-IN
'Icelandic (Iceland)         is-IS
'Igbo (Nigeria)              ig-NG
'Indonesian (Indonesia)      id-ID
'Inuktitut (Latin, Canada)   iu-Latn-CA
'Irish (Ireland)             ga-IE
'isiXhosa (South Africa)     xh-ZA
'isiZulu (South Africa)      zu-ZA
'Kannada (India)             kn-IN
'Kazakh (Kazakhstan)         kk-KZ
'Khmer (Cambodia)            km-KH
'Kinyarwanda (Rwanda)        rw-RW
'Kiswahili (Kenya)           sw-KE
'Konkani (India)             kok-IN
'Kyrgyz (Kyrgyzstan)         ky-KG
'Lao (Lao P.D.R.)            lo-LA
'Luxembourgish (Luxembourg)  lb-LU
'Macedonian (Former Yugoslav Republic of Macedonia) mk-MK
'Malay (Brunei Darussalam)   ms-BN
'Malay (Malaysia)            ms-MY
'Malayalam (India)           ml-IN
'Maltese (Malta)             mt-MT
'Maori (New Zealand)         mi-NZ
'Marathi (India)             mr-IN
'Nepali (Nepal)              ne-NP
'Norwegian, Nynorsk (Norway) nn-NO
'Oriya (India)               or-IN
'Pashto (Afghanistan)        ps-AF
'Persian                     fa-IR
'Punjabi (India)             pa-IN
'Quechua (Peru)              quz-PE
'Serbian (Cyrillic, Serbia)  sr-Cyrl-CS
'Sesotho sa Leboa (South Africa) nso-ZA
'Setswana (South Africa)     tn-ZA
'Sinhala (Sri Lanka)         si-LK
'Tamil (India)               ta-IN
'Tatar (Russia)              tt-RU
'Telugu (India)              te-IN
'Urdu (Islamic Republic of Pakistan) ur-PK
'Uzbek (Latin, Uzbekistan)   uz-Latn-UZ
'Vietnamese (Vietnam)        vi-VN
'Welsh (United Kingdom)      cy-GB
'Wolof (Senegal)             wo-SN
'Yoruba (Nigeria)            yo-NG
	On Error Resume Next
        Err=0
        If CBool(Instr(opts.sGUILang, "RU-RU")) Or CBool(Instr(opts.sGUILang, "UK-UA")) Or CBool(Instr(opts.sGUILang, "BE-BY")) Or CBool(Instr(opts.sGUILang, "RUS")) Then
    		GetLangInteger=&h0419 'Russian
        ElseIf  1=2 Then
    		'GetLangInteger=...
        ElseIf  1=2 Then
    		'GetLangInteger=...
        Else
            GetLangInteger=&h0409 'English - default
        End If
	On Error Goto 0
	End Function 'GetLangInteger

'*******************



Function ErrMsg(chk)
	Dim cmdstr
	If chk<20 Then
		Select Case chk
			Case 0		: 'do nothing
			Case 1		: cmdstr="Уже установлен!"
			Case 2		: cmdstr="В 64-битной OS не нужен"
			Case 3		: cmdstr="Поддерживается только Vista и выше"
			Case 4		: cmdstr="Редакция не поддерживается"
			Case 5		: cmdstr="Требуется запуск с правами администратора"
			Case Else   : 'do nothing
		End Select
		If (chk>0) And Not opts.bSilent Then objShell.Popup cmdstr, untimer, distr.dispname, 0 + 16
	Else
		Select Case chk
			Case 21		: 'отказался устанавливать
			Case 22		: 'нечего удалять
			Case 23		: 'отказался удалять
			Case 24		: 'отказался переустанавливать
			Case 25		: 'при переустановке удаление предыдущей версии по какой-то причине не сработало (может нет тихого удаления?)
			
			Case 101	: Msgbox ("ERR->Check")
			Case 102	: Msgbox ("ERR->bAdminAfterUAC (Требуется запуск с правами администратора)")
			Case 103	: Msgbox ("ERR->Prog_MakeDirs/Data_MakeDirs")
			Case 104	: Msgbox ("ERR->Prog_CopyFiles")
			Case 105	: Msgbox ("ERR->Data_CopyFiles")
			Case 107	: Msgbox ("ERR->MakeLinks")
			Case 108	: Msgbox ("ERR->RegAdd")
			Case 109	: Msgbox ("ERR->AddRegUninst")
			Case 110	: Msgbox ("ERR->AddLnkUninst")
			Case 111	: Msgbox ("ERR->DoInitial")
			Case 112	: Msgbox ("ERR->MakeUninstVBS/ZipScript3/CopyScript")
			Case 113	: Msgbox ("ERR->SetACL") ' было 106, но SetACL нужно вызывать после PostRestoreCFG
			Case Else   : Msgbox ("ERR->Common Action")
		End Select
	End If
End Function 'ErrMsg



'*******************
	Function ZipScript1
    	On Error Resume Next
    	'подготавливаем ZIP
        objFSO.DeleteFile (args.ScriptPath & "\" & cnst.sZipArch)
		oZIPHell.Init args.ScriptPath & "\" & cnst.sZipArch
		objFSO.GetFile(args.ScriptFullName).Copy args.ScriptPath & "\" & GetRemoveName()
		objFSO.GetFile(args.ScriptPath & "\" & GetRemoveName()).Attributes=0 'был для лучшей совместимости с explorer.exe|ZipSFX (или Attributes And 1 проверять в ZipSFX)
		oZIPHell.ToArchiveAsync args.ScriptPath & "\" & GetRemoveName()
        ZipScript1=False
		On Error Goto 0
	End Function 'ZipScript1
	Function ZipScript2
		On Error Resume Next
    	'продолжаем в фоне архивировать
	    bCanNotZIP_os=oZIPHell.ToArchiveWait (30)
        'bCanNotZIP_os=True ' - имитация ошибки в говносборке
        If bCanNotZIP_os Then oZIPHell.Done
		oZIPHell.ToArchiveAsync args.ScriptPath & "\" & cnst.icofile
        ZipScript2=False
		On Error Goto 0
	End Function 'ZipScript2
	Function ZipScript3
		On Error Resume Next
        Err=0
        oZIPHell.ToArchiveWait (30)
        oWriteCallBack.Draw 4, 2, 0
		objFSO.GetFile(args.ScriptPath & "\" & cnst.sZipArch).Move cnst.strPgmFilesDir & "\" & cnst.folder & "\"
		oZIPHell.Done
        If CBool(Err) Then oWriteCallBack.Draw 4, 3, 1 Else oWriteCallBack.Draw 4, 3, 0
        ZipScript3=CBool(Err)
		On Error Goto 0
	End Function 'ZipScript3



'*******************
	Function CopyScript
		On Error Resume Next
        Err=0
        oWriteCallBack.Draw 4, 4, 0
		objFSO.CreateFolder cnst.strPgmFilesDir & "\" & cnst.folder
		objFSO.CopyFile args.ScriptPath & "\" & cnst.icofile, cnst.strPgmFilesDir & "\" & cnst.folder & "\" & cnst.icofile
        Err=0
		objFSO.CopyFile args.ScriptFullName, cnst.strPgmFilesDir & "\" & cnst.folder & "\" & args.ScriptName
		CopyScript=CBool(Err)
        If CBool(Err) Then oWriteCallBack.Draw 4, 5, 1 Else oWriteCallBack.Draw 4, 5, 0
		On Error Goto 0
	End Function 'CopyScript



'*******************
	Function MakeUninstVBS
    'для совместимости с software restriction policy теперь поднимаем права внутри uninstall.vbs,
    'который находится в доверенной зоне "Program Files".
    'имея права админа, он сможет запустить из недовереннной папки %temp% распакованный "ntk128gb +final.vbs"
    '(подразумевается, что SRP не распространяется на администраторов, т.е. как по умолчанию.)
	Dim text, s
	On Error Resume Next
    oWriteCallBack.Draw 4, 0, 0

		objFSO.CreateFolder cnst.strPgmFilesDir & "\" & cnst.folder
		Err=0
		Set text=objFSO.CreateTextFile(cnst.strPgmFilesDir & "\" & cnst.folder & "\" & objFSO.GetBaseName(cnst.sZipArch) & "." & cnst.aVBS, True, False)
		If CBool(Err) Then MakeUninstVBS=True : Exit Function
		text.Write _
"packagename=""" &  strPackageID & """" & vbCrLf & _
"packagedepth=" &  opts.i864Only & vbCrLf & _
"packageforce86=" & CInt(opts.bForce86) & vbCrLf & _
"On Error Resume Next" & vbCrLf & _
"nouac=False" & vbCrLf & _
"no864=False" & vbCrLf & _
"act=1" & vbCrLf & _
"With CreateObject(""WScript.Shell"")" & vbCrLf & _
"OS64=.Environment(""PROCESS"")(""PROCESSOR_ARCHITECTURE"")=""AMD64""" & vbCrLf & _
"WoW64=.Environment(""PROCESS"")(""PROCESSOR_ARCHITEW6432"")=""AMD64""" & vbCrLf & _
"osver=""1.0""" & vbCrLf & _
"osver=.RegRead (""" & cnst.VerPath & "\CurrentVersion"")" & vbCrLf & _
"sys32path=.Environment(""PROCESS"")(""windir"") & ""\""" & vbCrLf & _
"sys64path=sys32path" & vbCrLf & _
"If (Eval(osver) >= 6) Then uacsupport=True Else uacsupport=False" & vbCrLf & _
"For i=0 To WScript.Arguments.Count" & vbCrLf & _
"  s=WScript.Arguments(i)" & vbCrLf & _
"  cmd_par=cmd_par & s & "" """ & vbCrLf & _ 
"  If s=""" & UCase(cnst.aNouac) & """ Then nouac=True" & vbCrLf & _
"  If s=""" & UCase(cnst.aNo864) & """ Then no864=True" & vbCrLf & _
"  If s=""/DEL"" Then act=1" & vbCrLf & _
"  If s=""" & UCase(cnst.aTask) & """ Then act=2" & vbCrLf & _
"Next" & vbCrLf & _
"If Not nouac And uacsupport Then" & vbCrLf & _
"  With CreateObject(""Shell.Application"")" & vbCrLf & _
"  .ShellExecute WScript.FullName, """""""" & WScript.ScriptFullName & """""" "" & cmd_par & """ & UCase(cnst.aNouac) & """, """", ""runas"", 1" & vbCrLf & _
"  WScript.Sleep 3000" & vbCrLf & _
"  End With" & vbCrLf & _
"  WScript.Quit 0" & vbCrLf & _
"End If" & vbCrLf & _
"If WoW64 Then" & vbCrLf & _
"  sys64path=sys64path & ""sysNative\""" & vbCrLf & _
"  sys32path=sys32path & ""sysWOW64\""" & vbCrLf & _
"Else" & vbCrLf & _
"  If OS64 Then sys64path=sys64path & ""system32\"" : sys32path=sys32path & ""sysWOW64\"" Else sys32path=sys32path & ""system32\"" : sys64path=sys32path" & vbCrLf & _
"End If" & vbCrLf & _
"s=""" & cnst.aWscriptexe & """" & vbCrLf & _
"If Not no864 Then" & vbCrLf & _
"Select Case packagedepth" & vbCrLf & _
"  Case 32, 86" & vbCrLf & _
"    s=sys32path & s" & vbCrLf & _
"  Case 64, 1" & vbCrLf & _
"    s=sys64path & s" & vbCrLf & _
"  Case 0" & vbCrLf & _
"    If CBool(packageforce86) Then s=sys32path & s Else s=sys64path & s" & vbCrLf & _
"  Case Else" & vbCrLf & _
"    'NOP" & vbCrLf & _
"End Select" & vbCrLf & _
"  .Run """""""" & s & """""" """""" & WScript.ScriptFullName & """""" "" & cmd_par & ""/NO864"", 0, False" & vbCrLf & _
"  WScript.Quit 0" & vbCrLf & _
"End If" & vbCrLf & _
"HKLM=""" & objFSO.GetParentFolderName(cnst.UninstRegPath) & "\"" & packagename" & vbCrLf & _
"sZipPath=.RegRead(HKLM & ""\zip.file"")" & vbCrLf & _
"vbsfile=.RegRead(HKLM & ""\zip.vbs"")" & vbCrLf & _
"With CreateObject (""Scripting.FileSystemObject"")" & vbCrLf & _
"  sExtractTo=.GetSpecialFolder(2) & ""\"" & .GetTempName" & vbCrLf & _
"  .Run ""rundll32.exe advpack.dll,DelNodeRunDLL32 "" & sExtractTo, 0, True" & vbCrLf & _
"  .CreateFolder(sExtractTo)" & vbCrLf & _
"End With" & vbCrLf & _
"With CreateObject(""Shell.Application"")" & vbCrLf & _
"  .NameSpace(sExtractTo).CopyHere(.NameSpace(sZipPath).items)" & vbCrLf & _
"End With" & vbCrLf & _
"s=s & "" """""" & sExtractTo & ""\"" & vbsfile & """"""""" & vbCrLf & _
"Select Case act" & vbCrLf & _
"  Case 1 : .Run s & "" /NOUAC"", 0, False" & vbCrLf & _
"  Case 2 : .Run s & "" /NOUAC /TASK"", 0, False" & vbCrLf & _
"End Select" & vbCrLf & _
"End With"
		text.Close
		Set text=Nothing
    	MakeUninstVBS=CBool(Err)
    If CBool(Err) Then oWriteCallBack.Draw 4, 1, 1 Else oWriteCallBack.Draw 4, 1, 0
	On Error Goto 0
	End Function 'MakeUninstVBS



'*******************
	Function AddRegUninst
		On Error Resume Next
            oWriteCallBack.Draw 3, 0, 0
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aDisplayName, distr.dispname
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aDisplayVersion, GetExpVer()
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aPublisher, cnst.Publisher

    If Not bCanNotZIP_os And Not opts.bNoZIP Then
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aUninstallString, cnst.aWscriptexe & _
				" """ & cnst.strPgmFilesDir & "\" & cnst.folder & "\" & objFSO.GetBaseName(cnst.sZipArch) & "." & cnst.aVBS & """ " & cnst.aNouac
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aZip_file, cnst.strPgmFilesDir & "\" & cnst.folder & "\" & cnst.sZipArch
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aZip_vbs, GetRemoveName()
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aZip_silentkeys, cnst.aSilent & " " & cnst.aNouac
    Else
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aUninstallString, cnst.aWscriptexe & _
				" """ & cnst.strPgmFilesDir & "\" & cnst.folder & "\" & args.ScriptName & """" & GetRemoveOpts() & " " & cnst.aNouac
			objShell.RegWrite cnst.UnInstRegPath & "\" & cnst.aUninstSilent, cnst.aWscriptexe & _
				" """ & cnst.strPgmFilesDir & "\" & cnst.folder & "\" & args.ScriptName & """" & GetRemoveOpts() & " " & cnst.aSilent & " " & cnst.aNouac
    End If
			objShell.RegWrite cnst.UninstRegPath & "\NoModify",        1, "REG_DWORD"
			objShell.RegWrite cnst.UninstRegPath & "\NoRepair",        1, "REG_DWORD"
			'objShell.RegWrite cnst.UninstRegPath & "\DisplayIcon",     cnst.strPgmFilesDir & "\" & cnst.folder & "\KeyboardLayoutMonitor.exe"
            objShell.RegWrite cnst.UninstRegPath & "\DisplayIcon",     cnst.strSys32Dir & "\SHELL32.dll,130"

			objShell.RegWrite cnst.UninstRegPath & "\EstimatedSize",   1, "REG_DWORD"
			objShell.RegWrite cnst.UninstRegPath & "\URLInfoAbout",    distr.URLInfoAbout
			objShell.RegWrite cnst.UninstRegPath & "\URLUpdateInfo",   distr.URLUpdateInfo
			objShell.RegWrite cnst.UninstRegPath & "\HelpLink",        distr.HelpLink

			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aAdvinf_UnLang, opts.sGUILang
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aAdvinf_InstDate, cnst.sNowDate
			objShell.RegWrite cnst.UninstRegPath & "\" & cnst.aAdvinf_InstUser, cnst.sInstUserName

            If CBool(Err) Then oWriteCallBack.Draw 3, 1, 1 Else oWriteCallBack.Draw 3, 1, 0
			AddRegUninst=CBool(Err)
		On Error Goto 0
	End Function 'AddRegUninst



'*******************
	Function DelRegUninst
    ' удаление данных uninstall из реестра
	On Error Resume Next
        Err=0
        oReg.DelRegKey(cnst.UninstRegPath)
		DelRegUninst=CBool(Err)
	On Error Goto 0
	End Function 'DelRegUninst



'*******************
	Function AddLnkUninst
    ' создать ярлык uninstall
	On Error Resume Next
        Err=0
        Dim sLinkPath, oLNK

' AllUsersPrograms
' Programs
' ---------------------------------
' WindowStyle:
' 1 Activates and displays a window. If the window is minimized or maximized, the system restores it to its original size and position.
' 3 Activates the window and displays it as a maximized window.
' 7 Minimizes the window and activates the next top-level window.

        sLinkPath = objShell.SpecialFolders("AllUsersPrograms")

        If distr.sLnkParentDir<>"" Then sLinkPath=sLinkPath & "\" & distr.sLnkParentDir : objFSO.CreateFolder sLinkPath
        If distr.sLnkDir<>"" Then sLinkPath=sLinkPath & "\" & distr.sLnkDir : objFSO.CreateFolder sLinkPath
        Err=0

        Set oLNK = objShell.CreateShortcut(sLinkPath & "\" & "Uninstall.lnk")
        oLNK.Description = "Remove Kilo-master"
        'oLNK.HotKey = ""
        oLNK.IconLocation = cnst.strSys32Dir & "\SHELL32.dll, 31"
        oLNK.WindowStyle = 1
        oLNK.WorkingDirectory = cnst.strSys32Dir

    If Not bCanNotZIP_os And Not opts.bNoZIP Then
        oLNK.TargetPath = cnst.strSys32Dir & "\" & cnst.aWscriptexe
        oLNK.Arguments = """" & cnst.strPgmFilesDir & "\" & cnst.folder & "\" & objfso.GetBaseName(cnst.sZipArch) & "." & cnst.aVBS & """"
    Else
        oLNK.TargetPath = cnst.strSys32Dir & "\" & cnst.aWscriptexe
        oLNK.Arguments = """" & cnst.strPgmFilesDir & "\" & cnst.folder & "\" & args.ScriptName & """" & GetRemoveOpts()
    End If

        oLNK.Save
        Set oLNK = Nothing

        AddLnkUninst=CBool(Err)
	On Error Goto 0
	End Function 'AddLnkUninst



'*******************
	Function DelLnkUninst
    ' удалить ярлык uninstall - как правило, не нужно, т.к. удаляем сразу всю папку с ярлыками в меню Пуск
	On Error Resume Next
        Err=0
        DelLnkUninst=CBool(Err)
	On Error Goto 0
	End Function 'DelLnkUninst



'*******************
	Function CallExternalUninst
    'процедура вызывается в том случае, если версии уже установленной программы
    'и данного установщика не совпадают, поэтому лучше удалить, используя родной
    'uninstall (т.е. внешний), просто вызвав его в тихом режиме.
		Dim sExtractTo, sZipPath, sVBSPath, sSilentKeys, sOverridedKeys
		On Error Resume Next
        sZipPath=""
        sVBSPath=""
        sSilentKeys=""
        sOverridedKeys=""
    	sExtractTo=objFSO.GetSpecialFolder(2) & "\" & objFSO.GetTempName
    	sZipPath=objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aZip_file)
    	sVBSPath=objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aZip_vbs)
        sVBSPath=sExtractTo & "\" &  sVBSPath
    	sSilentKeys=objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aZip_silentkeys)

        ' фикс при переустановке
        If opts.bSkipFW_CLI Then
            If opts.bSkipFW Then sOverridedKeys=sOverridedKeys & " " & cnst.aSkipFW Else sOverridedKeys=sOverridedKeys & " " & cnst.aSkipFW_NO
        End If 'opts.bSkipFW_CLI

        'сначала попробуем поискать сжатый uninstall, если его нет
        'то вероятно старая установленная версия его ещё не поддерживала.
        If Not bCanNotZIP_os And (sZipPath<>"") And (sVBSPath<>"") And objFSO.FileExists(sZipPath) Then
        	objShell.Run "rundll32.exe advpack.dll,DelNodeRunDLL32 " & sExtractTo, 0, True
        	objFSO.CreateFolder(sExtractTo)
            With CreateObject("Shell.Application")
            	.NameSpace(sExtractTo).CopyHere(.NameSpace(sZipPath).items)
            End With
            sSilentKeys=cnst.aWscriptexe & " """ & sVBSPath & """ " & sSilentKeys
            'MsgBox sSilentKeys
            If objFSO.FileExists(sVBSPath) Then
            	objShell.Run sSilentKeys & sOverridedKeys, 0, True
            	objShell.Run "rundll32.exe advpack.dll,DelNodeRunDLL32 " & sExtractTo, 0, True
                Exit Function
            End If
        End If
        	sSilentKeys=objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aUninstSilent)
        	objShell.Run sSilentKeys & sOverridedKeys, 0, True

		On Error Goto 0
	End Function 'CallExternalUninst



'*******************
	Function RunCMDAfterInstall (bReinst)
    'выполнение командного файла после установки
    'кроме того, при установке или при переустановке со сбросом конфигурации - запуск файла импорта реестра
		On Error Resume Next
        oWriteCallBack.Draw 8, 0, 0
		If args.inst_sfx_path<>"" Then
		    If opts.bResetCFG Or Not bReinst Then objShell.Run _
            "regedit.exe /s " & Chr(34) & args.inst_sfx_path & "\" & distr.regfile & Chr(34), 0, True
            objShell.Run "cmd.exe /c " & Chr(34) & args.inst_sfx_path & "\" & distr.cmdfile & chr(34), 0, True
        End If
        oWriteCallBack.Draw 8, 1, 0
		On Error Goto 0
	End Function 'RunCMDAfterInstall



'*******************
	Function NotepadHelp
        Dim Name, s, text
		On Error Resume Next
    	Name = objFSO.GetSpecialFolder(2) & "\" & objFSO.GetTempName & ".txt"

        s = _
distr.dispname & " Версия: " & GetExpVer() & vbCrLf & vbCrLf & _
"install.exe [+Silent | +AutoIt] [+Inst | +Inst=ResetCFG | +Remove | +Remove=Force | +SmartRun] [+Force86]" & vbCrLf & _
"    [+Final] [+NoZIP] [+SelectPackets=opt,op2,opt3,...] [+Lang=lng1,lng2,lng3,...] [+SkipFW=Yes|No]" & vbCrLf & _
"install.exe -Help : вызов справки по параметрам командной строки." & vbCrLf & _
vbCrLf & _
"Параметры не чувствительны к регистру." & vbCrLf & _
"Кроме того, их можно впечатывать в имя exe-файла установки, например, ""install +Silent.exe""." & vbCrLf & _
vbCrLf & _
"+NoCompact - не устанавливать приложение в сжатый каталог." & vbCrLf & _
"По умолчанию для экономии места приложение устанавливается в сжатый каталог." & vbCrLf & _
vbCrLf & _
"+Silent - Тихий запуск без графического интерфейса (сообщения о критических" & vbCrLf & _
"ошибках показываются всегда)." & vbCrLf & _
"По умолчанию установщик запускается с диалоговыми окнами." & vbCrLf & _
vbCrLf & _
"+AutoIt - не поддерживается, установка с отображением хода в GUI, но без участия пользователя." & vbCrLf & _
"Инсталятор сразу начинает устанавливать/удалять программу и показывает в" & vbCrLf & _
"графическом интерфейсе ход выполнения, после чего окно закрывается. Как и" & vbCrLf & _
"в случае с +Silent, для этого ключа нужно явно указывать действия" & vbCrLf & _
"+Remove|+Remove=Force|+Inst|+Inst=ResetCFG|+SmartRun. Параметр +Silent и +AutoIt нельзя" & vbCrLf & _
"использовать вместе. " & vbCrLf & _
vbCrLf & _
"+Inst - установка, действие по умолчанию, при переустановке настройки программы" & vbCrLf & _
"сохраняются (поддерживается только данный репак!)" & vbCrLf & _
vbCrLf & _
"+Inst=ResetCFG - при переустановке (т.е. установке ""поверх"") данные обнудяются в" & vbCrLf & _
"значения по умолчанию. Используется для сброса настроек." & vbCrLf & _
vbCrLf & _
"+Remove - удаление приложения." & vbCrLf & _
vbCrLf & _
"+Remove=Force : изменение логики удаления. " & vbCrLf & _
"При удалении проверяются версии уже установленной программы и версии " & vbCrLf & _
"запущенного инсталлятора. Если они разные, то запущенный инсталлятор сам " & vbCrLf & _
"не будет удалять программу, а пользуясь информацией из реестра вызовет " & vbCrLf & _
"программу uninstall, которая уже была установлена. Это сделано потому что " & vbCrLf & _
"разные версии программы могут устанавливаться и удаляться по-разному. " & vbCrLf & _
"Параметр командной строки +Remove=Force меняет это поведение, вызов " & vbCrLf & _
"uninstall не происходит, а установщик своими силами пытается удалить уже " & vbCrLf & _
"существующую программу, даже если номера версий не совпадают. " & vbCrLf & _
vbCrLf & _
"+SmartRun - автоматически выбрать действие - установить или удалить уже " & vbCrLf & _
"существующее приложение. Если приложение уже установлено, то выполнится удаление из " & vbCrLf & _
"системы, в противном случае - установка. Задаёт действие для " & vbCrLf & _
"ключей +Silent и +AutoIt, в GUI установка/удаление выбираются автоматически. " & vbCrLf & _
vbCrLf & _
"+Force86 - в 64-разрядной Windows установить 32-разрядную версию программы." & vbCrLf & _
"По умолчанию установщик сам определяет версию windows и автоматически выбирает" & vbCrLf & _
"32- или 64-разрядный дистрибутив." & vbCrLf & _
vbCrLf & _
"+Final - не поддерживается, изменение логики GUI. С помощью этого параметра  в GUI можно " & vbCrLf & _
"сделать лишь одно действие - установить либо удалить, потом доступен лишь " & vbCrLf & _
"выход из программы. Сделано в основном для Uninstall-GUI. " & vbCrLf & _
vbCrLf & _
"+NoZIP - не упаковывать данные для uninstall в ZIP-архив для экономии места. " & vbCrLf & _
"По умолчанию установщик при инсталляции пытается запаковать всю информацию " & vbCrLf & _
"для удаления в один ZIP-архив. Если задан параметр  +NoZIP, то архивирование " & vbCrLf & _
"заменяется обычным копированием файлов для процедуры uninstall. " & vbCrLf & _
vbCrLf & _
"+SelectPackets=opt,op2,opt3,... - не поддерживается, выбор компонентов устанавливаемого ПО." & vbCrLf & _
"По умолчанию устанавливаются все компоненты." & vbCrLf & _
vbCrLf & _
"+Lang=lng1,lng2,lng3,... -выбор языка установки, если совпадает хоть с одним (самым первым) из" & vbCrLf & _
"lng. При переустановке параметр игнорируется, если не использовать опцию +Inst=ResetCFG." & vbCrLf & _
"Язык для uninstall также будет совпадать с выбранным при установке, если не задать явно." & vbCrLf & _
vbCrLf & _
"+SkipFW=No - не поддерживается. По умолчанию. При (пере)установке и удалении корректируются исключения встроенного в" & vbCrLf & _
"Windows брандмауэра для корректной работы данного приложения. Если брандмауэр предполагается" & vbCrLf & _
"конфигурировать вручную, используйте опцию +SkipFW=Yes, чтобы инсталлятор не менял его параметры." & vbCrLf & _
"В этом случае при удалении и даже при переустановке (если не переопределено в командной строке)" & vbCrLf & _
"настройки брандмауэра также не удаляются." & vbCrLf & _
vbCrLf & _
"В конце установки или при переустановке со сбросом значений (+Inst=ResetCFG) синхронно" & vbCrLf & _
"запускается файл " & distr.regfile & ", если лежит в папке с дистрибутивом. В него" & vbCrLf & _
"можно записать какие-либо дополнительные настройки." & vbCrLf & _
"На последнем шаге установки синхронно запускается " & distr.cmdfile & ", если " & vbCrLf & _
"лежит в папке с дистрибутивом, в него можно записать какие-либо дополнительные " & vbCrLf & _
"действия. Установка считается законченной после выполнения этого файла. " & vbCrLf & _
vbCrLf & _
"домашняя страничка пока здесь:" & vbCrLf & _
distr.homepage  & vbCrLf & vbCrLf

		Set text = objFSO.OpenTextFile (Name, 2, True, 0)
		text.WriteLine s
		text.Close
		Set text = Nothing

		objShell.Run "notepad.exe " & Chr(34) & Name & Chr(34), 1, False

		On Error Goto 0
	End Function 'NotepadHelp



'*******************
	Function ReRun64
	Dim retcode
	ReRun64=-1
	On Error Resume Next

'               b64         bIsWoW64
' ---------------------------------
'x86_orig        0           0
' ---------------------------------
'x64_orig        1           0
'x64_wow64       0           1

'32 - 32-разрядный, в x64 тоже будет работать
'86 - 32-разрядный, но в x64 НЕ УСТАНАВЛИВАЕТСЯ
'64 - только 64-разрядный, нет 32-разрядной версии
'00 - есть 32-разрядная версия и 64-разрядная версия дистрибутива, есть поддержка опции bForce86
'01 - есть 32-разрядная версия и 64-разрядная версия дистрибутива, но опция bForce86 НЕ ПОДДЕРЖИВАЕТСЯ

    Select Case opts.i864Only
    Case 32
        retcode=oSUDO64.x32x64 (2, -1)
    Case 86
        If (b64 Or cnst.bIsWoW64) Then ReRun64=-100 : Exit Function
        retcode=oSUDO64.x32x64 (2, -1)
    Case 64
        If Not (b64 Or cnst.bIsWoW64) Then ReRun64=-101 : Exit Function
        retcode=oSUDO64.x32x64 (3, -1)
    Case 0
        If Not opts.bForce86 Then
            retcode=oSUDO64.x32x64 (3, -1) 'в 64-битной системе будет автоперезапуск в 64-битную среду выполнения из 32-разрядного 7zip_sfx.exe
        Else
            retcode=oSUDO64.x32x64 (2, -1) 'а если использовался ключ +Force86, то перезапуск может понадобиться из uninstall.zip
        End If
    Case 1
        retcode=oSUDO64.x32x64 (3, -1)
    Case Else
        Exit Function      
    End Select

	On Error Goto 0
	ReRun64=retcode
	End Function 'ReRun64



'**********************************************
'***   специфичные этапы установки
'**********************************************



	Function PreSaveCFG
    ' при переустановке сохраняем текущую конфигурацию, чтобы потом восстановить все настройки
	On Error Resume Next
        Dim s
        Err=0

		's=distr.HKLM_App
        's=Right(s, Len(s)-4)
        's="HKEY_LOCAL_MACHINE" & s
		'objShell.Run "regedit.exe /s /e " & Chr(34) & args.ScriptPath & "\HKLM_001.reg " & Chr(34) & _
        '            Chr(34) & s & Chr(34), 0, True

		s=distr.HKCU_App
        s=Right(s, Len(s)-4)
        s="HKEY_CURRENT_USER" & s
		objShell.Run "regedit.exe /s /e " & Chr(34) & args.ScriptPath & "\HKCU_001.reg " & Chr(34) & _
                    Chr(34) & s & Chr(34), 0, True

		PreSaveCFG=False
	On Error Goto 0
    End Function 'PreSaveCFG
'*******************
	Function PostRestoreCFG
    ' при переустановке восстановливаем настройки
	'On Error Resume Next
        Err=0

		'objShell.Run "regedit.exe /s " & Chr(34) & args.ScriptPath & "\HKLM_001.reg " & Chr(34), 0, True
		objShell.Run "regedit.exe /s " & Chr(34) & args.ScriptPath & "\HKCU_001.reg " & Chr(34), 0, True

		PostRestoreCFG=False
	On Error Goto 0
	End Function 'PostRestoreCFG
'*******************
	Function Prog_MakeDirs
    ' создаем все папки для копирования туда приложения и библиотек
	On Error Resume Next
        Err=0
    	Prog_MakeDirs=CBool(Err)
	On Error Goto 0
	End Function 'Prog_MakeDirs
'*******************
	Function Data_MakeDirs
    ' создаем папки, в которых хранятся данные программы
	On Error Resume Next
        Err=0
    	Data_MakeDirs=CBool(Err)
	On Error Goto 0
	End Function 'Data_MakeDirs
'*******************
	Function RenMovFile(FullName)
    Dim IsSameDrive, ShortName, TempFolderPath, NewPath
	On Error Resume Next

    'objFSO.GetTempName
    TempFolderPath=objFSO.GetSpecialFolder(2)
    IsSameDrive=UCase(objFSO.GetDriveName(FullName)) = UCase(objFSO.GetDriveName(TempFolderPath))
    ShortName=objFSO.GetFileName(FullName)

    If IsSameDrive Then
        NewPath=TempFolderPath & "\" & ShortName & "." & objFSO.GetTempName()
        objFSO.DeleteFile NewPath, True
    	objFSO.MoveFile FullName, NewPath
    Else
        NewPath=objFSO.GetParentFolderName(FullName) & "\" & ShortName & "." & objFSO.GetTempName()
        objFSO.DeleteFile NewPath, True
    	objFSO.MoveFile FullName, NewPath
    End If

	On Error Goto 0
	End Function 'RenMovFile
'*******************
	Function DirectoryPrepare
    Dim cmdstr
	On Error Resume Next
    'всегда предполагаем, что при установке эти DLL сначала надо попытаться стереть!

    'перед копированием по возможности попробуем удалить эти файлы (если они не используются):
    If objFSO.FolderExists (cnst.strPgmFilesDir & "\" & cnst.folder) Then
        'останавливают удаление на первом же захваченном файле, поэтому не подходят:
        'objFSO.DeleteFile cnst.strPgmFilesDir & "\" & cnst.folder & "\*.exe", True
        'objFSO.DeleteFile cnst.strPgmFilesDir & "\" & cnst.folder & "\*.dll", True

        cmdstr="cmd.exe /cDEL /F /Q """ & cnst.strPgmFilesDir & "\" & cnst.folder & "\*.exe""" & " """ & cnst.strPgmFilesDir & "\" & cnst.folder & "\*.dll"""
    	objShell.Run cmdstr, 0, True

        cmdstr=cnst.strPgmFilesDir & "\" & cnst.folder & "\x86\Hooker.dll"
        If objFSO.FileExists (cmdstr) Then RenMovFile cmdstr
        cmdstr=cnst.strPgmFilesDir & "\" & cnst.folder & "\x64\Hooker.dll"
        If objFSO.FileExists (cmdstr) Then RenMovFile cmdstr
        cmdstr=cnst.strPgmFilesDir & "\" & cnst.folder & "\x86\HookerWatcher.exe"
        If objFSO.FileExists (cmdstr) Then RenMovFile cmdstr
        cmdstr=cnst.strPgmFilesDir & "\" & cnst.folder & "\x64\HookerWatcher.exe"
        If objFSO.FileExists (cmdstr) Then RenMovFile cmdstr

        cmdstr=cnst.strPgmFilesDir & "\" & cnst.folder & "\KeyboardLayoutMonitor.exe"
        If objFSO.FileExists (cmdstr) Then RenMovFile cmdstr

    	objFSO.DeleteFolder cnst.strPgmFilesDir & "\" & cnst.folder, True
    	'objShell.Run  "rundll32.exe advpack.dll,DelNodeRunDLL32 " & cnst.strPgmFilesDir & "\" & cnst.folder, 0, True
    End If

	On Error Goto 0
	End Function 'DirectoryPrepare
'*******************
	Function Prog_CopyFiles
    ' копирование выполняемых файлов приложения и библиотек (кроме системы uninstall)
    ' по возможности копирование заменяем на перемещение (с последующей правкой ACL)
    ' objFSO.MoveFolder method allows moving folders inside volumes only

    Dim Arch
	On Error Resume Next

    ' предположим, что процессы старого репака так и не были остановлены:
    PSKill
    ' затем удалим папку в Program Files (или переименуем DLL/EXE, чтобы не мешались)
    DirectoryPrepare

    Err=0
    Arch=UCase(objFSO.GetDriveName(args.ScriptPath)) = UCase(objFSO.GetDriveName(cnst.strPgmFilesDir))

    If Arch Then
        'If b64 Then Arch="64" Else Arch="32"
        Arch="32"
    	objFSO.MoveFolder  args.ScriptPath & "\" & Arch & "\" & "pf" & "\" & cnst.folder, cnst.strPgmFilesDir & "\"
    	'objFSO.MoveFile    args.ScriptPath & "\" & Arch & "\" & "sys\*.*", cnst.strSys32Dir & "\"
    	'objFSO.MoveFolder  args.ScriptPath & "\" & "doc", cnst.strPgmFilesDir & "\" & cnst.folder & "\"
    	'objFSO.MoveFolder  args.ScriptPath & "\" & "languages", cnst.strPgmFilesDir & "\" & cnst.folder & "\"
    Else
        'If b64 Then Arch="64" Else Arch="32"
        Arch="32"
    	objFSO.CopyFolder  args.ScriptPath & "\" & Arch & "\" & "pf" & "\" & cnst.folder, cnst.strPgmFilesDir & "\"
    	'objFSO.CopyFile    args.ScriptPath & "\" & Arch & "\" & "sys\*.*", cnst.strSys32Dir & "\"
    	'objFSO.CopyFolder  args.ScriptPath & "\" & "doc", cnst.strPgmFilesDir & "\" & cnst.folder & "\"
    	'objFSO.CopyFolder  args.ScriptPath & "\" & "languages", cnst.strPgmFilesDir & "\" & cnst.folder & "\"
    End If

    Prog_CopyFiles=CBool(Err)
	On Error Goto 0
	End Function 'Prog_CopyFiles
'*******************
	Function Data_CopyFiles
    ' копирование файлов данных приложения
	On Error Resume Next
        Dim s
        s=UCase(objFSO.GetDriveName(args.ScriptPath))   =   UCase(objFSO.GetDriveName(cnst.strPgmFilesDir))

        Err=0
        'If s Then
        '	objFSO.MoveFile  args.ScriptPath & "\data\" & 
        'Else
        '	objFSO.CopyFile  args.ScriptPath & "\data\" & 
        'End If
        Data_CopyFiles=CBool(Err)
	On Error Goto 0
	End Function 'Data_CopyFiles
'*******************
	Function SetACL
    ' установка разрешений файловой системы
	On Error Resume Next
        Dim s
        Err=0
        s=UCase(objFSO.GetDriveName(args.ScriptPath))   =   UCase(objFSO.GetDriveName(cnst.strPgmFilesDir))
        If s Then
            'после Move из папки TEMP администратора нужно удалить все унаследованные оттуда разрешения и
            'восстановить разрешения, наследуемые от папки Program Files
            s="cmd.exe /cICACLS.EXE " & """" & cnst.strPgmFilesDir & "\" & cnst.folder & """" & " /reset /T /C"
        	objShell.Run s, 0, True
        End If
        SetACL=CBool(Err)
	On Error Goto 0
	End Function 'SetACL
'*******************
	Function RegAdd
    ' данные реестра  (кроме uninstall)
	On Error Resume Next
        Dim HKLM, HKCU
        Err=0
		objShell.RegWrite "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\KeyboardLayoutMonitor", """" & cnst.strPgmFilesDir & "\" & cnst.folder & "\KeyboardLayoutMonitor.exe"""
        RegAdd=CBool(Err)
	On Error Goto 0
	End Function 'RegAdd
'*******************
	Function MakeLinks
    ' создание ярлыков (кроме uninstall)
	On Error Resume Next
        Err=0
        Dim sLinkPath, oLNK, s
        sLinkPath = objShell.SpecialFolders("AllUsersPrograms")

' AllUsersDesktop
' Desktop
' AllUsersStartMenu
' StartMenu
' AllUsersPrograms
' Programs
' AllUsersStartup
' Startup
' Favorites
' Fonts
' MyDocuments
' SendTo
' ---------------------------------
' WindowStyle:
' 1 Activates and displays a window. If the window is minimized or maximized, the system restores it to its original size and position.
' 3 Activates the window and displays it as a maximized window.
' 7 Minimizes the window and activates the next top-level window.


        'sLinkPath=sLinkPath & "\" & distr.sLnkParentDir : objFSO.CreateFolder sLinkPath


        sLinkPath=sLinkPath & "\" & distr.sLnkDir : objFSO.CreateFolder sLinkPath


        'C:\Windows\System32\rundll32.exe url.dll,FileProtocolHandler http://www.ntwind.com/software/windowspace.html
        Set oLNK = objShell.CreateShortcut(sLinkPath & "\" & "Keyboard Layout Monitor Home Page.lnk")
        oLNK.TargetPath = cnst.strSys32Dir & "\rundll32.exe"
        oLNK.Arguments = "url.dll,FileProtocolHandler https://github.com/evgen-b/kelamon"
        oLNK.Description = "Very Suspicious Keyboard Layout Monitor"
        'oLNK.HotKey = ""
        oLNK.IconLocation = cnst.strPgmFilesDir & "\Internet Explorer\IEXPLORE.EXE"
        oLNK.WindowStyle = 1
        oLNK.WorkingDirectory = cnst.strSys32Dir
        oLNK.Save
        Set oLNK = Nothing

        'C:\Windows\System32\rundll32.exe url.dll,FileProtocolHandler https://rutracker.org/forum/tracker.php?nm=Aero%20Glass
        Set oLNK = objShell.CreateShortcut(sLinkPath & "\" & "RePack Home Page.lnk")
        oLNK.TargetPath = cnst.strSys32Dir & "\rundll32.exe"
        oLNK.Arguments = "url.dll,FileProtocolHandler https://rutracker.org/forum/tracker.php?nm=Aero%20Glass" ' & distr.homepage
        oLNK.Description = "Open in browser"
        'oLNK.HotKey = ""
        oLNK.IconLocation = cnst.strPgmFilesDir & "\Internet Explorer\IEXPLORE.EXE"
        oLNK.WindowStyle = 1
        oLNK.WorkingDirectory = cnst.strSys32Dir
        oLNK.Save
        Set oLNK = Nothing

        'sLinkPath=sLinkPath & "\" & distr.sLnkDir : objFSO.CreateFolder sLinkPath

        Err=0

        'для корректного запуска некоторых 32-битных приложений в 64-битной Windows
        'в ярлыках нужно вручную выставлять syswow64 вместо system32, т.к. ОС автоматически
        'это не делает почему-то, в отличие от обработки папки "program files (x86)"

        'If cnst.bIsWoW64 Then s=cnst.strWinDir & "\SysWOW64" Else s=cnst.strSys32Dir

        Set oLNK = objShell.CreateShortcut(sLinkPath & "\" & "Keyboard Layout Monitor Settings.lnk")
        oLNK.TargetPath = cnst.strPgmFilesDir & "\" & cnst.folder & "\" & "KeyboardLayoutMonitor.exe"
        oLNK.Arguments = "-auto"
        oLNK.Description = "Tune Keyboard Layout Monitor"
        'oLNK.IconLocation = cnst.strPgmFilesDir & "\" & cnst.folder & "\" & "KeyboardLayoutMonitor.exe"
        oLNK.IconLocation = cnst.strSys32Dir & "\SHELL32.dll, 130"
        oLNK.WindowStyle = 1
        oLNK.WorkingDirectory = cnst.strPgmFilesDir & "\" & cnst.folder
        oLNK.Save
        Set oLNK = Nothing

        Set oLNK = objShell.CreateShortcut(sLinkPath & "\" & "Keyboard Layout Monitor Help (rus).lnk")
        oLNK.TargetPath = cnst.strWinDir & "\" & "explorer.exe"
        oLNK.Arguments = """" & cnst.strPgmFilesDir & "\" & cnst.folder & "\" & "about.mht" & """"
        oLNK.Description = "Keyboard Layout Monitor Help"
        oLNK.IconLocation = cnst.strPgmFilesDir & "\Internet Explorer\IEXPLORE.EXE"
        oLNK.WindowStyle = 1
        oLNK.WorkingDirectory = cnst.strPgmFilesDir & "\" & cnst.folder
        oLNK.Save
        Set oLNK = Nothing




        MakeLinks=CBool(Err)
	On Error Goto 0
	End Function 'MakeLinks
'*******************
	Function DoInitial
    ' регистрация OCX, запуск настройщиков итп
	On Error Resume Next
        Err=0
    	'objShell.Run """" & cnst.strSys32Dir & "\regsvr32.exe"" /s """ & cnst.strPgmFilesDir & "\" & cnst.folder & "\sample.OCX""", 0, True
        DoInitial=CBool(Err)
	On Error Goto 0
	End Function 'DoInitial
'*******************
	Function AutoRunApplication
    ' если в самом конце установки перед самым выходом из инсталлятора нужно запустить программу
    ' например в трее такую как WindowSpace, то здесь самое подходящее место.
	On Error Resume Next
        Dim cmdstr
        Err=0

        'это не работает без магии:
    	'objShell.Run """" & cnst.strPgmFilesDir & "\" & cnst.folder & "\wspace.exe"" /install", 0, False

        'такой запуск работает:
        'cmdstr="""" & cnst.strPgmFilesDir & "\" & cnst.folder & "\KeyboardLayoutMonitor.exe"""
        'cmdstr="""" & "CD """ & cnst.strWinDir & """ && START ""1"" " & cmdstr & """"
        'cmdstr="cmd.exe /c" & cmdstr
        ' cd c:\windows - чтобы не запускать в контексте временной директории 7zsfx, которую нужно за собой стереть

        'небольшая вариация предыдущего примера - в UAC запускаем с минимальными правами:
        cmdstr="""" & cnst.strPgmFilesDir & "\" & cnst.folder & "\KeyboardLayoutMonitor.exe"""
        cmdstr="""" & "CD """ & cnst.strWinDir & """ & explorer.exe " & cmdstr & """"
        cmdstr="cmd.exe /c" & cmdstr
        'если, конечно, не включили наследование прав проводником у Вадима Стеркина

        'inputbox cmdstr, cmdstr, cmdstr

        'cmd.exe /c"START "1" "C:\Program Files\WindowSpace\wspace.exe" /install"
    	objShell.Run  cmdstr, 0, False
        AutoRunApplication=CBool(Err)
	On Error Goto 0
	End Function 'AutoRunApplication
'*******************
	Function SetFW
    ' установка исключений во встроенном в ОС файрволе
	'On Error Resume Next
    If Not opts.bSkipFW Then
        'Do Nothing
    End If
    SetFW=False
	On Error Goto 0
	End Function 'SetFW
'*******************
	Function Localize
    ' локализация ресурсов
    Dim cmdstr
	On Error Resume Next
        Err=0
        cmdstr=UCase(objFSO.GetDriveName(args.ScriptPath))   =   UCase(objFSO.GetDriveName(cnst.strPgmFilesDir))
        Select Case GetLangInteger()
        Case &h0419
    		'   objShell.RegWrite distr.HKCU_App & "\2.5\LangFile", "Russian"
        Case Else
            'english - Do Nothing
        End Select
        Localize=CBool(Err)
	On Error Goto 0
	End Function 'Localize
'*******************
Function CompactFolder(intStep)
' установка в сжатый каталог, добавление исключений, например, для лога (т.к. постоянно обновляется) и анинсталла (т.к. уже сжат в zip)
On Error Resume Next
Dim s
If Not opts.bCompact Then CompactFolder=False : Exit Function
Err=0

' compact.exe /i /c /a /s:"folder path"
' compact.exe /i /u /a /s:"folder path"
' compact.exe /i /c /a "file name"
' compact.exe /i /u /a "file name"

Select Case intStep
    Case 1
        ' сначала пакуем наиболее плотным методом сжатия
        s="cmd.exe /cCOMPACT.EXE /f /i /c /a /EXE:LZX /s:" & """" & cnst.strPgmFilesDir & "\" & cnst.folder & """"
        objShell.Run s, 0, True
        ' потом только маркируем каталоги флагом сжатия для всех новых помещаемых туда файлов
        s="cmd.exe /cCOMPACT.EXE /i /c /a /s:" & """" & cnst.strPgmFilesDir & "\" & cnst.folder & """"
        objShell.Run s, 0, True
        'исключения:
        s="cmd.exe /cCOMPACT.EXE /i /u /a " & """" & cnst.strPgmFilesDir & "\" & cnst.folder & "\" & cnst.sZipArch & """"
        objShell.Run s, 0, True
    Case 2
        'второе этап (пустой) и т.д.
    Case Else
    CompactFolder=True : Exit Function
End Select

CompactFolder=CBool(Err)
On Error Goto 0
End Function 'CompactFolder
'*******************



'**********************************************
'***   специфичные этапы удаления
'**********************************************



	Function PSKill()
    ' Убиваем процессы
	On Error Resume Next
        Dim e, stat, NotRunning, cmdstr

        ' сначала попробуем прибить штатными средствами
        stat=-1
        stat=IsProcRuning ("KeyboardLayoutMonitor.exe")
        NotRunning=CBool(stat)
        If stat=0 Then
            cmdstr="""" & cnst.strPgmFilesDir & "\" & cnst.folder & "\" & "KeyboardLayoutMonitor.exe" & """" & " -quit"
            cmdstr="cmd.exe /c" & cmdstr
        	objShell.Run cmdstr, 0, True
            'WScript.Sleep 500
        End If

        stat=-1
        stat=IsProcRuning ("HookerWatcher.exe")
        NotRunning=CBool(stat)
        If stat=0 Then
            cmdstr="taskkill.exe /f /im HookerWatcher.exe"
            cmdstr="cmd.exe /c" & cmdstr
        	objShell.Run cmdstr, 0, True
            'WScript.Sleep 500
        End If

        stat=-1
        stat=IsProcRuning ("KeyboardLayoutMonitor.exe")
        NotRunning=CBool(stat)
        If stat=0 Then
            cmdstr="taskkill.exe /f /im KeyboardLayoutMonitor.exe"
            cmdstr="cmd.exe /c" & cmdstr
        	objShell.Run cmdstr, 0, True
            'WScript.Sleep 500
        End If

        'надо хотя бы предполагать, что при установке сначала надо попытаться стереть предыдущие DLL/EXE.

        Err=0
        e=e Or CBool(Err)
        PSKill=CBool(e)
	On Error Goto 0
	End Function 'PSKill
'*******************
	Function IsProcRuning(strProcName)
    'если процесс запущен, возвращаем 0, иначе 128
    Dim objWMIService, colProc, objProc, Found
	On Error Resume Next
    Set objWMIService=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") 
    Set colProc=objWMIService.ExecQuery("Select * from Win32_Process")
    Found=False
    For Each objProc in colProc
    If UCase(objProc.Name) = UCase(strProcName) Then
        Found=True
        'WScript.Echo "PID:  " & objProc.Handle
        'WScript.Echo "IMG:  " & objProc.ExecutablePath & vbCrLf & "CMD:  " & objProc.CommandLine
        Exit For
    End If
    Next
    If Found Then IsProcRuning=0 Else IsProcRuning=128
	On Error Goto 0
	End Function 'IsProcRuning
'*******************
	Function DelACL
    ' возвращаем разрешения файловой системы как было или чтобы удалить файлы
    DelACL=False
	End Function 'DelACL
'*******************
	Function Prog_DelFiles
	' удаление выполняемых файлов приложения и библиотек (возможно, кроме системы uninstall)
	On Error Resume Next
        Err=0
        DirectoryPrepare

    	'objFSO.DeleteFolder     cnst.strPgmFilesDir & "\" & cnst.folder, True
        'более брутально:
    	objShell.Run  "rundll32.exe advpack.dll,DelNodeRunDLL32 " & cnst.strPgmFilesDir & "\" & cnst.folder, 0, True

        Prog_DelFiles=CBool(Err)
	On Error Goto 0
	End Function 'Prog_DelFiles
'*******************
    Function Data_DelFiles
    ' удаление файлов данных приложения
	On Error Resume Next
	On Error Goto 0
    Data_DelFiles=False
    End Function 'Data_DelFiles
'*******************
	Function RegDel
    ' удаление данных приложения из реестра  (не относится к uninstall)
	On Error Resume Next
        Dim s
        Err=0
        'oReg.DelRegKey(distr.HKLM_App)
        oReg.DelRegKey(distr.HKCU_App) ' вообще-то нужно для каждого юзера удалять

        RegDel=CBool(Err)

		objShell.RegDelete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\KeyboardLayoutMonitor" 'не проверяем это удаление на ошибки
	On Error Goto 0
	End Function 'RegDel
'*******************
	Function DelLinks
    ' удаление ярлыков (кроме uninstall)
	On Error Resume Next
        Err=0
        Dim sLinkPath, oSubFolders
        sLinkPath = objShell.SpecialFolders("AllUsersPrograms")

' AllUsersDesktop
' Desktop
' AllUsersStartMenu
' StartMenu
' AllUsersPrograms
' Programs
' AllUsersStartup
' Startup
' Favorites
' Fonts
' MyDocuments
' SendTo

        'sLinkPath=sLinkPath & "\" & distr.sLnkParentDir
        sLinkPath=sLinkPath & "\" & distr.sLnkDir
    	objFSO.DeleteFolder sLinkPath, True
        DelLinks=CBool(Err)
	On Error Goto 0
	End Function 'DelLinks
'*******************
	Function ClearFW
    ' очистка исключений во встроенном в ОС файрволе
	'On Error Resume Next
    If Not opts.bSkipFW Then
        'Do Nothing
    End If
    ClearFW=False
	On Error Goto 0
	End Function 'ClearFW



'**********************************************
'***   основная процедура
'**********************************************



Function Action
Dim bProblem, bIsReinstall, retcode

retcode=Check()
If retcode=-1 Then Action=101 : Exit Function

If Not cnst.bAdminAfterUAC Then
    Action=102
    oWriteCallBack.Draw 0, 0, 0
    oWriteCallBack.Draw 0, 1, 1001
    Exit Function
End If

Select Case intAction
	Case 1 'install
		If retcode<>0 Then
            'запустить диалог на переустановку
            bIsReinstall=True
			retcode=vbOK
			If Not opts.bSilent Then retcode=Dlg_Reinst
			If retcode=vbCancel Then Action=24 : Exit Function
            If Not opts.bResetCFG Then PreSaveCFG
            CallExternalUninst
			retcode=Check()
            If retcode<>0 Then
                If Not opts.bSilent Then Dlg_CantExtRemove
                Action=25 : Exit Function
            End If
        Else
            'обычный дилог
            bIsReinstall=False
			retcode=vbOK
			If Not opts.bSilent Then retcode=Dlg_Install
			If retcode=vbCancel Then Action=21 : Exit Function
		End If

		'Action=21 : Exit Function

        retcode=Prog_MakeDirs
		'If retcode Then Action=103 : Exit Function
        retcode=Data_MakeDirs
		'If retcode Then Action=103 : Exit Function

        If Not bCanNotZIP_os And Not opts.bNoZIP Then ZipScript1

        retcode=Prog_CopyFiles
		If retcode Then Action=104 : Prog_DelFiles : Exit Function

        retcode=Data_CopyFiles
		If retcode Then Action=105 : Data_DelFiles : Prog_DelFiles : Exit Function

        If Not bCanNotZIP_os And Not opts.bNoZIP Then ZipScript2 'значение CanNotZIP_os может измениться в ZipScript2
        If bCanNotZIP_os And (cnst.intWinVer > 5.0) Then
            oWriteCallBack.Draw 0, 0, 0
            oWriteCallBack.Draw 0, 0, -1001
        End If

        retcode=MakeLinks
		If retcode Then Action=107 : DelLinks : Data_DelFiles : Prog_DelFiles : Exit Function

        retcode=CompactFolder(1)

        retcode=RegAdd
		If retcode Then Action=108 : RegDel : DelLinks : Data_DelFiles : Prog_DelFiles : Exit Function

        retcode=AddRegUninst
		If retcode Then Action=109 : DelRegUninst : RegDel : DelLinks : Data_DelFiles : Prog_DelFiles : Exit Function

        retcode=AddLnkUninst
		If retcode Then Action=110 : DelLnkUninst : DelRegUninst : RegDel : DelLinks : Data_DelFiles : Prog_DelFiles : Exit Function

        retcode=DoInitial
		If retcode Then Action=111 : PSKill : DelLnkUninst : DelRegUninst : RegDel : DelLinks : Data_DelFiles : Prog_DelFiles : Exit Function

        If Not bCanNotZIP_os And Not opts.bNoZIP Then retcode=MakeUninstVBS : retcode=retcode Or ZipScript3 Else retcode=CopyScript
		If retcode Then Action=112 : PSKill : DelLnkUninst : DelRegUninst : RegDel : DelLinks : Data_DelFiles : Prog_DelFiles : Exit Function

        ClearFW : SetFW ' чистим все записи брандмауэра и устанавливаем полные разрешения

        If (Not opts.bResetCFG) And bIsReinstall Then PostRestoreCFG() Else Localize()

        retcode=SetACL
		If retcode Then Action=113 : DelACL : PSKill : DelLnkUninst : DelRegUninst : RegDel : DelLinks : Data_DelFiles : Prog_DelFiles : Exit Function

        RunCMDAfterInstall(bIsReinstall)

        AutoRunApplication

        If Not opts.bSilent Then
            If bIsReinstall Then Dlg_Reinst_End() Else Dlg_Install_End()
        End If

	Case 2 'remove
        'MsgBox "=remove="
		If (retcode <> 1) Then Action=22 : Exit Function

		retcode=vbOK
        If Not opts.bSilent Then retcode=Dlg_Uninst
		If retcode=vbCancel Then Action=23 : Exit Function
	
        retcode=""
		On Error Resume Next
    	retcode=objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aDisplayVersion)
    	On Error Goto 0
        If (GetExpVer() <> retcode) And Not opts.bForceRemove Then
            'MsgBox "CallRemove"
            oWriteCallBack.Draw 1, 0, 0
            CallExternalUninst
            oWriteCallBack.Draw 4, 1, 0
        Else
            'MsgBox "InstantRemove"
            ClearFW

            oWriteCallBack.Draw 1, 0, 0
            retcode=PSKill
            If retcode Then oWriteCallBack.Draw 1, 1, 1 Else oWriteCallBack.Draw 1, 1, 0
            bProblem=retcode
    		
            oWriteCallBack.Draw 2, 0, 0
            retcode=DelACL
            If retcode Then oWriteCallBack.Draw 2, 1, 1 Else oWriteCallBack.Draw 2, 1, 0
            bProblem=retcode Or bProblem

            oWriteCallBack.Draw 3, 0, 0
            retcode=Prog_DelFiles
            If retcode Then oWriteCallBack.Draw 3, 1, 1 Else oWriteCallBack.Draw 3, 1, 0
            bProblem=retcode Or bProblem

            oWriteCallBack.Draw 4, 0, 0
            retcode=Data_DelFiles
            If retcode Then oWriteCallBack.Draw 4, 1, 1 Else oWriteCallBack.Draw 4, 1, 0
            bProblem=retcode Or bProblem

            oWriteCallBack.Draw 5, 0, 0
            retcode=RegDel
            If retcode Then oWriteCallBack.Draw 5, 1, 1 Else oWriteCallBack.Draw 5, 1, 0
            bProblem=retcode Or bProblem

            oWriteCallBack.Draw 6, 0, 0
            retcode=DelLinks
            If retcode Then oWriteCallBack.Draw 6, 1, 1 Else oWriteCallBack.Draw 6, 1, 0
            bProblem=retcode Or bProblem

            oWriteCallBack.Draw 7, 0, 0
            retcode=DelLnkUninst
            If retcode Then oWriteCallBack.Draw 7, 1, 1 Else oWriteCallBack.Draw 7, 1, 0
            bProblem=retcode Or bProblem

            oWriteCallBack.Draw 8, 0, 0
            retcode=DelRegUninst
            If retcode Then oWriteCallBack.Draw 8, 1, 1 Else oWriteCallBack.Draw 8, 1, 0
            bProblem=retcode Or bProblem

            If Not opts.bSilent Then
    		    If (bProblem) Then
                    Dlg_Uninst_Error
                Else
                    Dlg_Uninst_End
                End If
    		End If
    
  		End If '(GetExpVer() <> retcode) And Not opts.bForceRemove
		On Error Goto 0
	Case 3 'при вызове внутренностей uninstall.zip из планировщика (обслуживание программы, например, чистка мусора)
        'ScheduleTask
	Case 4 'помощь
        NotepadHelp
	Case Else
		'do nothing
End Select
Action=0
End Function 'Action



'**********************************************
'***   диалоги
'**********************************************



	Function Dlg_Install
	On Error Resume Next
    Dim x : If b64 Then x="x64" Else x="x86"
    Dim retcode, msg, ttl
Select Case GetLangInteger()
Case &h0419
        msg=Chr(9) & "Установить " & vbCrLf & Chr(9) & distr.dispname & "?"
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Индикатор раскладки клавиатуры цветом"
        msg=msg & vbCrLf & Chr(9) & "панели задач и заголовка окна в Windows"
        msg=msg & vbCrLf & Chr(9) & "Vista, 7, 8, 8.1, 10, 2008/R2/2012/R2/2016."
        msg=msg & vbCrLf & vbCrLf & vbCrLf & Chr(9) & "Версия сборки " & GetExpVer()
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "[сохранение настроек файрвола]"
Case Else
        msg=Chr(9) & "Are You shure You want to install" & vbCrLf & _
        Chr(9) & distr.dispname & "?"
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "A keyboard layout indicator for Windows 7+"
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Version " & GetExpVer()
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "[Don't clear Windows Firewall settings for application]"
End Select
        ttl=distr.dispname & " " & distr.AppVer & " " & x
        retcode=MsgBox (msg, vbQuestion + vbOKCancel, ttl)
    Dlg_Install=retcode
	On Error Goto 0
	End Function 'Dlg_Install
'*******************
	Function Dlg_Install_End
	On Error Resume Next
    Dim x : If b64 Then x="x64" Else x="x86"
    Dim retcode, msg, ttl
Select Case GetLangInteger()
Case &h0419
        msg=Chr(9) & "Приложение установлено:" & vbCrLf & Chr(9) & distr.dispname
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Версия сборки " & GetExpVer()
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "[сохранение настроек файрвола]"
        If opts.bNeedReboot Then msg=msg & vbCrLf & Chr(9) & "(Перезагрузите компьютер для настройки шрифтов!)"
Case Else
        msg=Chr(9) & "Application installed:" & vbCrLf & Chr(9) & distr.dispname
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Version " & GetExpVer()
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "[Don't clear Windows Firewall settings for application]"
        If opts.bNeedReboot Then msg=msg & vbCrLf & Chr(9) & "(Please reboot Your computer!)"
End Select
        ttl=distr.dispname & " " & distr.AppVer & " " & x
        retcode=objShell.Popup (msg, opts.intUntimer, ttl, vbInformation + vbOKOnly)
    Dlg_Install_End=retcode
	On Error Goto 0
	End Function 'Dlg_Install_End
'*******************
	Function Dlg_Reinst
	On Error Resume Next
    Dim x : If b64 Then x="x64" Else x="x86"
    Dim olddispname, oldver, olddate, olduser
    Dim retcode, msg, ttl
        oldver="unknown" : olddispname=oldver : olddate=oldver : olduser=oldver
		olddispname = objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aDisplayName)
        oldver      = objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aDisplayVersion)
		olduser     = objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aAdvinf_InstUser)
        olddate     = objShell.RegRead (cnst.UninstRegPath & "\" & cnst.aAdvinf_InstDate)
Select Case GetLangInteger()
Case &h0419
        msg="В системе уже установлено приложение" & vbCrLf & olddispname & ":" & vbCrLf & _
            Chr(9) & "> версия " & oldver & vbCrLf & _
            Chr(9) & "> установлено " & olddate & vbCrLf & _
            Chr(9) & "> установил " & olduser
        ' current package futures:
        msg=msg & vbCrLf & "Параметры текущей сборки:" & vbCrLf & _
            Chr(9) & "> версия " & GetExpVer()
        ttl=distr.dispname & " " & distr.AppVer & " " & x
        If opts.bResetCFG Then
            ttl = ttl & " [Reset]"
            msg=msg & vbCrLf & Chr(9) & "> режим сброса настроек программы"
        Else
            msg=msg & vbCrLf & Chr(9) & "> режим сохранения существующих настроек"
        End If
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "> сохранение настроек файрвола"
        msg=msg & vbCrLf & vbCrLf & "Для продолжения установки приложение будет удалено."
Case Else
        msg=olddispname & vbCrLf & " already installed:" & vbCrLf & _
            Chr(9) & "> used version " & oldver & vbCrLf & _
            Chr(9) & "> installed date " & olddate & vbCrLf & _
            Chr(9) & "> installed by " & olduser
        ' current package futures:
        msg=msg & vbCrLf & "This software You want to setup:" & vbCrLf & _
            Chr(9) & "> version " & GetExpVer()
        ttl=distr.dispname & " " & distr.AppVer & " " & x
        If opts.bResetCFG Then
            ttl = ttl & " [Reset]"
            msg=msg & vbCrLf & Chr(9) & "> reset current configuration settings to default"
        Else
            msg=msg & vbCrLf & Chr(9) & "> preserve current configuration settings"
        End If
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "> preserve Windows Firewall settings for application"
        msg=msg & vbCrLf & vbCrLf & "To continue setup, old application will be removed."
End Select
        retcode=MsgBox (msg, vbQuestion + vbOKCancel, ttl)
    Dlg_Reinst=retcode
	On Error Goto 0
	End Function 'Dlg_Reinst
'*******************
	Function Dlg_Reinst_End
	On Error Resume Next
    Dim x : If b64 Then x="x64" Else x="x86"
    Dim retcode, msg, ttl
Select Case GetLangInteger()
Case &h0419
        msg=Chr(9) & distr.dispname & vbCrLf & Chr(9) & " переустановлено."
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Параметры текущей сборки:" & vbCrLf & _
            Chr(9) & "    > версия " & GetExpVer()
        ttl=distr.dispname & " " & distr.AppVer & " " & x
        If opts.bResetCFG Then
            ttl = ttl & " [Reset]"
            msg=msg & vbCrLf & Chr(9) & "    > режим сброса настроек программы"
        Else
            msg=msg & vbCrLf & Chr(9) & "    > режим сохранения существующих настроек"
        End If
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "    > сохранение настроек файрвола"
        If opts.bNeedReboot Then msg=msg & vbCrLf & Chr(9) & "(Перезагрузите компьютер для настройки шрифтов!)"
Case Else
        msg=Chr(9) & distr.dispname & vbCrLf & Chr(9) & " re-installed."
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Used setup options:" & vbCrLf & _
            Chr(9) & "    > Version " & GetExpVer()
        ttl=distr.dispname & " " & distr.AppVer & " " & x
        If opts.bResetCFG Then
            ttl = ttl & " [Reset]"
            msg=msg & vbCrLf & Chr(9) & "    > reset current configuration settings to default"
        Else
            msg=msg & vbCrLf & Chr(9) & "    > preserve current configuration settings"
        End If
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "    > preserve Windows Firewall settings for application"
        If opts.bNeedReboot Then msg=msg & vbCrLf & Chr(9) & "(Please reboot Your computer!)"
End Select
    retcode=objShell.Popup (msg, opts.intUntimer, ttl, vbInformation + vbOKOnly)
    Dlg_Reinst_End=retcode
	On Error Goto 0
	End Function 'Dlg_Reinst_End
'*******************
	Function Dlg_Uninst
	On Error Resume Next
    Dim x : If b64 Then x="x64" Else x="x86"
    Dim retcode, msg, ttl
Select Case GetLangInteger()
Case &h0419
        msg=Chr(9) & "Вы действительно хотите удалить" & vbCrLf & _
            Chr(9) & distr.dispname & vbCrLf & _
            Chr(9) & "и все компоненты программы?"
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Версия сборки " & GetExpVer()
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "[сохранение настроек файрвола]"
        ttl=distr.dispname & " " & distr.AppVer & " " & x
Case Else
        msg=Chr(9) & "Are You sure to completely remove" & vbCrLf & _
            Chr(9) & distr.dispname & vbCrLf & _
            Chr(9) & "and all its components?"
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Version " & GetExpVer()
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "[Don't clear Windows Firewall settings for application]"
        ttl=distr.dispname & " " & distr.AppVer & " " & x
End Select
        retcode=MsgBox (msg, vbQuestion + vbOKCancel, ttl)
    Dlg_Uninst=retcode
	On Error Goto 0
	End Function 'Dlg_Uninst
'*******************
	Function Dlg_Uninst_End
	'On Error Resume Next
    Dim x : If b64 Then x="x64" Else x="x86"
    Dim retcode, msg, ttl
Select Case GetLangInteger()
Case &h0419
        msg=Chr(9) & distr.dispname & vbCrLf & Chr(9) & " удалено."
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Версия сборки " & GetExpVer()
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "[сохранение настроек файрвола]"
Case Else
        msg=Chr(9) & distr.dispname & vbCrLf & Chr(9) & " removed."
        msg=msg & vbCrLf & vbCrLf & Chr(9) & "Version " & GetExpVer()
        If opts.bSkipFW Then msg=msg & vbCrLf & Chr(9) & "[Don't clear Windows Firewall settings for application]"
End Select
        ttl=distr.dispname & " " & distr.AppVer & " " & x
        retcode=objShell.Popup (msg, opts.intUntimer, ttl, vbInformation + vbOKOnly)
    Dlg_Uninst_End=retcode
	On Error Goto 0
	End Function 'Dlg_Uninst_End
'*******************
	Function Dlg_Uninst_Error
	'On Error Resume Next
    Dim x : If b64 Then x="x64" Else x="x86"
    Dim retcode, msg, ttl
Select Case GetLangInteger()
Case &h0419
        msg="При удалении возникли проблемы." & vbCrLf & _
			"Бегом к сисьодмину!!!111"
        msg=msg & vbCrLf & vbCrLf & "Версия сборки " & GetExpVer()
Case Else
        msg="Some issues occurred while removing application." & vbCrLf & _
			"Contact your system administrator."
        msg=msg & vbCrLf & vbCrLf & "Version " & GetExpVer()
End Select
        ttl=distr.dispname & " " & distr.AppVer & " " & x
        retcode=objShell.Popup (msg, opts.intUntimer+4, ttl, 0 + 64)
    Dlg_Uninst_Error=retcode
	On Error Goto 0
	End Function 'Dlg_Uninst_Error
'*******************
	Function Dlg_CantExtRemove
	'On Error Resume Next
    Dim x : If b64 Then x="x64" Else x="x86"
    Dim retcode, msg, ttl
Select Case GetLangInteger()
Case &h0419
        msg="При удалении существующей версии возникли проблемы." & vbCrLf & _
			"Отчет сформирован и отправлен в ближайшее отделение ФСБ." & vbCrLf & _
            "Никуда не выходите, за Вами уже выехали." & vbCrLf & _
            "Благодарим за использование нашего ПО, удачного дня!"
        msg=msg & vbCrLf & vbCrLf & "Версия сборки " & GetExpVer()
Case Else
        msg="Fatal problems occurred while removing application." & vbCrLf & _
			"Contact your system administrator."
        msg=msg & vbCrLf & vbCrLf & "Версия сборки " & GetExpVer()
End Select
        ttl=distr.dispname & " " & distr.AppVer & " " & x
        If opts.bResetCFG Then ttl = ttl & " [Reset]"
        retcode=objShell.Popup (msg, opts.intUntimer+4, ttl, 0 + 64)
    Dlg_CantExtRemove=retcode
	On Error Goto 0
	End Function 'Dlg_CantExtRemove



End Class 'Setup



' ===============================================================================================================
' Class clsHTAWindow : <nothing>
' ===============================================================================================================



Dim oInstall, intRetCode



'*******************
Function Init
	Init=-1

	Set oInstall = New Setup
	If oInstall.Init() Then Done : WScript.Echo ("ERR->MainInit") : WScript.Quit (0)

    oInstall.ParsArgs()
    'в GUI (которое сейчас отсутствует): При удалении, далее прочитаем старые настройки программы из реестра
    'и не будем их больше обновлять из CLI или по дефолту, чтобы можно было обновиться
    'не вбивая их заново.
    'Если запуск для установки, то после очередного действия сначала
    'устанавливаем все настройки по умолчанию, затем считываем параметры из
    'командной строки.

    'при необходимости перезапускаем приложение в новой среде (32 или 64 бита)
    Dim retcode
    retcode=oInstall.ReRun64()
	Select Case retcode
		Case 0      : ' do nothing
		Case 2      : oInstall.Done : Set oInstall=Nothing : WScript.Quit 0 ' : Exit Function 'на перезапуск
		Case -100   : Done : WScript.Echo "Error - 32 bit only!" : WScript.Quit (0)
		Case -101   : Done : WScript.Echo "Error - 64 bit only!" : WScript.Quit (0)
		Case Else   : Done : WScript.Echo "ERR->Elevate32Async" : WScript.Quit (0)
	End Select

	Init=0
End Function 'Init



'*******************
Function Done
    On Error Resume Next
	oInstall.Done
	Set oInstall=Nothing
    '----Window.close
    '----Set Window=Nothing
    '----objHTA.Break
    '----Set objHTA=Nothing
    On Error Goto 0
End Function 'Done



' ===============================================================================================================



Class DrawCallBack 'отрисовка действий установщика в окне.


'*******************
    Public Function Draw (N_ActionOf, N_SubOf, B_RetStat)
    End Function 'Draw
'*******************
	Function Done
	End Function 'Done
'*******************
    Private Sub Class_Initialize
    End Sub 'Class_Initialize
'*******************
	Function Init_Setup
	End Function 'Init_Setup
'*******************
	Function Init_Remove
	End Function 'Init_Remove
'*******************
	Function PutProgressBar
	End Function 'PutProgressBar
'*******************
	Function DelProgressBar
	End Function 'DelProgressBar
'*******************
	Function time2sec(t)
        time2sec=Second(t)+60*Minute(t)+3600*Hour(t)
	End Function 'time2sec
End Class 'DrawCallBack



' ===============================================================================================================



Init
Dim CBK: Set CBK = New DrawCallBack
oInstall.LoadCallBack(CBK)

intRetCode=oInstall.Action
oInstall.ErrMsg(intRetCode)

Done
WScript.Quit(0)
