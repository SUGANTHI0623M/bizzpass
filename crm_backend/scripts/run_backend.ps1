# Run CRM backend (from crm_backend directory or repo root).
# Usage: .\scripts\run_backend.ps1   or   cd crm_backend; ..\scripts\run_backend.ps1

$BackendDir = $PSScriptRoot -replace '\\scripts$', ''
if (-not (Test-Path "$BackendDir\main.py")) {
    $BackendDir = Join-Path $PSScriptRoot ".."
    $BackendDir = (Resolve-Path $BackendDir).Path
}
Set-Location $BackendDir

$VenvActivate = Join-Path $BackendDir ".venv\Scripts\Activate.ps1"
if (Test-Path $VenvActivate) {
    & $VenvActivate
}
# Use python -m uvicorn so it works even when uvicorn isn't on PATH
Write-Host "Starting backend at http://localhost:8000" -ForegroundColor Green
Write-Host "Plans create: POST http://localhost:8000/plans/create" -ForegroundColor Cyan
& (Join-Path $BackendDir ".venv\Scripts\python.exe") -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
