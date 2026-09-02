@echo off
cd /d "%~dp0"

rem run with Administrators right
call bin\IsAdmin.cmd

if not ERRORLEVEL 1 (
  if not "x%~1"=="xrunas" (
    set ElevateMe=1
    set "PATH=%PATH_ORG%"
    bin\ElevateMe.vbs "%~0" "runas" %*
  )
  goto :EOF
)
if "x%~1"=="xrunas" shift

rem Unload Registry Entries
reg unload HKLM\Src_SOFTWARE
reg unload HKLM\Src_SYSTEM
reg unload HKLM\Src_DEFAULT
reg unload HKLM\Src_DRIVERS
reg unload HKLM\Src_NTUSER.DAT

reg unload HKLM\Tmp_SOFTWARE
reg unload HKLM\Tmp_SYSTEM
reg unload HKLM\Tmp_DEFAULT
reg unload HKLM\Tmp_DRIVERS
reg unload HKLM\Tmp_NTUSER.DAT

rem unmount target Directory contents一subdirectory mounted folders
for /d %%i in ("%cd%\target\*") do (
  if exist "%%i\mounted\" (
    Dism /unmount-image /MountDir:"%%i\mounted" /discard 2>nul
    rd /s /q "%%i\mounted" 2>nul
  )

  rd /s /q "%%i\install" 2>nul
  rd /s /q "%%i\Temp" 2>nul

  del /A /F /Q "%cd%\target\winre.wim" 2>nul
  del /A /F /Q "%cd%\target\base.wim" 2>nul
)
