@echo off

title [ KX-3552 fix (for Win7-10 x86/x64) ver. 30.04.2016 ]
cls

SET /a ARCH=86
IF EXIST "%SystemRoot%\SysWOW64" SET /a ARCH=64
SET KX_MAIN=%HOMEDRIVE%\Program Files\kX Project
SET KX_MAIN86=%HOMEDRIVE%\Program Files (x86)\kX Project
SET DPINST_LOG=%SystemRoot%\DPINST.LOG

echo.
tasklist | find "kxmixer.exe" >nul 2>&1 && taskkill /f /im "kxmixer.exe" >nul

echo [ RE-INSTALL KX.INF ]
 IF EXIST "%DPINST_LOG%" (DEL /F /Q "%DPINST_LOG%")
 IF %ARCH% EQU 64 (
  "%~dp0DPInst64.exe" /q /f /path "%KX_MAIN%"
 ) ELSE (
  "%~dp0DPInst.exe" /q /f /path "%KX_MAIN%"
 )
 IF EXIST "%DPINST_LOG%" (MOVE /Y "%DPINST_LOG%" "%KX_MAIN%\DPINST.LOG")
echo.

echo [ REPAIR KX-MIXER ]
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "kX Mixer" /f 2>nul
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "kX Mixer" /t REG_SZ /d "%KX_MAIN%\kxmixer.exe --startup" /f
FOR /F "tokens=3 delims= " %%i in ('REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion') do (
 IF "%%i" GTR "6.1" (

   REM There are two paths: set kxmixer.exe "Windows 7 compatibility", OR disable the "WinMM initialization" with patched kxapi.dll.
   REM Thanks for patched kxapi.dll to GitHub User "linnaea" (https://github.com/linnaea)
   REM String to set Windows 7 compatibility now unused, but keeped ;)
   REM REG ADD "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%KX_MAIN%\kxmixer.exe" /t REG_SZ /d "~ WIN7RTM" /f
   
   IF %ARCH% EQU 64 (
     MOVE /Y "%KX_MAIN%\kxapi.dll" "%KX_MAIN%\kxapi_back.dll"
     MOVE /Y "%KX_MAIN86%\kxapi.dll" "%KX_MAIN86%\kxapi_back.dll"
     MOVE /Y "%~dp0kxapi_64.dll" "%KX_MAIN%\kxapi.dll"
     MOVE /Y "%~dp0kxapi_86.dll" "%KX_MAIN86%\kxapi.dll"
   ) ELSE (
     MOVE /Y "%KX_MAIN%\kxapi.dll" "%KX_MAIN%\kxapi_back.dll"
     MOVE /Y "%~dp0kxapi_86.dll" "%KX_MAIN%\kxapi.dll"
   )

 )
)
echo.

echo [ REGISTER KX-ASIO DRIVER ]
  IF %ARCH% EQU 64 (
   %SystemRoot%\system32\regsvr32.exe /u /s "%KX_MAIN%\kxasio.dll"
   %SystemRoot%\SysWOW64\regsvr32.exe /u /s "%KX_MAIN86%\kxasio.dll"
   %SystemRoot%\system32\regsvr32.exe "%KX_MAIN%\kxasio.dll"
   %SystemRoot%\SysWOW64\regsvr32.exe "%KX_MAIN86%\kxasio.dll"
 ) ELSE (
   %SystemRoot%\system32\regsvr32.exe /u /s "%KX_MAIN%\kxasio.dll"
   %SystemRoot%\system32\regsvr32.exe /s "%KX_MAIN%\kxasio.dll"
 ) 
echo.

echo [ REGISTER KX-MIXER SKIN ]
REG ADD "HKCU\Software\kX\Mixer" /v DefDevice /t REG_DWORD /d 0x00000000 /f
REG ADD "HKCU\Software\kX\Mixer" /v DefaultSkin /t REG_SZ /d "%KX_MAIN%\kxskin.kxs" /f
REG ADD "HKCU\Software\kX\Skins" /v 1F960575-9DBB-4ea3-9CB0-C69DD31FBB44 /t REG_SZ /d "%KX_MAIN%\kxskin.kxs" /f
REG ADD "HKCU\Software\kX\Skins" /v 1F960575-9DBB-4ea3-9CB0-C69DD31FBB44.name /t REG_SZ /d "Aqua Skin" /f
echo.

cls
echo.

REM "Ru/En final Msg"
COLOR 0E
chcp | findstr /L /E /I "866" >nul || goto :EN

:RU
chcp 1251 >nul
for /f "delims=" %%A in ("		! ÊÎÌÏÜÞÒÅÐ ÍÅÎÁÕÎÄÈÌÎ ÏÅÐÅÇÀÃÐÓÇÈÒÜ !") do >nul chcp 866& echo.%%A
goto :EX

:EN
echo         	! COMPUTER RESTART REQUIRED !

:EX
ping -n 5 -w 1000 127.0.0.1 >nul

exit
