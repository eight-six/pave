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
#Requires -PSEdition Core

param (
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version = $Env:PAVE_NODE_VER ,
    [string]$DownloadRoot = 'https://nodejs.org/dist'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

if (!$IsWindows) {
    throw "This script is for windows only. See https://nodejs.org/en/download/package-manager for other options"
}

$Heading = 'node'
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction "installing $Heading $version" -IncrementActionLevel

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

Push-LogAction "Downloading node $(emph $Version) from $(emph $DownloadUri)" 
Get-Download $DownloadUri $DownloadName
Pop-LogAction

$DestinationRoot = "$env:LOCALAPPDATA\Programs\nodejs"
$DestinationPath = "$DestinationRoot\node-v$Major.$Minor.$Build-win-x64"

if (!(Test-Path $DestinationRoot )) {
    md $DestinationPath | Out-Null 
}

if (Test-Path $DestinationPath) {
    Push-LogAction "Deleting existing node install at $(emph $DestinationPath)"
    rm -Force -Recurse $DestinationPath | Out-Null
    Pop-LogAction
}

Push-LogAction "Installing node $(emph $Version) from $DownloadName to $(emph $DestinationRoot)"
Expand-Archive $DownloadName -DestinationPath $DestinationRoot
Add-UserPath $DestinationPath -AtStart -AddToCurrentSession
$Env:Path = "$DestinationPath;$Env:Path" # shouldn't be necessary with -AddToCurrentSession on previous line
Pop-LogAction

$Proxy = ([System.Net.WebRequest]::GetSystemWebProxy().GetProxy('https://www.npmjs.com/'))

if ($null -ne $Proxy) {
    Push-LogAction "configuring npm proxy $(under $Proxy.OriginalString)" -IncrementActionLevel
    npm config set proxy $Proxy.OriginalString
    npm config set https-proxy $Proxy.OriginalString
    Pop-LogAction
}


Pop-LogAction

if($null -eq $MyInvocation.PSCommandPath){
    $Heading += ' - completed'
    Write-LogHeader $Heading 
}
