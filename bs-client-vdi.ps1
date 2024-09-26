
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = 'true'

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
lay bs-no-admin -PwshVersion '7.4.5'
winget install Python.Python.3.12
$Env:BS_USER_NAME = $Env:BS_USER_NAME ?? (Read-Host -Prompt "Enter your user name for git logs (set `$Env:BS_USER_NAME to avoid this prompt in future)")
$Env:BS_USER_EMAIL = $Env:BS_USER_EMAIL ?? (Read-Host -Prompt "Enter your email name for git logs (set `$Env:BS_USER_EMAIL to avoid this prompt in future)")

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
    
    git clone https://github.com/stvnrs/config
    & ./config/configs/uwm-vm/doit.ps1
} | & "$Env:LocalAppData\powershell\pwsh" -command -interactive - # note the sneaky '-' at the end!

lay reg-tweaks
