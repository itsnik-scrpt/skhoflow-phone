#requires -Version 5.1
<#
.SYNOPSIS
    Hands an unsigned SkhoFlow.ipa to Sideloadly for install on your iPhone.

.DESCRIPTION
    Finds the Sideloadly executable (env var, Program Files, %LOCALAPPDATA%),
    verifies the .ipa exists and looks valid, then launches Sideloadly with
    the .ipa pre-loaded. Finishes the install + Apple-ID prompt in Sideloadly's UI.

.PARAMETER Ipa
    Path to SkhoFlow.ipa. Defaults to the GitHub Actions artifact location
    after you've unzipped it into your Downloads folder.

.PARAMETER SideloadlyPath
    Explicit path to Sideloadly.exe. Optional; auto-detected otherwise.

.EXAMPLE
    .\sideload.ps1
    .\sideload.ps1 -Ipa "$env:USERPROFILE\Downloads\SkhoFlow-ipa\SkhoFlow.ipa"
#>

[CmdletBinding()]
param(
    [string] $Ipa,
    [string] $SideloadlyPath
)

$ErrorActionPreference = 'Stop'

function Find-Sideloadly {
    if ($SideloadlyPath -and (Test-Path $SideloadlyPath)) { return (Resolve-Path $SideloadlyPath).Path }
    if ($env:SIDELOADLY_PATH -and (Test-Path $env:SIDELOADLY_PATH)) { return $env:SIDELOADLY_PATH }

    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Sideloadly\Sideloadly.exe",
        "$env:LOCALAPPDATA\Sideloadly\Sideloadly.exe",
        "$env:ProgramFiles\Sideloadly\Sideloadly.exe",
        "${env:ProgramFiles(x86)}\Sideloadly\Sideloadly.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

function Find-Ipa {
    if ($Ipa) {
        if (-not (Test-Path $Ipa)) { throw "IPA not found at: $Ipa" }
        return (Resolve-Path $Ipa).Path
    }

    # Walk the typical "unzipped GitHub artifact" locations.
    $candidates = @(
        "$env:USERPROFILE\Downloads\SkhoFlow.ipa",
        "$env:USERPROFILE\Downloads\SkhoFlow-ipa\SkhoFlow.ipa"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }

    # Recursive search in Downloads as a last resort.
    $found = Get-ChildItem -Path "$env:USERPROFILE\Downloads" -Filter "SkhoFlow.ipa" -Recurse -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if ($found) { return $found.FullName }

    throw "Couldn't find SkhoFlow.ipa. Pass -Ipa <path> explicitly, or place the file in Downloads."
}

function Test-IpaSane {
    param([string] $Path)

    $info = Get-Item $Path
    if ($info.Length -lt 100KB) {
        throw "SkhoFlow.ipa is only $($info.Length) bytes - probably truncated. Re-download the artifact."
    }

    # Quick magic-bytes check: .ipa is a ZIP, starts with 'PK'.
    $bytes = [System.IO.File]::ReadAllBytes($Path)[0..1]
    if ($bytes[0] -ne 0x50 -or $bytes[1] -ne 0x4B) {
        throw "$Path doesn't look like a ZIP/IPA (no PK header). Re-download."
    }
}

Write-Host "SkhoFlow sideload helper" -ForegroundColor Red
Write-Host "------------------------" -ForegroundColor DarkGray

$ipaPath = Find-Ipa
Write-Host "  IPA        : $ipaPath"
Test-IpaSane -Path $ipaPath
Write-Host "  Size       : $([Math]::Round((Get-Item $ipaPath).Length / 1MB, 2)) MB"

$sideloadly = Find-Sideloadly
if (-not $sideloadly) {
    Write-Host ""
    Write-Host "Sideloadly isn't installed (or I can't find it)." -ForegroundColor Yellow
    Write-Host "Install it from https://sideloadly.io then rerun this script."
    Write-Host "Or pass -SideloadlyPath 'C:\path\to\Sideloadly.exe'."
    exit 1
}
Write-Host "  Sideloadly : $sideloadly"

# Prereq checks: iTunes provides the Apple Mobile Device service.
$amds = Get-Service -Name "Apple Mobile Device Service" -ErrorAction SilentlyContinue
if (-not $amds) {
    Write-Host ""
    Write-Host "Apple Mobile Device Service is not installed." -ForegroundColor Yellow
    Write-Host "Install iTunes from the Microsoft Store, then plug in your iPhone and tap Trust."
    Write-Host "(Sideloadly relies on it to talk to your phone.)"
    Write-Host ""
    $continue = Read-Host "Continue anyway? [y/N]"
    if ($continue -notmatch '^[Yy]') { exit 1 }
} elseif ($amds.Status -ne 'Running') {
    Write-Host "  Starting Apple Mobile Device Service..."
    try { Start-Service -Name "Apple Mobile Device Service" } catch { Write-Warning $_ }
}

# Make sure an iPhone is actually plugged in via USB.
$iDevicePresent = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -match '(?i)apple mobile device|iphone|ipad' } |
    Select-Object -First 1

if (-not $iDevicePresent) {
    Write-Host ""
    Write-Host "No iPhone detected over USB." -ForegroundColor Yellow
    Write-Host "Plug in your iPhone with a data cable, unlock it, and tap Trust on the popup."
    Write-Host ""
    $continue = Read-Host "Open Sideloadly anyway? [y/N]"
    if ($continue -notmatch '^[Yy]') { exit 1 }
} else {
    Write-Host "  iPhone     : $($iDevicePresent.FriendlyName)"
}

Write-Host ""
Write-Host "Launching Sideloadly with SkhoFlow.ipa..." -ForegroundColor Green
Write-Host ""
Write-Host "When the Sideloadly window opens:" -ForegroundColor Cyan
Write-Host "  1. The IPA should already be loaded (drag it in manually if not)."
Write-Host "  2. Enter your Apple ID."
Write-Host "  3. Click Start."
Write-Host "  4. Paste your app-specific password when prompted."
Write-Host "  5. On the iPhone: Settings > General > VPN & Device Management > Trust."
Write-Host ""

# Sideloadly accepts an .ipa as the first positional argument.
Start-Process -FilePath $sideloadly -ArgumentList "`"$ipaPath`""
