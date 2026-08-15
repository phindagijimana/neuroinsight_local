# Uninstall NeuroInsight-AutoHS

$ContainerName = "neuroinsight-autohs"
$VolumeName = "neuroinsight-autohs-data"

function Write-Info { param([string]$Message); Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message); Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message); Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message); Write-Host "[ERROR] $Message" -ForegroundColor Red }

Write-Host ""
Write-Warning "This will remove NeuroInsight-AutoHS and ALL DATA"
Write-Host ""
$response = Read-Host "Are you sure? Type 'yes' to confirm"

if ($response -ne "yes") {
    Write-Info "Uninstall cancelled"
    exit 0
}

# Stop and remove container
Write-Info "Removing container..."
docker stop $ContainerName 2>$null | Out-Null
docker rm $ContainerName 2>$null | Out-Null
Write-Success "Container removed"

# Remove volume
Write-Info "Removing data volume..."
docker volume rm $VolumeName 2>$null | Out-Null
Write-Success "Volume removed"

# Remove FreeSurfer image (optional)
Write-Host ""
$response = Read-Host "Remove FreeSurfer image (20GB)? (y/N)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Info "Removing FreeSurfer image..."
    docker rmi freesurfer/freesurfer:7.4.1 2>$null | Out-Null
    Write-Success "FreeSurfer image removed"
}

# Remove NeuroInsight-AutoHS image (optional)
$response = Read-Host "Remove NeuroInsight-AutoHS image? (y/N)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Info "Removing NeuroInsight-AutoHS image..."
    docker rmi phindagijimana321/neuroinsight:latest 2>$null | Out-Null
    Write-Success "NeuroInsight-AutoHS image removed"
}

Write-Host ""
Write-Success "Uninstall complete"
Write-Host ""
