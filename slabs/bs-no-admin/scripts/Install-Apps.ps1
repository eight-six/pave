#Requires -version 7.4
#Requires -modules pave-logger
#Requires -modules pave-utils

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$ScriptsFolder = $PSScriptRoot 
$VsBuildType = 'insider'
$Heading = 'default apps'
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction 'installing default apps' -IncrementActionLevel
& "$ScriptsFolder\Install-GitForWindows.ps1" 
& "$ScriptsFolder\Install-BsCode.ps1" -BuildType $VsBuildType
Pop-LogAction

if($null -eq $MyInvocation.PSCommandPath){
    $Heading += ' - completed'
    Write-LogHeader $Heading 
}