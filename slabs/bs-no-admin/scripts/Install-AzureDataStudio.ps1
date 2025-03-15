#Requires -PSEdition Core

param(
    [switch]$HideInstaller
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Heading =  "AzureDataStudio"
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction 'installing Azure Data Studio' -IncrementActionLevel

$DownloadPath = if ($Env:PAVE_DOWNLOAD_CACHE) { $Env:PAVE_DOWNLOAD_CACHE }else { $Pwd.Path }
$DownloadFilePath = Join-Path $DownloadPath 'InstallAzureDataStudio.exe'
$GoMsDownloadUri = 'https://go.microsoft.com/fwlink/?linkid=2251836'
$DownloadUri = (Invoke-WebRequest $GoMsDownloadUri -Method Head).BaseResponse.RequestMessage.RequestUri.AbsoluteUri

Push-LogAction "Downloading installer from $(emph $DownloadUri) to  $(emph $Setup)"
Get-Download $DownloadUri $DownloadFilePath
Pop-LogAction

Push-LogAction "installing AzureDatStudio from installer from $(emph $Setup)"
Start-Process $DownloadFilePath -Wait -ArgumentList '/CURRENTUSER', "/$($HideInstaller.IsPresent ? 'VERYSILENT' : 'SILENT')", '/MERGETASKS=!runcode'    
Pop-LogAction

Pop-LogAction

if($null -eq $MyInvocation.PSCommandPath){
    $Heading += ' - completed'
    Write-LogHeader $Heading 
}