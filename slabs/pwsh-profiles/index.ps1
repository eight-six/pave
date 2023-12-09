param(
    [switch]$DeploySynchedProfileShim
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 'latest'

$em = $Env:PS_EMPH ?? '``'

$SourcePath = Join-Path $PSScriptRoot 'src' '*.ps1'
$TargetPath =  Join-Path $HOME 'powershell' 'profile' 

if(!(Test-Path $TargetPath)){
    md $TargetPath 
}

cp $SourcePath $TargetPath -Verbose

if($DeploySynchedProfileShim.IsPresent){
    cp (Join-Path $PSScriptRoot 'src' 'synched-profile-shim.ps1') $PROFILE -Verbose
}

