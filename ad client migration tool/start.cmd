cmd.exe /c robocopy domainjoin C:\Windows\Temp\domainjoin  *.* /E
REG ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /t REG_SZ /d "cmd.exe /C C:\Windows\Temp\domainjoin\source\unjoin.cmd" /f
cmd.exe /c "C:\Windows\Temp\domainjoin\source\install.cmd"