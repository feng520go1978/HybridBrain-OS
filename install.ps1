param([switch]$SkipModelPull)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Set-UserDefault([string]$Name, [string]$Value) {
    $existing = [Environment]::GetEnvironmentVariable($Name, 'User')
    if (-not $existing) { [Environment]::SetEnvironmentVariable($Name, $Value, 'User'); $existing = $Value }
    [Environment]::SetEnvironmentVariable($Name, $existing, 'Process')
    return $existing
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { throw 'Python was not found. Install Python 3.10+ and rerun this installer.' }
$pyVersion = & $python.Source -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'
$parts = $pyVersion.Split('.')
if ([int]$parts[0] -lt 3 -or ([int]$parts[0] -eq 3 -and [int]$parts[1] -lt 10)) { throw 'Python 3.10 or newer is required.' }
$venv = Join-Path $repoRoot 'gateway\.venv'
if (-not (Test-Path (Join-Path $venv 'Scripts\python.exe'))) {
    & $python.Source -m venv $venv
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the gateway virtual environment.' }
}
$venvPython = Join-Path $venv 'Scripts\python.exe'
& $venvPython -m pip install --disable-pip-version-check -r (Join-Path $repoRoot 'gateway\requirements.txt')
if ($LASTEXITCODE -ne 0) { throw 'LiteLLM dependency installation failed.' }

$modelsPath = Join-Path $repoRoot 'models'
$null = New-Item -ItemType Directory -Force -Path $modelsPath
$null = Set-UserDefault 'OLLAMA_MODELS' $modelsPath
$ollamaHost = Set-UserDefault 'OLLAMA_HOST' '127.0.0.1:11434'
$null = Set-UserDefault 'OLLAMA_BASE_URL' ("http://" + $ollamaHost)

$key = [Environment]::GetEnvironmentVariable('LITELLM_MASTER_KEY', 'User')
if (-not $key) {
    $bytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    $rng.Dispose()
    $key = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
    [Environment]::SetEnvironmentVariable('LITELLM_MASTER_KEY', $key, 'User')
}
$env:LITELLM_MASTER_KEY = $key

$ollamaExe = [Environment]::GetEnvironmentVariable('OLLAMA_EXE', 'User')
if (-not $ollamaExe) {
    $ollamaCommand = Get-Command ollama.exe -ErrorAction SilentlyContinue
    if ($ollamaCommand) { $ollamaExe = $ollamaCommand.Source }
}
while (-not $ollamaExe -or -not (Test-Path -LiteralPath $ollamaExe)) {
    $ollamaExe = (Read-Host 'Enter the full path to ollama.exe (or Ctrl+C to stop)').Trim('"')
}
[Environment]::SetEnvironmentVariable('OLLAMA_EXE', $ollamaExe, 'User')
$env:OLLAMA_EXE = $ollamaExe

try {
    $null = Invoke-RestMethod -Uri ("http://" + $ollamaHost + '/api/tags') -TimeoutSec 3
    Write-Output 'Ollama API is responding.'
} catch {
    Write-Output 'Ollama API is not running yet; the CPU Startup launcher will start it at the next sign-in.'
}

if (-not $SkipModelPull) {
    $answer = Read-Host 'Pull qwen2.5:7b and granite-3b into OLLAMA_MODELS now? [y/N]'
    if ($answer -match '^(y|yes)$') {
        & $ollamaExe pull qwen2.5:7b
        if ($LASTEXITCODE -ne 0) { throw 'Pulling qwen2.5:7b failed.' }
        & $ollamaExe pull granite-3b
        if ($LASTEXITCODE -ne 0) { throw 'Pulling granite-3b failed.' }
    }
}

& $venvPython (Join-Path $repoRoot 'sync_clients.py')
if ($LASTEXITCODE -ne 0) { throw 'Client rule synchronization failed.' }
& (Join-Path $repoRoot 'gateway\install_autostart.ps1')
Write-Output 'Install complete. Sign out and back in if the current shell or Explorer has stale user environment values.'
