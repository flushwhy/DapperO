@echo off
setlocal

set "ROOT=%~dp0.."
set "DEST=%ROOT%\vendor\Gamejoltodin"
set "PINNED_COMMIT=2f49e315220f29d88f51648bf5f1757771f36d84"

if not exist "%DEST%\.git" (
    if not exist "%ROOT%\vendor" mkdir "%ROOT%\vendor"
    git clone https://github.com/flushwhy/Gamejoltodin.git "%DEST%"
    if errorlevel 1 exit /b 1
)

git -C "%DEST%" fetch origin %PINNED_COMMIT%
if errorlevel 1 exit /b %ERRORLEVEL%
git -C "%DEST%" checkout --detach %PINNED_COMMIT%
if errorlevel 1 exit /b %ERRORLEVEL%

echo Gamejoltodin dependency is pinned at %PINNED_COMMIT%.
