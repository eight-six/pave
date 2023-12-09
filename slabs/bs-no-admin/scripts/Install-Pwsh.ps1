
<#PSScriptInfo

.VERSION 1.0

.GUID f5010c9d-27c2-47b6-8033-a99b79041a13

.AUTHOR @stvnrs

.COMPANYNAME Eight Six Consulting

.COPYRIGHT (c)  Eight Six Consulting Limited

.TAGS

#install 

.COPYRIGHT

.TAGS

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
 Installs the specified version of powershell core 

#> 
param (
    [ValidatePattern('7\.\d+\.\d+')]
    [string]$Version = '7.4.0',
    [string]$InstallPath = "$env:LOCALAPPDATA\powershell",
    [string]$DownloadRoot = 'https://github.com/PowerShell/PowerShell/releases/download'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode  -Version 3

function AddToUserPath{
    param (
		[string]$PathToAdd,
		[switch]$AddToCurrentSession
	)
	
	$UserPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
	$UserPath += "$(if(-not $UserPath.EndsWith(';')){';'})$PathToAdd"
	[System.Environment]::SetEnvironmentVariable('PATH', $UserPath, 'User')
	
	if($AddToCurrentSession.IsPresent){
		$Env:Path += "$(if(-not $Env:Path.EndsWith(';')){';'})$PathToAdd"
	}
}

if($InstallPath -eq (Split-Path -Parent ([Environment]::GetCommandLineArgs()[0]) )){
    throw "cannot install another instance of pwsh in the same location as the running instance"
}

# install pwsh
Write-Information "INFO: $($Env:BS_LOG_HEADER)installing pwsh v$Version"


$InstallerFileName = "PowerShell-$Version-win-x64.zip"
$DownloadUri = "$DownloadRoot/v$Version/$InstallerFileName"

if(Test-Path $InstallPath){
    rm -Path $InstallPath -Recurse -Force
}

Start-BitsTransfer $DownloadUri
Expand-Archive $InstallerFileName $InstallPath
AddToUserPath -PathToAdd $InstallPath -AddToCurrentSession

{
if(!(Test-path $PROFILE)) {
    $ProfilePath = Split-Path $PROFILE -Parent
    
    if(!(Test-path $ProfilePath)) {
        md $ProfilePath | Out-Null
    }
    
    'function prompt{"P$ "}'| Out-File $PROFILE
}
}| pwsh -command - 					#note the sneaky minus = get command from stdin

Write-Information "INFO: $($Env:BS_LOG_HEADER)installing pwsh v$Version - done"


