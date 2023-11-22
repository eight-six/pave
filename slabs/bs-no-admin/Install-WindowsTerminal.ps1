<#
.DESCRIPTION 
 Installs the specified version of Windows Terminal

 If Windows Terminal is your default 

 $ start-process "ms-settings:developers"

 or 

 start conhost powershell

#>
#Requires -PSEdition Desktop

param (
    [ValidatePattern('\d+\.\d+\.\d+\.\d+')]
    [string]$Version = '1.18.2822.0',
    [string]$DownloadRoot = "https://github.com/microsoft/terminal/releases/download"
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Set-StrictMode  -Version 'latest'

if(Get-Process -Name 'WindowsTerminal'){
    throw 'Cannot install Windows Terminal when there is a running instance. Please close Windows Terminal'
}

$IsWindows10 = [Environment]::OSVersion.Version.Major -eq 10
$DownloadFolder = "v$Version"
$DownloadName = if($IsWindows10){  
    "Microsoft.WindowsTerminal_$($Version)_8wekyb3d8bbwe.msixbundle_Windows10_PreinstallKit.zip" 
} else {
    "Microsoft.WindowsTerminal_$($Version)_8wekyb3d8bbwe.msixbundle"
}

$DownloadUri = "$DownloadRoot/$DownloadFolder/$DownloadName"

$VerboseMessage = "Downloading $DownloadName from $DownloadUri..." 
Write-Verbose "$VerboseMessage..."

Start-BitsTransfer $DownloadUri

Write-Verbose "$VerboseMessage - done!"

if($IsWindows10){
    $PreinstallKitFolder = './Windows10_PreinstallKit'

    if(Test-Path $PreinstallKitFolder ){
        rm -recurse -force $PreinstallKitFolder
    }

    Expand-Archive $DownloadName $PreinstallKitFolder
    Add-AppxPackage "./$PreinstallKitFolder/Microsoft.UI.Xaml.2.8_8.2306.22001.0_x64__8wekyb3d8bbwe.appx"
    Add-AppxPackage "./$PreinstallKitFolder/0ef1881c68144b78ad517d9e8e2aab5d.msixbundle"
} else {
    Add-AppxPackage $DownloadName
}
