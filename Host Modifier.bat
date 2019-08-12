attrib -r %WINDIR%\system32\drivers\etc\hosts
@ECHO OFF
IF "%OS%"=="Windows_NT" (
SET HOSTFILE=%windir%\system32\drivers\etc\hosts
) ELSE (
SET HOSTFILE=%windir%\hosts
)
ECHO 127.0.0.1    www.exampleurl1.com>> %HOSTFILE%
ECHO 127.0.0.1    www.exampleurl2.com>> %HOSTFILE%
attrib +r %WINDIR%\system32\drivers\etc\hosts
IPCONFIG -flushdns
CLS
ECHO all sites have been added to your hosts file
ECHO DONE
PAUSE