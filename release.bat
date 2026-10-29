@echo off
setlocal

pushd "%~dp0"
call scripts\setup_gamejoltodin.bat
if errorlevel 1 (
    popd
    exit /b 1
)

odin build . -out:dappero.exe -strict-style -vet -no-bounds-check -o:speed -subsystem:windows -collection:gamejolt=vendor/Gamejoltodin
set "BUILD_RESULT=%ERRORLEVEL%"

popd
exit /b %BUILD_RESULT%
