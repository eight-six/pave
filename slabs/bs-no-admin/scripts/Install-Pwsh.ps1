
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
#Requires -modules pave-logger
#Requires -modules pave-utils

[CmdletBinding()]
param (
    [ValidatePattern('^7\.\d+(\.\d+){0,1}$')]
    [string]$Version = '7.5.0',
    [string]$InstallPath = "$env:LOCALAPPDATA\powershell\$Version",
    [string]$DownloadRoot = 'https://github.com/PowerShell/PowerShell/releases/download',
    [switch]$SkipDownload
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    
    if ($InstallPath -eq (Split-Path -Parent ([Environment]::GetCommandLineArgs()[0]) )) {
        throw "cannot install another instance of pwsh in the same location as the running instance"
    }

    if($Version -match '^7\.\d+$'){
        $Version = "$Version.0"
    }

    $Banner = "pwsh"

    if($null -eq $MyInvocation.PSCommandPath){
        Write-LogHeader $Banner 
    } else {
        Write-LogSubHeader $Banner
    }

    Push-LogAction "installing $(bold "pwsh v$Version")" -IncrementActionLevel

    $InstallerFileName = "PowerShell-$Version-win-x64.zip"
    $DownloadUri = "$DownloadRoot/v$Version/$InstallerFileName"

    if (Test-Path $InstallPath) {
        Push-LogAction "deleting existing installation in $(emph $InstallPath)"
        rm -Path $InstallPath -Recurse -Force
        Pop-LogAction
    }

    if ($SkipDownload.IsPresent) {
        Write-LogEntry "SkipDownload was specified. Required install must exist at $(emph ".\$InstallerFileName")"
    }
    else {
        Push-LogAction "downloading zip from $(emph $DownloadUri) to $(emph $InstallerFileName)"
   
        try {
            Start-BitsTransfer $DownloadUri
        }
        catch [Runtime.InteropServices.COMException] {
            Write-LogEntry "Download failed with $(emph Start-BitsTransfer) - error message: $(under $_.Exception.Message)"
        
            if ($_.Exception.Message -notmatch 'MUI Entry') {
                throw $_
            }
            else {
                Write-LogEntry "Start-BitsTransfer failed, trying Invoke-WebRequest"
                iwr $DownloadUri -OutFile $InstallerFileName 
            }
        }
    
        Pop-LogAction
    }

    # expand installer
    Push-LogAction "expanding zip from  $(emph $InstallerFileName) to $(emph $InstallPath)"
    $InstallerFilePath = Join-Path $Pwd.Path $InstallerFileName

    if (!(Test-Path $InstallerFilePath)) {
        throw "Installer not found at $(emph $InstallerFilePath)"
    }
    Expand-Archive $InstallerFileName $InstallPath
    Pop-LogAction

    Push-LogAction "adding $(emph $InstallPath) to path"
    Add-UserPath -PathToAdd $InstallPath -AtStart -AddToCurrentSession
    Pop-LogAction

    {
        $ErrorActionPreference = 'Stop'
        $PSNativeCommandUseErrorActionPreference = $true

        if (!(Test-path $PROFILE)) {
            $ProfilePath = Split-Path $PROFILE -Parent
        
            if (!(Test-path $ProfilePath)) {
                md $ProfilePath | Out-Null
            }
        
            $Prompt = @'
function prompt {        
    $Dollar = $IsAdmin ? '#' : '$'
    $Color = $IsAdmin ? $PSStyle.Formatting.Error : $PSStyle.Formatting.White
    $Options = Get-PSReadLineOption

    $Line1 = @(
        $Options.CommentColor
        $Pwd.Path.Replace($HOME, '~')
        $PSStyle.Reset
    ) -join ''

    $Line2 = "$($Color)P$Dollar $($PSStyle.Reset)"

    '', $Line1, $Line2 -join "`n"
}
'@  
            $Prompt | Out-File $PROFILE
        }
    } |  & "$InstallPath\pwsh" -NoProfile -command - #note the sneaky minus(-) = get command from stdin

    Pop-LogAction

    $Banner += ' - completed'

    if($null -eq $MyInvocation.PSCommandPath){
        Write-LogHeader $Banner 
    }

    [PSCustomObject]@{
        PwshPath = "$InstallPath\pwsh"
        Version  = $Version
    }

}
catch {
    Clear-LogAction
    throw $_
}