using namespace System.Management.Automation

$ErrorActionPreference = 'Stop'

$Script:Remote = if ($Env:PAVE_REMOTE) { $Env:PAVE_REMOTE }else { 'https://eightsixpaveprodstg.blob.core.windows.net/public/latest' }
$Script:Cache = if ($Env:PAVE_CACHE) { $Env:PAVE_CACHE }else { Join-Path (Join-Path $HOME 'pave') 'slabs' }

$LayFile = 'lay.ps1'

function emph {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Text
    )

    $em = if ($null -ne $Env:EM) { $Env:EM } else { '*' }

    "$em$($Text)$em"
}

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
    dynamicparam {
        $ParamDictionary = [RuntimeDefinedParameterDictionary]::new()

        if ($PSBoundParameters.ContainsKey('Name')) {
            $SlabName = $PSBoundParameters['Name']
            if (Test-Path "$Script:Cache/$SlabName") {
                $ast = [Language.Parser]::ParseFile("$Script:Cache/$SlabName/$LayFile", [ref]$null, [ref]$null)

                $params = $ast.FindAll({ $args[0] -is [Language.ParameterAst] }, $true)
                
                Write-Verbose "SlabName: $Script:Cache/$Name/$LayFile" -Verbose

                $params | ForEach-Object {
                    $param = $_
                    $paramName = $param.Name.VariablePath.UserPath
                    $paramDefaultValue = $param.DefaultValue.Extent.Text

                    Write-Verbose "paramName: $paramName" -Verbose
                    Write-Verbose "paramDefaultValue: $paramDefaultValue" -Verbose

                    $ParameterAttribute = [ParameterAttribute]@{
                        Mandatory = $false
                    }
                    $DefaultValueAttribute = [System.Runtime.InteropServices.DefaultParameterValueAttribute]::new($paramDefaultValue)
                    $AttributesCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
                    $AttributesCollection.Add($ParameterAttribute)
                    $AttributesCollection.Add($DefaultValueAttribute)
                    $NewParam = [RuntimeDefinedParameter]::new(
                        $paramName, $param.StaticType, $AttributesCollection
                    )
                    
                    $ParamDictionary.Add($paramName, $NewParam)
                }
            }
        }
        return $ParamDictionary
    }

    begin {
        $SlabParams = [hashtable]$PSBoundParameters # make a sneaky copy
        $SlabParams.Remove('Name')
    }
        
    process {
        $Name | ForEach-Object {
            if (Test-Path "$Script:Cache/$Name") {
                Write-Verbose "$Script:Cache/$Name exists"
            }
            else {
                throw "Slab $(emph $Name) not found in cache"
            }
            Write-Verbose "Deploying $(emph $Name) from $Script:Cache/$Name/$LayFile"

            & "$Script:Cache/$Name/$LayFile" @SlabParams
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
        $Slabs = Get-Content -Raw $TempFile.FullName | ConvertFrom-Json | Get-Member -Type NoteProperty | select -exp name
    }

    process {
        if ($Name) {
            if ($Slabs.Keys.Contains($Name)) {
                $Slabs[$Name]
            }
            else {
                throw "Slab $(emph $Name) not found."
            }
        }
        else {
            $Slabs.Keys | Sort-Object | ForEach-Object {
                $Slab = $Slabs[$_]
                [PSCustomObject]@{
                    Name        = $_
                    Description = $Slab | Select-Object -ExpandProperty 'description'
                    DependsOn   = $Slab | Select-Object -ExpandProperty 'dependsOn'
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
        [Parameter(Mandatory = $False, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )

    process {
        function GetSlabInfos {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Name,
                [Parameter(Mandatory = $true)]
                [string]$Description,
                [Parameter()]
                [string[]]$DependsOn,
                [Parameter()]
                [string]$Path
            )
            [PSCustomObject]@{
                Name        = $Name
                Description = $Description
                DependsOn   = $DependsOn
                Path        = $Path
            }

        }
        #$PSBoundParameters
        if ($Name) {
            if (Test-Path "$Script:Cache/$Name") {
                Write-Verbose "$Script:Cache/$Name exists"
                $Slab = Import-PowerShellDataFile "$Script:Cache/$Name/info.psd1"
                GetSlabInfos -Name $Name -Description $Slab.Description -DependsOn $Slab.dependsOn -Path "$Script:Cache/$Name"
            }
            else {
                throw "Slab $(emph $Name) not found in cache"
            }
        }
        else {
            Get-ChildItem "$Script:Cache" -Directory | ForEach-Object {
                $Slab = Import-PowerShellDataFile "$Script:Cache/$($_.Name)/info.psd1"
                GetSlabInfos -Name $_.Name -Description $Slab.Description -DependsOn $Slab.dependsOn -Path "$_"
            }
        }
    }

}

function Install-Slab {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
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

New-Alias -Name 'lay' -Value 'Deploy-Slab'



