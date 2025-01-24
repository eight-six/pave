
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$Script:ActionLevel = 0
$Script:Stack = [collections.stack]::new()
$Script:LogTarget = 'Information'


$EmphStart = '<em>'
$EmphEnd   = '</em>'
$BoldStart = '<b>'
$BoldEnd   = '</b>'
$UnderlineStart = '<u>'
$UnderlineEnd   = '</u>'

function Get-ActionLevel {
    $Script:ActionLevel
}

function Clear-ActionLevel {
    $Script:ActionLevel = 0
}

function Set-LogTargetStream {
    param(
        [ValidateSet('Default', 'Information', 'Output', 'Host')]
        [string]$Target 
    )

    $Script:LogTarget = $Target
}

function Write-Log {
    param (
        [string]$Message,
        [switch]$NoColor
    )

    Write-verbose "message: $Message" #-Verbose

    switch ($Script:LogTarget) {
        {$_ -in 'Default', 'Information'} {  
            if($NoColor.IsPresent){
                $Message = $Message -replace $EmphStart, '*'
                $Message = $Message -replace $EmphEnd, '*'
            } else {
                $Message = $Message -replace $EmphStart, $PSStyle.Foreground.Magenta
                $Message = $Message -replace $EmphEnd, $PSStyle.Reset
                $Message = $Message -replace $BoldStart, $PSStyle.Bold
                $Message = $Message -replace $BoldEnd, $PSStyle.Bold
                $Message = $Message -replace $UnderlineStart, $PSStyle.Underline
                $Message = $Message -replace $UnderlineEnd, $PSStyle.UnderlineOff
                
                $Message = "$($PSStyle.Foreground.Cyan)$Message$($PSStyle.Reset)"
            }
            Write-verbose "message: $Message" #-Verbose

            Write-Information $Message
        }
        'Output' {
            Write-Output $Message
        }
        'Host' {
            Write-Host $Message
        }
        Default {
            Write-Warning "Unknown log target stream '$_'"
            Write-Host $Message
        }
    }
}

# log-start-action
function Push-LogAction {
    param(
        [string]$Text,
        [switch]$IncrementActionLevel
    )

    if ($IncrementActionLevel.IsPresent) {
        $Script:ActionLevel++
    }

    $Script:Stack.Push([pscustomobject]@{Text = $text; LevelIncremented = $IncrementActionLevel.IsPresent })
    $Tokens = @()
    
    if($Script:ActionLevel -gt 0){
        $Tokens += '+' * $Script:ActionLevel
    }

    $Tokens +=  $Text, '...'

    Write-Log ($Tokens -join ' ')
}

function Pop-LogAction {
    param(
       
    )

    # if ( $Script:Stack.Count -eq 0) {
        $Item = $Script:Stack.Pop()
        Write-verbose "item $($Item | ConvertTo-Json -Compress)" #-Verbose

        $Tokens = @()
    
        if($Script:ActionLevel -gt 0){
            $Tokens += '+' * $Script:ActionLevel
        }
    
        $Tokens +=  $Item.Text, '✔️'

        if ($Item.LevelIncremented) {
            $Script:ActionLevel = $Script:ActionLevel -gt 0 ?  $Script:ActionLevel - 1 : 0
        
        }

        Write-Log ($Tokens -join ' ') 
    # }

}

function emph {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    "$($EmphStart)$Text$($EmphEnd)"
}

function bold {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    "$($BoldStart)$Text$($BoldEnd)"
}

function under {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    "$($UnderlineStart)$Text$($UnderlineEnd)"
}

function log {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ParameterSetName = 'StartAction')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CompleteAction')]
        [string]$Text,
        [Parameter(Mandatory = $true, ParameterSetName = 'StartAction')]
        [switch]$StartAction,
        [Parameter(Mandatory = $true, ParameterSetName = 'CompleteAction')]
        [switch]$CompleteAction,
        [int]$Level = 0
    )

    $LevelText = $LogOptions.LevelChar * $Level
    $Tokens =  $LevelText , $LogOptions.InfoPrefix, $Text

    if ($StartAction.IsPresent) {
        $Tokens += $LogOptions.ActionStartSuffix
    }

    if ($CompleteAction.IsPresent) {
        $Tokens += $LogOptions.ActionCompletedSuffix
    }
    
    $Tokens -join $LogOptions.PadChar
}

function Write-LogHeader {
    param(
        [string]$Text,
        [string]$HeaderChar = $LogOptions.HeaderChar
    )

    if($Text.Length -eq 0){
        Write-Log "$($HeaderChar * $Pre) $Text $($HeaderChar * $Post)"
    } else {   
        $Pre = [int](($Host.UI.RawUI.WindowSize.Width - ($Text.Length + 2)) / 2)
        $Post = $Host.UI.RawUI.WindowSize.Width - ($Pre + $Text.Length + 2)
        Write-Log "$($HeaderChar * $Pre) $Text $($HeaderChar * $Post)"
    }
}

function Write-LogSubheader {
    param(
        [string]$Text
    )

    header $text -HeaderChar $LogOptions.SubheaderChar
}


set-alias header Write-LogHeader
set-alias subheader Write-LogSubheader