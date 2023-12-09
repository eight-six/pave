#Requires -PSEdition Core

$ErrorActionPreference = 'Stop'

$ThisSlab = Split-Path $PSScriptRoot -Leaf
$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path

. "$SlabsRoot/slab-utils/slab-utils.ps1"

Deploy $ThisSlab 'pwsh-profiles' @{ DeploySynchedProfileShim = $true}
Deploy $ThisSlab 'pwsh-scripts'
