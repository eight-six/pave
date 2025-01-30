#Requires -PSEdition Core
#Requires -Modules pave-logger

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Heading = 'dotnet'
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction "installing dotnet latest lts" -IncrementActionLevel

$Heading = 'dotnet'
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction "installing dotnet latest lts" -IncrementActionLevel

$DotNetInstallUri = 'https://dot.net/v1/dotnet-install.ps1'
$DownloadFilePath = Join-Path $pwd.path 'dotnet-install.ps1' 
Push-LogAction "Downloading install script from $(emph $DotNetInstallUri) to $(emph $DownloadFilePath)"
Get-Download $DotNetInstallUri $DownloadFilePath 
Pop-LogAction

Push-LogAction "Running install script $(emph $DownloadFilePath)"
& .\dotnet-install.ps1 # LTS, latest
$DotNetInstallPath = "$Env:LocalAppData\Microsoft\dotnet"
Pop-LogAction

Push-LogAction "Adding DOTNET_ROOT adding to path"
Add-UserEnvVar 'DOTNET_ROOT' $DotNetInstallPath -AddToCurrentSession
Add-UserPath -PathToAdd $DotNetInstallPath -AddToCurrentSession
Pop-LogAction

Pop-LogAction

if($null -eq $MyInvocation.PSCommandPath){
	$Heading += ' - completed'
	Write-LogHeader $Heading 
}