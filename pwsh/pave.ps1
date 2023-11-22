
$Script:Remote = $Env:PAVE_REMOTE ?? 'https://github.com/eight-six/pave.git'
$Script:RemoteBranch = 'main'
$Script:Cache = $Env:PAVE_CACHE ?? (Join-Path $HOME 'pave' 'slabs')

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

function Get-Slab {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Name
    )

    $PSNativeCommandUseErrorActionPreference = $true

    $Cwd = Get-Location

    try {
        Push-Location $Env:TMP

        git clone $Script:Remote  --no-checkout --depth 1
        git sparse-checkout init --no-cone 
        git checkout slabs/$Name

        if(!(Test-Path $Script:Cache)) {
            mkdir $Script:Cache
        }

        cp pave/slabs/$Name "$Script:Cache/"

        rm -Recurse -Force 
    }
    finally {
        Pop-Location
    }

}