# verify-health.ps1
# Simple script to call the functions API health endpoint on the emulator
# Usage: run from any shell; pass project id as first param or edit below.

param(
    [string]$ProjectId = ''
)

if (-not $ProjectId) {
    Write-Host "Usage: .\verify-health.ps1 <FIREBASE_PROJECT_ID>" -ForegroundColor Yellow
    exit 1
}

$uri = "http://127.0.0.1:5019/$ProjectId/us-central1/api/health"
Write-Host "Calling $uri"
try {
    $resp = Invoke-RestMethod -Uri $uri -UseBasicParsing -TimeoutSec 10
    Write-Host "Response:" -ForegroundColor Green
    $resp | ConvertTo-Json -Depth 5
} catch {
    Write-Host "Failed to call health endpoint. Is the emulator running?" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
