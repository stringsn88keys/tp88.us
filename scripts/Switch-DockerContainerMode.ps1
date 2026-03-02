<#
.SYNOPSIS
  Switches Docker Desktop between Linux and Windows container modes.
#>

# Switch-DockerContainerMode.ps1
# Switches Docker Desktop between Linux and Windows container modes

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Linux', 'Windows', 'Auto')]
    [string]$Mode = 'Auto',
    
    [Parameter(Mandatory = $false)]
    [switch]$Help,
    
    [Parameter(Mandatory = $false)]
    [switch]$Status
)

# Display help
if ($Help) {
    Write-Host "`nSwitch-DockerContainerMode.ps1" -ForegroundColor Cyan
    Write-Host "Switches Docker Desktop between Linux and Windows container modes`n" -ForegroundColor White
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\Switch-DockerContainerMode.ps1 [-Mode <Linux|Windows|Auto>] [-Status] [-Help]`n"
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Mode <String>" -ForegroundColor Green
    Write-Host "    Linux   : Switch to Linux containers"
    Write-Host "    Windows : Switch to Windows containers"
    Write-Host "    Auto    : Toggle between modes (default)`n"
    Write-Host "  -Status" -ForegroundColor Green
    Write-Host "    Display current Docker container mode without switching`n"
    Write-Host "  -Help" -ForegroundColor Green
    Write-Host "    Display this help message`n"
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\Switch-DockerContainerMode.ps1"
    Write-Host "    Toggles between Linux and Windows containers`n"
    Write-Host "  .\Switch-DockerContainerMode.ps1 -Mode Linux"
    Write-Host "    Switches to Linux containers`n"
    Write-Host "  .\Switch-DockerContainerMode.ps1 -Status"
    Write-Host "    Shows current container mode`n"
    exit 0
}

# Path to Docker Desktop CLI
$dockerCliPath = "C:\Program Files\Docker\Docker\DockerCli.exe"

# Check if Docker Desktop CLI exists
if (-not (Test-Path $dockerCliPath)) {
    Write-Error "Docker Desktop CLI not found at: $dockerCliPath"
    Write-Error "Please ensure Docker Desktop is installed."
    exit 1
}

# Function to get current container mode
function Get-CurrentDockerMode {
    try {
        $dockerInfo = docker info 2>&1 | Out-String
        if ($dockerInfo -match "OSType:\s*(\w+)") {
            return $matches[1]
        }
        return "Unknown"
    }
    catch {
        Write-Warning "Could not determine current Docker mode: $_"
        return "Unknown"
    }
}

# Get current mode
$currentMode = Get-CurrentDockerMode

# Handle -Status flag
if ($Status) {
    Write-Host "`nDocker Container Mode Status:" -ForegroundColor Cyan
    Write-Host "Current mode: $currentMode" -ForegroundColor Green
    
    # Additional info
    try {
        $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
        if ($dockerVersion) {
            Write-Host "Docker version: $dockerVersion" -ForegroundColor White
        }
    }
    catch {
        # Ignore errors
    }
    Write-Host ""
    exit 0
}

Write-Host "Current Docker container mode: $currentMode" -ForegroundColor Cyan

# Determine target mode
$targetMode = $Mode
if ($Mode -eq 'Auto') {
    # Toggle mode
    if ($currentMode -eq 'linux') {
        $targetMode = 'Windows'
    }
    elseif ($currentMode -eq 'windows') {
        $targetMode = 'Linux'
    }
    else {
        Write-Error "Cannot determine current mode to toggle. Please specify -Mode explicitly."
        exit 1
    }
}

# Check if already in target mode
if ($currentMode.ToLower() -eq $targetMode.ToLower()) {
    Write-Host "Already in $targetMode container mode. No action needed." -ForegroundColor Green
    exit 0
}

# Switch to target mode
Write-Host "Switching to $targetMode containers..." -ForegroundColor Yellow

try {
    if ($targetMode -eq 'Windows') {
        & $dockerCliPath -SwitchWindowsEngine
        Write-Host "Switched to Windows containers successfully!" -ForegroundColor Green
    }
    elseif ($targetMode -eq 'Linux') {
        & $dockerCliPath -SwitchLinuxEngine
        Write-Host "Switched to Linux containers successfully!" -ForegroundColor Green
    }
    
    # Wait a moment for Docker to restart
    Write-Host "Waiting for Docker to restart..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Verify the switch
    $newMode = Get-CurrentDockerMode
    Write-Host "New Docker container mode: $newMode" -ForegroundColor Cyan
    
    if ($newMode.ToLower() -eq $targetMode.ToLower()) {
        Write-Host "Mode switch verified successfully!" -ForegroundColor Green
    }
    else {
        Write-Warning "Mode switch may still be in progress. Please verify with 'docker info'."
    }
}
catch {
    Write-Error "Failed to switch Docker mode: $_"
    exit 1
}
