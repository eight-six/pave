#Requires -version 7.4
#Requires -modules pave-logger
#Requires -modules pave-utils

param(
    [switch]$SkipDotNet 
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
    
    if(!$SkipDotNet.IsPresent)){
        # can't install dotnet with user scope using winget 
        & "$ScriptsFolder\Install-DotNetLts.ps1"
    }
    
    
    'Git.Git', 'Microsoft.VisualStudioCode.Insiders', 'Microsoft.Azure.StorageExplorer', 'Microsoft.AzureDataStudio' | % {
        Push-LogAction 'installing $_ (user scope) with winget'
        winget install --exact $_ --id Git.Git --scope user
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
