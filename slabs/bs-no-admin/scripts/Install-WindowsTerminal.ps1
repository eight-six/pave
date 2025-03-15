<#
.DESCRIPTION 
 Installs the specified version of Windows Terminal

 If Windows Terminal is your default you can start a shell outside of Terminal with:

    start conhost powershell
#>
#Requires -Version 5.1
#Requires -modules pave-logger
#Requires -modules pave-utils

[CmdletBinding(SupportsShouldProcess)]
param (
    [ValidatePattern('\d+\.\d+\.\d+\.\d+')]
    [string]$Version = '1.22.10352.0',
    [string]$DownloadRoot = "https://github.com/microsoft/terminal/releases/download"
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

try {
    $Heading = "$(u 'windows terminal')"
    Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)

    if (Get-Process -Name 'WindowsTerminal' -ea 'Ignore') {
        throw 'Cannot install Windows Terminal when there is a running instance. Please close Windows Terminal'
    }

    $IsWindows10 = [Environment]::OSVersion.Version.Major -eq 10 -and [Environment]::OSVersion.Version.Build -lt 22000
    $DownloadFolder = "v$Version"
    $DownloadName = if (!$IsWindows10) {  
        "Microsoft.WindowsTerminal_$($Version)_8wekyb3d8bbwe.msixbundle_Windows10_PreinstallKit.zip" 
    }
    else {
        "Microsoft.WindowsTerminal_$($Version)_8wekyb3d8bbwe.msixbundle"
    }

    $DownloadUri = "$DownloadRoot/$DownloadFolder/$DownloadName"
    $DownloadPath = if($Env:PAVE_DOWNLOAD_CACHE){$Env:PAVE_DOWNLOAD_CACHE}else{$Pwd.Path}
    $DownloadFilePath = Join-Path $DownloadPath $DownloadName

    Push-LogAction "Downloading $(em $DownloadName) from $(em $DownloadUri)" 
    Get-Download $DownloadUri $DownloadPath 
    Pop-LogAction


    if (!$IsWindows10) {
        $PreinstallKitFolder = Join-Path $Pwd.Path 'Windows10_PreinstallKit'

        if (Test-Path $PreinstallKitFolder ) {
            rm -recurse -force $PreinstallKitFolder
        }

        if ($PSCmdlet.ShouldProcess($DownloadName, "expand")) {
            Expand-Archive $DownloadFilePath $PreinstallKitFolder
        }

        $XamlPackage =  "$PreinstallKitFolder/Microsoft.UI.Xaml.2.8_8.2306.22001.0_x64__8wekyb3d8bbwe.appx"
        $TerminalPackage = "$PreinstallKitFolder/0ef1881c68144b78ad517d9e8e2aab5d.msixbundle"

        $XamlPackage, $TerminalPackage | % {
            if ($PSCmdlet.ShouldProcess($_, "add appx package")) {
                Add-AppxPackage $_
            }
        }

    }
    else {
        if ($PSCmdlet.ShouldProcess($DownloadFilePath, "add appx package")) {
            Add-AppxPackage $DownloadFilePath
        }
    }
    
    if ($null -eq $MyInvocation.PSCommandPath) {
        $Heading += ' - completed'
        Write-LogHeader $Heading 
    }
}
catch {
    Clear-LogAction
    throw $_
}
