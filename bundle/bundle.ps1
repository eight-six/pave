
$BuildDir = '$PSScriptRoot/../build'
$ModuleName = 'pave'
$ModuleBuildPath = "$BuildDir/$ModuleName"

if(!(Test-Path $BuildDir)){
    mkdir $BuildDir
}

if(!(Test-Path "$BuildDir/slabs")){
    mkdir "$BuildDir/slabs"
}

if(!(Test-Path $ModuleBuildPath)){
    mkdir $ModuleBuildPath
}

$Index = @()

ls -Directory "$PSScriptRoot/../slabs" | % {
    $Index += $_.Name
    Compress-Archive "$($_.FullName)/*" "$BuildDir/slabs/$($_.Name).zip" -Force 
}

$Index | Out-File "$BuildDir/slabs/.index"

cp "$PSScriptRoot/../pwsh/*" $ModuleBuildPath -recurse

Compress-Archive -path "$ModuleBuildPath/*"  -Destination "$BuildDir/pave.zip" -Force 

rm $ModuleBuildPath -recurse -force



