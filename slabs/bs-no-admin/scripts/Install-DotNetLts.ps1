#Requires -PSEdition Core
#Requires -Modules pave-logger

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Heading = "$(u dotnet)"
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction "installing dotnet latest lts" -IncrementActionLevel

$DotNetInstallUri = 'https://dot.net/v1/dotnet-install.ps1'
$DownloadPath = if ($Env:PAVE_DOWNLOAD_CACHE) { $Env:PAVE_DOWNLOAD_CACHE }else { $Pwd.Path }
$DownloadFilePath = Join-Path $DownloadPath 'dotnet-install.ps1' 

Push-LogAction "Downloading install script from $(emph $DotNetInstallUri) to $(emph $DownloadFilePath)"
Get-Download $DotNetInstallUri $DownloadFilePath 
Pop-LogAction

Push-LogAction "Running install script $(emph $DownloadFilePath)"

if ($PSCmdlet.ShouldProcess("dot net lts", "install")) {
	& $DownloadFilePath # LTS, latest
}

$DotNetInstallPath = "$Env:LocalAppData\Microsoft\dotnet"
Pop-LogAction

Push-LogAction "Adding $(em DOTNET_ROOT) adding to path"
Add-UserEnvVar 'DOTNET_ROOT' $DotNetInstallPath -AddToCurrentSession
Add-UserPath -PathToAdd $DotNetInstallPath -AddToCurrentSession
Pop-LogAction

Pop-LogAction

if ($null -eq $MyInvocation.PSCommandPath) {
	$Heading += ' - completed'
	Write-LogHeader $Heading 
}