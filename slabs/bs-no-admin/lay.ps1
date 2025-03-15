#Requires -version 5.1 # Windows Powershell
#Requires -modules PowershellGet
#Requires -modules pave-logger
#Requires -modules pave-utils

[CmdletBinding(SupportsShouldProcess)]
param (
    [ValidatePattern('^7\.\d+(\.\d+){0,1}$')]
    [string]$PwshVersion = $(if ($Env:PAVE_PWSH_VERSION) { $Env:PAVE_PWSH_VERSION }else { '7.5.0' }),
    [ValidatePattern('^[23].\d.\d.\d{1,3}$')]
    [string]$NugetMinVersion = $(if ($Env:PAVE_NUGET_MIN_VERSION) { $Env:PAVE_NUGET_MIN_VERSION }else { '2.8.5.201' }),
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

    $PwshResult = & "$ScriptsFolder\Install-Pwsh.ps1" -Version $PwshVersion -SkipDownload:$SkipDownload 

    $NugetResult = & "$ScriptsFolder\Install-Nuget.ps1" -MinVersion $NugetMinVersion 

    # install winget if specified
    if ($UseWinget.IsPresent) {
        Write-LogHeader -Subheader "$(u 'winget')"
        $Winget = gcm 'winget' -ErrorAction ignore

        if ($null -ne 'Winget') {
            log "winget $(winget --version) already installed"
        }
        else {
            if ($PSCmdlet.ShouldProcess("winget", "install")) {
                    Push-Location "Installing winget"
                    Install-Module -Name 'Microsoft.WinGet.Client'  -Repository 'PSGallery' -Force -Scope 'CurrentUser'

                    if ($PSCmdlet.ShouldProcess("Repair-WingetPackageManager", "call")) {
                        Repair-WingetPackageManager
                    }
         
                    Pop-LogAction
                }
            }
        }
    
        # install dotnet lts if not skipped
        if (!$SkipDownloadDotNetLts.IsPresent) {
            $DotNetScriptFilePath = Join-Path $ScriptsFolder 'Install-DotNetLts.ps1'

            if ($PSVersionTable.PSEdition -eq 'Core') {
                & $DotNetScriptFilePath
            }
            else {
                & $PwshResult.PwshPath -WorkingDirectory $PSScriptRoot -NoProfile -File $DotNetScriptFilePath

                if ($LASTEXITCODE -ne 0) {
                    $ErrorMessage = "Running $(emph $AppScriptsFilePath) with $(emph $PwshResult.PwshPath) failed with exit code $(em $LASTEXITCODE)."
                    Write-LogEntry $ErrorMessage -IgnoreActionLevel
                    throw $ErrorMessage
                }
            }
        }

        # install windows terminal if specified
        if ( $InstallWindowsTerminal.IsPresent) {
            $WindowsTerminalScriptFilePath = Join-Path $ScriptsFolder 'Install-WindowsTerminal.ps1'
            & $WindowsTerminalScriptFilePath 
        }

        # install apps with pwsh
        if ($Apps.Length -gt 0) {
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