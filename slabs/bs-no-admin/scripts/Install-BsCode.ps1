
<#PSScriptInfo

.VERSION 1.0

.GUID acd1a116-1805-4cfd-a24e-e521ab26d207

.AUTHOR StevenRose

.COMPANYNAME

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
 Installs specified version of VS Code 

#> 
Param(
    [Parameter(ParameterSetName='Default')]
    [ValidateSet('insider','stable')]
    [string]$BuildType, 
    [Parameter(ParameterSetName='Default')]
    [Parameter(ParameterSetName='UsingPSGallery')]
    [switch]$UsePSGallery,
    [Parameter(ParameterSetName='UsingPSGallery')]
    [string[]]$VsCodeExtensions
)

$ErrorActionPreference = 'Stop'
Set-StrictMode  -Version 3

if (!$IsWindows) {
    throw "This script is for windows only. For other platforms see https://www.powershellgallery.com/packages/Install-VSCode"
}

$LogMessage = "INFO: $($Env:BS_LOG_HEADER)installing VS Code (64-bit $BuildType)"
Write-Information "$LogMessage..."

if($UsePSGallery.IsPresent){
    if(!((Get-PSRepository).Name -contains 'PSGallery')){
        throw "Repository PSGallery not registered."
    }

    Save-Script  -Name 'Install-VsCode' -Path .
    $BuildEdition = "$BuildType-User"
    # seems to be some delay before the script is available on some systems - maybe antimalware
    sleep -seconds 10       
     $Params = @{
	Architecture = '64-bit' 
       BuildEdition = $BuildEdition 
     }
   
    if($null -ne $VsCodeExtensions){
       $Params.AdditionalExtensions = $VsCodeExtensions
     }
    .\Install-VSCode.ps1 @Params
} else {
    $VsCodeUri = "https://update.code.visualstudio.com/latest/win32-x64-user/$BuildType"
    Write-Verbose "$VsCodeUri"
    $VsSetupExe = ".\vscode-win32-x64-user-$BuildType-setup.exe"
    Start-BitsTransfer -Source $VsCodeUri -Destination $VsSetupExe
    Start-Process $VsSetupExe -Wait -ArgumentList "/silent /MERGETASKS=!runcode"    
}

Write-Information "$LogMessage - done!"



