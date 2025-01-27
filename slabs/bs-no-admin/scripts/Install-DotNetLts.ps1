#Requires -PSEdition Core

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Banner = "dotnet latest LTS"

if($null -eq $MyInvocation.PSCommandPath){
	Write-LogHeader $Banner 
} else {
	Write-LogSubHeader $Banner
}

$DotNetInstallUri = 'https://dot.net/v1/dotnet-install.ps1'
$DownloadFilePath = Join-Path $pwd.path 'dotnet-install.ps1' 
Pop-LogAction "Downloading install script from $(emph $DotNetInstallUri) to $(emph $DownloadFilePath)"
Start-BitsTransfer $DotNetInstallUri $DownloadFilePath 
Pop-LogAction

Pop-LogAction "Running install script $(emph $DownloadFilePath)"
& .\dotnet-install.ps1 # LTS, latest
$DotNetInstallPath = "$Env:LocalAppData\Microsoft\dotnet"
Add-UserEnvVar 'DOTNET_ROOT' $DotNetInstallPath -AddToCurrentSession
Add-UserPath -PathToAdd $DotNetInstallPath -AddToCurrentSession

$Banner += ' - completed'

if($null -eq $MyInvocation.PSCommandPath){
	Write-LogHeader $Banner 
} else {
	Write-LogSubHeader $Banner
}