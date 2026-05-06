<#
.SYNOPSIS
    Dermavision Setup Script for Windows
.DESCRIPTION
    Automates the setup of Flutter and Python environments for the Dermavision project.
#>

Write-Host "--- Dermavision Project Setup ---" -ForegroundColor Cyan

# 1. Check Flutter
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter not found. Please install Flutter and add it to your PATH."
    exit 1
}

# 2. Setup Mobile App
Write-Host "`n[1/3] Setting up Flutter application..." -ForegroundColor Yellow
Set-Location -Path "mobile_app"
Write-Host "Running flutter pub get..."
flutter pub get

# 3. Download TFLite Libraries
Write-Host "`n[2/3] Installing native TFLite libraries..." -ForegroundColor Yellow
& ".\download_tflite_libs.ps1"
Set-Location -Path ".."

# 4. Setup Python (Optional but recommended)
Write-Host "`n[3/3] Setting up Python environment..." -ForegroundColor Yellow
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Installing Python dependencies..."
    pip install -r requirements.txt
} else {
    Write-Host "Python not found. Skipping ML dependency installation." -ForegroundColor Gray
}

Write-Host "`n--- Setup Complete! ---" -ForegroundColor Green
Write-Host "You can now open the project in VS Code and run the app."
