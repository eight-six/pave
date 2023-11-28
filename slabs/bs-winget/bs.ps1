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
    [Parameter(ValueFromPipeline)]
    [string]$FilePath = "$PSScriptRoot\winget.dev-user.json"
)

begin {
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'
    $VerbosePreference = 'Continue'
    $WarningPreference = 'Continue'
}

process {
    Write-Information "winget importing $FilePath ..."

    $ImportFile = gc $FilePath | ConvertFrom-Json 
    Write-Information "  will install/upgrade:"
    $ImportFile.Sources.Packages | % {"    $($_.PackageIdentifier) ($(if($_.Scope){$_.Scope}else{'not-specifed'}))"}

    winget import --import-file $FilePath
    
    Write-Information "winget importing $FilePath - done!"
}

end {
    
}
