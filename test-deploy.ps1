
$SetUp = {
    import-Module .\pwsh\pave.psm1 -Force
    $Cache = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $Cache | Out-Null
    Set-Cache $Cache
    Set-Remote C:\Users\StevenRose\source\repos\pave\build\
    Find-Slab | Install-Slab

}

$TearDown = {
    Remove-Item -Path $Cache -Recurse -Force
}

$Setup.Invoke()
Deploy-Slab bs
