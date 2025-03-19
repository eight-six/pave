#Requires -version 5.1 # Windows Powershell
#Requires -Modules powershell-yaml

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

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
    timestamp             = $true
}

$AnsiEsc = [char]27

$AnsiColors = [ordered]@{
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

$DefaultStyle = "$($AnsiColors.Reset)$($AnsiColors.Foreground.White)"
$EmphStyle = "$($AnsiColors.Reset)$($AnsiColors.Foreground.BrightBlue)"


$EmphStart = '<em>'
$EmphEnd = '</em>'
$BoldStart = '<b>'
$BoldEnd = '</b>'
$UnderlineStart = '<u>'
$UnderlineEnd = '</u>'

function Get-ActionLevel {
    $Script:ActionLevel
}

function Set-LogTargetStream {
    param(
        [ValidateSet('Default', 'Information', 'Output', 'Host')]
        [string]$Target 
    )

    $Script:LogTarget = $Target
}

function Clear-LogAction {
    $Script:ActionLevel = 0
    $Script:Stack = [collections.stack]::new()
}

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
            $Timestamp = "$($AnsiColors.Reset)$($AnsiColors.Foreground.BrightBlack)$Timestamp$($AnsiColors.Reset)"
        }
            
        $Message = "$($DefaultStyle)$Timestamp $Message"
    } 

    switch ($Script:LogTarget) {
        { $_ -in 'Default', 'Information' } {  
            if (!$NoColor.IsPresent) {
                $Message = $Message -replace $EmphStart, $EmphStyle
                $Message = $Message -replace $EmphEnd, $DefaultStyle
                $Message = $Message -replace $BoldStart, $AnsiColors.Bold
                $Message = $Message -replace $BoldEnd, $AnsiColors.BoldOff
                $Message = $Message -replace $UnderlineStart, $AnsiColors.Underline
                $Message = $Message -replace $UnderlineEnd, $AnsiColors.UnderlineOff
                
            }
            
            $Message = "$Message$($AnsiColors.Reset)"
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
            
        $Tokens = $Item.Text, "$($AnsiColors.Foreground.Green)$($Script:LogOptions.actionCompletedSuffix)$($AnsiColors.Reset)$DefaultStyle"
            
        Write-LogEntry ($Tokens -join ' ') 
            
        if ($Item.LevelIncremented) {
            $Script:ActionLevel = if ($Script:ActionLevel -gt 0) { $Script:ActionLevel - 1 } else { 0 }
                
        }
        
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
    
    "$($UnderlineStart)$Text$($UnderlineEnd)"
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

function Get-LogOptions {
    $Script:LogOptions
}

if (Test-Path "$HOME/.pave-logger") {
    # get from ~/.pave-logger
    $LogOptions = gc -raw "$HOME/.pave-logger" -Encoding 'utf8' | ConvertFrom-Yaml -Ordered
}
else {
    $LogOptions | ConvertTo-Json | Out-File "$HOME/.pave-logger" -Encoding 'utf8'
}

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