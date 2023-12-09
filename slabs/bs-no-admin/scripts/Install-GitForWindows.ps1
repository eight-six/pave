#requires -Version 5.1

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
The version of git for windows to install. This will default to 2.24.0.2 (the latest at he time of publishing)
of the value of $Env:BS_GIT_VER if not specifed. 

This must be specifed as Major.Minor.Build.Revision

Only 64-bit release versions are supported

.PARAMETER DownloadRoot
Where to download git from - by default this will be https://github.com/git-for-windows/git/releases/download

This can be a uri or a file share e.g. file://lorem.ipsum/stash-of-git-installers or \\lorem\git-installers\

Inside the download root the installers must be saved in the same folder and with the same file name
as they are when published on github.

.PARAMETER HideInstaller
If specified no installer dialog will be displayed.

When not specified the installer will stil complete automatically, but its progress will be displayed.

.EXAMPLE
./Install-GitForWindows 

.EXAMPLE
./Install-GitForWindows -Version 2.41.0.1

.EXAMPLE
$Env:BS_GIT_VER = 2.41.0.1
./Install-GitForWindows


#> 

param (
    [ValidatePattern('\d+\.\d+\.\d+\.\d+')]
    [string]$Version = $Env:BS_GIT_VER ?? '2.42.0.2',
    [string]$DownloadRoot = 'https://github.com/git-for-windows/git/releases/download',
    [switch]$HideInstaller
)

$ErrorActionPreference = 'Stop'
Set-StrictMode  -Version 3

if (!$IsWindows) {
    throw "This script is for windows only. See https://git-scm.com/download/$($IsMacOS ? 'mac' : 'linux') "
}

$em = if ($null -ne $Env:PS_EM) { $Env:PS_EM } else { $Env:PS_EM = '*', $Env:PS_EM }

$VersionParts = $Version -split '\.'
$Major = $VersionParts[0]
$Minor = $VersionParts[1]
$Build = $VersionParts[2]
$Revision = $VersionParts[3] 

$DownloadFolder = "v$Major.$Minor.$Build.windows.$Revision"
$DownloadName = "Git-$Major.$Minor.$Build$($Revision -eq 1 ? '' : ".$Revision")-64-bit.exe"
$DownloadUri = "$DownloadRoot/$DownloadFolder/$DownloadName"

Write-Information "INFO: Downloading git $em$Version$em - $em$DownloadUri$em"
Start-BitsTransfer -Source $DownloadUri
Write-Information "INFO: Downloading git $em$Version$em - $em$DownloadUri$em - done!"

Write-Information "INFO: Installing git $em$Version$em"
Start-Process $DownloadName -Wait -ArgumentList ($HideInstaller ? '/VERYSILENT' : '/SILENT')
Write-Information "INFO: Installing git $em$Version$em - done!"