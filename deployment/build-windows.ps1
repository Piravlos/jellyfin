<#
.SYNOPSIS
    Build script for creating Jellyfin Windows executables.

.DESCRIPTION
    Builds Jellyfin for Windows with various configuration options including
    self-contained, single-file, and trimmed builds.

.PARAMETER Configuration
    Build configuration: Debug or Release. Default: Release

.PARAMETER Architecture
    Target architecture: x64, x86, or arm64. Default: x64

.PARAMETER SelfContained
    Create a self-contained build that doesn't require .NET runtime. Default: false

.PARAMETER SingleFile
    Bundle into a single executable file. Default: false

.PARAMETER Trimmed
    Trim unused code to reduce size (only with SelfContained). Default: false

.PARAMETER OutputDir
    Custom output directory. Default: ./artifacts/win-{arch}

.PARAMETER Clean
    Clean build artifacts before building. Default: false

.EXAMPLE
    .\build-windows.ps1
    # Basic framework-dependent build

.EXAMPLE
    .\build-windows.ps1 -SelfContained
    # Self-contained build (no .NET runtime required)

.EXAMPLE
    .\build-windows.ps1 -SelfContained -SingleFile
    # Single-file self-contained build

.EXAMPLE
    .\build-windows.ps1 -SelfContained -SingleFile -Trimmed
    # Trimmed single-file build (smallest size)

.EXAMPLE
    .\build-windows.ps1 -Architecture arm64 -SelfContained
    # Build for Windows ARM64
#>

param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [ValidateSet("x64", "x86", "arm64")]
    [string]$Architecture = "x64",

    [switch]$SelfContained,

    [switch]$SingleFile,

    [switch]$Trimmed,

    [string]$OutputDir,

    [switch]$Clean
)

$ErrorActionPreference = "Stop"

# Determine paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ProjectPath = Join-Path $RepoRoot "Jellyfin.Server" "Jellyfin.Server.csproj"
$RuntimeIdentifier = "win-$Architecture"

if (-not $OutputDir) {
    $OutputDir = Join-Path $RepoRoot "artifacts" $RuntimeIdentifier
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Jellyfin Windows Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:    $Configuration"
Write-Host "Architecture:     $Architecture"
Write-Host "Runtime:          $RuntimeIdentifier"
Write-Host "Self-Contained:   $SelfContained"
Write-Host "Single File:      $SingleFile"
Write-Host "Trimmed:          $Trimmed"
Write-Host "Output:           $OutputDir"
Write-Host ""

# Clean if requested
if ($Clean) {
    Write-Host "Cleaning previous build artifacts..." -ForegroundColor Yellow
    if (Test-Path $OutputDir) {
        Remove-Item -Recurse -Force $OutputDir
    }
    dotnet clean $ProjectPath -c $Configuration
}

# Build arguments
$publishArgs = @(
    "publish"
    $ProjectPath
    "-c", $Configuration
    "-r", $RuntimeIdentifier
    "-o", $OutputDir
)

if ($SelfContained) {
    $publishArgs += "--self-contained", "true"
} else {
    $publishArgs += "--self-contained", "false"
}

if ($SingleFile) {
    $publishArgs += "-p:PublishSingleFile=true"
    $publishArgs += "-p:IncludeNativeLibrariesForSelfExtract=true"
}

if ($Trimmed) {
    if (-not $SelfContained) {
        Write-Host "Warning: Trimming requires SelfContained. Enabling SelfContained." -ForegroundColor Yellow
        $publishArgs += "--self-contained", "true"
    }
    $publishArgs += "-p:PublishTrimmed=true"
}

# Execute build
Write-Host "Building Jellyfin..." -ForegroundColor Green
Write-Host "Command: dotnet $($publishArgs -join ' ')" -ForegroundColor DarkGray
Write-Host ""

& dotnet $publishArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Report results
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output directory: $OutputDir"

$exePath = Join-Path $OutputDir "jellyfin.exe"
if (Test-Path $exePath) {
    $fileInfo = Get-Item $exePath
    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    Write-Host "Executable: $exePath"
    Write-Host "Size: $sizeMB MB"
}

Write-Host ""
Write-Host "To run Jellyfin:"
Write-Host "  cd $OutputDir"
Write-Host "  .\jellyfin.exe"
