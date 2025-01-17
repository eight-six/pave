
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = 'true'

$Env:PAVE_PWSH_VERSION = '7.4.6'

# seperate multiple versions with a | - versions are installed left to right, the last one will be the default.
$Env:PAVE_PY_VERSION = '3.12|3.11'

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

# this is a wee hack as .net install doesn't add its install path to the path for the current session
# when the installer for Azure Storage Explorer doesn't find dotnet it attempts to install dotnet to 
# program files which requires elevation, which we don't have.
$Env:Path = "$Env:LocalAppData\Microsoft\DotNet;" + $Env:Path
Install-Slab bs-no-admin
Install-Slab reg-tweaks
lay bs-no-admin -PwshVersion $Env:PAVE_PWSH_VERSION 

$Env:PAVE_PY_VERSION -split '\|' | % {
    winget install "Python.Python.$_" --accept-source-agreements 
    $PyVersion = $_ -replace '\.', ''
    $Env:Path = "$Env:LOCALAPPDATA\Programs\Python\Python$PyVersion;$Env:LOCALAPPDATA\Programs\Python\Python$PyVersion\Scripts;" + $Env:Path
}

# When copy & pasted or directly downloaded line endings in this "file" are LF.  This causes
# some interesting issues.  Hence, write script to file and execute that.
@'
    $ErrorActionPreference = 'Stop'
    
    if($null -eq (gcm git -ea 'Ignore')){
        $Env:Path = "$Env:LOCALAPPDATA\Programs\git\bin;" + $Env:Path
        }
        
    $Uri = 'https://raw.githubusercontent.com/eight-six/pave/refs/heads/main/slabs/bs-no-admin/scripts/Install-Node.ps1'
    Start-BitsTransfer $Uri
    # the previous command downloads the raw file for github which has LF line endings - this causes issues with PowerShell 5.1 and 7.4.6
    # cat'ing the file replaces the LFs with CR+LFs
    cat .\Install-Node.ps1 > .\Install-NodeWin.ps1
    & .\Install-NodeWin.ps1
'@ | Out-File -Encoding utf8 ./bs-node.ps1

 & "$Env:LocalAppData\powershell\pwsh" -file ./bs-node.ps1
 
{
    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $true
    
    if($Env:Path[-1] -ne ';'){
        $Env:Path += ';'
    }

    if($null -eq (gcm git -ea 'Ignore')){
        $Env:Path = "$Env:LOCALAPPDATA\Programs\git\bin;" + $Env:Path
    }
    
    if($null -eq (gcm code-insiders -ea 'Ignore')){
        $Env:Path += "$Env:LOCALAPPDATA\Programs\Microsoft VS Code Insiders\bin;"
    }
    
    $Proxy = [System.Net.WebRequest]::GetSystemWebProxy().GetProxy('https://github.com')
    $AddtionalArgs = if($null -ne $Proxy){"-c http.proxy=$($Proxy.OriginalString)"}else{''}
    git clone $AddtionalArgs https://github.com/stvnrs/config
    & ./config/configs/uwm-vm/doit.ps1
} | & "$Env:LocalAppData\powershell\pwsh" -command - # note the sneaky '-' at the end!

{
    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $true
    
    if($null -eq (gcm git -ea 'Ignore')){
        $Env:Path = "$Env:LOCALAPPDATA\Programs\git\bin;" + $Env:Path
    }

    $Proxy = [System.Net.WebRequest]::GetSystemWebProxy().GetProxy('https://github.com')
    $AddtionalArgs = if($null -ne $Proxy){"-c http.proxy=$($Proxy.OriginalString)"}else{''}
    git clone  $AddtionalArgs  https://github.com/stvnrs/config-private
    . ./config-private/configs/uwm-vm/env/doit.ps1
    . ./config-private/configs/uwm-vm/pwsh/doit.ps1
    & ./config-private/configs/uwm-vm/code/doit.ps1

} | & "$Env:LocalAppData\powershell\pwsh" -command - # note the sneaky '-' at the end!


#lay reg-tweaks
