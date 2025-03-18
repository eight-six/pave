#Requires -version 5.1 # Windows Powershell
#Requires -modules PowershellGet
#Requires -modules pave-logger
#Requires -modules pave-utils

using namespace System.Collections

[CmdletBinding(SupportsShouldProcess)]
param (  
    [ValidateSet(
        'azure-data-studio',
        'code-insiders',
        'code',
        'git',
        'node',
        'storage-explorer')]
    [string[]]$Apps = @()
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    $ThisSlabName = Split-Path $PSScriptRoot -Leaf
    $SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
    . "$SlabsRoot/slab-utils/slab-utils.ps1"

    Write-LogHeader $ThisSlabName

    # install apps with pwsh
    $ScriptsFolder = Join-Path $PSScriptRoot 'scripts'

    if ($AppsList.Length -gt 0) {
        $InstallAppsScript = 'Install-AppsWinget.ps1'
        $AppScriptsFilePath = Join-Path $ScriptsFolder $InstallAppsScript
        
        if ($PSVersionTable.PSEdition -eq 'Core') {
            & $AppScriptsFilePath -Apps $Apps
        }
        else {
            & Invoke-Pwsh -FilePath $AppScriptsFilePath -Arguments @{Apps = -Apps $Apps }
        }
    }
    
    Write-LogHeader "$ThisSlabName - complete"
}
catch {
    Clear-LogAction
    throw
}
