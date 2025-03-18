#Requires -version 5.1 # Windows Powershell
#Requires -modules PowershellGet
#Requires -modules pave-logger
#Requires -modules pave-utils

using namespace System.Collections

[CmdletBinding(SupportsShouldProcess)]
param (
    [ValidatePattern('^7\.\d+(\.\d+){0,1}$')]
    [string]$PwshVersion = $(if ($Env:PAVE_PWSH_VERSION) { $Env:PAVE_PWSH_VERSION }else { '7.5.0' }),
    
    [ValidatePattern('^[23].\d.\d.\d{1,3}$')]
    
    [string]$NugetMinVersion = $(if ($Env:PAVE_NUGET_MIN_VERSION) { $Env:PAVE_NUGET_MIN_VERSION }else { '2.8.5.201' }),

    [switch]$UseWinget,
    
    [ValidateSet(
        'azure-data-studio',
        'code-insiders',
        'code',
        'git',
        'node',
        'storage-explorer',
        'windows-terminal')]
    [string[]]$Apps = @(),
    
    [switch]$SkipDownloadDotNetLts,
    
    [switch]$SkipDownload
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    $ThisSlabName = Split-Path $PSScriptRoot -Leaf
    $SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
    . "$SlabsRoot/slab-utils/slab-utils.ps1"

    Write-LogHeader $ThisSlabName

    $InstallWindowsTerminal = $Apps -contains 'windows-terminal'
    $AppsList = [ArrayList]$Apps
    $AppsList.Remove('windows-terminal')

    # install pwsh
    $ScriptsFolder = Join-Path $PSScriptRoot 'scripts'

    $PwshResult = & "$ScriptsFolder\Install-Pwsh.ps1" -Version $PwshVersion -SkipDownload:$SkipDownload 

    $NugetResult = & "$ScriptsFolder\Install-Nuget.ps1" -MinVersion $NugetMinVersion 

    # install winget if specified
    if ($UseWinget.IsPresent) {
        $WingetResult = & "$ScriptsFolder\Install-Winget.ps1"
    }
    
    # install dotnet lts if not skipped
    if (!$SkipDownloadDotNetLts.IsPresent) {
        $DotNetScriptFilePath = Join-Path $ScriptsFolder 'Install-DotNetLts.ps1'

        if ($PSVersionTable.PSEdition -eq 'Core') {
            & $DotNetScriptFilePath
        }
        else {
            Invoke-Pwsh -File $DotNetScriptFilePath
        }
    }
        
    # install windows terminal if specified
    if ( $InstallWindowsTerminal ) {
        $WindowsTerminalScriptFilePath = Join-Path $ScriptsFolder 'Install-WindowsTerminal.ps1'
        & $WindowsTerminalScriptFilePath
    }
        
    # install apps with pwsh
    if ($AppsList.Length -gt 0) {
        $AppSlab = if ($UseWinget.IsPresent) { 'user-apps-winget' }else { 'user-apps' }
        lay $AppSlab -Apps $AppsList
    }
    
    Write-LogHeader "$ThisSlabName - complete"
}
catch {
    Clear-LogAction
    throw
}
