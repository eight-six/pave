#Requires -PSEdition Core

param(
    [switch]$HideInstaller
)

Write-Information "INFO: bootstrap: installing AzureDataStudio"

# Write-Information "Issues with UAC!" -InformationAction 'Continue'

$Setup = 'InstallAzureDataStudio.exe'
$GoMsDownloadUri = 'https://go.microsoft.com/fwlink/?linkid=2251836'
$DownloadUri = (Invoke-WebRequest $GoMsDownloadUri -Method Head).BaseResponse.RequestMessage.RequestUri.AbsoluteUri
Start-BitsTransfer $DownloadUri $Setup
Start-Process $Setup -Wait -ArgumentList '/CURRENTUSER', "/$($HideInstaller.IsPresent ? 'VERYSILENT' : 'SILENT')", '/MERGETASKS=!runcode'    

Write-Information "INFO: bootstrap: installing AzureDataStudio - done"
