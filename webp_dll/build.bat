@echo off
REM build.bat <x86|x64> [Debug|Release]
SETLOCAL ENABLEDELAYEDEXPANSION
if "%1"=="" (
  echo Usage: build.bat x64|x86 [Debug|Release]
  exit /b 1
)
set PLATFORM=%1
set CONFIG=Release
if not "%2"=="" set CONFIG=%2

REM Ensure libwebp available (fetch script will skip if already present)
powershell -ExecutionPolicy Bypass -File "%~dp0\fetch_libwebp.ps1" -Platform %PLATFORM%
if ERRORLEVEL 1 (
  echo Failed to fetch libwebp
  exit /b 1
)

REM Choose MSBuild platform name
if /I "%PLATFORM%"=="x64" (
  set MSBUILD_PLATFORM=x64
) else (
  set MSBUILD_PLATFORM=Win32
)

echo Building project with msbuild (%CONFIG%|%MSBUILD_PLATFORM%)
msbuild "%~dp0webp_dll.vcxproj" /p:Configuration=%CONFIG%;Platform=%MSBUILD_PLATFORM%
if ERRORLEVEL 1 (
  echo Build failed
  exit /b 1
)

echo Build succeeded. Output in %~dp0\%CONFIG%\%MSBUILD_PLATFORM% or the project output folder.
ENDLOCAL
