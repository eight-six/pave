param(
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 'latest'

$em = $Env:PS_EMPH ?? '``'

$SourcePath = Join-Path $PSScriptRoot 'src' '*.ps1'
$TargetPath =  Join-Path $HOME 'powershell' 'scripts' 

if(!(Test-Path $TargetPath)){
    md $TargetPath 
}

cp $SourcePath $TargetPath -Verbose


