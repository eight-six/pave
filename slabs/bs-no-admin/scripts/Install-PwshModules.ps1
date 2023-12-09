
<#PSScriptInfo

.VERSION 1.0

.GUID 62c54c5b-24bb-4845-a29d-7cb717852cd5

.AUTHOR @stvnrs

.COMPANYNAME Eight Six Consulting

.COPYRIGHT (c)  Eight Six Consulting Limited

.TAGS

#install 

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Installs the specified version of powershell core 

#> 
param (
    [hashtable]$Modules,
    [string]$Repository = 'PSGallery',
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string]$Scope = 'CurrentUser'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode  -Version 3


$Modules.Keys | % {
    $ModuleName = $_
    $ModuleVersion = $Modules[$_] ?? '(latest)'

    $Message = "$($Env:BS_LOG_HEADER)installing module ``$ModuleName`` ``$ModuleVersion``"
    Write-Information "$Message..."

    $Params = @{
        Name = $ModuleName
        Repository = $Repository
        Scope = $Scope
    }

    if($ModuleVersion -ne '(latest)'){
        $Params.RequiredVersion = $ModuleVersion
    }

    Install-Module @Params -Force -AcceptLicense

    Write-Information "$Message - done!"
}