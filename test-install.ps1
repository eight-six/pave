import-Module .\pwsh\pave.psm1 -Force
$Cache = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $Cache | Out-Null
Set-Cache $Cache
Set-Remote C:\Users\StevenRose\source\repos\pave\build\

$Width = $Host.UI.RawUI.WindowSize.Width
$SectionLine = '*' * $Width
$HeaderLine = '-' * $Width

Write-Host $SectionLine  -ForegroundColor Cyan

Get-Slab

Write-Host $SectionLine  -ForegroundColor Cyan

Find-Slab | Install-Slab

$Slabs = Get-Slab 
$HomeExpr = [System.Text.RegularExpressions.Regex]::Escape($HOME)

Write-Host ('{0, -20} {1, -80} {2, -32} {3, -20}' -f 'Name', 'Description', 'DependsOn','Path') -ForegroundColor Yellow
Write-Host $HeaderLine -ForegroundColor DarkGray
$Slabs | ForEach-Object {
    $Line = '{0, -20} {1, -80} {2, -32} {3, -20}' -f $_.Name, $_.Description, ($_.DependsOn -join ','), ($_.Path -replace $HomeExpr, '~') 
    Write-Host $Line -ForegroundColor Green
}

Write-Host $SectionLine  -ForegroundColor Cyan

Remove-Item -Path $Cache -Recurse -Force

