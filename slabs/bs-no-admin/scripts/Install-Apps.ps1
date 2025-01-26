#Requires -version 7.4
#Requires -modules pave-logger
#Requires -modules pave-utils

$ScriptsFolder = Join-Path $PSScriptRoot 'scripts'
$VsBuildType = 'insiders'

& "$ScriptsFolder\Scripts\Install-DotNetLts.ps1"
& "$ScriptsFolder\Scripts\Install-GitForWindows.ps1" 
& "$ScriptsFolder\Scripts\Install-BsCode.ps1" -BuildType $VsBuildType
& "$ScriptsFolder\Scripts\Install-AzureDataStudio.ps1"
& "$ScriptsFolder\Scripts\Install-StorageExplorer.ps1"