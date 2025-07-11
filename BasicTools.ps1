
function prompt {"P$ "}

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$NugetMinVersion = '2.8.5.201'
$PwshVersion = '7.5.2'

Set-ExecutionPolicy -Scope 'CurrentUser' -ExecutionPolicy 'RemoteSigned' -Force

$InstallerFileName = "PowerShell-$PwshVersion-win-x64.zip"
$DownloadPath = "$HOME\Downloads"
$DownloadFilePath = Join-Path $DownloadPath $InstallerFileName
$DownloadRoot = 'https://github.com/PowerShell/PowerShell/releases/download'
$DownloadUri = "$DownloadRoot/v$PwshVersion/$InstallerFileName"
$InstallPath = "$env:LOCALAPPDATA\powershell\$PwshVersion"

if ($InstallPath -eq (Split-Path -Parent ([Environment]::GetCommandLineArgs()[0]) )) {
    throw "cannot install another instance of pwsh in the same location as the running instance"
}

if (Test-Path $InstallPath) {
    Write-Information "deleting existing installation in $InstallPath"
    rm -Path $InstallPath -Recurse -Force
    Write-Information "deleting existing installation in $InstallPath - done"
}

Write-Information "downloading zip from $DownloadUri to $InstallerFileName"
Start-BitsTransfer -Source $DownloadUri -Destination $DownloadFilePath
Write-Information "downloading zip from $DownloadUri to $InstallerFileName -done." 

Write-Information "expanding zip from $InstallerFileName to $InstallPath"
Expand-Archive $DownloadFilePath $InstallPath 
Write-Information "expanding zip from $InstallerFileName to $InstallPath - done"    

Write-Information "adding $InstallPath to PATH"
$Path = "$InstallPath;$Env:Path"
[Environment]::SetEnvironmentVariable('PATH', $Path , 'User')
Write-Information "adding $InstallPath to PATH - done."

$Nuget = Get-PackageProvider -Name 'nuget'

if ($null -eq $Nuget -or $Nuget.Version -lt $NugetMinVersion) {
    Install-PackageProvider -Name 'NuGet' -MinimumVersion $NugetMinVersion -Scope 'CurrentUser' -Force 
}

Install-Module -Name 'Microsoft.WinGet.Client'  -Repository 'PSGallery' -Force -Scope 'CurrentUser'
Repair-WingetPackageManager -Force

$Apps = @(
    'Microsoft.VisualStudioCode'
    'Git.Git'
    'OpenJS.NodeJS'
    'Microsoft.Azure.StorageExplorer'
)

Write-Information "installing apps with winget"

$Apps | % {
    $Id = $_

    Write-Information "installing $Id with winget (user scope)"
    
    $Package = Get-WinGetPackage -Id $Id

    if ($null -eq $Package) {
        $Result = Install-WinGetPackage -Id $Id -Scope 'User' -Mode 'Silent' 
    }
    else {
        $Result = Update-WinGetPackage -Id $Id
    }

    $Result

    Write-Information "installing $Id with winget (user scope) - done"
}

Write-Information "installing apps with winget - done."

$AzCliVersion = '2.75.0' # specify 'latest' for the latest 
$AzDownloadUri = if ($AzCliVersion -eq 'latest') { 'https://aka.ms/installazurecliwindowszipx64' }else { "https://azcliprod.blob.core.windows.net/zip/azure-cli-$AzCliVersion-x64.zip" }
$AzDownloadFilePath = "$HOME\downloads\azure-cli-$AzCliVersion-x64.zip"
$AzInstallPath = "$env:LOCALAPPDATA\az-cli\$AzCliVersion"

if (Test-Path $AzInstallPath) {
    Write-Information "deleting existing installation in $AzInstallPath"
    rm -Path $AzInstallPath -Recurse -Force
    Write-Information "deleting existing installation in $AzInstallPath - done"
}

Start-BitsTransfer -Source $AzDownloadUri -Destination $AzDownloadFilePath 
Expand-Archive $AzDownloadFilePath $AzInstallPath
$Path = "$AzInstallPath\bin;$Path"
[Environment]::SetEnvironmentVariable('PATH', $Path , 'User')

winget download 'Microsoft.WindowsTerminal' --accept-source-agreements 
Add-AppxPackage '.\Downloads\Microsoft.WindowsTerminal_1.22.11751.0\Dependencies\Microsoft.UI.Xaml_8.2310.30001.0_X64_msix_en-US.msix'
Add-AppxPackage '.\Downloads\Microsoft.WindowsTerminal_1.22.11751.0\Windows Terminal_1.22.11751.0_User_X64_msix_en-US.msix'

$TerminalDefaultSettings = @'
{
    "$help": "https://aka.ms/terminal-documentation",
    "$schema": "https://aka.ms/terminal-profiles-schema",
    "actions": [],
    "copyFormatting": "none",
    "copyOnSelect": false,
    "defaultProfile": "{17b095a0-059d-47de-a8d7-8400d875229a}",
    "keybindings": 
    [
        {
            "id": "Terminal.CopyToClipboard",
            "keys": "ctrl+c"
        },
        {
            "id": "Terminal.PasteFromClipboard",
            "keys": "ctrl+v"
        },
        {
            "id": "Terminal.DuplicatePaneAuto",
            "keys": "alt+shift+d"
        }
    ],
    "newTabMenu": 
    [
        {
            "type": "remainingProfiles"
        }
    ],
    "profiles": 
    {
        "defaults": {},
        "list": 
        [
            {
                "colorScheme": "One Half Dark",
                "commandline": "pwsh",
                "guid": "{17b095a0-059d-47de-a8d7-8400d875229a}",
                "hidden": false,
                "icon": "ms-appx:///ProfileIcons/pwsh.png",
                "name": "pwsh",
                "startingDirectory": "%USERPROFILE%"
            },
            {
                "colorScheme": "Campbell Powershell",
                "commandline": "%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
                "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
                "hidden": false,
                "name": "Windows PowerShell"
            },
            {
                "commandline": "%SystemRoot%\\System32\\cmd.exe",
                "guid": "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}",
                "hidden": false,
                "name": "Command Prompt"
            },
            {
                "guid": "{b453ae62-4e3d-5e58-b989-0a998ec441b8}",
                "hidden": false,
                "name": "Azure Cloud Shell",
                "source": "Windows.Terminal.Azure"
            },
            {
                "guid": "{2ece5bfe-50ed-5f3a-ab87-5cd4baafed2b}",
                "hidden": false,
                "name": "Git Bash",
                "source": "Git"
            }
        ]
    },
    "schemes": [],
    "themes": []
}
'@

$TerminalDefaultSettings | Out-File -Encoding 'utf8' -FilePath "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"


