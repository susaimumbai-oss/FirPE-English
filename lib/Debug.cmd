echo.
echo ===== DEBUG MODE =====
echo Enter any command to execute
echo Enter continue to execute
echo Enter exit Cancel Build
echo ======================
:debug_loop
set /p cmd=debug^> 
if /i "%cmd%"=="continue" goto :EOF
if /i "%cmd%"=="exit" exit /b 1
call %cmd%
goto debug_loop
