$PSStyle.Formatting.Debug = $PSStyle.Foreground.BrightBlue
$PSStyle.Formatting.Warning = $PSStyle.Foreground.Magenta

$em = $Env:PS_EMPH ?? '``'

if ($IsWindows) {
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent() 
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
else {
    $IsAdmin = (id -u) -eq 0
}

function prompt {
    $Dollar = $IsAdmin ? '#' : '$' 
    $Color = $IsAdmin ? $PSStyle.Formatting.Error : $PSStyle.Formatting.White
    "$($Color)P$Dollar $($PSStyle.Reset)"
}

$env:PWSH_PROFILE_PATH = $env:PWSH_PROFILE_PATH ?? (Join-Path $HOME 'powershell' 'profile')
$Env:PWSH_SCRIPTS_PATH = $env:PWSH_SCRIPTS_PATH ?? (Join-Path $HOME 'powershell' 'scripts')
$Env:REPOS_PATH = $Env:REPOS_PATH ?? (Join-Path $HOME 'source' 'repos')

$env:PWSH_PROFILE_PATH, $Env:PWSH_SCRIPTS_PATH, $Env:REPOS_PATH | % {
    if (!(Test-Path $_)) {
        New-Item -ItemType 'Directory' $_ #| Out-Null
    }
}

$ScriptsToLoad = @()

$DocumentsFolder = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Personal)
$HasRedirectedDocumentsFolder = $DocumentsFolder -ne (Join-Path $HOME 'powershell' 'modules')

if ($HasRedirectedDocumentsFolder) {
    Write-Warning "Documents folder is redirected to $em$($DocumentsFolder)$em. Installing package management shims"

    # change to use an env var $env:PWSH_INSTALL_PACMAN_SHIMS
    if ($true) {
        $ScriptsToLoad += '\Install-PacManShims.ps1'
    }
} 

$ScriptsToLoad  | % {
    $Path = Join-Path $Env:PWSH_SCRIPTS_PATH $_

    if (!(Test-Path $Path)) {
        Write-Warning "Script $em$($Path)$em not found in `$Env:PWSH_SCRIPTS_PATH $em$($Env:PWSH_SCRIPTS_PATH)$em"
    }
    else {
        Write-Warning "Dot-sourcing $em$($Path)$em"
        . $Path
    }
}

# set $env:PWSH_PROFILE_ADD_ALIASES to $true to load aliases
if ($env:PWSH_PROFILE_ADD_ALIASES) {
    . (Join-Path $PSScriptRoot 'aliases.ps1')
}

# set $env:PWSH_PROFILE_ADD_ALIASES to $true to load functions
if ($env:PWSH_PROFILE_ADD_FUNCTIONS) {
    . (Join-Path $PSScriptRoot 'functions.ps1')
}

# clean up
Remove-Variable 'ScriptsToLoad'
Remove-Variable 'DocumentsFolder'
Remove-Variable 'HasRedirectedDocumentsFolder'
