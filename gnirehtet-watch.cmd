@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Gnirehtet VR (watchdog)
cd /d "%~dp0"

set "DNS=%~1"
set "STAYON=%~2"
set "PROX=%~3"
set "INTERVAL=%~4"
if "%DNS%"=="" set "DNS=8.8.8.8,1.1.1.1"
if "%INTERVAL%"=="" set "INTERVAL=10"
set /a PINGS=%INTERVAL%+1
set "ADB=%~dp0adb.exe"

:watch
rem Exit when the main window is closed
tasklist /fi "WINDOWTITLE eq Gnirehtet VR (main)" 2>nul | find /i "cmd.exe" >nul
if errorlevel 1 exit /b 0

rem Go through every device that adb currently sees
for /f "skip=1 tokens=1,2" %%A in ('"%ADB%" devices 2^>nul') do (
    if /i "%%B"=="device" (
        call :check %%A
    ) else if /i "%%B"=="unauthorized" (
        echo [%time%] %%A: unauthorized - put the headset on and allow USB debugging.
    ) else if /i "%%B"=="offline" (
        echo [%time%] %%A: offline - reconnecting...
        "%ADB%" -s %%A reconnect >nul 2>&1
    )
)

ping -n %PINGS% 127.0.0.1 >nul
goto watch

:check
set "S=%~1"
if "%STAYON%"=="1" "%ADB%" -s %S% shell svc power stayon usb >nul 2>&1
if "%PROX%"=="1" "%ADB%" -s %S% shell am broadcast -a com.oculus.vrpowermanager.prox_close >nul 2>&1

rem If the gnirehtet client process on the device is gone, start it again
set "PID="
for /f %%P in ('"%ADB%" -s %S% shell pidof com.genymobile.gnirehtet 2^>nul') do set "PID=%%P"
if not defined PID (
    echo [%time%] %S%: client is not running - starting...
    java -jar gnirehtet-quiet.jar start %S% -d %DNS% >nul 2>&1
)
exit /b 0
