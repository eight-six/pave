
param (
    [Parameter(ParameterSetName = "Default", Mandatory = $false)]
    [string[]]$Include = @(),

    [Parameter(ParameterSetName = "Default", Mandatory = $false)]
    [string[]]$Exclude = @(),

    [Parameter(ParameterSetName = "ListAvailable", Mandatory = $true)]
    [switch]$ListAvailable,

    [Parameter(ParameterSetName = "ListAvailable", Mandatory = $false)]
    [switch]$Detailed,

    [Parameter(ParameterSetName = "Default", Mandatory = $false )]
    [Parameter(ParameterSetName = "ListAvailable", Mandatory = $false)]
    [string]$TweaksPath = "$PSScriptRoot\tweaks"

)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
. "$SlabsRoot/slab-utils/slab-utils.ps1"

$TweakList = Get-ChildItem "$TweaksPath\*.reg-tweaks.json"

switch ($PSCmdlet.ParameterSetName) {
    'ListAvailable' {
        $TweakList | ForEach-Object {
            $Tweak = Get-Content -Raw $_.FullName | ConvertFrom-Json

            $TweakInfo = [ordered]@{
                Name        =  [IO.Path]::GetFileNameWithoutExtension($_.BaseName)
                Description = $Tweak.Description     
                Path        = $_.FullName           
            }

            if ($Detailed.IsPresent) {
                $TweakInfo['Keys'] = $Tweak.Keys
            }

            [PSCustomObject]$TweakInfo
        }
    }
    'Default' {
        $TweakList | ForEach-Object {
            $Name =  [IO.Path]::GetFileNameWithoutExtension($_.BaseName)
            $ApplyTweak = $Include.Length -eq 0 -or $Include -contains $Name
            $ApplyTweak = $ApplyTweak -and ($Exclude.Length -eq 0 -or $Exclude -notcontains $Name)
            Write-Verbose "$($Name) : $ApplyTweak" -Verbose
            
            if ($ApplyTweak) {
                $Tweak = Get-Content -Raw $_.FullName | ConvertFrom-Json
                $Tweak.Keys | ForEach-Object {
                    $Params = @{
                        Path  = $_.Path
                        Name  = $_.Name
                        Value = $_.Value
                        Type  = $_.Type
                    }
                    
                    Set-ItemProperty @Params
                }
            }
        }
    }
    Default {
        throw "Unknown paramater set: $($PSCmdlet.ParameterSetName)"
    }
}


