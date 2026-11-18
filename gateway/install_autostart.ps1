param()
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$startup = [Environment]::GetFolderPath('Startup')
if (-not (Test-Path -LiteralPath $startup)) { throw 'Windows Startup folder was not found.' }
if (-not [Environment]::GetEnvironmentVariable('LITELLM_MASTER_KEY', 'User')) { throw 'LITELLM_MASTER_KEY is not configured for the current user. Run install.ps1 first.' }

function New-SilentLauncher([string]$Name, [string]$BatchPath, [int]$DelayMs) {
    $safePath = $BatchPath.Replace('"', '""')
    $lines = @('Set WshShell = CreateObject("WScript.Shell")')
    if ($DelayMs -gt 0) { $lines += "WScript.Sleep $DelayMs" }
    $lines += "WshShell.Run Chr(34) & `"$safePath`" & Chr(34), 0, False"
    $lines += 'Set WshShell = Nothing'
    $destination = Join-Path $startup $Name
    $content = $lines -join "`r`n"
    if ((Test-Path -LiteralPath $destination) -and ((Get-Content -LiteralPath $destination -Raw) -eq ($content + "`r`n"))) { return }
    if (Test-Path -LiteralPath $destination) {
        $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        Copy-Item -LiteralPath $destination -Destination "$destination.bak_$stamp"
    }
    [System.IO.File]::WriteAllText($destination, $content + "`r`n", [System.Text.Encoding]::ASCII)
    Write-Output "Installed $Name"
}

New-SilentLauncher 'HybridBrain-Ollama-CPU.vbs' (Join-Path $repoRoot 'gateway\start_ollama_cpu.bat') 0
New-SilentLauncher 'HybridBrain-LiteLLM-Gateway.vbs' (Join-Path $repoRoot 'gateway\start_gateway.bat') 5000
