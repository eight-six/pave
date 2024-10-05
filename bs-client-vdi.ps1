
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = 'true'

$Env:PAVE_PWSH_VERSION = '7.4.5'
$Env:PAVE_PY_VERSION = '3.11'

if($null -eq $Env:PAVE_USER_NAME){
    $Env:PAVE_USER_NAME = Read-Host -Prompt "Enter your user name for git logs (set `$Env:PAVE_USER_NAME to avoid this prompt in future)"
} 

if($null -eq $Env:PAVE_USER_EMAIL ){
    $Env:PAVE_USER_EMAIL = Read-Host -Prompt "Enter your email name for git logs (set `$Env:PAVE_USER_NAME to avoid this prompt in future)"
} 

Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser'

$ModulePath = "$($env:PSModulePath -split ';' | select -First 1)/pave"
$ModuleZipFileName = 'pave-module.zip'
cd "$HOME\downloads" 
Start-BitsTransfer "https://eightsixpaveprodstg.blob.core.windows.net/public/latest/$ModuleZipFileName" 
Expand-Archive $ModuleZipFileName $ModulePath
rm $ModuleZipFileName 
Import-Module pave
Install-Slab slab-utils
Install-Slab bs-no-admin
Install-Slab reg-tweaks
lay bs-no-admin -PwshVersion $Env:PAVE_PWSH_VERSION 
winget install "Python.Python.$Env:PAVE_PY_VERSION"

{
    if($Env:Path[-1] -ne ';'){
        $Env:Path += ';'
    }

    if($null -eq (gcm git -ea 'Ignore')){
        $Env:Path += "$Env:LOCALAPPDATA\Programs\git\bin;"
    }
    
    if($null -eq (gcm code-insiders -ea 'Ignore')){
        $Env:Path += "$Env:LOCALAPPDATA\Programs\Microsoft VS Code Insiders\bin;"
    }
    
    $PyVersion = $Env:PAVE_PY_VERSION -replace '\.', ''
    $Env:Path = "$Env:LOCALAPPDATA\Programs\Python\Python$PyVersion;$Env:LOCALAPPDATA\Programs\Python\Python$PyVersion\Scripts;" + $Env:Path

    git clone https://github.com/stvnrs/config
    & ./config/configs/uwm-vm/doit.ps1
} | & "$Env:LocalAppData\powershell\pwsh" -command - # note the sneaky '-' at the end!

lay reg-tweaks
