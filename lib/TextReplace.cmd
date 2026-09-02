rem MACRO:TextReplace
rem Note：Only supports basic string，Not support regular expressions
rem Using: call TextReplace "file.txt" "old" "new"

if "x%~1"=="x" goto :EOF
echo [MACRO]TextReplace %*

set "file=%~1"
set "search=%~2"
set "replace=%~3"
set "tmpfile=%~1.tmp"

rem clear temp file
type nul>"%tmpfile%"

rem read file and replace text
set "content="
for /f "delims=" %%i in ('type "%file%"') do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    set "line=!line:%search%=%replace%!"
    echo !line!>>"%tmpfile%"
    endlocal
)

rem replace original file
move /y "%tmpfile%" "%file%" >nul
goto :EOF
