# Helper script to start local services for development on Windows PowerShell.
#
# Usage: run this script from the repository root in PowerShell:
#   .\start-local.ps1
#
# What it does (interactive / safe by default):
# - Checks for required CLIs (firebase, flutter)
# - Reminds you to create .env from .env.example if missing
# - Starts Firebase emulators (functions) in the backend folder
# - Optionally runs Flutter web (if Flutter SDK is installed)
#
# Note: This script does not deploy anything. Provide real secrets in
# `backend/functions/.env` and `flutter_app/.env` before running services.

function Ensure-EnvFile {
    param(
        [string]$ExamplePath,
        [string]$TargetPath
    )
    if (-not (Test-Path $TargetPath)) {
        Write-Host "WARNING: $TargetPath not found. Copy $ExamplePath to $TargetPath and fill values before running." -ForegroundColor Yellow
    } else {
        Write-Host "$TargetPath exists." -ForegroundColor Green
    }
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Repository root: $root"

Ensure-EnvFile -ExamplePath "backend/functions/.env.example" -TargetPath "backend/functions/.env"
Ensure-EnvFile -ExamplePath "flutter_app/.env.example" -TargetPath "flutter_app/.env"

if (Get-Command firebase -ErrorAction SilentlyContinue) {
    Write-Host "firebase CLI found: $(firebase --version)"
} else {
    Write-Host "firebase CLI not found. Install with: npm install -g firebase-tools" -ForegroundColor Yellow
}

# Start Firebase emulators (functions) - run in backend folder where firebase.json lives
Push-Location "$root\backend"
Write-Host "Starting Firebase Functions emulator in folder: $PWD"
Write-Host "If this is your first time, run 'firebase login' and ensure your .env is configured."

Write-Host "Running: firebase emulators:start --only functions" -ForegroundColor Cyan
firebase emulators:start --only functions

Pop-Location

# Optional: run Flutter web (uncomment the following lines if you want the script to also run Flutter)
# if (Get-Command flutter -ErrorAction SilentlyContinue) {
#     Push-Location "$root\flutter_app"
#     Write-Host "Running Flutter web: flutter run -d chrome"
#     flutter run -d chrome
#     Pop-Location
# } else {
#     Write-Host "Flutter SDK not found. Install Flutter and add to PATH to run the app locally." -ForegroundColor Yellow
# }
