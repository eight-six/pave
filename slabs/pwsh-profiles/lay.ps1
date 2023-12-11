#Requires -PSEdition Core

param(
    [switch]$DeploySynchedProfileShim
)

$ErrorActionPreference = 'Stop'

$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
. "$SlabsRoot/slab-utils/slab-utils.ps1"

$SourcePath = Join-Path $PSScriptRoot 'src' '*.ps1'
$TargetPath =  Join-Path $HOME 'powershell' 'profile' 

if(!(Test-Path $TargetPath)){
    $InfoMessage = "Creating profile directory $(emph $TargetPath)"
    Write-Information "INFO: $InfoMessage$LogStart"
    mkdir $TargetPath | Out-Null
    Write-Information "INFO: $InfoMessage$LogDone"
}

$InfoMessage = "Copying profiles to $(emph $TargetPath)"
Write-Information "INFO: $InfoMessage$LogStart"
Copy-Item $SourcePath $TargetPath
Write-Information "INFO: $InfoMessage$LogDone"

if($DeploySynchedProfileShim.IsPresent){
    $InfoMessage = "Deploying synched-profile-shim.ps1 to $PROFILE"
    Write-Information "INFO: $InfoMessage$LogStart"
    Copy-Item (Join-Path $PSScriptRoot 'src' 'synched-profile-shim.ps1') $PROFILE
    Write-Information "INFO: $InfoMessage$LogDone"
}

