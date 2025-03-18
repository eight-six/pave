#Requires -version 5.1 # Windows Powershell
#Requires -modules PowershellGet
#Requires -modules pave-logger
#Requires -modules pave-utils

[CmdletBinding(SupportsShouldProcess)]
param (
    [ValidatePattern('^[23].\d.\d.\d{1,3}$')]
    [string]$MinVersion = $(if ($Env:PAVE_NUGET_MIN_VERSION) { $Env:PAVE_NUGET_MIN_VERSION }else { '2.8.5.201' })
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$Heading = "$(u nuget)"
$ScriptName = Split-Path -Path $PSCommandPath -Leaf
Write-LogHeader "$Heading" -Subheader:($null -ne $MyInvocation.PSCommandPath)

try {
    $Nuget = Get-PackageProvider | ? { ($_.Name -eq 'NuGet') }

    if ($null -ne $Nuget -and ($Nuget.Version -ge [Version]$MinVersion) ) {
        log "Nuget $($Nuget.Version) already installed (satisfies >= $MinVersion)"
    }
    else {
        Push-LogAction "$(emph $ScriptName ) installing nuget >= $MinVersion" -IncrementActionLevel

        if ($PSCmdlet.ShouldProcess("nuget $($MinVersion)", "install")) {
            $Nuget = Install-PackageProvider -Name 'NuGet' -MinimumVersion $MinVersion -Scope 'CurrentUser' -Force 
            Write-LogEntry "Nuget package provider installed: $($Nuget | ConvertTo-Json -Compress )"
        }
        
        Pop-LogAction
    }
    
    if($null -eq $MyInvocation.PSCommandPath){
        $Heading += " - $(u completed)"
        Write-LogHeader $Heading 
    }

    $Nuget
}
catch {
    Clear-LogAction
    throw
}
