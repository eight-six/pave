$ErrorActionPreference = 'Stop'

$BuildDir = "$PSScriptRoot/../build"
$ModuleVersion = $Env:BUILD_MODULE_VERSION ??  '0.0.0'
$ModuleName = 'pave-module'
$ModuleFilePath = "$ModuleName-v$ModuleVersion.zip"
$ModuleBuildPath = "$BuildDir/$ModuleVersion"
$ModuleSourcePath = "$PSScriptRoot/../pwsh"
$BundleFilePath = "$BuildDir/pave-full-v$ModuleVersion.zip"

if(!(Test-Path $BuildDir)){
    mkdir $BuildDir
}

if(!(Test-Path "$BuildDir/slabs")){
    mkdir "$BuildDir/slabs"
}

if(!(Test-Path $ModuleBuildPath)){
    mkdir $ModuleBuildPath
}

$Slabs = @()

Get-ChildItem -Directory "$PSScriptRoot/../slabs" | % {
    $Slabs += $_.Name
    Compress-Archive "$($_.FullName)/*" "$BuildDir/slabs/$($_.Name).zip" -Force 
}

$Index = @{}
$Slabs | % { 
    $Infos = Import-PowerShellDataFile "$PSScriptRoot/../slabs/$($_)/info.psd1"
    $Index[$_]=$Infos
}
$Index | ConvertTo-Json | Out-File "$BuildDir/slabs/~index"

Update-ModuleManifest -Path "$ModuleSourcePath/pave.psd1" -ModuleVersion $ModuleVersion 

Copy-Item "$ModuleSourcePath/*" $ModuleBuildPath -recurse

Compress-Archive -path "$ModuleBuildPath"  -Destination "$BuildDir/$ModuleFilePath" -Force -verbose

Remove-Item $ModuleBuildPath -recurse -force


Compress-Archive -path "$BuildDir/*" -Destination $BundleFilePath -Force -verbose




