<#

.EXAMPLE

.\src\pwsh\pwsh\bs-winget\index.ps1 


.EXAMPLE

.\src\pwsh\pwsh\bs-winget\index.ps1 -FilePath .\src\pwsh\pwsh\bs-winget\winget.wsl.json


.EXAMPLE

ls .\src\pwsh\pwsh\bs-winget\winget.wsl.json | select -exp FullName | .\src\pwsh\pwsh\bs-winget\index.ps1

.EXAMPLE

ls .\src\pwsh\pwsh\bs-winget\*.json | .\src\pwsh\pwsh\bs-winget\index.ps1


#>

param(
    [Parameter(ValueFromPipeline = $true, Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateSet('dev-machine-scope', 'dev-user-scope', 'wsl')]
    [string]$PackageSet 
)
    
begin {
    $ErrorActionPreference = 'Stop'

    $ThisSlabName = Split-Path $PSScriptRoot -Leaf
    $SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
    . "$SlabsRoot/slab-utils/slab-utils.ps1"
}
    
process {
    $FilePath = "$PSScriptRoot\packages\winget.$PackageSet.json"
    $LogMessage = "INFO: winget importing package set $(emph $PackageSet) from $(emph $FilePath)"
    Write-Information "$LogMessage$LogStart"
    $ImportFile = Get-Content $FilePath | ConvertFrom-Json 
    $ImportFile.Sources.Packages | % { "    $($_.PackageIdentifier) ($(if($_.Scope){$_.Scope}else{'not-specifed'}))" }
    winget import --import-file $FilePath
    Write-Information "$LogMessage$LogDone"
}

end {
    
}
