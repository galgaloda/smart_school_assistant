# Smart School Assistant - Clear App Data (PowerShell Script)
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Smart School Assistant - Clear App Data" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$confirmation = Read-Host "This will clear all user data for Smart School Assistant including Hive databases, settings, and cached files. Continue? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Clearing app data directories..." -ForegroundColor Green
Write-Host ""

# Get user profile paths
$appDataPath = "$env:APPDATA\smart_school_assistant"
$localAppDataPath = "$env:LOCALAPPDATA\smart_school_assistant"
$documentsPath = "$env:USERPROFILE\Documents\smart_school_assistant"
$tempPath = "$env:TEMP\flutter_app_data"

# Clear main app data directory
if (Test-Path $appDataPath) {
    Write-Host "Clearing $appDataPath" -ForegroundColor Yellow
    Remove-Item -Path $appDataPath -Recurse -Force
    Write-Host "✓ Cleared main app data" -ForegroundColor Green
} else {
    Write-Host "⚠ Main app data directory not found" -ForegroundColor Gray
}

# Clear local app data directory
if (Test-Path $localAppDataPath) {
    Write-Host "Clearing $localAppDataPath" -ForegroundColor Yellow
    Remove-Item -Path $localAppDataPath -Recurse -Force
    Write-Host "✓ Cleared local app data" -ForegroundColor Green
} else {
    Write-Host "⚠ Local app data directory not found" -ForegroundColor Gray
}

# Clear documents directory
if (Test-Path $documentsPath) {
    Write-Host "Clearing $documentsPath" -ForegroundColor Yellow
    Remove-Item -Path $documentsPath -Recurse -Force
    Write-Host "✓ Cleared documents data" -ForegroundColor Green
} else {
    Write-Host "⚠ Documents data directory not found" -ForegroundColor Gray
}

# Clear temp flutter data
if (Test-Path $tempPath) {
    Write-Host "Clearing $tempPath" -ForegroundColor Yellow
    Remove-Item -Path $tempPath -Recurse -Force
    Write-Host "✓ Cleared temp flutter data" -ForegroundColor Green
} else {
    Write-Host "⚠ Temp flutter data directory not found" -ForegroundColor Gray
}

# Clear any Hive boxes in current directory
$currentDir = Get-Location
$hiveFiles = Get-ChildItem -Path $currentDir -Filter "*.hive" -File
if ($hiveFiles.Count -gt 0) {
    Write-Host "Clearing local Hive database files" -ForegroundColor Yellow
    $hiveFiles | Remove-Item -Force
    Write-Host "✓ Cleared local Hive files" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " App data clearing completed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All user data has been cleared. The app will start fresh" -ForegroundColor White
Write-Host "with no previous data when you run it next time." -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"