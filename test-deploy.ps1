


$SetUp = {
    Import-Module .\pwsh\pave.psm1 -Force
    $Cache = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $Cache 
    Set-Cache $Cache
    Set-Remote C:\Users\StevenRose\source\repos\pave\build\
    Find-Slab | Install-Slab

}

$TearDown = {
    Remove-Item -Path (Get-Cache) -Recurse -Force -Verbose
    $ErrorActionPreference = $CurrentErrorActionPreference
    $InformationPreference = $CurrentInformationPreference
    $VerbosePreference = $CurrentVerbosePreference
    Read-Host -Prompt 'Press any key to exit'
    exit
}

$Setup.Invoke()

$CurrentErrorActionPreference = $ErrorActionPreference
$CurrentInformationPreference = $InformationPreference
$CurrentVerbosePreference = $VerbosePreference 

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$VerbosePreference = 'Continue'
# Deploy-Slab bs
