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

$ESC = [char]27

$AnsiColor = [ordered]@{
    Reset        = "$ESC[0m"
    Bold         = "$ESC[1m"
    BoldOff      = "$ESC[22m"
    Underline    = "$ESC[4m"
    UnderlineOff = "$ESC[24m"
    Foreground   = @{
        Black         = "$ESC[30m"
        BrightBlack   = "$ESC[90m"
        White         = "$ESC[37m"
        BrightWhite   = "$ESC[97m"
        Red           = "$ESC[31m"
        BrightRed     = "$ESC[91m"
        Magenta       = "$ESC[35m"
        BrightMagenta = "$ESC[95m"
        Blue          = "$ESC[34m"
        BrightBlue    = "$ESC[94m"
        Cyan          = "$ESC[36m"
        BrightCyan    = "$ESC[96m"
        Green         = "$ESC[32m"
        BrightGreen   = "$ESC[92m"
        Yellow        = "$ESC[33m"
        BrightYellow  = "$ESC[93m"
    }
    Background   = @{
        Black         = "$ESC[40m"
        BrightBlack   = "$ESC[100m"
        White         = "$ESC[47m"
        BrightWhite   = "$ESC[107m"
        Red           = "$ESC[41m"
        BrightRed     = "$ESC[101m"
        Magenta       = "$ESC[45m"
        BrightMagenta = "$ESC[105m"
        Blue          = "$ESC[44m"
        BrightBlue    = "$ESC[104m"
        Cyan          = "$ESC[46m"
        BrightCyan    = "$ESC[106m"
        Green         = "$ESC[42m"
        BrightGreen   = "$ESC[102m"
        Yellow        = "$ESC[43m"
        BrightYellow  = "$ESC[103m"
    }
}

$DefaultStyle = "$($AnsiColor.Reset)$($AnsiColor.Foreground.White)"
$EmphStyle = "$($AnsiColor.Reset)$($AnsiColor.Foreground.BrightBlue)"


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

    if($NoColor.IsPresent){
        $Message = GetNoColorText $Message
    }

    $Message = "$($DefaultStyle)$Message"

    if ($Script:ActionLevel -gt 0 -and !$IgnoreActionLevel.IsPresent ) {
        $Message = ($Script:LogOptions.levelChar * $Script:ActionLevel) + ' ' + $Message
    }

    if ($LogOptions.timestamp) {
        $Timestamp = get-date -Format 'u'
    
        if(!$NoColor.IsPresent){
            $Timestamp = "$($AnsiColor.Reset)$($AnsiColor.Foreground.BrightBlack)$Timestamp$($AnsiColor.Reset)"
        }
            
        $Message = "$($DefaultStyle)$Timestamp $Message"
    } 

    switch ($Script:LogTarget) {
        { $_ -in 'Default', 'Information' } {  
            if (!$NoColor.IsPresent) {
                $Message = $Message -replace $EmphStart, $EmphStyle
                $Message = $Message -replace $EmphEnd, $DefaultStyle
                $Message = $Message -replace $BoldStart, $AnsiColor.Bold
                $Message = $Message -replace $BoldEnd, $AnsiColor.BoldOff
                $Message = $Message -replace $UnderlineStart, $AnsiColor.Underline
                $Message = $Message -replace $UnderlineEnd, $AnsiColor.UnderlineOff
                
            }
            
            $Message = "$Message$($AnsiColor.Reset)"
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
            
        $Tokens = $Item.Text, "$($AnsiColor.Foreground.Green)$($Script:LogOptions.actionCompletedSuffix)$($AnsiColor.Reset)$DefaultStyle"
            
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
        [Parameter(ParameterSetName='default', Position = 0)]
        [Parameter(ParameterSetName='SpecificChar', Position = 0)]
        [string]$Text,
        [Parameter(ParameterSetName='default')]
        [switch]$Subheader,
        [Parameter(Mandatory,ParameterSetName='SpecificChar')]
        [string]$HeaderChar,
        [switch]$NoColor
    )

    $WindowSize = [Math]::Min($Host.UI.RawUI.WindowSize.Width, $Script:LogOptions.maxLineLength) - 3

    if([string]::IsNullOrWhiteSpace($HeaderChar)){
        $HeaderChar = if ($Subheader.IsPresent){
            $Script:LogOptions.subHeaderChar
        } else {
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
        $TextLength = if($NoColor.IsPresent) {(GetNoColorText $Text).Length } else {(GetNoFormatText $Text).Length}    
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
    $LogOptions | ConvertTo-Json| Out-File "$HOME/.pave-logger" -Encoding 'utf8'
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
