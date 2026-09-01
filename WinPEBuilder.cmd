@echo off
chcp 65001>nul
setlocal enabledelayedexpansion

cd /d "%~dp0"
title %~n0(%cd%)

set "APP_ROOT=%cd%"
set "PATH=%APP_ROOT%\bin;%PATH%"
set "PATH=%APP_ROOT%\lib;%PATH%"

set APP_OPT_HELP=
call :PARSE_OPTIONS %*
rem set APP_OPT_
if /i "x%APP_OPT_HELP%"=="x1" goto :SHOW_HELP

set PROCESSOR_ARCHITECTURE=AMD64
if /i %PROCESSOR_IDENTIFIER:~0,3%==x86 (
  set PROCESSOR_ARCHITECTURE=x86
)

set APP_ARCH=x86
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  set APP_ARCH=x64
  set "PATH=%APP_ROOT%\bin\x64;%PATH%"
) else (
  set "PATH=%APP_ROOT%\bin\x86;%PATH%"
)

set findcmd=findstr
if not exist "%windir%\System32\findstr.exe" set findcmd=find

rem run with Administrators right
call IsAdmin.cmd

if not ERRORLEVEL 1 (
  if not "x%~1"=="xrunas" (
    set ElevateMe=1
    set "PATH=%PATH_ORG%"
    bin\ElevateMe.vbs "%~0" "runas" %*
  )
  goto :EOF
)

if "x%APP_RUNAS_TI%"=="x" (
  set APP_RUNAS_TI=1
  NSudoC.exe -UseCurrentConsole -Wait -U:T "%~0"
  goto :EOF
)

if "x%APP_SRC_FOLDER%"=="x" if "x%APP_SRC_WIM%"=="x" goto :cui
set APP_EXEC_MODE=1
if "%APP_SRC_FOLDER:~1%"=="" set "APP_SRC_FOLDER=%APP_SRC_FOLDER%:"
if not "x%APP_SRC_FOLDER%"=="x" (
  if exist "%APP_SRC_FOLDER%\sources\install.wim" (
    set "APP_SRC=%APP_SRC_FOLDER%\sources\install.wim"
  ) else if exist "%APP_SRC_FOLDER%\sources\install.esd" (
    set "APP_SRC=%APP_SRC_FOLDER%\sources\install.esd"
  ) else (
    echo Error：in %APP_SRC_FOLDER% The source image not found
    goto :EOF
  )

  if "x%APP_BASE_WIM%"=="x" (
    if exist "%APP_SRC_FOLDER:~,1%:\sources\boot.wim" (
      set "APP_BASE_WIM=%APP_SRC_FOLDER:~,1%:\sources\boot.wim"
      set APP_BASE_INDEX=2
    ) else  if exist "%APP_SRC_FOLDER:~,1%:\sources\winre.wim" (
      set "APP_BASE_WIM=%APP_SRC_FOLDER:~,1%:\sources\winre.wim"
      set APP_BASE_INDEX=1
    ) else (
      echo Error：in %APP_SRC_FOLDER% Not found boot.wim or winre.wim
      goto :EOF
    )
  )
) else if not "x%APP_SRC_WIM%"=="x" (
  if not exist "%APP_SRC_WIM%" (echo Error：The source WIM file does not exist：%APP_SRC_WIM% & goto :EOF)
  set "APP_SRC=%APP_SRC_WIM%"
) else (
  echo Error：Must be slected --source-folder or --source-wim Parameters
  goto :EOF
)

if "x%APP_BASE_WIM%"=="x" (echo Error：No base image selected & goto :EOF)
if "x%APP_OPT_PROJECT%"=="x" (echo Error：Project not selected & goto :EOF)

if not exist "%APP_BASE_WIM%" (echo Error：Base WIM file not exist：%APP_BASE_WIM% & goto :EOF)
if not exist "%cd%\projects\%APP_OPT_PROJECT%" (echo Error：The project does not exist：%APP_OPT_PROJECT% & goto :EOF)

if "x%APP_SRC_INDEX%"=="x" set APP_SRC_INDEX=1
if "x%APP_BASE_INDEX%"=="x" set APP_BASE_INDEX=1

echo [Command Line] Source Image：%APP_SRC%，Index：%APP_SRC_INDEX%
echo [Command Line] Base Image：%APP_BASE_WIM%，Index：%APP_BASE_INDEX%

set "APP_PROJECT=%APP_OPT_PROJECT%"
set "APP_BASE_PATH=%cd%\target\%APP_PROJECT%\base.wim"
if not exist "%cd%\target\%APP_PROJECT%" mkdir "%cd%\target\%APP_PROJECT%"
copy /y "%APP_BASE_WIM%" "%cd%\target\%APP_PROJECT%\base.wim" >nul
goto :build

:cui
set /p APP_SRC_FOLDER=Enter ISO mounted drive letter or directory path：
if "%APP_SRC_FOLDER%"=="" (echo No drive letter or directory path was entered & goto :cui)
if "%APP_SRC_FOLDER:~1%"=="" set "APP_SRC_FOLDER=%APP_SRC_FOLDER%:"
if exist "%APP_SRC_FOLDER%\sources\install.wim" (
  set "APP_SRC=%APP_SRC_FOLDER%\sources\install.wim"
) else if exist "%APP_SRC_FOLDER%\sources\install.esd" (
  set "APP_SRC=%APP_SRC_FOLDER%\sources\install.esd"
) else (
  echo Not found install.wim or install.esd
  goto :cui
)
echo ————————————————————————————————————————————————
for /f "tokens=2 delims=: " %%a in ('Dism.exe /English /Get-WimInfo /WimFile:"%APP_SRC%" ^| findstr /i Index') do (
  Dism.exe /English /Get-WimInfo /WimFile:"%APP_SRC%" /Index:%%a >"%TEMP%\wiminfo_%%a.tmp" 2>nul
  rem Convert to UTF-8 encoding
  iconv -f GBK -t UTF-8 "%TEMP%\wiminfo_%%a.tmp" > "%TEMP%\wiminfo_%%a_utf8.tmp" 2>nul
  del "%TEMP%\wiminfo_%%a.tmp" 2>nul

  for /f "tokens=2 delims=:" %%b in ('type "%TEMP%\wiminfo_%%a_utf8.tmp" ^| findstr /i Name') do set Name=%%b
  for /f "tokens=2 delims=:" %%c in ('type "%TEMP%\wiminfo_%%a_utf8.tmp" ^| findstr /i Version') do set Version=%%c
  for /f "tokens=3 delims=: " %%d in ('type "%TEMP%\wiminfo_%%a_utf8.tmp" ^| findstr /i Build') do set Build=%%d
  for /f "tokens=2 delims=:" %%e in ('type "%TEMP%\wiminfo_%%a_utf8.tmp" ^| findstr /i Architecture') do set Architecture=%%e

  del "%TEMP%\wiminfo_%%a_utf8.tmp" 2>nul
  echo  %%a	!Name! !Version!.!Build! !Architecture!
  set index=%%a
)
echo ————————————————————————————————————————————————
set /p APP_SRC_INDEX=Enter Index Volume Number：
if "%APP_SRC_INDEX%"=="" (set APP_SRC_INDEX=1&echo No Volume number is entered，Volume 1 is auto selected)
if %APP_SRC_INDEX% lss 1 (echo No volume number was selected & goto :cui)
if %APP_SRC_INDEX% gtr %index% (echo No volume number was selected & goto :cui)

set index=0
echo.
echo Existing WinPE Projects：
echo ————————————————————————————————————————————————
for /d %%i in ("%cd%\Projects\*") do (
  set /a index=index+1
  echo  !index!     %%~nxi
)
echo ————————————————————————————————————————————————
set /p project=Enter Project Number：
if "%project%"=="" (echo Select None & goto :cui)
if "%project%" lss "1" (echo No project selected & goto :cui)
if "%project%" gtr "%index%" (echo No project selected & goto :cui)
set index=0
for /d %%x in ("%cd%\Projects\*") do (
  set /a index=index+1
  if "!index!"=="%project%" (set APP_PROJECT=%%~nx)
)

echo.
echo Base Image
echo ————————————————————————————————————————————————
echo  1     Boot.wim (Volume2) (Base to Boot WinPE)
echo  2     WinRE.wim (Volume1) (Base to WinRE WinPE)
echo        Custom Base Image (Volume1)
echo ————————————————————————————————————————————————
set /p bore=Please Enter Base Image:
if "%bore%"=="" (set bore=1&echo Not selected wim, Auto selected Boot.wim)

echo.
choice /M "Create an ISO image?"
if %errorlevel%==1 set APP_OPT_MAKE_ISO=1
if %errorlevel%==2 set APP_OPT_MAKE_ISO=0

if "%bore%"=="1" (
  if not exist "%cd%\target\%APP_PROJECT%" mkdir "%cd%\target\%APP_PROJECT%"
  copy /y "%APP_SRC_FOLDER:~,1%:\sources\boot.wim" "%cd%\target\%APP_PROJECT%\base.wim" >nul
  set "APP_BASE_PATH=%cd%\target\%APP_PROJECT%\base.wim"
  set APP_BASE_INDEX=2
) else if "%bore%"=="2" (
  if not exist "%cd%\target\%APP_PROJECT%" mkdir "%cd%\target\%APP_PROJECT%"
  set "APP_BASE_PATH=%cd%\target\%APP_PROJECT%\winre.wim"
  set APP_BASE_INDEX=1
  echo \033[93;46m [Build] Extracting winre.wim...... | CmdColor.exe
  wimlib-imagex.exe extract "%APP_SRC%" %APP_SRC_INDEX% "\Windows\System32\Recovery\winre.wim" --dest-dir="%cd%\target\%APP_PROJECT%" --nullglob --no-acls
) else if exist "%bore%" (
  if not exist "%cd%\target\%APP_PROJECT%" mkdir "%cd%\target\%APP_PROJECT%"
  copy /y "%bore%" "%cd%\target\%APP_PROJECT%\base.wim" >nul
  set "APP_BASE_PATH=%cd%\target\%APP_PROJECT%\base.wim"
  set APP_BASE_INDEX=1
) else echo No project selected & goto :cui

:build
set "t=%time: =0%"
set /a "start_ts=(1%t:~0,2%-100)*3600 + (1%t:~3,2%-100)*60 + (1%t:~6,2%-100)"

echo \033[93;46m [Build] Getting base image details... | CmdColor.exe
for /f "tokens=1,2 delims=:(" %%i in ('Dism.exe /Get-WimInfo /WimFile:"%APP_BASE_PATH%" /Index:%APP_BASE_INDEX% /English') do (
  if "%%i"=="Architecture " set APP_PE_ARCH=%%j
  if "%%i"=="Version " set APP_PE_VER=%%j
  if "%%i"=="ServicePack Build " set APP_PE_BUILD=%%j
  if "x!LANG_FLAG!"=="x1" (
    set APP_PE_LANG=%%i
    set LANG_FLAG=
  )
  if "%%i"=="Languages " set LANG_FLAG=1
)
if "x%APP_PE_LANG%"=="x" (
  echo \033[93;46m [Build] Failed to get base image details | CmdColor.exe
  if "x%APP_EXEC_MODE%"=="x1" goto :EOF
  cmd /k
)

rem set Enviroment

set "APP_PE_ARCH=%APP_PE_ARCH: =%"
set "APP_PE_VER=%APP_PE_VER: =%"
set "APP_PE_BUILD=%APP_PE_BUILD: =%"
rem here is TAB, not SPACE 
set "APP_PE_LANG=%APP_PE_LANG:	=%"
set "APP_PE_LANG=%APP_PE_LANG: =%"

echo %APP_PE_VER%.%APP_PE_BUILD%,%APP_PE_ARCH%,%APP_PE_LANG%

set "SRC_PATH=%cd%\target\%APP_PROJECT%\install"
set "APP_TMP_PATH=%cd%\target\%APP_PROJECT%\Temp"
set "PROJECT_PATH=%cd%\projects\%APP_PROJECT%"
set "BUILD_WIM=%cd%\target\%APP_PROJECT%\boot.wim"
set "ISO_DIR=%cd%\target\%APP_PROJECT%\_ISO_"

set "V_APP=%APP_ROOT%\vendor"
set "V=%V_APP%"

set "X=%cd%\target\%APP_PROJECT%\mounted"
set "X_PF=%X%\Program Files"
set "X_PF(x86)=%X%\Program Files (x86)"
set "X_WIN=%X%\Windows"
set "X_SYS=%X_WIN%\System32"
set "X_WOW64=%X_WIN%\SysWOW64"
set "X_Desktop=%X%\Users\Default\Desktop"

call V2X -init

if not exist "%X%" mkdir "%X%"
if not exist "%APP_TMP_PATH%" mkdir "%APP_TMP_PATH%"

echo \033[93;46m [Build] Extracting install image registry... | CmdColor.exe
wimlib-imagex.exe extract "%APP_SRC%" %APP_SRC_INDEX% "\Windows\System32\config\DEFAULT" --dest-dir="%SRC_PATH%" --nullglob --no-acls --preserve-dir-struct
wimlib-imagex.exe extract "%APP_SRC%" %APP_SRC_INDEX% "\Windows\System32\config\DRIVERS" --dest-dir="%SRC_PATH%" --nullglob --no-acls --preserve-dir-struct
wimlib-imagex.exe extract "%APP_SRC%" %APP_SRC_INDEX% "\Windows\System32\config\SYSTEM" --dest-dir="%SRC_PATH%" --nullglob --no-acls --preserve-dir-struct
wimlib-imagex.exe extract "%APP_SRC%" %APP_SRC_INDEX% "\Windows\System32\config\SOFTWARE" --dest-dir="%SRC_PATH%" --nullglob --no-acls --preserve-dir-struct
wimlib-imagex.exe extract "%APP_SRC%" %APP_SRC_INDEX% "\Users\Default\NTUSER.DAT" --dest-dir="%SRC_PATH%" --nullglob --no-acls --preserve-dir-struct

rem Mount base image
call RunHooks before-mount.cmd
echo \033[93;46m [Build] Mount base image: %APP_BASE_PATH% | CmdColor.exe
Dism /mount-wim /wimfile:"%APP_BASE_PATH%" /index:%APP_BASE_INDEX% /mountdir:"%X%"
call RunHooks after-mount.cmd

rem 挂载注册表
call RunHooks before-mount-reg.cmd
echo \033[93;46m [Setup] Mount install image and setup | CmdColor.exe
reg load HKLM\Src_SOFTWARE "%SRC_PATH%\Windows\System32\config\SOFTWARE"
reg load HKLM\Src_SYSTEM "%SRC_PATH%\Windows\System32\config\SYSTEM"
reg load HKLM\Src_DEFAULT "%SRC_PATH%\Windows\System32\config\DEFAULT"
reg load HKLM\Src_DRIVERS "%SRC_PATH%\Windows\System32\config\DRIVERS"
reg load HKLM\Src_NTUSER.DAT "%SRC_PATH%\Users\Default\NTUSER.DAT"

echo \033[93;46m [Build] Mount base image registry | CmdColor.exe
reg load HKLM\Tmp_SOFTWARE "%X%\Windows\System32\config\SOFTWARE"
reg load HKLM\Tmp_SYSTEM "%X%\Windows\System32\config\SYSTEM"
reg load HKLM\Tmp_DEFAULT "%X%\Windows\System32\config\DEFAULT"
reg load HKLM\Tmp_DRIVERS "%X%\Windows\System32\config\DRIVERS"
reg load HKLM\Tmp_NTUSER.DAT "%X%\Users\Default\NTUSER.DAT"

call RunHooks after-mount-reg.cmd

rem Run the project script
call RunHooks before-project.cmd
call ApplyProjectPatches "%PROJECT_PATH%"
call RunHooks after-project.cmd
echo \033[93;46m [Build] Project operation completed; cleaning up..... | CmdColor.exe

rem Remove registry keys
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

rem Compress registry
ru.exe -accepteula -nobanner -h "%X%\Windows\System32\config\DRIVERS"
ru.exe -accepteula -nobanner -h "%X%\Windows\System32\config\SOFTWARE"
ru.exe -accepteula -nobanner -h "%X%\Windows\System32\config\SYSTEM"
ru.exe -accepteula -nobanner -h "%X%\Users\Default\NTUSER.DAT"

rem Clean up registry log files
del /f /q /a "%X%\Windows\System32\config\*.LOG*" 1>nul 2>nul
del /f /q /a "%X%\Windows\System32\config\*{*}*" 1>nul 2>nul
del /f /q /a "%X%\Windows\System32\SMI\Store\Machine\*.LOG*" 1>nul 2>nul
del /f /q /a "%X%\Windows\System32\SMIStore\Machine\*{*}*" 1>nul 2>nul
del /f /q /a "%X%\Users\Default\*.LOG*" 1>nul 2>nul
del /f /q /a "%X%\Users\Default\*{*}*" 1>nul 2>nul

rem Save and unmount volume
call RunHooks before-commit.cmd
echo \033[93;46m [Build] Saving Unmount base image...... | CmdColor.exe
Dism /Unmount-Image /MountDir:"%X%" /commit

rem Export image
echo \033[93;46m [Build] Exporting WinPE image...... | CmdColor.exe
if exist "%BUILD_WIM%" del /A /F /Q "%BUILD_WIM%"
rem wimlib-imagex.exe export "%APP_BASE_PATH%" %APP_BASE_INDEX% "%BUILD_WIM%" --boot
Dism /Export-Image /SourceImageFile:"%APP_BASE_PATH%" /SourceIndex:%APP_BASE_INDEX% /DestinationImageFile:"%BUILD_WIM%" /Bootable

rem Build an ISO image
if "x%APP_OPT_MAKE_ISO%"=="x1" (
  echo \033[93;46m [Build] Build ISO image...... | CmdColor.exe
  call MakeBootISO.cmd
)

rem Clean up files
rd /s /q "%SRC_PATH%" 2>nul
rd /s /q "%X%" 2>nul
rd /s /q "%APP_TMP_PATH%" 2>nul
rd /s /q "%ISO_DIR%" 2>nul
del /A /F /Q "%cd%\target\%APP_PROJECT%\winre.wim" 2>nul
del /A /F /Q "%cd%\target\%APP_PROJECT%\base.wim" 2>nul

set "t=%time: =0%"
set /a "end_ts=(1%t:~0,2%-100)*3600 + (1%t:~3,2%-100)*60 + (1%t:~6,2%-100)"
set /a "diff=end_ts - start_ts"
if %diff% LSS 0 set /a "diff+=86400"
set /a "min=diff / 60, sec=diff %% 60"
if %min% GTR 0 (
  echo \033[93;46m [Complete] WinPE creation complete; total time taken %min% minutes %sec% seconds. | CmdColor.exe
) else (
  echo \033[93;46m [Complete] WinPE creation complete; total time: %sec% seconds. | CmdColor.exe
)

call RunHooks finished.cmd
if "x%APP_EXEC_MODE%"=="x1" goto :EOF
cmd /k
goto :EOF

:SHOW_HELP
echo Usage: %~nx0 [-h^|--help] [^<Options^>...]
echo.
echo ^<Options^>
echo    --source-folder FOLDER^|DRIVE
echo    --source-wim SOURCE_WIM_FILE
echo    --source-index INDEX
echo    --base-wim BASE_WIM_FILE
echo    --base-index INDEX
echo    --project PROJECT
echo    --make-iso
echo.
echo Examples:
echo.
echo    %~nx0 --source-folder I: --project Windows11PE
echo    %~nx0 --source-folder I: --source-index 1 --project Windows11PE
echo    %~nx0 --source-wim "D:\win10v1903\sources\install.wim" --source-index 4 --make-iso
echo    %~nx0 --source-folder H: --source-index 1 --base-wim "D:\BOOTPE\boot.wim" --make-iso
goto :EOF

:PARSE_OPTIONS
if /i "x%1"=="x" goto :EOF
if /i "x%1"=="x-h" (
  set APP_OPT_HELP=1
  goto :EOF
) else if /i "x%1"=="x--help" (
  set APP_OPT_HELP=1
  goto :EOF
) else if /i "x%1"=="x--source-driver" (
  set "APP_SRC_FOLDER=%~2"
  SHIFT
) else if /i "x%1"=="x--source-folder" (
  set "APP_SRC_FOLDER=%~2"
  SHIFT
) else if /i "x%1"=="x--source-wim" (
  set "APP_SRC_WIM=%~2"
  SHIFT
) else if /i "x%1"=="x--source-index" (
  set APP_SRC_INDEX=%2
  SHIFT
) else if /i "x%1"=="x--base-wim" (
  set "APP_BASE_WIM=%~2"
  SHIFT
) else if /i "x%1"=="x--base-index" (
  set APP_BASE_INDEX=%2
  SHIFT
) else if /i "x%1"=="x--project" (
  set APP_OPT_PROJECT=%2
  SHIFT
) else if /i "x%1"=="x--make-iso" (
  set APP_OPT_MAKE_ISO=1
)
SHIFT
goto :PARSE_OPTIONS
goto :EOF
