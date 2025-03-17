<#

Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser' -Force;
$Branch = 'tidy';
$FileName = 'bs-win-sandbox-lite.ps1';
$FilePath = "~\downloads\$FileName";
iwr "https://raw.githubusercontent.com/eight-six/pave/refs/heads/$Branch/$FileName" -OutFile $FilePath;
Unblock-File $FilePath;
. $FilePath;

#>

#requires -Modules PowershellGet

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = 'true'

#region config
$Env:PAVE_NUGET_MIN_VERSION = '2.8.5.201'
$Env:PAVE_PWSH_VERSION = '7.5.0'
$Env:PAVE_REMOTE = "https://eightsixpaveprodstg.blob.core.windows.net/public/latest-test"
$Env:PAVE_PY_VERSION = '3.12|3.11' # separate multiple versions with a | - versions are installed left to right, the last one will be the default.
$Env:PAVE_DOWNLOAD_CACHE = "~\pave\downloads"
$AdditionalApps = @('windows-terminal', 'git', 'code-insiders')

$ConfigsConfig = @"
org: stvnrs
repos:
- name: config
  groups:
  - path: default 
    dotSource: 
    - env
    call:
    - windows-terminal
    - git
    - code-insders
    - pwsh
  - Path: sandbox
    Call: []
    DotSource: env
"@
    
if ($null -eq $Env:PAVE_USER_NAME) {
    $Env:PAVE_USER_NAME = Read-Host -Prompt "Enter your user name for git logs (set `$Env:PAVE_USER_NAME to avoid this prompt in future)"
} 

if ($null -eq $Env:PAVE_USER_EMAIL ) {
    $Env:PAVE_USER_EMAIL = Read-Host -Prompt "Enter your email name for git logs (set `$Env:PAVE_USER_NAME to avoid this prompt in future)"
}
#endregion config

#region support functions
function log {
    param(
        [string] $message
    )
    Write-Information "$(get-date -format 'yyyy-MM-ddTHH:mm:ssZ') $message"
}

function prompt {        
    $Role = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole($role)
    $Dollar = if ($IsAdmin ) { '>' } else { 'P$' }
    $Options = Get-PSReadLineOption
    $Color = if ($IsAdmin) { $Options.ErrorColor } else { $Options.DefaultTokenColor }

    $Line1 = @(
        $Options.CommentColor
        $Pwd.Path.Replace($HOME, '~')
        $PSStyle.Reset
    ) -join ''

    $Line2 = "$($Color)$Dollar $($PSStyle.Reset)"

    '', $Line1, $Line2 -join "`n"
}

#endregion support functions 

Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser' -Force

#region install pave
$InstallCachePath = "$HOME\downloads\.pave" 

if (!(Test-Path $InstallCachePath )) {
    md $InstallCachePath | Out-Null
} else {
    rm "$InstallCachePath/*" -Recurse -Force
}

cd $InstallCachePath  

$ModulePath = "$($env:PSModulePath -split ';' | select -First 1)"
$PackageBaseName = 'pave-full-v99.99.99'
$ModuleZipFileName = "$PackageBaseName.zip"

if (Test-Path $ModuleZipFileName ) {
    rm $ModuleZipFileName | Out-Null
}

'pave-logger', 'pave-utils', 'pave' | % {
    if (Test-Path "$ModulePath\$_") {
        rm "$ModulePath\$_" -Recurse -Force | Out-Null
    }
}

Start-BitsTransfer "$Env:PAVE_REMOTE/$ModuleZipFileName" 
Expand-Archive $ModuleZipFileName
Expand-Archive './pave-full-v99.99.99/pave-logger-module-v99.99.99.zip' $ModulePath
Expand-Archive './pave-full-v99.99.99/pave-utils-module-v99.99.99.zip' $ModulePath
Expand-Archive './pave-full-v99.99.99/pave-module-v99.99.99.zip' $ModulePath
Expand-Archive './pave-full-v99.99.99/pave-config-module-v99.99.99.zip' $ModulePath
rm $ModuleZipFileName 

if (!(Get-Module -ListAvailable 'powershell-yaml')) {
    Install-Module powershell-yaml -Scope 'CurrentUser' -Force
}

Import-Module pave-logger -Force
Import-Module pave-utils -Force
Import-Module pave -Force
Import-Module pave-config -Force
Set-Remote $Env:PAVE_REMOTE
Install-Slab slab-utils
Install-Slab bs-no-admin
Install-Slab reg-tweaks
#endregion

#region install default apps
$BsParams = @{
    PwshVersion = $Env:PAVE_PWSH_VERSION
    UseWinget = $true
    SkipDownloadDotNetLts = $true
    Apps = $AdditionalApps
}


lay bs-no-admin @BsParams
Update-PathEnvVar 
#region

$Configs = $ConfigsConfig | ConvertFrom-Yaml 
Set-Configs -configs $Configs
