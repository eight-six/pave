#Requires -PSEdition Core

param(
)

$ErrorActionPreference = 'Stop'

$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
. "$SlabsRoot/slab-utils/slab-utils.ps1"

$SourcePath = Join-Path $PSScriptRoot 'src' '*.ps1'
$TargetPath =  Join-Path $HOME 'powershell' 'scripts' 

if(!(Test-Path $TargetPath)){
    mkdir $TargetPath 
}

Copy-Item $SourcePath $TargetPath


