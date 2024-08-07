
$ErrorActionPreference = 'Stop'

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
lay bs-no-admin -PwshVersion '7.4.4'
lay reg-tweaks

