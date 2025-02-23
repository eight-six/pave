<#

Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser';
$FileName = 'bs-win-sandbox.ps1'
$FilePath = "~\downloads\$FileName"
iwr "https://raw.githubusercontent.com/eight-six/pave/refs/heads/tidy/$FileName" -OutFile $FilePath;
Unblock-File $FilePath;
. $FilePath;

#>

#requires -Modules PowershellGet

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function Log {
    param(
        [string] $message
    )

    Write-Information "$(get-date -format 'yyyy-MM-ddTHH:mm:ssZ') $message"
}

$NugetMinVersion = '2.8.5.201'

Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser' -Force

if($null -eq (Get-PackageProvider | ? { ($_.Name -eq 'NuGet') -and ($_.Version -ge $NugetMinVersion)})){
    Log "Installing nuget $NugetMinVersion or later..."
    Install-PackageProvider -Name 'NuGet' -MinimumVersion $NugetMinVersion -Scope 'CurrentUser' -Force 
    Log "Installing nuget $NugetMinVersion or later - done!"
} else {
    Log "Nuget already installed :)"
}

if($null -eq (Get-PSRepository | ? SourceLocation -eq 'https://www.powershellgallery.com/api/v2' )){
    Log "Registering PS Gallery..."
    Register-PSRepository -Default -Force
    Log "Registering PS Gallery - done!"
} else {
    Log "PS Gallery already registered :)"
}

Log "Installing winget..."
Install-Module -Name 'Microsoft.WinGet.Client'  -Repository 'PSGallery' -Force -Scope 'CurrentUser'
Repair-WingetPackageManager
Log "Installing winget - done"
