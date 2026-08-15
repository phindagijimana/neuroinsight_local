# NeuroInsight Docker Management CLI for Windows
# PowerShell equivalent of Linux neuroinsight-docker script

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ContainerName = "neuroinsight"
$ImageName = "phindagijimana321/neuroinsight:latest"
$FreeSurferImage = if ($env:FREESURFER_IMAGE) { $env:FREESURFER_IMAGE } else { "freesurfer/freesurfer:7.4.1" }
$VolumeName = "neuroinsight-data"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DeployDir = Join-Path (Split-Path -Parent $ScriptDir) "deploy"
$ProjectRoot = Split-Path -Parent $DeployDir

# Colors
function Write-Info { param([string]$Message); Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message); Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message); Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message); Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Helper functions
function Test-Docker {
    try {
        docker ps | Out-Null
        return $true
    } catch {
        Write-Error "Docker is not running"
        Write-Host "Please start Docker Desktop and try again"
        return $false
    }
}

function Test-ContainerExists {
    $exists = docker ps -a --filter "name=^${ContainerName}$" --format "{{.Names}}"
    return ($exists -eq $ContainerName)
}

function Test-ContainerRunning {
    $running = docker ps --filter "name=^${ContainerName}$" --format "{{.Names}}"
    return ($running -eq $ContainerName)
}

function Get-ContainerPort {
    $portMapping = docker port $ContainerName 8000 2>$null
    if ($portMapping) {
        return ($portMapping -replace '.*:', '')
    }
    return $null
}

function Get-DockerPlatformArgs {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        return @("--platform", "linux/amd64")
    }
    return @()
}

function Get-EntrypointMountArgs {
    $entrypoint = Join-Path $DeployDir "entrypoint.sh"
    if (Test-Path $entrypoint) {
        return @("-v", "${entrypoint}:/app/entrypoint.sh:ro")
    }
    return @()
}

function Find-LicensePath {
    $candidates = @(
        (Join-Path $DeployDir "license.txt"),
        (Join-Path (Split-Path -Parent $DeployDir) "license.txt"),
        (Join-Path $env:USERPROFILE "Documents\license.txt"),
        (Join-Path $env:USERPROFILE "license.txt")
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) {
            $content = Get-Content $path -Raw -ErrorAction SilentlyContinue
            if ($content -match "REPLACE THIS EXAMPLE" -or $content -match "FreeSurfer License File - EXAMPLE") {
                continue
            }
            return (Resolve-Path $path).Path
        }
    }
    return $null
}

function Write-LicenseHelp {
    param([string]$Reason = "not found")
    Write-Host "FreeSurfer license.txt $Reason."
    Write-Host ""
    Write-Host "This is the only manual setup step. Place your license file here (recommended):"
    Write-Host "  $(Join-Path $ProjectRoot 'license.txt')"
    Write-Host ""
    Write-Host "Other accepted locations:"
    Write-Host "  $env:USERPROFILE\Documents\license.txt"
    Write-Host "  $env:USERPROFILE\license.txt"
    Write-Host ""
    Write-Host "Get a free research license (required for MRI processing):"
    Write-Host "  https://surfer.nmr.mgh.harvard.edu/registration.html"
    Write-Host ""
    Write-Host "After adding the license, run:"
    Write-Host "  .\neuroinsight-docker.ps1 setup"
}

function Test-PortFree {
    param([int]$Port)
    $connection = Test-NetConnection -ComputerName localhost -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
    return (-not $connection)
}

function Invoke-PreflightInstall {
    param([switch]$ShowSteps)

    $blockers = @()
    $fixes = @()
    $warnings = @()
    $totalSteps = 9
    $step = 0

    function Write-PreflightStepBegin {
        param([string]$Label)
        $script:step++
        if ($ShowSteps) {
            Write-Host ""
            Write-Host "[$($script:step)/$totalSteps] $Label..." -ForegroundColor Cyan
        }
    }

    function Write-PreflightStepOk {
        param([string]$Message)
        if ($ShowSteps) { Write-Host "      OK   $Message" -ForegroundColor Green }
    }

    function Write-PreflightStepFail {
        param([string]$Message)
        if ($ShowSteps) { Write-Host "      FAIL $Message" -ForegroundColor Red }
    }

    function Write-PreflightStepWarn {
        param([string]$Message)
        if ($ShowSteps) { Write-Host "      WARN $Message" -ForegroundColor Yellow }
    }

    function Test-DockerDaemon {
        try {
            docker info 2>$null | Out-Null
            return ($LASTEXITCODE -eq 0)
        } catch {
            return $false
        }
    }

    if ($ShowSteps) {
        Write-Host ""
        Write-Info "Project: $ProjectRoot"
        Write-Info "Running $totalSteps setup checks..."
    }

    Write-PreflightStepBegin "Checking Docker installation"
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-PreflightStepFail "Docker CLI not found"
        $blockers += "Docker is not installed"
        $fixes += @(
            "Install Docker Desktop, then re-run:",
            "  .\neuroinsight-docker.ps1 setup",
            "  https://www.docker.com/products/docker-desktop/"
        ) -join "`n"
    } else {
        Write-PreflightStepOk "Docker CLI found"
    }

    Write-PreflightStepBegin "Checking Docker daemon"
    if ((Get-Command docker -ErrorAction SilentlyContinue) -and (Test-DockerDaemon)) {
        Write-PreflightStepOk "Docker daemon is running"
    } elseif (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-PreflightStepFail "Docker daemon is not running"
        $blockers += "Docker is installed but the daemon is not running"
        $fixes += @(
            "Start Docker Desktop, then re-run:",
            "  .\neuroinsight-docker.ps1 setup"
        ) -join "`n"
    } else {
        Write-PreflightStepFail "Skipped (Docker not installed)"
    }

    Write-PreflightStepBegin "Checking FreeSurfer license.txt"
    $licensePath = Find-LicensePath
    if (-not $licensePath) {
        Write-PreflightStepFail "license.txt not found"
        $blockers += "FreeSurfer license.txt not found"
        $fixes += @(
            "Place your license in the neuroinsight_local folder (recommended):",
            "  $(Join-Path $ProjectRoot 'license.txt')",
            "",
            "Other accepted locations:",
            "  $env:USERPROFILE\Documents\license.txt",
            "  $env:USERPROFILE\license.txt",
            "",
            "Get a free research license:",
            "  https://surfer.nmr.mgh.harvard.edu/registration.html"
        ) -join "`n"
    } else {
        Write-PreflightStepOk "Valid license found at $licensePath"
    }

    Write-PreflightStepBegin "Checking web UI port (8000-8050)"
    $webPort = $null
    for ($p = 8000; $p -le 8050; $p++) {
        if (Test-PortFree -Port $p) { $webPort = $p; break }
    }
    if (-not $webPort) {
        Write-PreflightStepFail "No free port in range 8000-8050"
        $blockers += "No free port for web UI (range 8000-8050)"
        $fixes += "Stop other services using ports 8000-8050, then re-run setup."
    } else {
        Write-PreflightStepOk "Port $webPort available for web UI"
    }

    Write-PreflightStepBegin "Checking MinIO ports (9000-9050)"
    $minioApiPort = $null
    $minioConsolePort = $null
    for ($p = 9000; $p -le 9050; $p++) {
        if (Test-PortFree -Port $p) { $minioApiPort = $p; break }
    }
    for ($p = 9000; $p -le 9050; $p++) {
        if ($p -eq $minioApiPort) { continue }
        if (Test-PortFree -Port $p) { $minioConsolePort = $p; break }
    }
    if (-not $minioApiPort -or -not $minioConsolePort) {
        Write-PreflightStepFail "Need two free ports in range 9000-9050"
        $blockers += "No free ports for MinIO (range 9000-9050)"
        $fixes += "Stop other services using ports 9000-9050, then re-run setup."
    } else {
        Write-PreflightStepOk "Ports $minioApiPort (API) and $minioConsolePort (console) available"
    }

    Write-PreflightStepBegin "Checking Docker Desktop entrypoint fix"
    $entrypoint = Join-Path $DeployDir "entrypoint.sh"
    if (Test-Path $entrypoint) {
        Write-PreflightStepOk "deploy/entrypoint.sh present (will mount on install)"
    } else {
        Write-PreflightStepWarn "deploy/entrypoint.sh missing — some Docker Desktop installs may fail"
        $warnings += "deploy/entrypoint.sh missing — some Docker Desktop installs may fail"
    }

    Write-PreflightStepBegin "Checking network tools (UI readiness wait)"
    Write-PreflightStepOk "Invoke-WebRequest available (built-in on Windows)"

    Write-PreflightStepBegin "Checking disk space"
    try {
        $drive = (Get-Location).Drive
        if ($drive) {
            $freeGb = [math]::Round($drive.Free / 1GB)
            if ($freeGb -lt 50) {
                Write-PreflightStepWarn "$freeGb GB free (recommend 50GB+ for MRI data)"
                $warnings += "Low disk space: ${freeGb}GB free (recommend 50GB+ for MRI data)"
            } else {
                Write-PreflightStepOk "$freeGb GB free disk space"
            }
        } else {
            Write-PreflightStepOk "Disk space check skipped"
        }
    } catch {
        Write-PreflightStepOk "Disk space check skipped"
    }

    Write-PreflightStepBegin "Checking system memory"
    try {
        $memGb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
        if ($memGb -lt 16) {
            Write-PreflightStepWarn "$memGb GB RAM (recommend 16GB+ for MRI processing)"
            $warnings += "Low RAM: ${memGb}GB (recommend 16GB+ for MRI processing)"
        } else {
            Write-PreflightStepOk "$memGb GB RAM"
        }
    } catch {
        Write-PreflightStepOk "Memory check skipped"
    }

    if ($ShowSteps) {
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Cyan
        if ($blockers.Count -eq 0) {
            Write-Host "Check complete — all required items OK" -ForegroundColor Green
        } else {
            Write-Host "Check complete — $($blockers.Count) required item(s) need attention" -ForegroundColor Red
        }
        Write-Host "======================================" -ForegroundColor Cyan
    }

    if ($blockers.Count -eq 0) {
        if (-not $ShowSteps) {
            foreach ($w in $warnings) { Write-Warning $w }
        }
        return $true
    }

    if (-not $ShowSteps) {
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Red
        Write-Host "Setup requirements not met" -ForegroundColor Red
        Write-Host "======================================" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Fix the items below, then re-run:"
    if ($ShowSteps) {
        Write-Host "  .\neuroinsight-docker.ps1 check"
        Write-Host "  .\neuroinsight-docker.ps1 setup"
    } else {
        Write-Host "  .\neuroinsight-docker.ps1 setup"
    }
    Write-Host ""

    for ($i = 0; $i -lt $blockers.Count; $i++) {
        Write-Error $blockers[$i]
        Write-Host ""
        Write-Host $fixes[$i]
        Write-Host ""
    }

    if ($warnings.Count -gt 0) {
        Write-Host "Warnings (non-blocking):"
        foreach ($w in $warnings) { Write-Warning $w }
        Write-Host ""
    }

    return $false
}

function Invoke-PullRequiredImages {
    $platform = Get-DockerPlatformArgs
    Write-Info "Pulling application image: $ImageName..."
    docker pull @platform $ImageName
    Write-Info "Pulling FreeSurfer image: $FreeSurferImage (large download)..."
    try {
        docker pull @platform $FreeSurferImage | Out-Null
    } catch {
        Write-Warning "FreeSurfer image pull failed — will retry when a job starts"
    }
}

function Wait-WebReady {
    param([int]$Port, [int]$Attempts = 60)
    Write-Info "Waiting for NeuroInsight web UI on port $Port..."
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port/" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
            if ($response.StatusCode -ge 200) {
                Write-Success "Web UI is ready (http://localhost:$Port)"
                return $true
            }
        } catch {
            if (-not (Test-ContainerRunning)) {
                Write-Error "Container stopped while starting"
                return $false
            }
        }
        Start-Sleep -Seconds 5
    }
    Write-Warning "Web UI did not respond in time — check status"
    return $false
}

# Command: install
function Invoke-Install {
    param([switch]$AssumeYes)
    
    if (-not (Invoke-PreflightInstall)) { exit 1 }
    
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "  NeuroInsight Docker Installation" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check existing
    if (Test-ContainerExists) {
        if ($AssumeYes) {
            Invoke-Remove
        } else {
            Write-Warning "NeuroInsight container already exists"
            $response = Read-Host "Remove and reinstall? (y/N)"
            if ($response -ne "y" -and $response -ne "Y") {
                Write-Info "Keeping existing container — run: .\neuroinsight-docker.ps1 start"
                exit 0
            }
            Invoke-Remove
        }
    }
    
    # Find available port
    Write-Info "Finding available port (range: 8000-8050)..."
    $selectedPort = $null
    for ($testPort = 8000; $testPort -le 8050; $testPort++) {
        $connection = Test-NetConnection -ComputerName localhost -Port $testPort -InformationLevel Quiet -WarningAction SilentlyContinue
        if (-not $connection) {
            $selectedPort = $testPort
            break
        }
    }
    
    if (-not $selectedPort) {
        Write-Error "No available ports found in range 8000-8050"
        exit 1
    }
    
    Write-Success "Selected web port: $selectedPort"
    
    # MinIO ports in 9000-9050 (exclude web-derived offsets)
    $minioApiPort = $null
    for ($testPort = 9000; $testPort -le 9050; $testPort++) {
        $connection = Test-NetConnection -ComputerName localhost -Port $testPort -InformationLevel Quiet -WarningAction SilentlyContinue
        if (-not $connection) {
            $minioApiPort = $testPort
            break
        }
    }
    if (-not $minioApiPort) {
        Write-Error "No available ports found in range 9000-9050 for MinIO API"
        exit 1
    }
    Write-Success "Selected MinIO API port: $minioApiPort"
    
    $minioConsolePort = $null
    for ($testPort = 9000; $testPort -le 9050; $testPort++) {
        if ($testPort -eq $minioApiPort) { continue }
        $connection = Test-NetConnection -ComputerName localhost -Port $testPort -InformationLevel Quiet -WarningAction SilentlyContinue
        if (-not $connection) {
            $minioConsolePort = $testPort
            break
        }
    }
    if (-not $minioConsolePort) {
        Write-Error "No available ports found in range 9000-9050 for MinIO Console"
        exit 1
    }
    Write-Success "Selected MinIO Console port: $minioConsolePort"
    
    $licensePath = Find-LicensePath
    if (-not $licensePath) {
        Write-LicenseHelp
        exit 1
    }
    Write-Success "License found and will be mounted: $licensePath"
    
    Invoke-PullRequiredImages
    
    # Create volume
    Write-Info "Creating data volume..."
    $existingVolume = docker volume ls --filter "name=^${VolumeName}$" --format "{{.Name}}"
    if ($existingVolume -ne $VolumeName) {
        docker volume create $VolumeName | Out-Null
        Write-Success "Volume created"
    } else {
        Write-Success "Volume exists (preserving data)"
    }
    
    # Create container
    Write-Info "Creating container..."
    Write-Info "  Web Interface: http://localhost:${selectedPort}"
    Write-Info "  MinIO API: http://localhost:${minioApiPort}"
    Write-Info "  MinIO Console: http://localhost:${minioConsolePort}"
    
    $dockerArgs = @(
        "run", "-d",
        "--name", $ContainerName,
        "-p", "${selectedPort}:8000",
        "-p", "${minioApiPort}:9000",
        "-p", "${minioConsolePort}:9001",
        "-v", "/var/run/docker.sock:/var/run/docker.sock",
        "-v", "${VolumeName}:/data",
        "-v", "${licensePath}:/app/license.txt:ro",
        "--restart", "unless-stopped"
    )
    $dockerArgs += Get-EntrypointMountArgs
    $dockerArgs += Get-DockerPlatformArgs
    $dockerArgs += $ImageName
    
    try {
        docker @dockerArgs | Out-Null
        Write-Success "Container created"
    } catch {
        Write-Error "Failed to create container"
        exit 1
    }
    
    Wait-WebReady -Port $selectedPort | Out-Null
    
    Invoke-Status
    
    Write-Host ""
    Write-Success "NeuroInsight is ready!"
    Write-Host "Web Interface: http://localhost:${selectedPort}" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-Setup {
    Invoke-Install -AssumeYes
}

function Invoke-Check {
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "NeuroInsight setup check" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    if (Invoke-PreflightInstall -ShowSteps) {
        Write-Host ""
        Write-Success "All requirements met — run: .\neuroinsight-docker.ps1 setup"
    } else {
        exit 1
    }
}

# Command: start
function Invoke-Start {
    if (-not (Test-Docker)) { exit 1 }
    
    if (-not (Test-ContainerExists)) {
        Write-Error "Container does not exist."
        Write-Host ""
        if (Find-LicensePath) {
            Write-Host "License is ready. Run:"
            Write-Host "  .\neuroinsight-docker.ps1 setup"
        } else {
            Write-LicenseHelp
        }
        exit 1
    }
    
    if (Test-ContainerRunning) {
        Write-Warning "Container is already running"
        $port = Get-ContainerPort
        if ($port) {
            Write-Host "Web Interface: http://localhost:$port" -ForegroundColor Cyan
        }
        exit 0
    }
    
    Write-Info "Starting NeuroInsight..."
    docker start $ContainerName | Out-Null
    Start-Sleep -Seconds 3
    
    Write-Success "Container started"
    $port = Get-ContainerPort
    if ($port) {
        Wait-WebReady -Port ([int]$port) -Attempts 24 | Out-Null
        Write-Host "Web Interface: http://localhost:$port" -ForegroundColor Cyan
    }
}

# Command: stop
function Invoke-Stop {
    if (-not (Test-Docker)) { exit 1 }
    
    if (-not (Test-ContainerRunning)) {
        Write-Warning "Container is not running"
        exit 0
    }
    
    Write-Info "Stopping NeuroInsight..."
    docker stop $ContainerName | Out-Null
    Write-Success "Container stopped"
}

# Command: restart
function Invoke-Restart {
    Invoke-Stop
    Start-Sleep -Seconds 2
    Invoke-Start
}

# Command: status
function Invoke-Status {
    if (-not (Test-Docker)) { exit 1 }
    
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "  NeuroInsight Docker Status" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-ContainerExists)) {
        Write-Error "Container does not exist"
        Write-Host "Run: .\neuroinsight-docker.ps1 install"
        exit 1
    }
    
    if (Test-ContainerRunning) {
        Write-Success "Container is running"
        Write-Host ""
        
        $port = Get-ContainerPort
        if ($port) {
            Write-Host "Web Interface: http://localhost:$port" -ForegroundColor Cyan
            Write-Host ""
        }
        
        # Container details
        docker ps --filter "name=^${ContainerName}$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        Write-Host ""
        
        # Service status
        Write-Info "Services:"
        try {
            docker exec $ContainerName supervisorctl status 2>$null
        } catch {
            Write-Warning "Could not get service status"
        }
    } else {
        Write-Warning "Container exists but is not running"
        Write-Host "Run: .\neuroinsight-docker.ps1 start"
    }
    
    Write-Host ""
}

# Command: logs
function Invoke-Logs {
    param([string]$Service = "all", [switch]$Follow)
    
    if (-not (Test-ContainerRunning)) {
        Write-Error "Container is not running"
        exit 1
    }
    
    $followArg = if ($Follow) { "-f" } else { "--tail", "100" }
    
    switch ($Service) {
        "backend" {
            Write-Info "Backend logs:"
            docker exec $ContainerName tail $followArg /var/log/supervisor/backend.log
        }
        "worker" {
            Write-Info "Worker logs:"
            docker exec $ContainerName tail $followArg /var/log/supervisor/celery_worker.log
        }
        "monitor" {
            Write-Info "Job monitor logs:"
            docker exec $ContainerName tail $followArg /var/log/supervisor/job_monitor.log
        }
        default {
            Write-Info "All container logs:"
            docker logs @followArg $ContainerName
        }
    }
}

# Command: health
function Invoke-Health {
    if (-not (Test-ContainerRunning)) {
        Write-Error "Container is not running"
        exit 1
    }
    
    Write-Info "Running health check..."
    docker exec $ContainerName /app/healthcheck.sh
}

# Command: clean
function Invoke-Clean {
    param([int]$Days = 30, [switch]$DryRun)
    
    if (-not (Test-ContainerRunning)) {
        Write-Error "Container is not running"
        exit 1
    }
    
    Write-Info "Cleaning jobs older than $Days days..."
    if ($DryRun) {
        Write-Warning "DRY RUN MODE"
    }
    
    $cleanCmd = "cd /app && python -c `"from scripts.clean import main; main(days=$Days"
    if ($DryRun) { $cleanCmd += ", dry_run=True" }
    $cleanCmd += ")`""
    
    docker exec -it $ContainerName bash -c $cleanCmd
}

# Command: backup
function Invoke-Backup {
    param([string]$Output = "neuroinsight-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').tar.gz")
    
    Write-Info "Creating backup: $Output"
    docker run --rm -v "${VolumeName}:/data" -v "$(Get-Location):/backup" alpine tar czf "/backup/$Output" /data
    Write-Success "Backup created: $Output"
}

# Command: restore
function Invoke-Restore {
    param([string]$BackupFile)
    
    if (-not $BackupFile) {
        Write-Error "Please specify backup file"
        Write-Host "Usage: .\neuroinsight-docker.ps1 restore <backup-file>"
        exit 1
    }
    
    if (-not (Test-Path $BackupFile)) {
        Write-Error "Backup file not found: $BackupFile"
        exit 1
    }
    
    Write-Warning "This will overwrite all data"
    $response = Read-Host "Continue? (yes/no)"
    if ($response -ne "yes") { exit 0 }
    
    if (Test-ContainerRunning) {
        Write-Info "Stopping container..."
        docker stop $ContainerName | Out-Null
        $needRestart = $true
    } else {
        $needRestart = $false
    }
    
    $fullPath = (Resolve-Path $BackupFile).Path
    Write-Info "Restoring from: $fullPath"
    
    docker run --rm -v "${VolumeName}:/data" -v "$(Split-Path $fullPath):/backup" alpine sh -c "cd / && tar xzf /backup/$(Split-Path $fullPath -Leaf)"
    Write-Success "Restore completed"
    
    if ($needRestart) {
        docker start $ContainerName | Out-Null
        Write-Success "Container restarted"
    }
}

# Command: remove/uninstall
function Invoke-Remove {
    if (-not (Test-Docker)) { exit 1 }
    
    Write-Warning "This will remove the NeuroInsight container"
    Write-Info "Data volume will be preserved (use 'clean --all' to remove data)"
    
    if (Test-ContainerRunning) {
        Write-Info "Stopping container..."
        docker stop $ContainerName | Out-Null
    }
    
    if (Test-ContainerExists) {
        Write-Info "Removing container..."
        docker rm $ContainerName | Out-Null
        Write-Success "Container removed"
    } else {
        Write-Warning "Container does not exist"
    }
}

# Command: update
function Invoke-Update {
    if (-not (Test-Docker)) { exit 1 }
    
    Write-Info "Updating NeuroInsight to latest version..."
    Write-Host ""
    
    Invoke-PullRequiredImages
    
    if (-not (Test-ContainerExists)) {
        Write-Info "No container to update. Run: .\neuroinsight-docker.ps1 setup"
        exit 0
    }
    
    Write-Info "Recreating container with new image..."
    Invoke-Remove
    Invoke-Install -AssumeYes
}

# Command: license
function Invoke-License {
    if (-not (Test-ContainerRunning)) {
        Write-Error "Container is not running"
        exit 1
    }
    
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "  FreeSurfer License" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    $licenseExists = docker exec $ContainerName test -f /app/license.txt 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "License found in container"
        Write-Host ""
        docker exec $ContainerName cat /app/license.txt
        Write-Host ""
    } else {
        Write-Warning "No license in container"
        Write-Host ""
        Write-Host "To add license:" -ForegroundColor Yellow
        Write-Host "  1. Get license: https://surfer.nmr.mgh.harvard.edu/registration.html"
        Write-Host "  2. Save as 'license.txt' in this folder"
        Write-Host "  3. Run: .\neuroinsight-docker.ps1 restart"
        Write-Host ""
    }
}

# Command: help
function Show-Help {
    Write-Host @"

NeuroInsight Docker Management CLI for Windows

USAGE:
    .\neuroinsight-docker.ps1 <command> [options]

COMMANDS:
    setup           First-time install (non-interactive; license.txt required)
    check           Run step-by-step prerequisite checks (license, Docker, ports)
    install [-y]    Install and start NeuroInsight
    start           Start the container
    stop            Stop the container
    restart         Restart the container
    status          Show container status
    logs [service]  View logs (all, backend, worker, monitor)
    health          Run health check
    clean [days]    Clean old jobs (default: 30 days)
    backup [file]   Backup all data
    restore <file>  Restore from backup
    license         Check FreeSurfer license
    update          Update to latest version
    remove          Remove container (keeps data)
    uninstall       Same as remove
    help            Show this help

EXAMPLES:
    .\neuroinsight-docker.ps1 setup
    .\neuroinsight-docker.ps1 install
    .\neuroinsight-docker.ps1 start
    .\neuroinsight-docker.ps1 status
    .\neuroinsight-docker.ps1 logs worker
    .\neuroinsight-docker.ps1 clean -Days 7
    .\neuroinsight-docker.ps1 backup
    .\neuroinsight-docker.ps1 restore backup.tar.gz

QUICK SHORTCUTS (Batch files):
    install.bat     Install
    start.bat       Start
    stop.bat        Stop
    status.bat      Status
    logs.bat        Logs

MORE INFO:
    README.md              Complete documentation
    QUICK_REFERENCE.md     Command reference

"@
}

# Main command dispatcher
switch ($Command.ToLower()) {
    "setup" {
        Invoke-Setup
    }
    "check" {
        Invoke-Check
    }
    "install" {
        $assumeYes = ($Arguments -contains "-y")
        Invoke-Install -AssumeYes:$assumeYes
    }
    "start" {
        Invoke-Start
    }
    "stop" {
        Invoke-Stop
    }
    "restart" {
        Invoke-Restart
    }
    "status" {
        Invoke-Status
    }
    "logs" {
        $service = if ($Arguments[0]) { $Arguments[0] } else { "all" }
        $follow = $Arguments -contains "-f" -or $Arguments -contains "--follow"
        Invoke-Logs -Service $service -Follow:$follow
    }
    "health" {
        Invoke-Health
    }
    "clean" {
        $days = 30
        $dryRun = $false
        foreach ($arg in $Arguments) {
            if ($arg -match '^\d+$') {
                $days = [int]$arg
            } elseif ($arg -eq "--dry-run" -or $arg -eq "-d") {
                $dryRun = $true
            }
        }
        Invoke-Clean -Days $days -DryRun:$dryRun
    }
    "backup" {
        $output = if ($Arguments[0]) { $Arguments[0] } else { "" }
        if ($output) {
            Invoke-Backup -Output $output
        } else {
            Invoke-Backup
        }
    }
    "restore" {
        if (-not $Arguments[0]) {
            Write-Error "Please specify backup file"
            exit 1
        }
        Invoke-Restore -BackupFile $Arguments[0]
    }
    "license" {
        Invoke-License
    }
    "update" {
        Invoke-Update
    }
    { $_ -in @("remove", "uninstall") } {
        Invoke-Remove
    }
    { $_ -in @("help", "--help", "-h", "?") } {
        Show-Help
    }
    default {
        Write-Error "Unknown command: $Command"
        Write-Host ""
        Show-Help
        exit 1
    }
}
