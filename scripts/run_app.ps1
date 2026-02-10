# Start backend (Docker) and print URLs for BizzPass Admin CRM.
# Run from project root: .\scripts\run_app.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Set-Location $Root

Write-Host ""
Write-Host "BizzPass Admin CRM - Starting backend..." -ForegroundColor Cyan
docker compose up -d 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker failed. Is Docker running?" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Backend (API):  http://localhost:8000" -ForegroundColor Green
Write-Host "App (UI):       http://localhost:8080" -ForegroundColor Green
Write-Host ""
Write-Host "Open the app in your browser: http://localhost:8080" -ForegroundColor Yellow
Write-Host ""
Write-Host "To start the Flutter app (if not already running):" -ForegroundColor Gray
Write-Host "  cd bizzpass_crm" -ForegroundColor Gray
Write-Host "  flutter run -d web-server --web-port 8080" -ForegroundColor Gray
Write-Host ""
