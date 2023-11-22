#Requires -PSEdition Core

$Root = Join-Path $PSScriptRoot '..'

& "$Root\pwsh-profiles\deploy.ps1" -DeploySynchedProfileShim
& "$Root\pwsh-scripts\deploy.ps1"