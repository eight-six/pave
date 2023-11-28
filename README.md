# pave

Get the pave module

```pwsh
Start-BitsTransfer 'https://eightsixpaveprodstg.blob.core.windows.net/public/latest/pwsh-pave.zip' 
Expand-Archive '.\pwsh-pave.zip' './powershell/modules/pave'
rm '.\pwsh-pave.zip'
Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser'
```

Install module

```pwsh
Import-Module pave
```

Check remote repo location

```pwsh
Get-Remote
```

```pwsh
https://eightsixpaveprodstg.blob.core.windows.net/public/latest
```

Check local cache location

```pwsh
Get-Cache
```

```
C:\Users\StevenRose\pave\slabs
```

Set remote repo location

```pwsh
Set-Remote https://pave.eightsix.io/public/latest
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
Deploy-Slab 
```