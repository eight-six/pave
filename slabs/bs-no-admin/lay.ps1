#Requires -version 5.1 # Windows Powershell
#Requires -modules pave-logger
#Requires -modules pave-utils

param (
    [string]$PwshVersion = "7.5.0",
    [string]$NugetMinVersion = "2.8.5.201",
    [switch]$InstallWindowsTerminal,
    [switch]$SkipDownload
)

$ErrorActionPreference = 'Stop'

try {
    
    $ThisSlabName = Split-Path $PSScriptRoot -Leaf
    $SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
    . "$SlabsRoot/slab-utils/slab-utils.ps1"

    Write-LogHeader $ThisSlabName

    if ( $InstallWindowsTerminal.IsPresent) {
        Write-LogSubheader 'Windows Terminal'
        .\Install-WindowsTerminal.ps1
    }

    # install pwsh
    $ScriptsFolder = Join-Path $PSScriptRoot 'scripts'
    $PwshResult = & "$ScriptsFolder\Install-Pwsh.ps1" -Version $PwshVersion -SkipDownload:$SkipDownload 

    # install nuget
    Push-LogAction "$(emph $ThisSlabName) installing nuget >= $NugetMinVersion" -IncrementActionLevel
    $PackageProvider = Install-PackageProvider -Name NuGet -MinimumVersion $NugetMinVersion -Scope 'CurrentUser' -Force 
    Write-LogEntry "Package provider installed: $($PackageProvider | ConvertTo-Json -Compress )"
    Pop-LogAction

    # instal default apps
    $AppScriptsFilePath = Join-Path $ScriptsFolder 'Install-Apps.ps1'
    $ExitCode = & $PwshResult.PwshPath -WorkingDirectory $PSScriptRoot -NoProfile -File $AppScriptsFilePath

    if ($ExitCode -ne 0) {
        throw "Running $(emph $AppScriptsFilePath) with $(emph $PwshResult.PwshPath) failed."
    }
}
catch {
    Clear-LogAction
    throw
}

Write-LogHeader "$ThisSlabName - complete"