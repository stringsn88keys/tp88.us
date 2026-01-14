## Automatically installs uru and registers all Ruby installations found on the system

$ErrorActionPreference = "Stop"

# Global variable to store uru path
$script:UruCommand = $null

# Function to check if uru is installed
function Test-UruInstalled {
    try {
        $uruPath = Get-Command uru -ErrorAction SilentlyContinue
        if ($null -ne $uruPath) {
            $script:UruCommand = $uruPath.Source
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Function to install uru
function Install-Uru {
    Write-Host "Installing uru from BitBucket..." -ForegroundColor Cyan

    $uruInstallDir = Join-Path $env:LOCALAPPDATA "uru"
    if (-not (Test-Path $uruInstallDir)) {
        New-Item -ItemType Directory -Path $uruInstallDir | Out-Null
    }

    $tempDir = Join-Path $env:TEMP "uru-download"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    try {
        # Download the Windows x86 7z archive from BitBucket
        $uruUrl = "https://bitbucket.org/jonforums/uru/downloads/uru-0.8.5-windows-x86.7z"
        $uruFile = Join-Path $tempDir "uru.7z"

        Write-Host "Downloading from $uruUrl..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $uruUrl -OutFile $uruFile -UseBasicParsing

        # Extract using tar (built into Windows 10+)
        Write-Host "Extracting 7z archive..." -ForegroundColor Yellow
        & tar -xf $uruFile -C $tempDir

        # Find uru_rt.exe
        $uruRtExe = Get-ChildItem -Path $tempDir -Filter "uru_rt.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1

        # Also check for uru.exe in case it's already named that
        if (-not $uruRtExe) {
            $uruRtExe = Get-ChildItem -Path $tempDir -Filter "uru.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        }

        if ($uruRtExe) {
            $destPath = Join-Path $uruInstallDir "uru.exe"
            Copy-Item $uruRtExe.FullName -Destination $destPath -Force
            Write-Host "Installed uru.exe to $destPath" -ForegroundColor Green

            # Add to PATH
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($userPath -notlike "*$uruInstallDir*") {
                Write-Host "Adding to PATH..." -ForegroundColor Yellow
                [Environment]::SetEnvironmentVariable("Path", "$userPath;$uruInstallDir", "User")
                # Update current session PATH
                $env:Path = "$env:Path;$uruInstallDir"
            }

            $script:UruCommand = $destPath

            # Clean up
            Remove-Item $tempDir -Recurse -Force
            return $true
        }
        else {
            throw "Could not find uru_rt.exe or uru.exe in extracted archive"
        }
    }
    catch {
        Write-Host "Failed to download/install uru: $_" -ForegroundColor Red
        Write-Host "" -ForegroundColor Yellow
        Write-Host "Please install manually:" -ForegroundColor Yellow
        Write-Host "  1. Download from: https://bitbucket.org/jonforums/uru/downloads/uru-0.8.5-windows-x86.7z" -ForegroundColor Gray
        Write-Host "  2. Extract uru_rt.exe to: $uruInstallDir" -ForegroundColor Gray
        Write-Host "  3. Rename it to uru.exe" -ForegroundColor Gray
        Write-Host "  4. Add $uruInstallDir to your PATH" -ForegroundColor Gray
        Write-Host ""

        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
}

# Function to get Ruby version from ruby.exe
function Get-RubyVersion {
    param([string]$RubyPath)

    try {
        $versionOutput = & $RubyPath -v 2>$null
        if ($LASTEXITCODE -eq 0 -and $versionOutput) {
            # Parse version from output like "ruby 3.2.0 (2022-12-25 revision a528908271) [x64-mingw-ucrt]"
            if ($versionOutput -match "ruby ([\d.]+)") {
                return $matches[1]
            }
        }
    }
    catch {
        Write-Verbose "Failed to get version from $RubyPath"
    }
    return $null
}

# Function to find all Ruby installations
function Find-RubyInstallations {
    Write-Host "Searching for Ruby installations..." -ForegroundColor Cyan

    $rubyPaths = @()
    $searchPaths = @(
        "C:\Ruby*",
        "C:\Program Files\Ruby*",
        "C:\Program Files (x86)\Ruby*",
        "${env:ProgramFiles}\Ruby*",
        "${env:ProgramFiles(x86)}\Ruby*",
        "${env:LOCALAPPDATA}\Ruby*",
        "${env:USERPROFILE}\.rubies\*"
    )

    foreach ($searchPath in $searchPaths) {
        $dirs = Get-ChildItem -Path (Split-Path $searchPath) -Filter (Split-Path $searchPath -Leaf) -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $dirs) {
            # Look for ruby.exe in bin subdirectory
            $rubyExe = Join-Path $dir.FullName "bin\ruby.exe"
            if (Test-Path $rubyExe) {
                $version = Get-RubyVersion -RubyPath $rubyExe
                if ($version) {
                    $rubyPaths += @{
                        Path = $dir.FullName
                        RubyExe = $rubyExe
                        Version = $version
                    }
                    Write-Host "  Found: Ruby $version at $($dir.FullName)" -ForegroundColor Gray
                }
            }

            # Also check root directory (some installations don't use bin)
            $rubyExe = Join-Path $dir.FullName "ruby.exe"
            if (Test-Path $rubyExe) {
                $version = Get-RubyVersion -RubyPath $rubyExe
                if ($version) {
                    $rubyPaths += @{
                        Path = $dir.FullName
                        RubyExe = $rubyExe
                        Version = $version
                    }
                    Write-Host "  Found: Ruby $version at $($dir.FullName)" -ForegroundColor Gray
                }
            }
        }
    }

    return $rubyPaths
}

# Function to get currently registered uru rubies
function Get-UruRubies {
    try {
        if ($script:UruCommand) {
            $uruList = & $script:UruCommand ls 2>$null
        } else {
            $uruList = uru ls 2>$null
        }
        if ($LASTEXITCODE -eq 0) {
            return $uruList
        }
    }
    catch {
        Write-Verbose "Failed to get uru list: $_"
    }
    return @()
}

# Function to invoke uru command
function Invoke-Uru {
    param([string[]]$Arguments)

    if ($script:UruCommand -and (Test-Path $script:UruCommand)) {
        Write-Verbose "Using uru at: $script:UruCommand with args: $($Arguments -join ' ')"
        & $script:UruCommand @Arguments
    } else {
        # Try to find uru in PATH
        $uruInPath = Get-Command uru -ErrorAction SilentlyContinue
        if ($uruInPath) {
            & $uruInPath.Source @Arguments
        } else {
            throw "uru command not found. Please ensure uru is properly installed."
        }
    }
}

# Main script execution
Write-Host "`n=== URU Configuration Script ===" -ForegroundColor Cyan
Write-Host "This script will install uru (if needed) and register all Ruby installations`n" -ForegroundColor White

# Check if uru is installed
if (-not (Test-UruInstalled)) {
    Write-Host "uru is not installed on this system." -ForegroundColor Yellow
    $installResult = Install-Uru

    if (-not $installResult) {
        Write-Host "Exiting: uru installation failed or requires manual intervention." -ForegroundColor Red
        exit 1
    }

    # Verify uru command is set
    if (-not $script:UruCommand) {
        # Try to find it again
        Start-Sleep -Seconds 1
        $uruPath = Get-Command uru -ErrorAction SilentlyContinue
        if ($uruPath) {
            $script:UruCommand = $uruPath.Source
        } else {
            Write-Host "Error: Failed to locate uru executable after installation." -ForegroundColor Red
            Write-Host "Please restart your PowerShell session and run this script again." -ForegroundColor Yellow
            exit 1
        }
    }

    # After installation, initialize uru
    Write-Host "`nInitializing uru..." -ForegroundColor Cyan
    try {
        Invoke-Uru admin, install
        Write-Host "uru initialized successfully" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANT: To use uru, you must:" -ForegroundColor Yellow
        Write-Host "  1. Close this PowerShell session" -ForegroundColor Cyan
        Write-Host "  2. Open a new PowerShell session" -ForegroundColor Cyan
        Write-Host "  3. Then you can use: uru ruby-3.4.2, uru ruby-2.7.8, etc." -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Host "Note: uru admin install returned an error." -ForegroundColor Yellow
        Write-Host "Error details: $_" -ForegroundColor Gray
        Write-Host "This is often normal on first run. Continuing..." -ForegroundColor Yellow
    }
}
else {
    Write-Host "uru is already installed at: $script:UruCommand" -ForegroundColor Green
}

# Find all Ruby installations
$rubyInstalls = Find-RubyInstallations

if ($rubyInstalls.Count -eq 0) {
    Write-Host "`nNo Ruby installations found on this system." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nFound $($rubyInstalls.Count) Ruby installation(s)" -ForegroundColor Green

# Get currently registered rubies
Write-Host "`nChecking currently registered rubies in uru..." -ForegroundColor Cyan
$uruList = Get-UruRubies

# Register new rubies
$registered = 0
$skipped = 0
foreach ($ruby in $rubyInstalls) {
    $tagName = "ruby-$($ruby.Version)"

    # Check if this path is already registered
    $alreadyRegistered = $false
    foreach ($line in $uruList) {
        if ($line -like "*$($ruby.Path)*" -or $line -like "*$tagName*") {
            $alreadyRegistered = $true
            break
        }
    }

    if ($alreadyRegistered) {
        Write-Host "  Skipping: Ruby $($ruby.Version) (already registered)" -ForegroundColor Gray
        $skipped++
    }
    else {
        Write-Host "  Registering: Ruby $($ruby.Version) as '$tagName'" -ForegroundColor Yellow
        try {
            # Use the bin directory if ruby.exe is in bin, otherwise use the root path
            $regPath = $ruby.Path
            if (Test-Path (Join-Path $ruby.Path "bin\ruby.exe")) {
                $regPath = Join-Path $ruby.Path "bin"
            }

            Invoke-Uru admin, add, $regPath, "--tag", $tagName
            if ($LASTEXITCODE -eq 0) {
                $registered++
                Write-Host "    Successfully registered!" -ForegroundColor Green
            } else {
                Write-Host "    Failed to register (exit code: $LASTEXITCODE)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "    Failed to register: $_" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total Ruby installations found: $($rubyInstalls.Count)" -ForegroundColor White
Write-Host "Already registered: $skipped" -ForegroundColor White
Write-Host "Newly registered: $registered" -ForegroundColor White

Write-Host "`nRun 'uru ls' to see all registered rubies" -ForegroundColor Yellow
Write-Host "Run 'uru <version>' to switch between Ruby versions`n" -ForegroundColor Yellow
