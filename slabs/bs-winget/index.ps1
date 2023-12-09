<#

.EXAMPLE

.\src\pwsh\pwsh\bs-winget\bs.ps1 


.EXAMPLE

.\src\pwsh\pwsh\bs-winget\bs.ps1 -FilePath .\src\pwsh\pwsh\bs-winget\winget.wsl.json


.EXAMPLE

ls .\src\pwsh\pwsh\bs-winget\winget.wsl.json | select -exp FullName | .\src\pwsh\pwsh\bs-winget\bs.ps1

.EXAMPLE

ls .\src\pwsh\pwsh\bs-winget\*.json | .\src\pwsh\pwsh\bs-winget\bs.ps1


#>

param(
    [Parameter(ValueFromPipeline = $true, Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateSet('dev-machine-scope', 'dev-user-scope', 'wsl')]
    [string]$PackageSet 
)
    
begin {
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'
    $VerbosePreference = 'Continue'
    $WarningPreference = 'Continue'
}
    
process {
    [string]$FilePath = "$PSScriptRoot\packages\winget.$PackageSet.json"
    $LogMessage = "winget importing package set ``$Package`` from ``$FilePath``"
    Write-Information "$LogMessage..."
    $ImportFile = Get-Content $FilePath | ConvertFrom-Json 
    Write-Information '  will install/upgrade:'
    $ImportFile.Sources.Packages | % { "    $($_.PackageIdentifier) ($(if($_.Scope){$_.Scope}else{'not-specifed'}))" }
    winget import --import-file $FilePath
    Write-Information "$LogMessage - done!"
}

end {
    
}
