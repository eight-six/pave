#Requires -version 5.1 # Windows Powershell
#Requires -Modules powershell-yaml

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$Script:ActionLevel = 0
$Script:Stack = [collections.stack]::new()
$Script:LogTarget = 'Information'


$LogOptions = [ordered]@{
    actionCompletedSuffix = '✓'
    actionStartSuffix     = '…'
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

function Write-LogEntry {
    param (
        [string]$Message,
        [switch]$NoColor,
        [switch]$IgnoreActionLevel
    )

    Write-verbose "message: $Message" #-Verbose

    $Message = "$($DefaultStyle)$Message"

    if ($Script:ActionLevel -gt 0 -and !$IgnoreActionLevel.IsPresent ) {
        $Message = ($Script:LogOptions.levelChar * $Script:ActionLevel) + ' ' + $Message
    }

    if ($LogOptions.timestamp) {
        $Message = "$($AnsiColor.Reset)$($AnsiColor.Foreground.BrightBlack)$(get-date -Format 'u')$($AnsiColor.Reset) $Message"
    } 

    switch ($Script:LogTarget) {
        { $_ -in 'Default', 'Information' } {  
            if ($NoColor.IsPresent) {
                $Message = $Message -replace $EmphStart, '*'
                $Message = $Message -replace $EmphEnd, '*'
            }
            else {
                $Message = $Message -replace $EmphStart, $EmphStyle
                $Message = $Message -replace $EmphEnd, $DefaultStyle
                $Message = $Message -replace $BoldStart, $AnsiColor.Bold
                $Message = $Message -replace $BoldEnd, $AnsiColor.BoldOff
                $Message = $Message -replace $UnderlineStart, $AnsiColor.Underline
                $Message = $Message -replace $UnderlineEnd, $AnsiColor.UnderlineOff
                
                $Message = "$Message$($AnsiColor.Reset)"
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
function Write-LogHeader {
    param(
        [Parameter(ParameterSetName='default', Position = 0)]
        [Parameter(ParameterSetName='SpecificChar', Position = 0)]
        [string]$Text,
        [Parameter(ParameterSetName='default')]
        [switch]$Subheader,
        [Parameter(Mandatory,ParameterSetName='SpecificChar')]
        [string]$HeaderChar 
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
        $Pre = [int](($WindowSize - ($Text.Length + 2)) / 2)
        $Post = $WindowSize - ($Pre + $Text.Length + 2)
        Write-LogEntry "$($HeaderChar * $Pre) $Text $($HeaderChar * $Post)" -IgnoreActionLevel
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
    $LogOptions | ConvertTo-Yaml | Out-File "$HOME/.pave-logger" -Encoding 'utf8'
}

Set-Alias log Write-LogEntry
set-alias logh Write-LogHeader
set-alias logsh Write-LogSubheader
set-alias pusha Push-LogAction
set-alias popa Pop-LogAction
