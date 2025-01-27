#Requires -PSEdition Core

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Heading = 'dotnet latest LTS'
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction "installing dot lts" -IncrementActionLevel

$DotNetInstallUri = 'https://dot.net/v1/dotnet-install.ps1'
$DownloadFilePath = Join-Path $pwd.path 'dotnet-install.ps1' 
Pop-LogAction "Downloading install script from $(emph $DotNetInstallUri) to $(emph $DownloadFilePath)"
Get-Download $DotNetInstallUri $DownloadFilePath 
Pop-LogAction

Pop-LogAction "Running install script $(emph $DownloadFilePath)"
& .\dotnet-install.ps1 # LTS, latest
$DotNetInstallPath = "$Env:LocalAppData\Microsoft\dotnet"
Add-UserEnvVar 'DOTNET_ROOT' $DotNetInstallPath -AddToCurrentSession
Add-UserPath -PathToAdd $DotNetInstallPath -AddToCurrentSession

Pop-LogAction

if($null -eq $MyInvocation.PSCommandPath){
	$Heading += ' - completed'
	Write-LogHeader $Heading 
}