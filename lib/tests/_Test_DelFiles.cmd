@echo off
cd /d "%~dp0"
cd ..

if not exist tests\tmp md tests\tmp

if exist tests\tmp\Windows rd /s /q tests\tmp\Windows

md tests\tmp\Windows\System32\drivers
md tests\tmp\Windows\System32\zh-CN
md tests\tmp\Windows\SysWOW64\zh-CN
md tests\tmp\Windows\SystemResources

echo. > tests\tmp\Windows\System32\test1.exe
echo. > tests\tmp\Windows\System32\test2.dll
echo. > tests\tmp\Windows\System32\test3.msc
echo. > tests\tmp\Windows\System32\drivers\test4.sys
echo. > tests\tmp\Windows\System32\drivers\test5.sys
echo. > tests\tmp\Windows\System32\zh-CN\test1.exe.mui
echo. > tests\tmp\Windows\System32\zh-CN\test2.dll.mui
echo. > tests\tmp\Windows\SysWOW64\test1.exe
echo. > tests\tmp\Windows\SysWOW64\test2.dll
echo. > tests\tmp\Windows\SysWOW64\zh-CN\test1.exe.mui
echo. > tests\tmp\Windows\SysWOW64\zh-CN\test2.dll.mui
echo. > tests\tmp\Windows\SystemResources\test1.exe.mun
echo. > tests\tmp\Windows\SystemResources\test2.dll.mun

echo. > tests\tmp\Windows\System32\test3.exe
echo. > tests\tmp\Windows\System32\test4.exe
echo. > tests\tmp\Windows\System32\zh-CN\test3.exe.mui
echo. > tests\tmp\Windows\SysWOW64\test3.exe
echo. > tests\tmp\Windows\SysWOW64\zh-CN\test3.exe.mui
echo. > tests\tmp\Windows\SystemResources\test3.exe.mun

echo. > tests\tmp\Windows\System32\test5.exe
echo. > tests\tmp\Windows\System32\test6.exe

md tests\tmp\Windows\System32\testdir
echo. > tests\tmp\Windows\System32\testdir\test1.exe
echo. > tests\tmp\Windows\System32\testdir\test2.exe

md tests\tmp\Windows\System32\testdir2
echo. > tests\tmp\Windows\System32\testdir2\test14.exe
echo. > tests\tmp\Windows\System32\testdir2\test15.dll

echo. > tests\tmp\Windows\System32\test16.exe
echo. > tests\tmp\Windows\System32\test17.exe
echo. > tests\tmp\Windows\System32\test18.dll
echo. > tests\tmp\Windows\System32\test19.dll

set "APP_TMP_PATH=%cd%\tests\tmp"
set "APP_PE_LANG=en-US"
set "APP_PE_VER=10.0.22631"
set "X=%~dp0tmp"

rem ============================================================================
call DelFiles "\Windows\System32\test1.exe"
call DelFiles "\Windows\System32\test2.dll,test3.msc"
call DelFiles "\Windows\System32\drivers"

if exist tests\tmp\Windows\System32\test1.exe echo [Failed] The file still exists
if exist tests\tmp\Windows\System32\test2.dll echo [Failed] test2.dll still exists
if exist tests\tmp\Windows\System32\test3.msc echo [Failed] test3.msc still exists
if exist tests\tmp\Windows\System32\drivers echo [Failed] Directory still exists

rem ============================================================================
call DelFiles %0 :end_files
goto :end_files

@\Windows\System32\testdir\
test1.exe
test2.exe

+syswow64
\Windows\System32\test3.exe
\Windows\System32\test4.exe
-syswow64

+ver > 22600
\Windows\System32\test5.exe
+ver < 22650
\Windows\System32\test6.exe
+ver*
:end_files

if exist tests\tmp\Windows\System32\testdir\test1.exe echo [Failed] test1.exe still exists
if exist tests\tmp\Windows\System32\testdir\test2.exe echo [Failed] test2.exe still exists

if exist tests\tmp\Windows\System32\test3.exe echo [Failed] test3.exe still exists
if exist tests\tmp\Windows\System32\test4.exe echo [Failed] test4.exe still exists
if exist tests\tmp\Windows\System32\zh-CN\test3.exe.mui echo [Failed] test3.exe.mui still exists

if exist tests\tmp\Windows\SysWOW64\test3.exe echo [Failed] SysWOW64\test3.exe still exists
if exist tests\tmp\Windows\SysWOW64\zh-CN\test3.exe.mui echo [Failed] SysWOW64\zh-CN\test3.exe.mui still exists
if exist tests\tmp\Windows\SystemResources\test3.exe.mun echo [Failed] test3.exe.mun still exists

if exist tests\tmp\Windows\System32\test5.exe echo [Failed] test5.exe still exists
if exist tests\tmp\Windows\System32\test6.exe echo [Failed] test6.exe still exists

rem ============================================================================

call DelFiles "\Windows\System32\test1*.exe"
call DelFiles "\Windows\System32\test1*.dll"

if exist tests\tmp\Windows\System32\test16.exe echo [Failed] test16.exe still exists
if exist tests\tmp\Windows\System32\test17.exe echo [Failed] test17.exe still exists
if exist tests\tmp\Windows\System32\test18.dll echo [Failed] test18.dll still exists
if exist tests\tmp\Windows\System32\test19.dll echo [Failed] test19.dll still exists

rem ============================================================================
call DelFiles %0 :[DirectX_Files]
goto :test_files_5

:[DirectX_Files]
@\Windows\System32\testdir2\
test14.exe
test15.dll
goto :EOF

:test_files_5
if exist tests\tmp\Windows\System32\testdir2\test14.exe echo [Failed] test14.exe still exists
if exist tests\tmp\Windows\System32\testdir2\test15.dll echo [Failed] test15.dll still exists

if exist tests\tmp\Windows rd /s /q tests\tmp\Windows
pause
goto :EOF
