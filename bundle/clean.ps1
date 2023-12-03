
$BuildDir = '$PSScriptRoot/../build'

if(Test-Path $BuildDir){
    rm $BuildDir -recurse -force
}


