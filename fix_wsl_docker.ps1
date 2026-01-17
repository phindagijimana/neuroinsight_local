# PowerShell script to fix WSL/Docker Desktop issues
# Run this as Administrator in PowerShell

Write-Host "🔧 WSL/Docker Desktop Fix Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Stop Docker Desktop
Write-Host "1. Stopping Docker Desktop..." -ForegroundColor Yellow
Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "com.docker.backend" -Force -ErrorAction SilentlyContinue

# Wait a moment
Start-Sleep -Seconds 5

# Reset WSL
Write-Host "2. Resetting WSL integration..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep -Seconds 3

# Clean up Docker system
Write-Host "3. Cleaning Docker system..." -ForegroundColor Yellow
wsl -d docker-desktop -- /bin/sh -c "docker system prune -a --volumes -f"

# Restart WSL
Write-Host "4. Restarting WSL..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep -Seconds 5

# Start Docker Desktop
Write-Host "5. Starting Docker Desktop..." -ForegroundColor Green
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

Write-Host ""
Write-Host "✅ WSL/Docker Desktop reset complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Wait for Docker Desktop to fully start (2-3 minutes)" -ForegroundColor White
Write-Host "2. Check Docker status in Docker Desktop" -ForegroundColor White
Write-Host "3. Try running: docker run hello-world" -ForegroundColor White
Write-Host "4. Restart NeuroInsight: ./neuroinsight start" -ForegroundColor White
Write-Host ""
Write-Host "If issues persist, try:" -ForegroundColor Yellow
Write-Host "- Restart your computer" -ForegroundColor Yellow
Write-Host "- Reset Docker Desktop to factory defaults" -ForegroundColor Yellow
Write-Host "- Reinstall Docker Desktop" -ForegroundColor Yellow
