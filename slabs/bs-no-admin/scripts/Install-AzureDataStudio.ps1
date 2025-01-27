#Requires -PSEdition Core

param(
    [switch]$HideInstaller
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Heading =  "AzureDataStudio"
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction 'installing Azure Data Studio' -IncrementActionLevel

$Setup = Join-Path $pwd.path 'InstallAzureDataStudio.exe'
$GoMsDownloadUri = 'https://go.microsoft.com/fwlink/?linkid=2251836'
$DownloadUri = (Invoke-WebRequest $GoMsDownloadUri -Method Head).BaseResponse.RequestMessage.RequestUri.AbsoluteUri

Push-LogAction "Downloading installer from $(emph $DownloadUri) to  $(emph $Setup)"
Get-Download $DownloadUri $Setup
Pop-LogAction

Push-LogAction "installing AzureDatStudio from installer from $(emph $Setup)"
Start-Process $Setup -Wait -ArgumentList '/CURRENTUSER', "/$($HideInstaller.IsPresent ? 'VERYSILENT' : 'SILENT')", '/MERGETASKS=!runcode'    
Pop-LogAction

Pop-LogAction

if($null -eq $MyInvocation.PSCommandPath){
    $Heading += ' - completed'
    Write-LogHeader $Heading 
}