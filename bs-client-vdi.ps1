
<#

Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser'
iwr https://github.com/eight-six/pave/blob/tidy/bs-client-vdi.ps1 ~\downloads\bs-client-vdi.ps1
Unblock-File ~\downloads\bs-client-vdi.ps1
. ~\downloads\bs-client-vdi.ps1

#>


$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = 'true'

$Env:PAVE_PWSH_VERSION = '7.5.0'
$Env:PAVE_REMOTE = "https://eightsixpaveprodstg.blob.core.windows.net/public/latest-test"
$Env:PAVE_PY_VERSION = '3.12|3.11' # separate multiple versions with a | - versions are installed left to right, the last one will be the default.

if ($null -eq $Env:PAVE_USER_NAME) {
    $Env:PAVE_USER_NAME = Read-Host -Prompt "Enter your user name for git logs (set `$Env:PAVE_USER_NAME to avoid this prompt in future)"
} 

if ($null -eq $Env:PAVE_USER_EMAIL ) {
    $Env:PAVE_USER_EMAIL = Read-Host -Prompt "Enter your email name for git logs (set `$Env:PAVE_USER_NAME to avoid this prompt in future)"
} 

Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser'

function prompt {        
    $Dollar = '$'
    $Options = Get-PSReadLineOption
    $Color = $Options.DefaultTokenColor

    $Line1 = @(
        $Options.CommentColor
        $Pwd.Path.Replace($HOME, '~')
        $PSStyle.Reset
    ) -join ''

    $Line2 = "$($Color)P$Dollar $($PSStyle.Reset)"

    '', $Line1, $Line2 -join "`n"
}

$InstallCachePath = "$HOME\downloads\~pave" 

if (!(Test-Path $InstallCachePath )) {
    md $InstallCachePath | Out-Null
}

cd $InstallCachePath  

$ModulePath = "$($env:PSModulePath -split ';' | select -First 1)"
$PackageBaseName = 'pave-full-v99.99.99'
$ModuleZipFileName = "$PackageBaseName.zip"

if (Test-Path $ModuleZipFileName ) {
    rm $ModuleZipFileName | Out-Null
}

'pave-logger', 'pave-utils', 'pave' | % {
    if (Test-Path "$ModulePath\$_") {
        rm "$ModulePath\$_" -Recurse -Force | Out-Null
    }
}

Start-BitsTransfer "$Env:PAVE_REMOTE/$ModuleZipFileName" 
Expand-Archive $ModuleZipFileName
Expand-Archive './pave-full-v99.99.99/pave-logger-module-v99.99.99.zip' $ModulePath
Expand-Archive './pave-full-v99.99.99/pave-utils-module-v99.99.99.zip' $ModulePath
Expand-Archive './pave-full-v99.99.99/pave-module-v99.99.99.zip' $ModulePath
rm $ModuleZipFileName 

if (!(Get-Module -ListAvailable 'powershell-yaml')) {
    Install-Module powershell-yaml -Scope 'CurrentUser' -Force
}

Import-Module pave-logger
Import-Module pave-utils
Import-Module pave

Set-Remote $Env:PAVE_REMOTE
Install-Slab slab-utils
Install-Slab bs-no-admin
Install-Slab reg-tweaks
lay bs-no-admin -PwshVersion $Env:PAVE_PWSH_VERSION
Update-PathEnvVar 

function Invoke-ScriptWithPwsh {
    param(
        [string]$FilePath
    )

    $PwshPath = "$Env:LocalAppData\powershell\$Env:PAVE_PWSH_VERSION\pwsh"
    & $PwshPath -NoProfile -File $FilePath 
    
    if ($LASTEXITCODE -ne 0) {
        $ErrorMessage = "Running $(em $FilePath ) with $(em $PwshPath ) failed with exit code $(em $LASTEXITCODE)."
        Write-LogEntry $ErrorMessage -IgnoreActionLevel
        throw $ErrorMessage
    }

    Update-PathEnvVar 

}

$PwshPath = "$Env:LocalAppData\powershell\$Env:PAVE_PWSH_VERSION\pwsh"
$ScriptsPath = "$(Get-Cache)\bs-no-admin\scripts"

# install python versions
$InstallPythonFilePath = Join-Path $ScriptsPath 'Install-PythonWinget.ps1'
Invoke-ScriptWithPwsh $InstallPythonFilePath 

# install node
$InstallNodeFilePath = Join-Path $ScriptsPath 'Install-Node.ps1'
Invoke-ScriptWithPwsh $InstallNodeFilePath 

# apply configs
$ConfigFilePath = Join-Path $ScriptsPath 'Set-ConfigConfig.ps1'
Invoke-ScriptWithPwsh $ConfigFilePath 
$ConfigFilePath = Join-Path $ScriptsPath 'Set-ConfigPrivate.ps1'
Invoke-ScriptWithPwsh $ConfigFilePath 

