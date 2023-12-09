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
    mkdir $TargetPath 
}

Copy-Item $SourcePath $TargetPath

if($DeploySynchedProfileShim.IsPresent){
    Copy-Item (Join-Path $PSScriptRoot 'src' 'synched-profile-shim.ps1') $PROFILE
}

