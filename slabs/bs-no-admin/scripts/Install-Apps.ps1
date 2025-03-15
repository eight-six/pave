#Requires -version 7.4
#Requires -modules pave-logger
#Requires -modules pave-utils

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet(
        'azure-data-studio',
        'code-insiders',
        'code',
        'git',
        'node',
        'storage-explorer',
        'windows-terminal-preview',
        'windows-terminal')]
    [string[]]$Apps = @()
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$AppLookup = @{
    'azure-data-studio' = 'AzureDataStudio'
    'code-insiders'     = @{ScriptId = 'BsCode'; Params = @{BuildType = 'insider' } }
    'code'              = @{ScriptId = 'BsCode'; Params = @{BuildType = 'stable' } }
    # 'deno'                     = 'Deno'
    'duckdb'            = 'DuckDB'
    'git'               = 'GitForWindows'
    'node'              = 'Node'
    'storage-explorer'  = 'StorageExplorer'
    'windows-terminal'  = 'WindowsTerminal'
}

try {
    $Heading = "$(u apps)"
    Write-LogHeader "$Heading" -Subheader:($null -ne $MyInvocation.PSCommandPath)
    
    $ScriptsFolder = $PSScriptRoot 

    $Apps | % {
        Push-LogAction "installing $(em $_)" -IncrementActionLevel

        $Scripto = $AppLookup[$_]
        
        if ($Scripto -is [string]) {
            if ($PSCmdlet.ShouldProcess("Install-$Scripto.ps1", "call")) {
                & "$ScriptsFolder\Install-$Scripto.ps1"
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess("Install-$($Scripto.ScriptId).ps1", "call")) {
                & "$ScriptsFolder\Install-$($Scripto.ScriptId).ps1" @$Scripto.Params
            }
        }

        Pop-LogAction
    }

    if ($null -eq $MyInvocation.PSCommandPath) {
        $Heading += ' - completed'
        Write-LogHeader $Heading 
    }
}
catch {
    Clear-LogAction
    throw $_
}
