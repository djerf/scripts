@echo off

:START
set RESTART=0
Set BITNESS=x64
IF %PROCESSOR_ARCHITECTURE% == x86 (
  IF NOT DEFINED PROCESSOR_ARCHITEW6432 Set BITNESS=x86
  )

:NETFX45
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319\SKUs\.NETFramework,Version=v4.5" 2>NUL
if %ERRORLEVEL% equ 0 (
    echo .NET Framework 4.5 Already present.
    echo.
    goto WMF4
)
echo Installing .NET Framework 4.5
    echo.
start /wait C:\Windows\Temp\domainjoin\source\dotnetfx45_full_x86_x64.exe /q /norestart
if %ERRORLEVEL% equ 0 (
echo Finished installing .NET Framework 4.5
    echo.
	goto WMF4
)
if %ERRORLEVEL% equ 1641 (
echo Finished installing .NET Framework 4.5
    echo.
	goto WMF4
)
if %ERRORLEVEL% equ 3010 (
echo Finished installing .NET Framework 4.5
    echo.
    goto WMF4
) else (
echo Error installing .NET Framework 4.5
    echo.
	REG delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /f
    goto QUIT
)

:WMF4
reg query "HKLM\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine" /v PowerShellVersion 2>&1 | find "4.0" 2>&1>NUL
if %ERRORLEVEL% equ 0 (
    echo Windows Management Framework 4.0 %BITNESS% Already present.
    echo.
    goto EXIT
)

echo Installing Windows Management Framework 4.0 %BITNESS%
    echo.
start /wait wusa.exe C:\Windows\Temp\domainjoin\source\Windows6.1-KB2819745-%BITNESS%-MultiPkg.msu /quiet /norestart
if %ERRORLEVEL% equ 0 (
echo Windows Management Framework 4.0 %BITNESS% installation successful.
    echo.
    set RESTART=1
    goto EXIT
)
if %ERRORLEVEL% equ 3010 (
echo Windows Management Framework 4.0 %BITNESS% installation successful.
    echo.
    set RESTART=1
    goto EXIT
)

:EXIT
echo Finished setting up .NET Framework 4.5 and Windows Management Framework 4.0 %BITNESS%. 
echo.
echo The computer will restart.
echo. 
shutdown /r /t 1 -c "Restarting"


:QUIT