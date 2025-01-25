
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$Script:ActionLevel = 0
$Script:Stack = [collections.stack]::new()
$Script:LogTarget = 'Information'


$LogOptions = [ordered]@{
    actionCompletedSuffix= '✔'
    actionStartSuffix= '…'
    bold= '**'
    emph= '*'
    headerChar= '='
    infoPrefix= ""
    levelChar= '+'
    padChar= ""
    subheaderChar= '-'
    timestamp= $false
}

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

function Write-LogEntry {
    param (
        [string]$Message,
        [switch]$NoColor
    )

    Write-verbose "message: $Message" #-Verbose

    $DefaultStyle = "$($PSStyle.Reset)$($PSStyle.Foreground.White)"
    $EmphStyle = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightBlue)"

    $Message = "$($DefaultStyle)$Message"

    if($LogOptions.timestamp){
        $Message = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightBlack)$(get-date -Format 'u')$($PSStyle.Reset) $Message"
    } 

    switch ($Script:LogTarget) {
        {$_ -in 'Default', 'Information'} {  
            if($NoColor.IsPresent){
                $Message = $Message -replace $EmphStart, '*'
                $Message = $Message -replace $EmphEnd, '*'
            } else {
                $Message = $Message -replace $EmphStart, $EmphStyle
                $Message = $Message -replace $EmphEnd, $DefaultStyle
                $Message = $Message -replace $BoldStart, $PSStyle.Bold
                $Message = $Message -replace $BoldEnd, $PSStyle.BoldOff
                $Message = $Message -replace $UnderlineStart, $PSStyle.Underline
                $Message = $Message -replace $UnderlineEnd, $PSStyle.UnderlineOff
                
                $Message = "$Message$($PSStyle.Reset)"
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

    $Tokens +=  $Text, $LogOptions.actionStartSuffix

    Write-LogEntry ($Tokens -join ' ')
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
    
        $Tokens +=  $Item.Text, "$($PSStyle.Foreground.Green)$($LogOptions.actionCompletedSuffix)$($PSStyle.Reset)$($PSStyle.Foreground.Cyan)"

        if ($Item.LevelIncremented) {
            $Script:ActionLevel = $Script:ActionLevel -gt 0 ?  $Script:ActionLevel - 1 : 0
        
        }

        Write-LogEntry ($Tokens -join ' ') 
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

# function log {
#     param(
#         [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
#         [Parameter(Mandatory = $true, ParameterSetName = 'StartAction')]
#         [Parameter(Mandatory = $true, ParameterSetName = 'CompleteAction')]
#         [string]$Text,
#         [Parameter(Mandatory = $true, ParameterSetName = 'StartAction')]
#         [switch]$StartAction,
#         [Parameter(Mandatory = $true, ParameterSetName = 'CompleteAction')]
#         [switch]$CompleteAction,
#         [int]$Level = 0
#     )

#     $LevelText = $LogOptions.LevelChar * $Level
#     $Tokens =  $LevelText , $LogOptions.InfoPrefix, $Text

#     if ($StartAction.IsPresent) {
#         $Tokens += $LogOptions.ActionStartSuffix
#     }

#     if ($CompleteAction.IsPresent) {
#         $Tokens += $LogOptions.ActionCompletedSuffix
#     }
    
#     $Tokens -join $LogOptions.PadChar
# }

function Write-LogHeader {
    param(
        [string]$Text,
        [string]$HeaderChar = $LogOptions.HeaderChar
    )

    $WindowSize = [Math]::Min($Host.UI.RawUI.WindowSize.Width, $Script:LogOptions.maxLineLength) - 1

    if($Script:LogOptions.timestamp){
        $WindowSize -= 21
    }

    if($Text.Length -eq 0){
        Write-LogEntry "$($HeaderChar * $Pre) $Text $($HeaderChar * $Post)"
    } else {   
        $Pre = [int](($WindowSize - ($Text.Length + 2)) / 2)
        $Post = $WindowSize - ($Pre + $Text.Length + 2)
        Write-LogEntry "$($HeaderChar * $Pre) $Text $($HeaderChar * $Post)"
    }
}

function Write-LogSubheader {
    param(
        [string]$Text
    )

    Write-LogHeader $text -HeaderChar $LogOptions.SubheaderChar
}

function Get-LogOptions {
    $Script:LogOptions
}

if(Test-Path "$HOME/.pave-logger"){
    # get from ~/.pave-logger
    $LogOptions = gc -raw "$HOME/.pave-logger" | ConvertFrom-Yaml -Ordered
} else {
    $LogOptions | ConvertTo-Yaml | Out-File "$HOME/.pave-logger"
}

Set-Alias log Write-LogEntry
set-alias log-header Write-LogHeader
set-alias log-subheader Write-LogSubheader