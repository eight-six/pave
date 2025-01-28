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
& "$ScriptsFolder\Install-DotNetLts.ps1"
& "$ScriptsFolder\Install-GitForWindows.ps1" 
& "$ScriptsFolder\Install-BsCode.ps1" -BuildType $VsBuildType
& "$ScriptsFolder\Install-AzureDataStudio.ps1"
& "$ScriptsFolder\Install-StorageExplorer.ps1"
Pop-LogAction

if($null -eq $MyInvocation.PSCommandPath){
    $Heading += ' - completed'
    Write-LogHeader $Heading 
}