<#
.SYNOPSIS
    Changes the desktop wallpaper for the current user.

.DESCRIPTION
    This script changes the desktop wallpaper to either a specified image file
    or the most recently downloaded image in the Downloads folder.

.PARAMETER ImagePath
    Path to the image file to set as wallpaper. If not specified, uses the
    most recently downloaded image from ~/Downloads.

.EXAMPLE
    .\Set-Wallpaper.ps1
    Sets the most recently downloaded image from ~/Downloads as wallpaper.

.EXAMPLE
    .\Set-Wallpaper.ps1 -ImagePath "C:\Pictures\wallpaper.jpg"
    Sets the specified image as wallpaper.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ImagePath
)

Add-Type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    public const int SPI_SETDESKWALLPAPER = 0x0014;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDCHANGE = 0x02;

    public static void SetWallpaper(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }
}
"@

function Get-MostRecentImage {
    param([string]$DownloadsPath)

    $imageExtensions = @('*.jpg', '*.jpeg', '*.png', '*.bmp', '*.gif')
    $images = @()

    foreach ($ext in $imageExtensions) {
        $images += Get-ChildItem -Path $DownloadsPath -Filter $ext -File -ErrorAction SilentlyContinue
    }

    if ($images.Count -eq 0) {
        throw "No image files found in $DownloadsPath"
    }

    $mostRecent = $images | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $mostRecent.FullName
}

try {
    # If no image path specified, find the most recent image in Downloads
    if ([string]::IsNullOrEmpty($ImagePath)) {
        $downloadsPath = Join-Path $env:USERPROFILE "Downloads"

        if (-not (Test-Path $downloadsPath)) {
            throw "Downloads folder not found at: $downloadsPath"
        }

        Write-Host "Searching for most recent image in Downloads folder..."
        $ImagePath = Get-MostRecentImage -DownloadsPath $downloadsPath
        Write-Host "Found: $ImagePath"
    }

    # Validate the image path exists
    if (-not (Test-Path $ImagePath)) {
        throw "Image file not found: $ImagePath"
    }

    # Get absolute path
    $absolutePath = (Resolve-Path $ImagePath).Path

    # Set the wallpaper
    Write-Host "Setting wallpaper to: $absolutePath"
    [Wallpaper]::SetWallpaper($absolutePath)

    Write-Host "Wallpaper changed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to set wallpaper: $_"
    exit 1
}
