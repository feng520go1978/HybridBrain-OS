@echo off
setlocal
set "CUDA_VISIBLE_DEVICES=-1"
if not defined OLLAMA_HOST set "OLLAMA_HOST=127.0.0.1:11434"
if not defined OLLAMA_MODELS set "OLLAMA_MODELS=%~dp0..\models"
cd /d "%~dp0"

if defined OLLAMA_EXE (
  if not exist "%OLLAMA_EXE%" (
    echo OLLAMA_EXE does not point to an existing executable.
    exit /b 1
  )
  "%OLLAMA_EXE%" serve
  exit /b %ERRORLEVEL%
)
where ollama.exe >nul 2>&1
if errorlevel 1 (
  echo Ollama was not found on PATH. Set OLLAMA_EXE or add Ollama to PATH.
  exit /b 1
)
ollama.exe serve
