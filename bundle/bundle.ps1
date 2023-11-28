
$BuildDir = '$PSScriptRoot/../build'

if(!(Test-Path $BuildDir)){
    mkdir $BuildDir
}

if(!(Test-Path "$BuildDir/slabs")){
    mkdir "$BuildDir/slabs"
}

$Index = @()

ls -Directory "$PSScriptRoot/../slabs" | % {
    $Index += $_.Name
    Compress-Archive "$($_.FullName)/*" "$BuildDir/slabs/$($_.Name).zip" -Force 
}

$Index | Out-File "$BuildDir/slabs/.index"

Compress-Archive "$PSScriptRoot/../pwsh/*" "$BuildDir/pwsh-pave.zip" -Force 


