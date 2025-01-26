#Requires -version 5.1 # Windows Powershell
#Requires -modules pave-logger
#Requires -modules pave-utils

param (
    [string]$PwshVersion = "7.4.6",
    [string]$NugetMinVersion = "2.8.5.201",
    [switch]$InstallWindowsTerminal,
    [switch]$SkipDownload
)

$ErrorActionPreference = 'Stop'

$ThisSlabName = Split-Path $PSScriptRoot -Leaf
$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
. "$SlabsRoot/slab-utils/slab-utils.ps1"

log-header $ThisSlabName

if( $InstallWindowsTerminal.IsPresent){
    log-subheader 'Windows Terminal'
    .\Install-WindowsTerminal.ps1
}

$ScriptsFolder = Join-Path $PSScriptRoot 'scripts'
log-subheader 'pwsh'

$PwshResult = & "$ScriptsFolder\Install-Pwsh.ps1" -Version $PwshVersion -SkipDownload $SkipDownload

log-subheader 'nuget'
Push-LogAction "$(emph $ThisSlabName) installing nuget >= $NugetMinVersion" -IncrementActionLevel
Install-PackageProvider -Name NuGet -MinimumVersion $NugetMinVersion -Scope 'CurrentUser' -Force
Pop-LogAction

log-subheader 'default apps'
$AppScriptsFilePath = Join-Path $ScriptsFolder ''
$ExitCode = & $PwshResult.PwshPath -WorkingDirectory $PSScriptRoot -NoProfile -File $AppScriptsFilePath

if($ExitCode -ne 0){
    throw "Running $(emph $AppScriptsFilePath) with $(emph $PwshResult.PwshPath) failed."
}

log-header "$ThisSlabName - complete"