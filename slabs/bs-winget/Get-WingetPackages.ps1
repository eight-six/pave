<#
.DESCRIPTION

Executes winget list and formats the text outout to objects

#>
param(
    [switch]$WingetOnly,

    [ValidateSet('user','machine')]
    [string]$Scope
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 'latest'

$WingetArgs = @('list')

if($WingetOnly.IsPresent){
    $WingetArgs += '--source', 'winget'
}

if(![string]::IsNullOrWhiteSpace( $scope)){
    $WingetArgs += '--scope', $Scope
}

Write-Verbose "winget $($WingetArgs -join ' ')" -Verbose

$Response = & winget $WingetArgs

Write-Verbose "winget exit code: $LastExitCode" -Verbose

if($LastExitCode -ne 0){
    throw "failed to execute winget. $Response"
}

$TableThings = '-' * 20

$X = $Response | select-string -SimpleMatch $TableThings | select -exp LineNumber
$TableWidth = $Response[$X - 1].Length 
$HeaderRow = $Response[$X - 2]
$Columns = $HeaderRow -split '\s+'

$Indexes = [ordered]@{}

$Columns | % {
    $Indexes[$_] = [ordered]@{StartsAt = $HeaderRow.IndexOf($_) ; Length = $null }
}

for ($i = 0; $i -lt $Indexes.Count - 1; $i++) {
    $Indexes[$i].length = $Indexes[$i + 1].StartsAt - $Indexes[$i].StartsAt
}
$LastIndex = $Indexes.Count - 1
$Indexes[$LastIndex].length = $TableWidth - $Indexes[$LastIndex].StartsAt

$LineIndex = 0

$Packages = $Response | select -skip $X <#-first 10#> | % {
    $Line = $_ -replace 'ΓÇª', '…'

    try {
        if ($Line.Length -lt $TableWidth) {
            $Line += (' ' * ($TableWidth - $Line.Length))

        }
        Write-Verbose "Line: [$LineIndex] ``$Line`` Length: $($Line.Length) "#-Verbose
        $Item = [ordered]@{}
    
        $Indexes.Keys | % {
            $Item[$_] = $Line.Substring($Indexes[$_].StartsAt, $Indexes[$_].Length).Trim()
        }
        
        [pscustomobject]$Item
    }
    catch {
        $Line
        $Line.Length
    }

    $LineIndex++ 
} 

$Packages

