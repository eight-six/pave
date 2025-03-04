
<#

Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser';
$Branch = 'tidy';
$FileName = 'bs-client-vdi.ps1';
$FilePath = "~\downloads\$FileName";
iwr "https://raw.githubusercontent.com/eight-six/pave/refs/heads/$Branch/$FileName" -OutFile $FilePath;
Unblock-File $FilePath;
. $FilePath;

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

#region support functions
function prompt {        
    $Role = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole($role)
    $Dollar = if ($IsAdmin ) { '♆' } else { 'P$' }
    $Options = Get-PSReadLineOption
    $Color = if ($IsAdmin) { $Options.ErrorColor } else { $Options.DefaultTokenColor }

    $Line1 = @(
        $Options.CommentColor
        $Pwd.Path.Replace($HOME, '~')
        $PSStyle.Reset
    ) -join ''

    $Line2 = "$($Color)$Dollar $($PSStyle.Reset)"

    '', $Line1, $Line2 -join "`n"
}
function Invoke-Pwsh {
    param(
 
        [Parameter(ParameterSetName = 'WithFile', Mandatory)]
        [string]$FilePath,
        [Parameter(ParameterSetName = 'WithScriptBlock', Mandatory)]
        [string]$ScriptBlock,
        [Parameter(ParameterSetName = 'WithCommandText', Mandatory)]
        [string]$CommandText
    )
 
 
    Write-Verbose "ParameterSetName: $($PSCmdLet.ParameterSetName)" -verbose
 
    $PwshPath = "$Env:LocalAppData\powershell\$Env:PAVE_PWSH_VERSION\pwsh"
 
    switch ($PSCmdLet.ParameterSetName) {
        "WithFile" {
            & $PwshPath -NoProfile -File $FilePath
        }
        "WithScriptBlock" {
            & $PwshPath -NoProfile -Command $ScriptBlock
        }
        "WithCommandText" {
            & $PwshPath -NoProfile -Command "$CommandText"
        }
        default {
            throw "Unknown parameter set : $($PSCmdLet.ParameterSetName)"
        }
    }        
 
    if ($LASTEXITCODE -ne 0) {
        $ErrorMessage = "Running $(em $FilePath ) with $(em $PwshPath ) failed with exit code $(em $LASTEXITCODE)."
        Write-LogEntry $ErrorMessage -IgnoreActionLevel
        throw $ErrorMessage
    }
 
    Update-PathEnvVar
 
}

function Update-UserEnvVar {
    <#
    .SYNOPSIS
    Updates the specified env var from the latest USER settings
    
    .DESCRIPTION
    Long description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    params(
        [Parameter(Mandatory, Position=0)]
        [string]$Name
    )
    
    $Value = [System.Environment]::GetEnvironmentVariable($Name, [EnvironmentVariableTarget]::User)
    Write-verbose "$Name Value: $UserPath"
    Set-Item -Path "env:\$Name" -Value $Value -force
} 
#endregion

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
lay bs-no-admin -PwshVersion $Env:PAVE_PWSH_VERSION -UseWinget
Update-PathEnvVar 

$ScriptsPath = "$(Get-Cache)\bs-no-admin\scripts"

#region install other apps
# install python versions
$InstallPythonFilePath = Join-Path $ScriptsPath 'Install-PythonWinget.ps1'
Invoke-Pwsh -File $InstallPythonFilePath 
# install node
$InstallNodeFilePath = Join-Path $ScriptsPath 'Install-Node.ps1'
Invoke-Pwsh -File $InstallNodeFilePath 
#endregion

#region apply configs
$ConfigFilePath = Join-Path $ScriptsPath 'Set-Config.ps1'
$SharedParams = "-Org 'stvnrs' -Repo 'config' -Path 'uwm-vm'"  
Invoke-Pwsh -CommandText "$ConfigFilePath $SharedParams -DotSource -Include 'env'"
Invoke-Pwsh -CommandText "$ConfigFilePath $SharedParams -Exclude 'env', 'code'"
$SharedParams = "-Org 'stvnrs' -Repo 'config-private' -Path 'uwm-vm'"  
Invoke-Pwsh -CommandText "$ConfigFilePath $SharedParams -DotSource -Include 'env'"
Update-UserEnvVar "REPOS_LOCAL"
Invoke-Pwsh -CommandText "$ConfigFilePath $SharedParams -Exclude 'env'"
#endregion
