#Requires -version 7.4
#Requires -modules pave-logger
#Requires -modules pave-utils


$VsBuildType = 'insiders'

& ".\Scripts\Install-DotNetLts.ps1"
& ".\Scripts\Install-GitForWindows.ps1" 
& ".\Scripts\Install-BsCode.ps1" -BuildType $VsBuildType
& ".\Scripts\Install-AzureDataStudio.ps1"
& ".\Scripts\Install-StorageExplorer.ps1"