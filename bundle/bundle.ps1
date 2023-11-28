
$BuildDir = '$PSScriptRoot/../build'

if(!(Test-Path $BuildDir)){
    mkdir $BuildDir
}


$Index = @()

ls -Directory '$PSScriptRoot/../slabs' | % {
    $Index += $_.Name
    Compress-Archive "$($_.FullName)/*" "$BuildDir/$($_.Name).zip" -Force 
}

$Index | Out-File "$BuildDir/.index"

