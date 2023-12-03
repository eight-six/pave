
$BuildDir = "$PSScriptRoot/../build"

if(Test-Path $BuildDir){
    Remove-Item $BuildDir -recurse -force
}


