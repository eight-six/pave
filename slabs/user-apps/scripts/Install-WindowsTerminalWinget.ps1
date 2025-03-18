<#
.DESCRIPTION 
 Installs the specified version of Windows Terminal using winget

 If Windows Terminal is your default you can start a shell outside of Terminal with:

    start conhost powershell

#>
#Requires -Version 5.1

param ()

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Set-StrictMode  -Version 'latest'

if(Get-Process -Name 'WindowsTerminal' -ea 'Ignore'){
    throw 'Cannot install Windows Terminal when there is a running instance. Please close Windows Terminal'
}


# Windows Terminal seems to be quite hard to install with winget, installing from msstore works on a windows sandbox 
# from  https://github.com/microsoft/winget-cli/issues/1705#issuecomment-1828796032

winget install "windows terminal" --source "msstore" --accept-source-agreements --accept-package-agreements

