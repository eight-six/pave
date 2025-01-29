
param(
   [switch]$Test
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Params = @{
    Org = 'stvnrs'
    Repo = 'config-private'
    Configs = ,'.\configs\uwm-vm\code\doit.ps1'
    DotSourceConfigs = @(
        'configs\uwm-vm\env\doit.ps1'
        'configs\uwm-vm\pwsh\doit.ps1'
    )
}

& "$PSScriptRoot\Set-Config" @Params -Test:$Test


    
