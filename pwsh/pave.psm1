
# $Script:Remote = $Env:PAVE_REMOTE ?? 'https://pave.eightsix.io/public/latest'
# $Script:Remote = $Env:PAVE_REMOTE ?? 'https://eightsixpaveprodstg.blob.core.windows.net/public/latest'
# $Script:Cache = $Env:PAVE_CACHE ?? (Join-Path $HOME 'pave' 'slabs')
$Script:Remote = if ($Env:PAVE_REMOTE) { $Env:PAVE_REMOTE }else { 'https://eightsixpaveprodstg.blob.core.windows.net/public/latest' }
$Script:Cache = if ($Env:PAVE_CACHE) { $Env:PAVE_CACHE }else { Join-Path (Join-Path $HOME 'pave') 'slabs' }
$ErrorActionPreference = 'Stop'

function Get-Remote {
    param(
    )
    $Script:Remote

}
function Set-Remote {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Remote
    )

    $Script:Remote = $Remote
}

function Get-Cache {
    param(
    )

    $Script:Cache
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

            & "$Script:Cache/$Name/deploy.ps1"
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
        $TempFile = New-TemporaryFile
        $IndexUri = "$Script:Remote/slabs/~index"
        Write-Verbose "Getting index from $IndexUri"
        Start-BitsTransfer $IndexUri $TempFile.FullName
        $Slabs = Get-Content -Raw $TempFile.FullName | ConvertFrom-Json -Depth 3 -AsHashtable
    }

    process {
        if ($Name) {
            if ($Slabs.Keys.Contains($Name)) {
                $Slabs[$Name]
            }
            else {
                throw "Slab ``$Name`` not found."
            }
        }
        else {
            $Slabs.Keys| Sort-Object | ForEach-Object {
                $Slab =  $Slabs[$_]
                [PSCustomObject]@{
                    Name = $_
                    Description =  $Slab | Select-Object -ExpandProperty "description"
                    DependsOn =   ($Slab | Select-Object -ExpandProperty "dependsOn") -join ', '
                }
            }
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
                Write-Verbose "$Script:Cache/slabs/$Name exists" -Verbose
                Get-ChildItem "$Script:Cache" -Name $Name -Directory | Select-Object -exp PSChildName
            }
            else {
                throw "Slab ``$Name`` not found in cache"
            }
        }
        else {
            Get-ChildItem "$Script:Cache" -Directory | Select-Object -exp name
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
        
        if (!(Test-Path $Script:Cache)) {
            mkdir $Script:Cache
        }
    }

    process {
        $Name | ForEach-Object {
            $Uri = "$Script:Remote/slabs/$Name.zip"
            Write-Verbose "downloading $Uri"
            Start-BitsTransfer $Uri "$Script:Cache/"
            Write-Verbose "installing at $Script:Cache/$Name"
            Expand-Archive "$Script:Cache/$Name.zip" "$Script:Cache/$Name" -Force 
            Remove-Item "$Script:Cache/$Name.zip"
        }
    }
    
    end {
        
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
    }
}


'Deploy-Slab', 'Get-Slab', 'Uninstall-Slab' | ForEach-Object {
    Register-ArgumentCompleter -CommandName $_ -ParameterName 'Name' -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        Get-ChildItem "$Script:Cache" -Directory | Select-Object -exp name | Where-Object { $_ -like "$wordToComplete*" }
    }
}

# 'Find-Slab', 'Install-Slab' | ForEach-Object {
#     Register-ArgumentCompleter -CommandName $_ -ParameterName 'Name' -ScriptBlock {
#         param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
#         $Script:AvailableSlabs | Where-Object { $_ -like "$wordToComplete*" }
#     }
# }


