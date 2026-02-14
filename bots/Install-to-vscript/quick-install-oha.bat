@echo off
chcp 65001 >nul
:: Check if the script is run as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Get the current timestamp (format: YYYYMMDD_HHMMSS)
for /f "tokens=1-4 delims=/:. " %%a in ("%date% %time%") do (
    set year=%%a
    set month=%%b
    set day=%%c
    set hour=%%d
)
set timestamp=%year%%month%%day%_%time:~0,2%%time:~3,2%%time:~6,2%

:: Remove spaces in the hour if present (in case of 24-hour format)
set timestamp=%timestamp: =0%

set source_path=%~dp0..

echo Using source path: %source_path%

:: Check if the folder already exists
if exist "%~dp0..\..\..\..\..\common\dota 2 beta\game\dota\scripts\vscripts\bots" (
    echo bots folder already exists, renaming to bots_old_%timestamp%...
    ren "%~dp0..\..\..\..\..\common\dota 2 beta\game\dota\scripts\vscripts\bots" "bots_old_%timestamp%"
)

echo Creating symbolic link...
mklink /d "%~dp0..\..\..\..\..\common\dota 2 beta\game\dota\scripts\vscripts\bots" "%source_path%"

if exist "%~dp0..\..\..\..\..\common\dota 2 beta\game\dota\scripts\vscripts\game\Customize" (
    echo Customize folder already exists, renaming to bots_old_%timestamp%...
    ren "%~dp0..\..\..\..\..\common\dota 2 beta\game\dota\scripts\vscripts\game\Customize" "Customize_old_%timestamp%"
)
echo Creating Customize script...
xcopy  "%~dp0..\Customize\" "%~dp0..\..\..\..\..\common\dota 2 beta\game\dota\scripts\vscripts\game\Customize\" /E

if %errorlevel% equ 0 (
    echo ============
    echo ============
    echo Install Succeeded!!!
    echo ============
    echo ============
) else (
    echo ============
    echo "1. Make sure to execute this file from a valid local bot source folder (Install-to-vscript).
    echo "2. If you don't know where Steam is, right click Dota2 in Library, select Properties > Installed Files > Browse.
    echo "3. Run this file as Administrator"
    echo ============
    echo Install failed!!!
    echo ============
)
pause
