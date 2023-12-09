#Requires -PSEdition Core

param(
)

$ErrorActionPreference = 'Stop'

$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
. "$SlabsRoot/slab-utils/slab-utils.ps1"

$SourcePath = Join-Path $PSScriptRoot 'scripts' '*.sh'
$TargetPath =  Join-Path $HOME '.config' 'git' 

if(!(Test-Path $TargetPath)){
    mkdir $TargetPath 
}

Copy-Item $SourcePath $TargetPath
