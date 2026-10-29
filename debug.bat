@echo off
setlocal

pushd "%~dp0"
call scripts\setup_gamejoltodin.bat
if errorlevel 1 (
    popd
    exit /b 1
)

odin run . -collection:gamejolt=vendor/Gamejoltodin
set "RUN_RESULT=%ERRORLEVEL%"

popd
exit /b %RUN_RESULT%
