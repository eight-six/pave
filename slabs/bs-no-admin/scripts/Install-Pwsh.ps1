
<#PSScriptInfo

.VERSION 1.0

.GUID f5010c9d-27c2-47b6-8033-a99b79041a13

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
 Installs the specified version of powershell core with local admin privs. 

#> 

#Requires -version 5.1 # Windows Powershell

param (
    [ValidatePattern('7\.\d+\.\d+')]
    [string]$Version = '7.4.6',
    [string]$InstallPath = "$env:LOCALAPPDATA\powershell\$Version",
    [string]$DownloadRoot = 'https://github.com/PowerShell/PowerShell/releases/download'
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

if($InstallPath -eq (Split-Path -Parent ([Environment]::GetCommandLineArgs()[0]) )){
    throw "cannot install another instance of pwsh in the same location as the running instance"
}

Push-LogAction "$($Env:BS_LOG_HEADER)installing pwsh v$Version" -IncrementActionLevel

$InstallerFileName = "PowerShell-$Version-win-x64.zip"
$DownloadUri = "$DownloadRoot/v$Version/$InstallerFileName"

if(Test-Path $InstallPath){
    Push-LogAction "deleting existing installation in $(emph $InstallPath)"
    rm -Path $InstallPath -Recurse -Force
    Pop-LogAction
}

Push-LogAction "downloading zip from $(emph $DownloadUri) to $InstallerFileName"

try {
    Start-BitsTransfer $DownloadUri
}
catch [Runtime.InteropServices.COMException]{
    Write-Log "Download failed with $(emph Start-BitsTransfer) - error message: $(under $_.Exception.Message)"

    if($_.Exception.Message -notmatch 'MUI Entry'){
        throw $_
    } else {
        Write-Log "Start-BitsTransfer failed, trying Invoke-WebRequest"
        iwr $DownloadUri -OutFile $InstallerFileName 
    }
}

Pop-LogAction

# expand installer
Push-LogAction "expanding zip from  $(emph $InstallerFileName) to $(emph $InstallPath)"
Expand-Archive $InstallerFileName $InstallPath
Pop-LogAction

Push-LogAction "adding $(emph $InstallPath) to path..."
. $PSScriptRoot/FnAddToUserPath.ps1
AddToUserPath -PathToAdd $InstallPath -AddToCurrentSession
Pop-LogAction

# {
#     $ErrorActionPreference = 'Stop'
#     $PSNativeCommandUseErrorActionPreference = $true

#     if(!(Test-path $PROFILE)) {
#         $ProfilePath = Split-Path $PROFILE -Parent
        
#         if(!(Test-path $ProfilePath)) {
#             md $ProfilePath | Out-Null
#         }
        
#         'function prompt{"$($PWD.Path.replace( $Env:USERPROFILE, ''~''))`nP$ "}'| Out-File $PROFILE
#     }
# } | & "$InstallPath\pwsh" -NoProfile -command - #note the sneaky minus(-) = get command from stdin

Pop-LogAction
