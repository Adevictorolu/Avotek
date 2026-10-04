# =============================================================================
# Avotek Web Launcher
# Runs the Flutter Web app smoothly without DWDS debugger connection timeouts.
# =============================================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "          AVOTEK WEB LAUNCHER                " -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Choose how to run the application:"
Write-Host " [1] Chrome (Release Mode - Fast, Smooth, Never Shuts Off) [Default]" -ForegroundColor Green
Write-Host " [2] Web Server (http://localhost:3000 - Hot Reload enabled)" -ForegroundColor Yellow
Write-Host " [3] Edge (Release Mode - Smooth & Fast)" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "Enter option (1, 2, or 3) [Default: 1]"
if ([string]::IsNullOrWhiteSpace($choice)) {
    $choice = "1"
}

$flutterDir = Join-Path $PSScriptRoot "avotek\avotek_flutter"
Set-Location $flutterDir

switch ($choice) {
    "1" {
        Write-Host "`nLaunching on Chrome in Release Mode..." -ForegroundColor Green
        Write-Host "Chrome will open and stay open continuously.`n" -ForegroundColor Gray
        flutter run -d chrome --release --web-hostname=127.0.0.1
    }
    "2" {
        Write-Host "`nStarting Local Web Server on port 3000 with Hot Reload..." -ForegroundColor Yellow
        Write-Host "Open http://localhost:3000 in your browser." -ForegroundColor Gray
        Write-Host "Press 'r' for Hot Reload, 'R' for Hot Restart, 'q' to Quit.`n" -ForegroundColor Gray
        Start-Process "http://localhost:3000"
        flutter run -d web-server --web-port=3000 --web-hostname=127.0.0.1
    }
    "3" {
        Write-Host "`nLaunching on Microsoft Edge in Release Mode..." -ForegroundColor Cyan
        flutter run -d edge --release --web-hostname=127.0.0.1
    }
    Default {
        Write-Host "`nLaunching on Chrome in Release Mode..." -ForegroundColor Green
        flutter run -d chrome --release --web-hostname=127.0.0.1
    }
}
