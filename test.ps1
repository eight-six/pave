import-Module .\pwsh\pave.psm1 -Force
Set-Cache C:\Users\StevenRose\source\repos\pave\slabs\
Set-Remote C:\Users\StevenRose\source\repos\pave\build\

# Find-Slab

'*' * 120

Get-Slab -Name bs

'*' * 120
Get-Slab bs

'*' * 120
Get-Slab | Get-Slab

'*' * 120
