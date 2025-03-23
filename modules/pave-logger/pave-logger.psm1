#Requires -version 5.1 # Windows Powershell
#Requires -Modules powershell-yaml

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

#region script stuff
$Script:ActionLevel = 0
$Script:Stack = [collections.stack]::new()
$Script:LogTarget = 'Information'


$LogOptions = [ordered]@{
    actionCompletedSuffix = [char]0x2713
    actionStartSuffix     = [char]0x2026
    bold                  = '**'
    emph                  = '*'
    headerChar            = '='
    infoPrefix            = ""
    levelChar             = '+'
    maxLineLength         = 256
    padChar               = ""
    subheaderChar         = '-'
    showTimestamp         = $true
}

$AnsiEsc = [char]27
$AnsiEscDisplay = "``e"

$AnsiStyle = [ordered]@{
    Reset        = "$AnsiEsc[0m"
    Bold         = "$AnsiEsc[1m"
    BoldOff      = "$AnsiEsc[22m"
    Underline    = "$AnsiEsc[4m"
    UnderlineOff = "$AnsiEsc[24m"
    Foreground   = @{
        Black         = "$AnsiEsc[30m"
        BrightBlack   = "$AnsiEsc[90m"
        White         = "$AnsiEsc[37m"
        BrightWhite   = "$AnsiEsc[97m"
        Red           = "$AnsiEsc[31m"
        BrightRed     = "$AnsiEsc[91m"
        Magenta       = "$AnsiEsc[35m"
        BrightMagenta = "$AnsiEsc[95m"
        Blue          = "$AnsiEsc[34m"
        BrightBlue    = "$AnsiEsc[94m"
        Cyan          = "$AnsiEsc[36m"
        BrightCyan    = "$AnsiEsc[96m"
        Green         = "$AnsiEsc[32m"
        BrightGreen   = "$AnsiEsc[92m"
        Yellow        = "$AnsiEsc[33m"
        BrightYellow  = "$AnsiEsc[93m"
    }
    Background   = @{
        Black         = "$AnsiEsc[40m"
        BrightBlack   = "$AnsiEsc[100m"
        White         = "$AnsiEsc[47m"
        BrightWhite   = "$AnsiEsc[107m"
        Red           = "$AnsiEsc[41m"
        BrightRed     = "$AnsiEsc[101m"
        Magenta       = "$AnsiEsc[45m"
        BrightMagenta = "$AnsiEsc[105m"
        Blue          = "$AnsiEsc[44m"
        BrightBlue    = "$AnsiEsc[104m"
        Cyan          = "$AnsiEsc[46m"
        BrightCyan    = "$AnsiEsc[106m"
        Green         = "$AnsiEsc[42m"
        BrightGreen   = "$AnsiEsc[102m"
        Yellow        = "$AnsiEsc[43m"
        BrightYellow  = "$AnsiEsc[103m"
    }
    Formatting   = @{
        FormatAccent           = "$AnsiEsc[32;1m"
        ErrorAccent            = "$AnsiEsc[36;1m"
        Error                  = "$AnsiEsc[31;1m"
        Warning                = "$AnsiEsc[35m"
        Verbose                = "$AnsiEsc[33;1m"
        Debug                  = "$AnsiEsc[94m"
        TableHeader            = "$AnsiEsc[32;1m"
        CustomTableHeaderLabel = "$AnsiEsc[32;1;3m"
        FeedbackName           = "$AnsiEsc[33m"
        FeedbackText           = "$AnsiEsc[96m"
        FeedbackAction         = "$AnsiEsc[97m"
    }
}

$DefaultStyle = "$($AnsiStyle.Reset)$($AnsiStyle.Foreground.White)"
$EmphStyle = "$($AnsiStyle.Reset)$($AnsiStyle.Foreground.BrightBlue)"

$EmphStart = '<em>'
$EmphEnd = '</em>'
$BoldStart = '<b>'
$BoldEnd = '</b>'
$UnderlineStart = '<u>'
$UnderlineEnd = '</u>'
#endregion script stuff



#region exported functions
function Clear-LogAction {
    $Script:ActionLevel = 0
    $Script:Stack = [collections.stack]::new()
}

function ConvertFrom-FormattedText {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'Default')]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'WithNoColor')]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'WithRaw')]
        [string]$Text,
        [Parameter(Mandatory, ParameterSetName = 'WithNoColor')]
        [switch]$AsPlainText,
        [Parameter(Mandatory, ParameterSetName = 'WithRaw')]
        [switch]$Raw
    )

    $Text = $DefaultStyle + $Text

    if ($AsPlainText.IsPresent) {
        $Text = $Text -replace $EmphStart, '*'
        $Text = $Text -replace $EmphEnd, '*'
        $Text = $Text -replace $BoldStart, '**'
        $Text = $Text -replace $BoldEnd, '**'
        $Text = $Text -replace $UnderlineStart, ''
        $Text = $Text -replace $UnderlineEnd, ''
    }
    else {
        $Text = $Text -replace $EmphStart, $EmphStyle
        $Text = $Text -replace $EmphEnd, $DefaultStyle
        $Text = $Text -replace $BoldStart, $AnsiStyle.Bold
        $Text = $Text -replace $BoldEnd, $AnsiStyle.BoldOff
        $Text = $Text -replace $UnderlineStart, $AnsiStyle.Underline
        $Text = $Text -replace $UnderlineEnd, $AnsiStyle.UnderlineOff

        $RawText = $Text -replace $AnsiEsc, $AnsiEscDisplay
    }
    
    $Text = "$Text$($AnsiStyle.Reset)"

    Write-verbose "Text: $RawText"

    if ($Raw.IsPresent) {
        $RawText
    }
    else {
        $Text
    }
}

function Format-Emhpasis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    "$($EmphStart)$Text$($EmphEnd)"
}

function Format-Bold {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    "$($BoldStart)$Text$($BoldEnd)"
}

function Format-Underline {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $Builder = [Collections.ArrayList]::new()
    $Chars = $Text.ToCharArray()
    
    $AreDropping = $Chars[0] -cin 'g', 'j', 'p', 'q', 'y'
    
    if (!$AreDropping) {
        $Builder.Add($UnderlineStart) | Out-Null
    }

    for ($i = 0; $i -lt $Chars.Count; $i++) {
        $Char = $Chars[$i]
        $IsDropChar = $Char -cin 'g', 'j', 'p', 'q', 'y'

        if ($IsDropChar) {
            if (!$AreDropping) {
                $Builder.Add($UnderlineEnd)  | Out-Null
            }
        }
        else {
            if ($AreDropping) {
                $Builder.Add($UnderlineStart)  | Out-Null
            }
        }

        $Builder.Add($Char) | Out-Null
        $AreDropping = $IsDropChar
    }

    # foreach ($Char in $Chars) {

    #     $IsDrop = $Char -cin 'g', 'j', 'p', 'q', 'y'

    #     if($WasDrop -and !$IsDrop){
    #         $Builder.Add($UnderlineStart)  | Out-Null
    #     }

    #     $Builder.Add($Char) | Out-Null
        
    #     $WasDrop = $IsDrop
    # }

    if (!$AreDropping) {
        $Builder.Add($UnderlineEnd)  | Out-Null
    }

    $Ret = $Builder -join ''

    $Ret
}
function Get-ActionLevel {
    $Script:ActionLevel
}

function Get-AnsiStyle {
    [CmdletBinding()]
    param()

    $Script:AnsiStyle
}

function Get-LogOptions {
    $Script:LogOptions
}

function Get-LogTargetStream {
    param()

    $Script:LogTarget 
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
    $Tokens = $Text, $LogOptions.actionStartSuffix

    Write-LogEntry ($Tokens -join ' ')
}

function Pop-LogAction {
    param(
       
    )

    Write-Verbose "Stack count: $($Script:Stack.Count)" #-verbose
    
    if ($Script:Stack.Count -gt 0) {
        # if ($null -ne $Script:Stack.Peek()) {
        $Item = $Script:Stack.Pop()
        Write-verbose "item $($Item | ConvertTo-Json -Compress)" #-Verbose
            
        $Tokens = $Item.Text, "$($AnsiStyle.Foreground.Green)$($Script:LogOptions.actionCompletedSuffix)$($AnsiStyle.Reset)$DefaultStyle"
            
        Write-LogEntry ($Tokens -join ' ') 
            
        if ($Item.LevelIncremented) {
            $Script:ActionLevel = if ($Script:ActionLevel -gt 0) { $Script:ActionLevel - 1 } else { 0 }
                
        }
        
    }
}

function Save-LogOptions {
    [CmdletBinding()]
    param()

     $Script:LogOptions | ConvertTo-Json | Out-File "$HOME/.pave-logger" -Encoding 'utf8'

}
function Set-LogOptions {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [string]$ActionCompletedSuffix = $Script:LogOptions.actionCompletedSuffix,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [string]$ActionStartSuffix = $Script:LogOptions.ActionStartSuffix,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [string]$Bold = $Script:LogOptions.Bold.Bold,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [string]$Emph = $Script:LogOptions.Emph.Emph,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [string]$HeaderChar = $Script:LogOptions.HeaderChar.HeaderChar,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [string]$InfoPrefix = $Script:LogOptions.InfoPrefix,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [string]$LevelChar = $Script:LogOptions.LevelChar,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [int]$MaxLineLength = $Script:LogOptions.MaxLineLength,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [string]$PadChar = $Script:LogOptions.PadChar,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [string]$SubheaderChar = $Script:LogOptions.SubheaderChar,

        [Parameter(ParameterSetName = "SetIndividualValues", ValueFromPipelineByPropertyName)]
        [switch]$ShowTimestamp = $Script:LogOptions.ShowTimestamp,

        [Parameter(ParameterSetName = "SetIndividualValues")]
        [switch]$Save,

        [Parameter(ParameterSetName = "FromConfigFile", Mandatory)]
        [switch]$FromConfigFile
    )

    Write-Verbose "Supplied values: $($PSBoundParameters | ConvertTo-Json -Compress -Depth 2)"
    Write-Verbose "Before: $($LogOptions | ConvertTo-Json -Compress)"

    if ($PSCmdlet.ParameterSetName -eq 'FromConfigFile') {
        if (Test-Path "$HOME/.pave-logger") {
            $Script:LogOptions = gc -raw "$HOME/.pave-logger" -Encoding 'utf8' | ConvertFrom-Json
        } else {
            throw "Config file $HOME/.pave-logger not found."
        }
    }
    else {
        $Updates = @{}
        $Keys = $Script:LogOptions.Keys

        $Script:LogOptions.Keys | % {
            if ($PSBoundParameters.Keys -contains $_) {
                $Value = $PSBoundParameters[$_]

                if ($_ -eq 'ShowTimestamp') {
                    $Updates.Add($_, $Value.IsPresent)
                }
                else {
                    $Updates.Add($_, $Value)
                }
            }
        }

        $Updates.GetEnumerator() | % {
            $Script:LogOptions[$_.Key] = $_.Value
        }

        Write-Verbose "After: $($LogOptions | ConvertTo-Json -Compress)"

        if ($Save.IsPresent) {
           Save-LogOptions
        }
    }
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
        [switch]$NoColor,
        [switch]$IgnoreActionLevel
    )

    Write-verbose "message: $Message" #-Verbose

    if ($NoColor.IsPresent) {
        $Message = GetNoColorText $Message
    }

    $Message = "$($DefaultStyle)$Message"

    if ($Script:ActionLevel -gt 0 -and !$IgnoreActionLevel.IsPresent ) {
        $Message = ($Script:LogOptions.levelChar * $Script:ActionLevel) + ' ' + $Message
    }

    if ($LogOptions.timestamp) {
        $Timestamp = get-date -Format 'u'
    
        if (!$NoColor.IsPresent) {
            $Timestamp = "$($AnsiStyle.Reset)$($AnsiStyle.Foreground.BrightBlack)$Timestamp$($AnsiStyle.Reset)"
        }
            
        $Message = "$($DefaultStyle)$Timestamp $Message"
    } 

    switch ($Script:LogTarget) {
        { $_ -in 'Default', 'Information' } {  
            if (!$NoColor.IsPresent) {
                $Message = $Message -replace $EmphStart, $EmphStyle
                $Message = $Message -replace $EmphEnd, $DefaultStyle
                $Message = $Message -replace $BoldStart, $AnsiStyle.Bold
                $Message = $Message -replace $BoldEnd, $AnsiStyle.BoldOff
                $Message = $Message -replace $UnderlineStart, $AnsiStyle.Underline
                $Message = $Message -replace $UnderlineEnd, $AnsiStyle.UnderlineOff
                
            }
            
            $Message = "$Message$($AnsiStyle.Reset)"
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

function Write-LogHeader {
    param(
        [Parameter(ParameterSetName = 'default', Position = 0)]
        [Parameter(ParameterSetName = 'SpecificChar', Position = 0)]
        [string]$Text,
        [Parameter(ParameterSetName = 'default')]
        [switch]$Subheader,
        [Parameter(Mandatory, ParameterSetName = 'SpecificChar')]
        [string]$HeaderChar,
        [switch]$NoColor
    )

    $WindowSize = [Math]::Min($Host.UI.RawUI.WindowSize.Width, $Script:LogOptions.maxLineLength) - 3

    if ([string]::IsNullOrWhiteSpace($HeaderChar)) {
        $HeaderChar = if ($Subheader.IsPresent) {
            $Script:LogOptions.subHeaderChar
        }
        else {
            $Script:LogOptions.headerChar
        }
    }

    if ($Script:LogOptions.timestamp) {
        $WindowSize -= 21
    }

    if ($Text.Length -eq 0) {
        Write-LogEntry "$($HeaderChar * $WindowSize)" -IgnoreActionLevel
    }
    else {   
        $TextLength = if ($NoColor.IsPresent) { (GetNoColorText $Text).Length } else { (GetNoFormatText $Text).Length }    
        $Pre = [int](($WindowSize - ($TextLength + 2)) / 2)
        $Post = $WindowSize - ($Pre + $TextLength + 2)
        Write-LogEntry "$($HeaderChar * $Pre) $Text $($HeaderChar * $Post)" -IgnoreActionLevel -NoColor:$NoColor
    }
}

function Write-LogSubheader {
    param(
        [string]$Text
    )

    Write-LogHeader -Text $Text -Subheader
}
#endregion exported functions

#region non-exported functions
function GetNoColorText {
    param (
        [string]$Text
    )
    $Text = $Text -replace $EmphStart, '*'
    $Text = $Text -replace $EmphEnd, '*'
    $Text = $Text -replace $BoldStart, '**'
    $Text = $Text -replace $BoldEnd, '**'
    $Text = $Text -replace $UnderlineStart, '~'
    $Text = $Text -replace $UnderlineEnd, '~'
    $Text
}

function GetNoFormatText {
    param (
        [string]$Text
    )
    $Text = $Text -replace '</{0,1}\w+>', ''
    $Text
}
#endregion non-exported function

#region init
if (Test-Path "$HOME/.pave-logger") {
    # get from ~/.pave-logger
    $LogOptions = gc -raw "$HOME/.pave-logger" -Encoding 'utf8' | ConvertFrom-Yaml -Ordered
}
else {
    $LogOptions | ConvertTo-Json | Out-File "$HOME/.pave-logger" -Encoding 'utf8'
}
#endregion init

Set-Alias log Write-LogEntry
set-alias logh Write-LogHeader
set-alias logsh Write-LogSubheader
set-alias pusha Push-LogAction
set-alias popa Pop-LogAction
set-alias em Format-Emhpasis
set-alias emph Format-Emhpasis
set-alias b Format-Bold
set-alias bold Format-Bold
set-alias u Format-Underline
set-alias under Format-Underline
set-alias cfft ConvertFrom-FormattedText