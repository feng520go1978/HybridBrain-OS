@echo off
chcp 65001 >nul
set "PYTHONUTF8=1"
setlocal

if not defined OLLAMA_HOST set "OLLAMA_HOST=127.0.0.1:11434"
if not defined OLLAMA_BASE_URL set "OLLAMA_BASE_URL=http://%OLLAMA_HOST%"
if not defined LITELLM_MASTER_KEY (
  echo LITELLM_MASTER_KEY is not set. Run install.ps1 or set it in the user environment.
  exit /b 1
)
if not exist "%~dp0.venv\Scripts\litellm.exe" (
  echo LiteLLM is not installed. Run install.ps1 first.
  exit /b 1
)

call "%~dp0.venv\Scripts\activate.bat"
cd /d "%~dp0"
"%~dp0.venv\Scripts\litellm.exe" --config router_config.yaml --port 4000
