<#PSScriptInfo

.VERSION 1.0

.GUID f04f3668-3c3f-472a-9c77-3f82ee27484a

.AUTHOR @stvnrs

.COMPANYNAME Eight Six Consulting

.COPYRIGHT (c)  Eight Six Consulting Limited

.TAGS

#install #git

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Installs the specified version of git for windows for the current user to the default install folder 
 $Env:LocalAppData\Programs\Git\

.PARAMETER Version
The version of git for windows to install. This will default to 2.47.1.2 (the latest at he time of publishing)

This must be specified as Major.Minor.Build.Revision

Only 64-bit release versions are supported

.PARAMETER DownloadRoot
Where to download git from - by default this will be https://github.com/git-for-windows/git/releases/download

This can be a uri or a file share e.g. file://lorem.ipsum/stash-of-git-installers or \\lorem\git-installers\

Inside the download root the installers must be saved in the same folder and with the same file name
as they are when published on github.

.PARAMETER HideInstaller
If specified no installer dialog will be displayed.

When not specified the installer will still complete automatically, but its progress will be displayed.

.EXAMPLE
./Install-GitForWindows 

.EXAMPLE
./Install-GitForWindows -Version 2.41.0.1



#> 
#Requires -PSEdition Core

param (
    [ValidatePattern('\d+\.\d+\.\d+\.\d+')]
    [string]$Version = '2.47.1.2',
    [string]$DownloadRoot = 'https://github.com/git-for-windows/git/releases/download',
    [switch]$HideInstaller
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

if (!$IsWindows) {
    throw "This script is for windows only. See https://git-scm.com/download/$($IsMacOS ? 'mac' : 'linux') "
}

$Heading = 'git'
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction "installing $Heading" -IncrementActionLevel

if($null -eq $MyInvocation.PSCommandPath){
    $Heading += ' - completed'
    Write-LogHeader $Heading 
}

$VersionParts = $Version -split '\.'
$Major = $VersionParts[0]
$Minor = $VersionParts[1]
$Build = $VersionParts[2]
$Revision = $VersionParts[3] 

$DownloadFolder = "v$Major.$Minor.$Build.windows.$Revision"
$DownloadName = "Git-$Major.$Minor.$Build$($Revision -eq 1 ? '' : ".$Revision")-64-bit.exe"
$DownloadUri = "$DownloadRoot/$DownloadFolder/$DownloadName"

Push-LogAction "Downloading git $(emph $Version) - $(emph $DownloadUri)"
Get-Download -Source $DownloadUri
Pop-LogAction

Push-LogAction  "Installing git $(emph $Version)"
Start-Process $DownloadName -Wait -ArgumentList ($HideInstaller ? '/VERYSILENT' : '/SILENT')
Pop-LogAction

$Heading = 'pwsh'
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction "installing $Heading" -IncrementActionLevel

Pop-LogAction

if($null -eq $MyInvocation.PSCommandPath){
    $Heading += ' - completed'
    Write-LogHeader $Heading 
}