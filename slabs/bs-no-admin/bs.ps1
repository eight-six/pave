param (
    [switch]$InstallWindowsTerminal
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$PwshVersion = "7.3.9"
$NugetMinVersion = "2.8.5.201"

if($InstallWindowsTerminal.IsPresent){
    .\Install-StorageExplorer.ps1
}
    
& "$PSScriptRoot\Install-Pwsh.ps1" -Version $PwshVersion

$LogMessage = "bootstrap: installing nuget >= $NugetMinVersion"
Write-Information "$LogMessage..."
Install-PackageProvider -Name NuGet -MinimumVersion $NugetMinVersion -Scope 'CurrentUser' -Force
Write-Information "$LogMessage - done"

{
    $VsBuildType = 'insider'
    $VsCodeExtensions = @(
        'GitHub.remotehub'
        'mechatroner.rainbow-csv'
        'ms-azuretools.vscode-bicep'
        'ms-dotnettools.vscode-dotnet-runtime'
        'ms-vscode.azure-repos'
        'ms-vscode.powershell'
        'ms-vscode.remote-repositories'
    )
    
    .\Install-DotNetLts.ps1
    .\Install-GitForWindows.ps1 
    .\Install-BsCode.ps1 -BuildType $VsBuildType #-UsePSGallery #-VsCodeExtensions $VsCodeExtensions
    .\Install-AzureDataStudio.ps1
    .\Install-StorageExplorer.ps1
    

} | & "$Env:LocalAppData\powershell\pwsh" -WorkingDirectory $PSScriptRoot -noexit  -command -
