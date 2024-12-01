#requires -Version 5.1

<#PSScriptInfo

.VERSION 1.0

.GUID f04f3668-3c3f-472a-9c77-3f82ee27484a

.AUTHOR @stvnrs

.COMPANYNAME Eight Six Consulting

.COPYRIGHT (c)  Eight Six Consulting Limited

.TAGS

#install #node

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
 Installs the specified version of node for the current user to the folder $Env:LOCALAPPDATA\Programs\nodejs\

.PARAMETER Version
The version of node for windows to install. This will default to 20.18.0 (the latest at he time of publishing)
or the value of $Env:PAVE_NODE_VER if not specifed. 

This must be specifed as Major.Minor.Build

Only 64-bit release versions are supported

.PARAMETER DownloadRoot
Where to download node from - by default this will be https://nodejs.org/dist/

This can be a uri or a file share e.g. file://lorem.ipsum/stash-of-installers/nodejs or \\lorem\installers\nodejs

Inside the download root the installers must be saved in the same folder and with the same file name
as they are when published on nodejs.org.

.EXAMPLE
./Install-Node 

.EXAMPLE
./Install-Node -Version 23.0.0

.EXAMPLE
$Env:PAVE_NODE_VER = 2.22.10
./Install-Node


#> 

param (
    [ValidatePattern('\d+\.\d+\.\d+')]
    [string]$Version = $Env:PAVE_NODE_VER ,
    [string]$DownloadRoot = 'https://nodejs.org/dist'
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -ge 7 -and !$IsWindows) {
    throw "This script is for windows only. See https://nodejs.org/en/download/package-manager for other options"
}

if (!$Version) {
    $Version = '20.18.0'
}

$em = if ($null -ne $Env:PS_EM) { $Env:PS_EM } else { $Env:PS_EM = '*'; $Env:PS_EM }

$VersionParts = $Version -split '\.'
$Major = $VersionParts[0]
$Minor = $VersionParts[1]
$Build = $VersionParts[2]

# https://nodejs.org/dist/v20.18.0/node-v20.18.0-win-x64.zip
$DownloadFolder = "v$Major.$Minor.$Build"
$DownloadName = "node-v$Major.$Minor.$Build-win-x64.zip"
$DownloadUri = "$DownloadRoot/$DownloadFolder/$DownloadName"

Write-Information "INFO: Downloading node $em$Version$em - $em$DownloadUri$em"
# Bits Transfer failing on client vdi - only for this download. works with iwr!
# Start-BitsTransfer -Source $DownloadUri
iwr $DownloadUri -OutFile $DownloadName
Write-Information "INFO: Downloading node $em$Version$em - $em$DownloadUri$em - done!"

$DestinationRoot = "$env:LOCALAPPDATA\Programs\nodejs"
$DestinationPath = "$DestinationRoot\node-v$Major.$Minor.$Build-win-x64"

if (!(Test-Path $DestinationRoot )) {
    md $DestinationPath | Out-Null 
}

if (Test-Path $DestinationPath) {
    Write-Information "INFO: Deleting existing node install at $em$DestinationPath$em"
    rm -Force -Recurse $DestinationPath | Out-Null
    Write-Information "INFO: Deleting existing node install at $em$DestinationPath$em - done."
}

Write-Information "INFO: Installing node $em$Version$em"
Expand-Archive $DownloadName -DestinationPath $DestinationRoot

$Env:Path = "$DestinationPath;$env:Path"

$Proxy = ([System.Net.WebRequest]::GetSystemWebProxy().GetProxy('https://www.npmjs.com/'))

if ($null -ne $Proxy) {
    npm config set proxy $Proxy.OriginalString
    npm config set https-proxy $Proxy.OriginalString
}

$Path = $Env:Path
$UserPaths = [Environment]::GetEnvironmentVariable('PATH', 'USER') -split ';'  | ? {$_ -ne $DestinationPath}
$UserPath = "$DestinationPath;$($UserPaths -join ';')"

[Environment]::SetEnvironmentVariable('PATH', $UserPath , 'USER')
[Environment]::SetEnvironmentVariable('PATH', $Path , 'PROCESS')

Write-Information "INFO: Installing node $em$Version$em - done!"
