$ErrorActionPreference = 'Stop'

$BuildDir = "$PSScriptRoot/../build"
$ModuleName = 'pave'
$ModuleVersion = $Env:BUILD_MODULE_VERSION ??  '0.0.0'
$ModuleBuildPath = "$BuildDir/$ModuleVersion"
$ModuleSourcePath = "$PSScriptRoot/../pwsh"

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

Get-ChildItem -Directory "$PSScriptRoot/../slabs" | % {
    $Index += $_.Name
    Compress-Archive "$($_.FullName)/*" "$BuildDir/slabs/$($_.Name).zip" -Force 
}

$Index | Out-File "$BuildDir/slabs/.index"

Update-ModuleManifest -Path "$ModuleSourcePath/pave.psd1" -ModuleVersion $ModuleVersion 

Copy-Item "$ModuleSourcePath/*" $ModuleBuildPath -recurse

Compress-Archive -path "$ModuleBuildPath"  -Destination "$BuildDir/$ModuleName .zip" -Force 

Remove-Item $ModuleBuildPath -recurse -force



