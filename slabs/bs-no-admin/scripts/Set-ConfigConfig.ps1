
param(
   [switch]$Test
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Params = @{
    Org = 'stvnrs'
    Repo = 'config'
    Configs = ,'configs\uwm-vm\doit.ps1'
    DotSourceConfigs = @()
}

& "$PSScriptRoot\Set-Config" @Params -Test:$Test
