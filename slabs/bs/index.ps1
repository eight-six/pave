
<#
#>
param (
    [switch]$NoElevation 
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$VerbosePreference = 'Continue'
$WarningPreference = 'Continue'

#Set-StrictMode -Version 'latest'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if (!($NoElevation.IsPresent)) {
    Write-Information "Installing tools with bs-winget..."
    & "$Root\bs-winget\bs.ps1" -FilePath "$Root\bs-winget\winget.dev-machine.json"
    & "$Root\bs-winget\bs.ps1" -FilePath "$Root\bs-winget\winget.dev-user.json"
    Write-Information "Installing tools with bs-winget - done."
}
else {
    Write-Information "Installing tools with **bs-no-admin** winget..."
    & "$Root\bs-no-admin\bs.ps1"
    Write-Information "Installing tools with **bs-no-admin** - done."
}

$PwshBootstrapFilePath = Join-Path (Join-Path $Root 'bs-pwsh') 'bs.ps1'

if ($PSVersionTable.PSEdition -eq 'Core') {
    & $PwshBootstrapFilePath
}
elseif ($null -ne (gcm pwsh -ea 'Ignore')) {
    pwsh -NoProfile -File $PwshBootstrapFilePath
}
else {
    Write-Warning "pwsh not on the path for the current session. Launch pwsh manually and run`n`n         & '$PwshBootstrapFilePath'"
}

$RegTweaksFilePath = Join-Path $PSScriptRoot 'reg-tweaks.ps1'
& $RegTweaksFilePath