#requires -Version 5.1

<#PSScriptInfo

.VERSION 1.0

.GUID f04f3668-3c3f-472a-9c77-3f82ee27484a

.AUTHOR @stvnrs

.COMPANYNAME Eight Six Consulting

.COPYRIGHT (c)  Eight Six Consulting Limited

.TAGS

#install #duckdb

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Installs the specified version of duckdb for the current user to the folder $Env:LOCALAPPDATA\Programs\duckdb\

.PARAMETER Version
The version of duckdb for windows to install. This will default to 1.1.3 (the latest at he time of publishing)
or the value of $Env:PAVE_DUCKDB_VER if not specifed. 

This must be specifed as Major.Minor.Build


.PARAMETER DownloadRoot
Where to download duckdb from - by default this will be https://github.com/duckdb/duckdb/releases/download/

This can be a uri or a file share e.g. file://lorem.ipsum/stash-of-installers/duckdb or \\lorem\installers\duckdb

Inside the download root the installers must be saved in the same folder and with the same file name
as they are when published on duckdb.org.

.EXAMPLE
./Install-DuckDB 

.EXAMPLE
./Install-DuckDB -Version 1.1.2

.EXAMPLE
$Env:PAVE_DUCKDB_VER = 1.1.1
./Install-DuckDB

#> 

param (
    [ValidatePattern('\d+\.\d+\.\d+')]
    [string]$Version = $Env:PAVE_DUCKDB_VER ,
    [string]$DownloadRoot = 'https://github.com/duckdb/duckdb/releases/download/'
)

if ($MyInvocation.InvocationName -eq '.') {
    Write-Warning "This script is not intended to be dot sourced. PLese try again without the $($em)dot sourcing$em operator " -wa 'Continue'
    return
} 

function do-it {
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'
    $WarningPreference = 'Continue'

    $App = 'duckdb'

    if ($PSVersionTable.PSVersion.Major -ge 7 -and !$IsWindows) {
        throw "This script is for windows only. See https://duckdb.org/docs/installation/?version=stable&environment=cli&platform=win&download_method=direct&architecture=x86_64 for other options"
    }

    if (!$Version) {
        $Version = '1.1.3'
    }

    $em = if ($null -ne $Env:PS_EM) { $Env:PS_EM } else { $Env:PS_EM = '*'; $Env:PS_EM }

    $VersionParts = $Version -split '\.'
    $Major = $VersionParts[0]
    $Minor = $VersionParts[1]
    $Build = $VersionParts[2]

    # e.g. https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-windows-amd64.zip
    $DownloadFolder = "v$Major.$Minor.$Build"
    $DownloadName = "duckdb_cli-windows-amd64.zip"

    if($DownloadRoot[-1] -eq '/'){
        $DownloadRoot = $DownloadRoot.Substring(0, $DownloadRoot.Length-1)
    }

    $DownloadUri = "$DownloadRoot/$DownloadFolder/$DownloadName"

    Write-Information "INFO: Downloading $App $em$Version$em - $em$DownloadUri$em"
    Start-BitsTransfer -Source $DownloadUri
    Write-Information "INFO: Downloading $App $em$Version$em - $em$DownloadUri$em - done!"

    $DestinationRoot = "$env:LOCALAPPDATA\Programs\$App"
    $DestinationPath = join-Path $DestinationRoot $DownloadFolder
    $DestinationFilePath = Join-Path $DestinationPath "$App.exe"

    if (!(Test-Path $DestinationRoot )) {
        md $DestinationRoot | Out-Null 
    }
    
    # remove link if it exists
    $DefaultFilePath = Join-Path $DestinationRoot "$App.exe"
    $VersionFilePath = Join-Path $DestinationRoot "$App.$Version.exe"
    
    if(Test-Path $DefaultFilePath){
        rm  $DefaultFilePath
    }

    if(Test-Path $VersionFilePath){
        rm  $VersionFilePath
    }
    
    if (Test-Path $DestinationPath) {
        Write-Information "INFO: Deleting existing $App install at $em$DestinationPath$em"
        rm -Force -Recurse $DestinationPath | Out-Null
        Write-Information "INFO: Deleting existing $App install at $em$DestinationPath$em - done."
    }
    
    Write-Information "INFO: Installing $App $em$Version$em to $em$DestinationPath$em"
    Expand-Archive $DownloadName -DestinationPath $DestinationPath
    
    # this will create a link in "$env:LOCALAPPDATA\Programs\duckdb\duckdb.exe" which links to the version currently being installed
    New-Item -ItemType 'HardLink' -Path (Join-Path $DestinationRoot "$App.exe") -Target $DestinationFilePath | Out-Null
    New-Item -ItemType 'HardLink' -Path (Join-Path $DestinationRoot "$App.$version.exe") -Target $DestinationFilePath | Out-Null
    Write-Information "INFO: $App will default to $em$Version$em - use $App.$version.exe for specific version"

    $UserPaths = [Environment]::GetEnvironmentVariable('PATH', 'USER') -split ';'

    if($UserPaths -notcontains $DestinationRoot){
        $UserPath = "$DestinationRoot;$($UserPaths -join ';')"
        [Environment]::SetEnvironmentVariable('PATH', $UserPath , 'USER')
        Write-Information "INFO: $App $em$Version$em added to path - start a new shell to use it."
    }

    Write-Information "INFO: Installing $App $em$Version$em - done!"
}

do-it