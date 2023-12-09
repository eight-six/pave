#Requires -PSEdition Core

param(
    [switch]$HideInstaller
)

Write-Information "bootstrap: installing StorageExplorer"

Write-Information "Issues with UAC!" -InformationAction 'Continue'

$Setup = 'InstallStorageExplorer.exe'
$GoMsDownloadUri = 'https://go.microsoft.com/fwlink/?LinkId=708343&clcid=0x809'
$DownloadUri = (iwr $GoMsDownloadUri -Method Head).BaseResponse.RequestMessage.RequestUri.AbsoluteUri
Start-BitsTransfer $DownloadUri $Setup
Start-Process $Setup -Wait -ArgumentList '/CURRENTUSER', "/$($HideInstaller.IsPresent ? 'VERYSILENT' : 'SILENT')"

Write-Information "bootstrap: installing StorageExplorer - done"