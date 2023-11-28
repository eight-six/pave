# pave

Get the pave module

```pwsh
cd $HOME 
Start-BitsTransfer 'https://eightsixpaveprodstg.blob.core.windows.net/public/latest/pwsh-pave.zip' 
Expand-Archive '.\pwsh-pave.zip' './powershell/modules/pave'
rm '.\pwsh-pave.zip'
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

on WIndows Powershell you may have to import the psm1 file:

```pwsh
Import-Module $HOME/powershell/modules/pave/pave.psm1
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
Set-Remote '~/slabs'
```

Find available slabs

```pwsh
Find-Slab 
```

```text
bs
bs-no-admin
bs-pwsh
bs-winget
pwsh-profiles
pwsh-scripts
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

Deploy a slab - some slabs e.g. `pwsh-profiles` are designed to be deployed after install - these will have a `deploy.ps1` script in the root of the slab.  A quick way to deploy this type of slab is to use the `Deploy-Slab` cmdlet:

```pwsh
Deploy-Slab 'pwsh-profiles'
```
