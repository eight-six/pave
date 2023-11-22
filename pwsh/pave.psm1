
$Script:Remote = $Env:PAVE_REMOTE ?? 'https://github.com/eight-six/pave.git'
$Script:RemoteBranch = 'main'
$Script:Cache = $Env:PAVE_CACHE ?? (Join-Path $HOME 'pave' 'slabs')

$ErrorActionPreference = 'Stop'

$Script:RepoCache = Join-Path $Env:Temp ([System.IO.Path]::GetRandomFileName())
$Script:RepoCachedAt = $null
$Script:RepoCacheSecs = 60

$Script:AvailableSlabs = @()
$Script:InstalledSlabs = @()

function UpdateRepoCache {
    $PSNativeCommandUseErrorActionPreference = $true
    
    if (!(Test-Path $Script:RepoCache) -or $null -eq $RepoCachedAt -or (Get-Date).Subtract($Script:RepoCachedAt).TotalSeconds -gt $Script:RepoCacheSecs ) {
        Write-Verbose "Updating repo cache ``$Script:RepoCache``" -Verbose
        if (Test-Path $Script:RepoCache) {
            Remove-Item $Script:RepoCache -Recurse -Force
        }
        $Response = git clone $Script:Remote --branch=$Script:RemoteBranch --depth 1 $Script:RepoCache 2>&1
        Write-Verbose $Response

        $Script:RepoCachedAt = Get-Date
        $Script:AvailableSlabs = Get-ChildItem "$Script:RepoCache/slabs" -Directory | Select-Object -exp name
    }
    else {
        Write-Verbose "Using cached repo ``$Script:RepoCache``" -Verbose
    }
}

function UpdateInstalledSlabs {
    Write-Verbose "Updating installed slabs ``$Script:Cache``" -Verbose

    $Script:InstalledSlabs = Get-ChildItem "$Script:Cache" -Directory | Select-Object -exp name
}

function Set-Remote {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Remote
    )
    $Script:Remote = $Remote

}

function Set-Cache {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Cache
    )

    $Script:Cache = $Cache
}
function Deploy-Slab {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $Name
    )

    begin {
       
    }

    process {
        $Name | ForEach-Object {
            if (Test-Path "$Script:Cache/$Name") {
                Write-Verbose "$Script:Cache/$Name exists" -Verbose
            }
            else {
                throw "Slab ``$Name`` not found in cache"
            }

            & "$Script:Cache/$Name/deploy.ps1" Recurse -Force
        }
    }
}

function Find-Slab {
    param(
        # Name of the slab to find e.g. 'bs', 'bs-pwsh'
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Name
    )
    begin {
        UpdateRepoCache
    }
    process {
        $Path = Join-Path $Script:RepoCache 'slabs'
        $PathPath = Join-Path $Path $Name

        if ($Name) {
            if (Test-Path "$PathPath") {
                Write-Verbose "$PathPath exists" -Verbose
                ls "$Path" -Name $Name -Directory | select -exp PSChildName
            }
            else {
                throw "Slab ``$Name`` not found in cache ``$Path``"
            }
        }
        else {
            $Script:AvailableSlabs
        }
    }
    end {

    }

}

function Get-Slab {
    param(
        # Name of the slab to get e.g. 'bs', 'bs-pwsh'
        [Parameter(Mandatory = $False, ValueFromPipeline = $true)]
        [string]$Name
    )

    process {
        #$PSBoundParameters
        if ($Name) {
            if (Test-Path "$Script:Cache/$Name") {
                Write-Verbose "$Script:Cache/$Name exists" -Verbose
                ls "$Script:Cache" -Name $Name -Directory | select -exp PSChildName
            }
            else {
                throw "Slab ``$Name`` not found in cache"
            }
        }
        else {
            ls "$Script:Cache" -Directory | select -exp name
        }
    }

}

function Install-Slab {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $Name
    )
    
    begin {
        UpdateRepoCache
        
        if (!(Test-Path $Script:Cache)) {
            mkdir $Script:Cache
        }
    }

    process {
        $Name | ForEach-Object {
            if (Test-Path "$Script:Cache/$Name") {
                rm "$Script:Cache/$Name" -Recurse -Force
            }

            Copy-Item "$Script:RepoCache/$Name" "$Script:Cache/" -Recurse
        }
    }
    
    end {
        UpdateInstalledSlabs
    }
}


function Uninstall-Slab {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $Name
    )

    begin {
       
    }

    process {
        $Name | ForEach-Object {
            if (Test-Path "$Script:Cache/$Name") {
                Remove-Item "$Script:Cache/$Name" -Recurse -Force
            }
        }
    }

    end {
        UpdateInstalledSlabs
    }
}

UpdateInstalledSlabs

'Deploy-Slab', 'Get-Slab', 'Uninstall-Slab' | ForEach-Object {
    Register-ArgumentCompleter -CommandName $_ -ParameterName 'Name' -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        $Script:InstalledSlabs | Where-Object { $_ -like "$wordToComplete*" }
    }
}

'Find-Slab', 'Install-Slab' | ForEach-Object {
    Register-ArgumentCompleter -CommandName $_ -ParameterName 'Name' -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        $Script:AvailableSlabs | Where-Object { $_ -like "$wordToComplete*" }
    }
}

Export-ModuleMember -Function 'Deploy-Slab', 'Find-Slab', 'Get-Slab', 'Install-Slab', 'Set-Cache', 'Set-Remote', 'Uninstall-Slab'
