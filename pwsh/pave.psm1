
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
        $Slabs = (iwr "$Script:Remote/slabs/.index" | select -exp content ) -split '\r{0,1}\n'
    }
    process {
        if ($Name) {
            if ($Slabs -contains $Name) {
                $Name
            }
            else {
                throw "Slab ``$Name`` not found."
            }
        }
        else {
            $Slabs
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
        
        if (!(Test-Path $Script:Cache)) {
            mkdir $Script:Cache
        }
    }

    process {
        $Name | ForEach-Object {
            $Uri = "$Script:Remote/slabs/$Name.zip"

            Start-BitsTransfer $Uri "$Script:Cache/"
            Expand-Archive "$Script:Cache/$Name.zip" "$Script:Cache/$Name" -Force 
            rm "$Script:Cache/$Name.zip"
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

Export-ModuleMember -Function 'Deploy-Slab', 'Find-Slab', 'Get-Slab', 'Get-Cache', 'Get-Remote', 'Install-Slab', 'Set-Cache', 'Set-Remote', 'Uninstall-Slab'
