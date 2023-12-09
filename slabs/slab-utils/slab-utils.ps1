$InformationPreference = 'Continue'
# $VerbosePreference = 'Continue'
# $WarningPreference = 'Continue'

$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path

$LayFile = 'lay.ps1'
$InfosFile = 'info.psd1'

$em = if ($null -ne $Env:EM) { $Env:EM } else { '*' }
$LogStart = if ($null -ne $Env:LOG_START) { $Env:LOG_START } else { '...' }
$LogDone = if ($null -ne $Env:LOG_DONE) { $Env:LOG_DONE } else { ' - done!' }

function emph {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    return "$em$($Text)$em"
}

function Deploy {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $CallerName,
        [Parameter()]
        [string]
        $SlabName,
        [Parameter()]
        [hashtable]$Params = @{}
    )

    $LayFilePath = "$SlabsRoot\$SlabName\$LayFile" 
    $LogMessage = "INFO: $(emph $CallerName) deploying $(emph $SlabName) from $(emph $LayFilePath)"
    Write-Information "$LogMessage$($LogStart)"
    & $LayFilePath @Params
    Write-Information "$LogMessage$($LogDone)" 
}