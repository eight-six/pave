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
$NugetMinVersion = '2.8.5.201'
$Env:PAVE_PWSH_VERSION = '7.5.0'
$Env:PAVE_REMOTE = "https://eightsixpaveprodstg.blob.core.windows.net/public/latest-test"
$Env:PAVE_PY_VERSION = '3.12|3.11' # separate multiple versions with a | - versions are installed left to right, the last one will be the default.
$AdditionalApps = @('windows-terminal')

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
  - Path: uvm
    Call: []
    DotSource: env
"@

$Configs = $ConfigsConfig | ConvertFrom-Yaml 
    
if ($null -eq $Env:PAVE_USER_NAME) {
    $Env:PAVE_USER_NAME = Read-Host -Prompt "Enter your user name for git logs (set `$Env:PAVE_USER_NAME to avoid this prompt in future)"
} 

if ($null -eq $Env:PAVE_USER_EMAIL ) {
    $Env:PAVE_USER_EMAIL = Read-Host -Prompt "Enter your email name for git logs (set `$Env:PAVE_USER_NAME to avoid this prompt in future)"
}
#endregion config

#region support functions
function cLog {
    param(
        [string] $message
    )
    Write-Information "$(get-date -format 'yyyy-MM-ddTHH:mm:ssZ') $message"
}
#endregion support functions

Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser' -Force

#region install winget
if ($null -eq (Get-PackageProvider | ? { ($_.Name -eq 'NuGet') -and ($_.Version -ge $NugetMinVersion) })) {
    cLog "Installing nuget $NugetMinVersion or later..."
    Install-PackageProvider -Name 'NuGet' -MinimumVersion $NugetMinVersion -Scope 'CurrentUser' -Force 
    cLog "Installing nuget $NugetMinVersion or later - done!"
}
else {
    cLog "Nuget already installed :)"
}

if ($null -eq (Get-PSRepository | ? SourceLocation -eq 'https://www.powershellgallery.com/api/v2' )) {
    cLog "Registering PS Gallery..."
    Register-PSRepository -Default -Force
    cLog "Registering PS Gallery - done!"
}
else {
    cLog "PS Gallery already registered :)"
}

cLog "Installing winget..."
Install-Module -Name 'Microsoft.WinGet.Client'  -Repository 'PSGallery' -Force -Scope 'CurrentUser'
Repair-WingetPackageManager
cLog "Installing winget - done"
#endregion

#region install pave
$InstallCachePath = "$HOME\downloads\~pave" 

if (!(Test-Path $InstallCachePath )) {
    md $InstallCachePath | Out-Null
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
rm $ModuleZipFileName 

if (!(Get-Module -ListAvailable 'powershell-yaml')) {
    Install-Module powershell-yaml -Scope 'CurrentUser' -Force
}

Import-Module pave-logger
Import-Module pave-utils
Import-Module pave

Set-Remote $Env:PAVE_REMOTE
Install-Slab slab-utils
Install-Slab bs-no-admin
Install-Slab reg-tweaks
#endregion

#region install default apps
lay bs-no-admin -PwshVersion $Env:PAVE_PWSH_VERSION -UseWinget
Update-PathEnvVar 
#endregion

#region install additional apps
$ScriptsPath = "$(Get-Cache)\bs-no-admin\scripts"

$AdditionalApps | % {
    $InstallFileName = "Install-$([cultureinfo]::CurrentCulture.TextInfo.ToTitleCase($_)).ps1"
    $InstallFilePath = Join-Path $ScriptsPath $InstallFileName
    Invoke-Pwsh -File $InstallFilePath 
}

#region apply configs
$ConfigFilePath = Join-Path $ScriptsPath 'Set-Config.ps1'

$Configs.Repos | % {
    $Repo = $_

    $Repo.Groups | % {
        $Group = $_
        $SharedParams = "-Org '$($Configs.Org)' -Repo '$($Repo.Name)' -Path '$($Group.Path)'"  
        $CommandTextBase = "$ConfigFilePath $SharedParams"

        if($Group.DotSource.Length -gt 0){
            $DotSource = ($Group.DotSource | % { "'$_'" } ) -join ', '
            $CommandText =  $CommandTextBase + " -DotSource -Include $DotSource"
            Invoke-Pwsh -CommandText $CommandText
        }
                
        if($Group.Call.Length -gt 0){
            $Call = ($Group.Call | % { "'$_'" } ) -join ', '
            $CommandText = $CommandTextBase + " -Include $Call"
            Invoke-Pwsh -CommandText $CommandText
        }
    }
}

#endregion
