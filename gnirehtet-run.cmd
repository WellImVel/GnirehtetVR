@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Gnirehtet VR (main)
cd /d "%~dp0"

rem ===================== SETTINGS =====================
rem DNS used by the headsets through the tunnel (public DNS is more stable than the PC's own).
set "DNS=8.8.8.8,1.1.1.1"
rem 1 = keep headsets awake while plugged in via USB (safe, recommended)
set "STAYON=1"
rem 1 = disable the proximity sensor on headsets (they will not sleep when taken off). Resets on reboot.
set "PROX=0"
rem Pause (seconds) before restarting after a failure
set "RETRY_DELAY=3"
rem Watchdog check interval (seconds)
set "WATCH_INTERVAL=10"
rem ====================================================

rem Use the adb.exe from this folder (no conflicts with another adb on the PC)
set "ADB=%~dp0adb.exe"

where java >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Java was not found. Install Java and run again.
    pause
    exit /b 1
)

echo [*] Restarting adb server...
"%ADB%" kill-server >nul 2>&1
"%ADB%" start-server >nul 2>&1

rem Watchdog runs in a separate minimized window, in parallel with the relay.
rem It handles EVERY connected device (any number) and closes itself when this window closes.
start "Gnirehtet VR (watchdog)" /min cmd /c ""%~dp0gnirehtet-watch.cmd" "%DNS%" %STAYON% %PROX% %WATCH_INTERVAL%"

echo.
echo [*] Gnirehtet is working with ALL connected devices at once.
echo [*] Plug in / unplug headsets any time - they are picked up automatically.
echo [*] Ctrl+C to quit.

:loop
echo.
echo [*] %date% %time% - starting relay...
java -jar gnirehtet-quiet.jar run -d %DNS%

echo.
echo [!] %date% %time% - gnirehtet stopped. Restarting in %RETRY_DELAY% s...
set /a PINGS=%RETRY_DELAY%+1
ping -n %PINGS% 127.0.0.1 >nul
"%ADB%" start-server >nul 2>&1
goto loop
