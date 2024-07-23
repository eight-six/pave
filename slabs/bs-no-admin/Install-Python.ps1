#requires -Version 5.1

<#PSScriptInfo

.VERSION 1.0

.GUID 63e9fad4-392d-4947-af5a-500e444734f3

.AUTHOR @stvnrs

.COMPANYNAME Eight Six Consulting

.COPYRIGHT (c)  Eight Six Consulting Limited

.TAGS

#install #python

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
 Installs the specified version of python for the current user to the default install folder 
 $Env:LOCALAPPDATA\Programs\python\versio

.PARAMETER Version
The version of python to install. This will default to 3.12.4 (the latest at he time of publishing)
of the value of $Env:BS_PY_VER if not specifed. 

This must be specifed as Major.Minor.Build

Only 64-bit release versions are supported

.PARAMETER DownloadRoot
Where to download python from - by default this will be https://www.python.org/ftp/python/

This can be a uri or a file share e.g. file://lorem.ipsum/stash-of-installers or \\lorem\installers\

Inside the download root the installers must be saved in the same folder and with the same file name
as they are when published on python.org

.PARAMETER HideInstaller
If specified no installer dialog will be displayed.

When not specified the installer will still complete automatically, but its progress will be displayed.

.EXAMPLE
./Install-Python 

.EXAMPLE
./Install-Python -Version 3.11.2

.EXAMPLE
$Env:BS_PY_VER = 3.12.3
./Install-Python

#> 

param (
    [ValidatePattern('\d+\.\d+\.\d+')]
    [string]$Version = $Env:BS_PY_VER ?? '3.12.4',
    [string]$DownloadRoot = 'https://www.python.org/ftp/python/',
     [switch]$HideInstaller
)

$ErrorActionPreference = 'Stop'

function PrependToUserPath{
    param (
		[string]$PathToAdd,
		[switch]$AddToCurrentSession
	)
	
	$UserPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
	$UserPath = "$PathToAdd;$UserPath$(if(-not $UserPath.EndsWith(';')){';'})"
	[System.Environment]::SetEnvironmentVariable('PATH', $UserPath, 'User')
	
	if($AddToCurrentSession.IsPresent){
		$Env:Path = "$PathToAdd;$Env:Path$(if(-not $Env:Path.EndsWith(';')){';'})"
	}
}

if (!$IsWindows){
    throw "This script is for windows only See https://www.python.org/downloads/ for options for you OS."
}

$em = if ($null -ne $Env:PS_EM) { $Env:PS_EM } else { $Env:PS_EM = '*', $Env:PS_EM }

$VersionParts = $Version -split '\.'
$Major = $VersionParts[0]
$Minor = $VersionParts[1]
$Build = $VersionParts[2]

$Product = 'python'
$DownloadFolder = "$Major.$Minor.$Build"    
$DownloadSuffix = 'amd64.exe'
$DownloadName = "$Product-$Major.$Minor.$Build-$DownloadSuffix"
$DownloadUri = "$DownloadRoot/$DownloadFolder/$DownloadName"

Write-Information "INFO: Downloading $Product $em$Version$em - $em$DownloadUri$em"
Start-BitsTransfer -Source $DownloadUri
Write-Information "INFO: Downloading $Product $em$Version$em - $em$DownloadUri$em - done!"

Write-Information "INFO: Installing $Product $em$Version$em"
Start-Process $DownloadName -Wait -ArgumentList ($HideInstaller ? '/quiet' : '/passive')
Write-Information "INFO: Installing $Product $em$Version$em - done!"

$InstallFolder = "Python$Major$Minor"  
PrependToUserPath  "$Env:LOCALAPPDATA\Programs\Python\$InstallFolder" -AddToCurrentSession
PrependToUserPath  "$Env:LOCALAPPDATA\Programs\Python\$InstallFolder\scripts" -AddToCurrentSession

$WindowsAppsRoot = "$Env:LOCALAPPDATA\Microsoft\WindowsApps"
$WindowsStorePythonPaths = "$WindowsAppsRoot\python.exe", "$WindowsAppsRoot\python3.exe"

$WindowsStorePythonPaths | ForEach-object {
    if (Test-Path $_){
        Remove-Item -path $_ -Force
    }
}


# pip intall xxx --Proxy <proxyurl>
# $env:LOCALAPPDATA/Programs/Python/Python312/python.exe -m pip install ipykernel -U --user --force-reinstall --Proxy <proxyurl>'