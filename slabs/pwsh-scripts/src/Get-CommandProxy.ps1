
using namespace System.Management.Automation

param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [ValidateNotNullOrEmpty()]
    [string]$FilePath = "$Name.ps1"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 'latest'

[Management.Automation.CommandInfo]$CommandInfo = Get-Command $Name
$Metadata = [CommandMetaData]::new($CommandInfo)
[ProxyCommand]::Create($Metadata) | 
    Out-File -FilePath $FilePath