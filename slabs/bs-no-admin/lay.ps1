#Requires -version 5.1

param (
    [string]$PwshVersion = "7.4.0",
    [string]$NugetMinVersion = "2.8.5.201",
    [switch]$InstallWindowsTerminal
)

$ErrorActionPreference = 'Stop'

$ThisSlabName = Split-Path $PSScriptRoot -Leaf
$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
. "$SlabsRoot/slab-utils/slab-utils.ps1"

if($InstallWindowsTerminal.IsPresent){
    .\Install-StorageExplorer.ps1
}

$ScriptsFolder = Join-Path $PSScriptRoot 'scripts'
& "$ScriptsFolder\Install-Pwsh.ps1" -Version $PwshVersion

$LogMessage = "INFO: $(emph $ThisSlabName) installing nuget >= $NugetMinVersion"
Write-Information "$LogMessage$LogStart"
Install-PackageProvider -Name NuGet -MinimumVersion $NugetMinVersion -Scope 'CurrentUser' -Force
Write-Information "$LogMessage$LogDone"

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
    
    & ".\Scripts\Install-DotNetLts.ps1"
    & ".\Scripts\Install-GitForWindows.ps1" 
    & ".\Scripts\Install-BsCode.ps1" -BuildType $VsBuildType #-UsePSGallery #-VsCodeExtensions $VsCodeExtensions
    & ".\Scripts\Install-AzureDataStudio.ps1"
    & ".\Scripts\Install-StorageExplorer.ps1"
    
} | & "$Env:LocalAppData\powershell\pwsh" -WorkingDirectory $PSScriptRoot -noexit  -command -
