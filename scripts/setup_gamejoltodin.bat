@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0.."
set "DEST=%ROOT%\vendor\Gamejoltodin"
set "PINNED_COMMIT=2f49e315220f29d88f51648bf5f1757771f36d84"

if not exist "%DEST%\.git" (
    if not exist "%ROOT%\vendor" mkdir "%ROOT%\vendor"
    git clone https://github.com/flushwhy/Gamejoltodin.git "%DEST%"
    if errorlevel 1 exit /b 1
)

git -C "%DEST%" fetch origin %PINNED_COMMIT%
if errorlevel 1 exit /b 1
git -C "%DEST%" checkout --detach %PINNED_COMMIT%
if errorlevel 1 exit /b 1

echo Gamejoltodin dependency is pinned at %PINNED_COMMIT%.

rem Find an existing x64 libcurl import library before installing one.
set "CURL_LIB_DIR="
if defined GAMEJOLT_CURL_LIB_DIR if exist "%GAMEJOLT_CURL_LIB_DIR%\libcurl.lib" set "CURL_LIB_DIR=%GAMEJOLT_CURL_LIB_DIR%"
if not defined CURL_LIB_DIR if defined VCPKG_INSTALLATION_ROOT if exist "%VCPKG_INSTALLATION_ROOT%\installed\x64-windows\lib\libcurl.lib" set "CURL_LIB_DIR=%VCPKG_INSTALLATION_ROOT%\installed\x64-windows\lib"
if not defined CURL_LIB_DIR if exist "%LOCALAPPDATA%\vcpkg\installed\x64-windows\lib\libcurl.lib" set "CURL_LIB_DIR=%LOCALAPPDATA%\vcpkg\installed\x64-windows\lib"
if not defined CURL_LIB_DIR if exist "%ROOT%\vendor\curl\lib\libcurl.lib" set "CURL_LIB_DIR=%ROOT%\vendor\curl\lib"
if not defined CURL_LIB_DIR if exist "C:\odin\vendor\curl\lib\libcurl.lib" set "CURL_LIB_DIR=C:\odin\vendor\curl\lib"
if not defined CURL_LIB_DIR for /d %%D in ("C:\ProgramData\chocolatey\lib\curl\tools\curl-*") do if exist "%%D\lib\libcurl.lib" if not defined CURL_LIB_DIR set "CURL_LIB_DIR=%%D\lib"

if not defined CURL_LIB_DIR (
    echo [curl] libcurl.lib not found; installing curl:x64-windows with vcpkg...
    set "VCPKG_ROOT=%VCPKG_INSTALLATION_ROOT%"
    if not defined VCPKG_ROOT set "VCPKG_ROOT=%LOCALAPPDATA%\vcpkg"
    if not exist "!VCPKG_ROOT!\vcpkg.exe" (
        if exist "!VCPKG_ROOT!" if not exist "!VCPKG_ROOT!\.git" set "VCPKG_ROOT=%LOCALAPPDATA%\vcpkg-bootstrap"
        if not exist "!VCPKG_ROOT!\vcpkg.exe" (
            if not exist "!VCPKG_ROOT!\.git" (
                git clone https://github.com/microsoft/vcpkg.git "!VCPKG_ROOT!"
                if errorlevel 1 (
                    echo [ERROR] Could not download vcpkg. Install Git or set VCPKG_INSTALLATION_ROOT.
                    exit /b 1
                )
            )
            call "!VCPKG_ROOT!\bootstrap-vcpkg.bat" -disableMetrics
            if errorlevel 1 exit /b 1
        )
    )
    call "!VCPKG_ROOT!\vcpkg.exe" install curl:x64-windows
    if errorlevel 1 exit /b 1
    set "CURL_LIB_DIR=!VCPKG_ROOT!\installed\x64-windows\lib"
)

if not exist "%CURL_LIB_DIR%\libcurl.lib" (
    echo [ERROR] libcurl.lib was not found after dependency setup.
    echo Checked: "%CURL_LIB_DIR%\libcurl.lib"
    exit /b 1
)

set "CURL_BIN_DIR="
if exist "%CURL_LIB_DIR%\..\bin" set "CURL_BIN_DIR=%CURL_LIB_DIR%\..\bin"
if defined GITHUB_ENV echo GAMEJOLT_CURL_LIB_DIR=%CURL_LIB_DIR%>>"%GITHUB_ENV%"
if defined GITHUB_PATH if defined CURL_BIN_DIR echo %CURL_BIN_DIR%>>"%GITHUB_PATH%"
echo [curl] Using libcurl.lib: "%CURL_LIB_DIR%\libcurl.lib"
endlocal & set "GAMEJOLT_CURL_LIB_DIR=%CURL_LIB_DIR%" & set "LIB=%CURL_LIB_DIR%;%LIB%" & set "PATH=%CURL_BIN_DIR%;%PATH%"
