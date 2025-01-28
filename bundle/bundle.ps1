$ErrorActionPreference = 'Stop'

$BuildDir = "$PSScriptRoot/../build"
$ModuleVersion = $Env:BUILD_MODULE_VERSION ?? '99.99.99'
$ModuleBuildPath = "$BuildDir/$ModuleVersion"
$ModuleSourcePath = "$PSScriptRoot/../modules"
$BundleFilePath = "$BuildDir/pave-full-v$ModuleVersion.zip"

if (!(Test-Path $BuildDir)) {
    mkdir $BuildDir
}

if (!(Test-Path "$BuildDir/slabs")) {
    mkdir "$BuildDir/slabs"
}

if (!(Test-Path $ModuleBuildPath)) {
    mkdir $ModuleBuildPath
}

$Slabs = @()

Get-ChildItem -Directory "$PSScriptRoot/../slabs" | ForEach-Object {
    $Slabs += $_.Name
    Compress-Archive "$($_.FullName)/*" "$BuildDir/slabs/$($_.Name).zip" -Force 
}

$Index = @{}
$Slabs | ForEach-Object { 
    $Infos = Import-PowerShellDataFile "$PSScriptRoot/../slabs/$($_)/info.psd1"
    $Index[$_] = $Infos
}
$Index | ConvertTo-Json | Out-File "$BuildDir/slabs/~index"

'pave-logger', 'pave-utils', 'pave' | % {
    $ModuleName = $_
    $ModuleFilePath = "$ModuleName-module-v$ModuleVersion.zip"

    Update-ModuleManifest -Path "$ModuleSourcePath/$ModuleName/$ModuleName.psd1" -ModuleVersion $ModuleVersion 
    Copy-Item "$ModuleSourcePath/$ModuleName/" "$ModuleBuildPath/$ModuleName/" -recurse
    Compress-Archive -path "$ModuleBuildPath/$ModuleName/"  -Destination "$BuildDir/$ModuleFilePath" -Force -verbose
}

Remove-Item $ModuleBuildPath -recurse -force
Compress-Archive -path "$BuildDir/*" -Destination $BundleFilePath -Force -verbose




