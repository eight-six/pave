#Requires -version 5.1 # Windows Powershell
#Requires -modules PowershellGet
#Requires -modules pave-logger
#Requires -modules pave-utils

param (
    [string]$NugetMinVersion = "2.8.5.201"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$ScriptName = Split-Path -Path $PSCommandPath -Leaf
Write-LogHeader "$ScriptName" -Subheader:($null -ne $MyInvocation.PSCommandPath)

try {
    $Nuget = Get-PackageProvider | ? { ($_.Name -eq 'NuGet') }

    if ($null -ne $Nuget -and ($Nuget.Version -ge [Version]$NugetMinVersion) ) {
        log "Nuget $($Nuget.Version) >= $NugetMinVersion already installed"
    }
    else {
        Push-LogAction "$(emph $ThisSlabName) installing nuget >= $NugetMinVersion" -IncrementActionLevel
        $Nuget = Install-PackageProvider -Name NuGet -MinimumVersion $NugetMinVersion -Scope 'CurrentUser' -Force 
        Write-LogEntry "Nuget package provider installed: $($PackageProvider | ConvertTo-Json -Compress )"
        Pop-LogAction
    }
}
catch {
    Clear-LogAction
    throw
}

Write-LogHeader "$ScriptName - done."