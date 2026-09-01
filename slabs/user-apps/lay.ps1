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
        'storage-explorer',
        'windows-terminal'
    )]
    [string[]]$Apps = @()
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    $ThisSlabName = Split-Path $PSScriptRoot -Leaf
    $SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
    . "$SlabsRoot/slab-utils/slab-utils.ps1"

    $Heading = "$(apps $ThisSlabName)"
    Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)

    # install apps with pwsh
    $ScriptsFolder = Join-Path $PSScriptRoot 'scripts'

    if ($Apps.Length -gt 0) {
        $InstallAppsScript = 'Install-Apps.ps1'
        $AppScriptsFilePath = Join-Path $ScriptsFolder $InstallAppsScript
        
        if ($PSVersionTable.PSEdition -eq 'Core') {
            & $AppScriptsFilePath -Apps $Apps
        }
        else {
            & Invoke-Pwsh -FilePath $AppScriptsFilePath -Arguments @{Apps = $Apps }
        }
    }
    
    if ($null -eq $MyInvocation.PSCommandPath) {
        $Heading += " - $(u completed)"
        Write-LogHeader $Heading 
    }
}
catch {
    Clear-LogAction
    throw
}
