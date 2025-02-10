#Requires -version 7.4
#Requires -modules pave-logger
#Requires -modules pave-utils

param(
    [string[]]$Apps =  @(
        'Git.Git'
        'Microsoft.VisualStudioCode.Insiders'
        'Microsoft.Azure.StorageExplorer'
        'Microsoft.AzureDataStudio'
    )
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$InformationPreference = 'Continue'

try{
    $ScriptsFolder = $PSScriptRoot 
    $VsBuildType = 'insider'
    $Heading = 'default apps'

    Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
    Push-LogAction 'installing default apps' -IncrementActionLevel
        
    $Apps | % {
        Push-LogAction "installing $(em $_) (user scope) with winget"
        winget install --exact $_ --id "$_" --scope user --accept-source-agreements
        Pop-LogAction
    }

    Pop-LogAction

    if($null -eq $MyInvocation.PSCommandPath){
        $Heading += ' - completed'
        Write-LogHeader $Heading 
    }
}
catch{
    Clear-LogAction
    throw $_
}
