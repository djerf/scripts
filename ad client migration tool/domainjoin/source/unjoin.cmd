REG ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v Setup /t REG_SZ /d "cmd.exe /C C:\Windows\Temp\domainjoin\source\join.cmd" /f
start /wait PowerShell.exe -ExecutionPolicy UnRestricted -command "& { . C:\Windows\Temp\domainjoin\source\domainjoin.ps1; remove }"