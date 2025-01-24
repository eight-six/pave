$InformationPreference = 'Continue'
# $VerbosePreference = 'Continue'
# $WarningPreference = 'Continue'

$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path

$LayFile = 'lay.ps1'
$InfosFile = 'info.psd1'

# get from ~/.pave
$Config = @"
logOptions:
  infoPrefix: ""
  actionStartSuffix: …
  levelChar: +
  subheaderChar: '-'
  padChar: ""
  actionCompletedSuffix: ✔
  bold: '**'
  emph: '*'
  headerChar: =
"@

$PaveConfig = $Config | ConvertFrom-Yaml
$LogOptions = $PaveConfig.LogOptions


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
    $LogAction = "$(emph $CallerName) deploying $(emph $SlabName) from $(emph $LayFilePath)"
    Log $LogAction -StartAction
    & $LayFilePath @Params
    Log $LogAction -CompleteAction

}