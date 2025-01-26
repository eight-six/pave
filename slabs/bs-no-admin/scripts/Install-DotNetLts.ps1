#Requires -PSEdition Core

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

log-subheader "installing dotnet latest LTS"
$DotNetInstallUri = 'https://dot.net/v1/dotnet-install.ps1'
$DownloadFilePath = Resolve-Path .\dotnet-install.ps1 
Pop-LogAction "Downloading install script from $(emph $DotNetInstallUri) to $(emph $DownloadFilePath)"
Start-BitsTransfer $DotNetInstallUri $DownloadFilePath 
Pop-LogAction

Pop-LogAction "Running install script $(emph $DownloadFilePath)"
.\dotnet-install.ps1 # LTS, latest
$DotNetInstallPath = "$Env:LocalAppData\Microsoft\dotnet"
Add-UserEnvVar 'DOTNET_ROOT' $DotNetInstallPath -AddToCurrentSession
Add-UserPath -PathToAdd $DotNetInstallPath -AddToCurrentSession

log-subheader "installing dotnet latest LTS - completed"