# pave

Get the pave module

```pwsh
$ModulePath = "$($env:PSModulePath -split ';' | select -First 1)/pave"
$ModuleZipFileName = 'pave-module.zip'
cd "$HOME\downloads" 
Start-BitsTransfer "https://eightsixpaveprodstg.blob.core.windows.net/public/latest/$ModuleZipFileName" 
Expand-Archive $ModuleZipFileName $ModulePath
rm $ModuleZipFileName 
Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser'
```

If you are going to install with winget (recommended if you can elevate) then its worth running your PowerShell as admin to avoid approving all the UAC prompts.

```pwsh
Start-Process powershell -Verb runAs
```

Install module

```pwsh
Import-Module pave
```

Check remote repo location

```pwsh
Get-Remote
```

```text
https://eightsixpaveprodstg.blob.core.windows.net/public/latest
```

Check local cache location

```pwsh
Get-Cache
```

```text
C:\Users\StevenRose\pave\slabs
```

Set remote repo location

```pwsh
Set-Remote 'https://pave.eightsix.io/public/latest'
```

Set local cache location

```pwsh
Set-Cache '~/slabs'
```

Find available slabs

```pwsh
Find-Slab 
```

```text
Name          Description                                                                  DependsOn
----          -----------                                                                  ---------
bs            Bootstrap a Windows development machine                                      {bs-no-admin, bs-pwsh, bs-winget, slab-u…
bs-no-admin   Bootstrap a Windows dev machine without admin rights                         slab-utils
bs-pwsh       Bootstrap pwsh settings                                                      {pwsh-profiles, pwsh-scripts, slab-utils}
bs-winget     Bootstrap using winget (Windows Package Manager)                             slab-utils
git-bash      Deploy a git-prompts shell script that hides the MINGW element in the prompt
pwsh-profiles Deploys pwsh profiles and supporting scripts                                 slab-utils
pwsh-scripts  deploys some pwsh scripts                                                    slab-utils
reg-tweaks    Changes a variety of registry settings                                       slab-utils
slab-utils    common utilities for slabs
```

Install a slab

```pwsh
Install-Slab bs
Install-Slab -name 'bs-winget'

```

Get installed slabs

```pwsh
Get-Slab 
```

```text
bs
bs-winget
```

Get installed slab

```pwsh
Get-Slab bs
```

```text
bs
```

Deploy a slab - some slabs e.g. `pwsh-profiles` are designed to be deployed after install - these will have a `index.ps1` script in the root of the slab.  A quick way to deploy this type of slab is to use the `Deploy-Slab` cmdlet:

```pwsh
Deploy-Slab 'pwsh-profiles'
```

or using the `lay` alias

```pwsh
lay 'pwsh-profiles'
```


