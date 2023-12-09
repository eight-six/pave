#requires -Version 5.1

<#
#>
param (
    [switch]$NoElevation 
)

$ErrorActionPreference = 'Stop'

$ThisSlabName = Split-Path $PSScriptRoot -Leaf
$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
. "$SlabsRoot/slab-utils/slab-utils.ps1"

if (!($NoElevation.IsPresent)) {
    Deploy $ThisSlabName 'bs-winget' @{PackageSet = 'dev-machine-scope' }
    Deploy $ThisSlabName 'bs-winget' @{PackageSet = 'dev-user-scope' }
}
else {
    Deploy $ThisSlabName 'bs-no-admin'
}

$PwshBootstrapFilePath = Join-Path (Join-Path $SlabsRoot 'bs-pwsh') $LayFile

if ($PSVersionTable.PSEdition -eq 'Core') {
    Deploy $ThisSlabName 'bs-pwsh'
}
elseif ($null -ne (Get-Command pwsh -ea 'Ignore')) {
    pwsh -NoProfile -File $PwshBootstrapFilePath
}
else {
    Write-Warning "pwsh not on the path for the current session. Launch pwsh manually and run`n`n`t& '$PwshBootstrapFilePath'"
}

Deploy $ThisSlabName 'reg-tweaks'