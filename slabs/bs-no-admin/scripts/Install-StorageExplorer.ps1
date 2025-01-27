#Requires -PSEdition Core

param(
    [switch]$HideInstaller
)

$Heading =  "StorageExplorer"
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction "installing $Heading" -IncrementActionLevel

# this needs to be moved to Write-LogEntry
$Cont = '>> '
$PadChars = if((Get-LogOptions).timestamp){21} else {0}
$Pad = (' ' * $PadChars) + $Cont 

$UacWarning = @"
StorageExplorer installer will fail to find dotnet if it is not installed in Program Files. In which case it
$($Pad)attempts to install it - which needs elevation. If dotnet is installed, or you plan to install it, 
$($Pad)cancel the UAC prompt and click OK the warning dialog which is displayed subsequently.
$($Pad)Alternatively, if you have local admin privs, you can accept the UAC prompt and dotnet will be installed in
$($Pad)Program Files."
"@

Write-LogEntry $UacWarning

$Setup = 'InstallStorageExplorer.exe'
$GoMsDownloadUri = 'https://go.microsoft.com/fwlink/?LinkId=708343&clcid=0x809'
$DownloadUri = (iwr $GoMsDownloadUri -Method Head).BaseResponse.RequestMessage.RequestUri.AbsoluteUri
Start-BitsTransfer $DownloadUri $Setup
Start-Process $Setup -Wait -ArgumentList '/CURRENTUSER', "/$($HideInstaller.IsPresent ? 'VERYSILENT' : 'SILENT')"

Push-LogAction