#Requires -version 5.1 # Windows Powershell
#Requires -modules PowershellGet
#Requires -modules pave-logger
#Requires -modules pave-utils

[CmdletBinding(SupportsShouldProcess)]
param (
    [string]$PwshVersion = "7.5.0",
    [string]$NugetMinVersion = "2.8.5.201",
    [switch]$UseWinget,
    [switch]$InstallWindowsTerminal,
    [ValidateSet(
        'azure-data-studio',
        'code-insiders',
        'code',
        'git',
        'node',
        'storage-explorer',
        'windows-terminal-preview',
        'windows-terminal')]
    [string[]]$Apps = @(),
    [switch]$SkipDownloadDotNetLts,
    [switch]$SkipDownload
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    $ThisSlabName = Split-Path $PSScriptRoot -Leaf
    $SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
    . "$SlabsRoot/slab-utils/slab-utils.ps1"

    Write-LogHeader $ThisSlabName

    # install pwsh
    $ScriptsFolder = Join-Path $PSScriptRoot 'scripts'

    if ($PSCmdlet.ShouldProcess("pwsh $PwshVersion", "install")) {
        $PwshResult = & "$ScriptsFolder\Install-Pwsh.ps1" -Version $PwshVersion -SkipDownload:$SkipDownload 
    }
    else {
        $PwshResult = @{PwshPath = 'pwsh' }
    }

    # install winget if specified
    if ($UseWinget.IsPresent -and $PSCmdlet.ShouldProcess("winget", "install")) {
        $IsWingetAvailable = $null -ne (gcm winget -ErrorAction ignore)

        if (!$IsWingetAvailable) {
            Push-Location "Installing winget"
            Install-Module -Name 'Microsoft.WinGet.Client'  -Repository 'PSGallery' -Force -Scope 'CurrentUser'

            if ($PSCmdlet.ShouldProcess("Repair-WingetPackageManager", "call")) {
                Repair-WingetPackageManager
            }
            Pop-LogAction
        }
    }
    
    # install dotnet lts if not skipped
    if (!$SkipDownloadDotNetLts.IsPresent -and $PSCmdlet.ShouldProcess("DotNet LTS", "install")) {
        $DotNetScriptFilePath = Join-Path $ScriptsFolder 'Install-DotNetLts.ps1'
        & $PwshResult.PwshPath -WorkingDirectory $PSScriptRoot -NoProfile -File $DotNetScriptFilePath

        if ($LASTEXITCODE -ne 0) {
            $ErrorMessage = "Running $(emph $AppScriptsFilePath) with $(emph $PwshResult.PwshPath) failed with exit code $(em $LASTEXITCODE)."
            Write-LogEntry $ErrorMessage -IgnoreActionLevel
            throw $ErrorMessage
        }
    }

    # install windows terminal if specified
    if ( $InstallWindowsTerminal.IsPresent -and $PSCmdlet.ShouldProcess("Windows Terminal", "install")) {
        .\Install-WindowsTerminal.ps1
    }

    # install apps with pwsh
    if ($Apps.Length -gt 0) {
        # if ($Apps.Length -gt 0 -and $PSCmdlet.ShouldProcess("Apps", "install")){
        $InstallAppsScript = if ($UseWinget.IsPresent) { 'Install-AppsWinget.ps1' }else { 'Install-Apps.ps1' }
        $AppScriptsFilePath = Join-Path $ScriptsFolder $InstallAppsScript
        
        if ($PSVersionTable.PSEdition -eq 'Core') {
            & $AppScriptsFilePath -Apps $Apps
        }
        else {
            & $PwshResult.PwshPath -WorkingDirectory $PSScriptRoot -NoProfile -File $AppScriptsFilePath -Apps $Apps
            
            if ($LASTEXITCODE -ne 0) {
                $ErrorMessage = "Running $(emph $AppScriptsFilePath) with $(emph $PwshResult.PwshPath) failed with exit code $(em $LASTEXITCODE)."
                Write-LogEntry $ErrorMessage -IgnoreActionLevel
                throw $ErrorMessage
            }
        }
    }
}
catch {
    Clear-LogAction
    throw
}

Write-LogHeader "$ThisSlabName - complete"