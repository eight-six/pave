#Requires -version 5.1 # Windows Powershell
#Requires -Modules pave-logger

using namespace System
using namespace System.Net

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'

New-Variable -Name 'ENV_VAR_PATH' -Value 'PATH' -Option Constant -Scope 'Script'

function Add-UserEnvVar {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$Name,
        [string]$Value,
        [switch]$AddToCurrentSession
    )
    
    if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
        $WhatIfPreference = $PSCmdlet.GetVariableValue('WhatIfPreference')
    }

    if ($PSCmdlet.ShouldProcess("$Name", "set user scope env var")) {
        [System.Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::User)

        if ($AddToCurrentSession.IsPresent) {
            Set-Item -Path "env:$name" -Value $Value  | Out-Null 
        }
    }
}

function Add-UserPath {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$PathToAdd,
        [switch]$AtStart,
        [switch]$AddToCurrentSession
    )

    if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
        $WhatIfPreference = $PSCmdlet.GetVariableValue('WhatIfPreference')
    }

    if ($PSCmdlet.ShouldProcess("$PathToAdd", "add user scope path")) {
        Write-Verbose "PathToAdd = ``$PathToAdd``"

        $UserPaths = [Environment]::GetEnvironmentVariable($Script:ENV_VAR_PATH , [EnvironmentVariableTarget]::User) -split [io.path]::PathSeparator | 
        ? { ![string]::IsNullOrWhiteSpace($_) } | 
        select -Unique

        $HasChanged = $false

        if ($UserPaths -notcontains $PathToAdd) {
            $HasChanged = $true
            if ($AtStart.IsPresent) {
                $UserPaths = , $PathToAdd + $UserPaths
            }
            else {
                $UserPaths = $UserPaths + $PathToAdd
            }
        }
        else {
            Write-Verbose "UserPaths[0]: ``$($UserPaths[0])``"
            Write-Verbose "First user path equals path to add: $($UserPaths[0] -eq $PathToAdd)"
        
            if ($AtStart.IsPresent -and ($UserPaths[0] -ne $PathToAdd)) {
                $HasChanged = $true
                $UserPaths = , $PathToAdd + ($UserPaths | ? { $_ -ne $PathToAdd })
            }
        }
    
        Write-Verbose "has changed: $HasChanged"
        Write-Verbose "user path: $($UserPaths -join ';')"

        if ($HasChanged) {
            if (!(Test-Path $PathToAdd)) {
                Write-Warning "Path: $PathToAdd does not exist"
            }

            $NewPath = "$($UserPaths -join [IO.Path]::PathSeparator)$([IO.Path]::PathSeparator)"
            Write-Verbose "new path: ``$NewPath``)"
            Write-Verbose "target: ``$Script:ENV_VAR_PATH``)"

            Add-UserEnvVar -Name $Script:ENV_VAR_PATH -Value $NewPath

            if ($AddToCurrentSession.IsPresent) {
                Update-PathEnvVar
            }
        }
    }
}

function Get-Download {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,
        
        [switch]$Force,

        [switch]$NoFallback
    )

    if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
        $WhatIfPreference = $PSCmdlet.GetVariableValue('WhatIfPreference')
    }

    if ($PSCmdlet.ShouldProcess("$Uri -> $FilePath", "download file")) {
        $DownloadRoot = Split-Path $FilePath -Parent

        if (!(Test-Path $DownloadRoot)) {
            md $DownloadRoot | Out-Null
        } 
        
        $DownloadPath = Resolve-Path (Split-Path $FilePath -Parent) | select -exp Path
        $FileName = Split-Path $FilePath -Leaf

        if (-not $Force.IsPresent -and ($DownloadPath -eq (Resolve-Path $Env:PAVE_DOWNLOAD_CACHE)) -and (Test-Path $FilePath)) {
            Write-LogEntry "$($AnsiColors.Formatting.Warning)File $(em $FileName) already exists in download cache. Use $(em '-Force') to re-download$($AnsiColors.Reset)"
        }
        else {
            try {
                Start-BitsTransfer $Uri $FilePath
            }
            catch [Runtime.InteropServices.COMException] {
                Write-LogEntry "Download of $(emph $Uri) failed with $(emph 'Start-BitsTransfer') - error message: $(under $_.Exception.Message)"
    
                if ($_.Exception.Message -notmatch 'MUI Entry') {
                    throw $_
                }
            
                if (!$NoFallback.IsPresent) {
                    Write-LogEntry "Start-BitsTransfer failed, trying $(emph Invoke-WebRequest)"
                    iwr $Uri -OutFile $FilePath 
                    Write-LogEntry "Download of $(emph $Uri) with $(emph Invoke-WebRequest) succeeded."
                }
            }
        }
    }
}

function GetArgsString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [hashtable]$Arguments,

        [switch]$NoQoutes
    )

    $Builder = [Collections.ArrayList]::new()

    $Arguments.GetEnumerator() | % {
  
        Write-Verbose "$($_.Value.GetType().Name)" #-Verbose
        $RawValue = $_.Value
        $TypeName = $RawValue.GetType().Name
        Write-Verbose $TypeName #-Verbose
        switch ( $TypeName) {
            'Object[]' {
                $Value = "`"$(($RawValue -as [string[]])  -Join ',')`""
                break
            }

            'String[]' {
                $Value = "`"$($RawValue  -Join ',')`""
                break
            }
            
            'DateTime' {
                $Value = "'$($RawValue.ToUniversalTime().ToString('s'))Z'"
                break
            }
            
            { $_ -in 'Byte', 'Int16', 'Int32', 'Single', 'Double' } {
                $Value = $RawValue
                break
            }

            'Int64' {
                $Value = "$($RawValue)l"
                break
            }

            'Decimal' {
                $Value = "$($RawValue)d"
                break
            }

            'BigInteger' {
                $Value = "$($RawValue)n"
                break
            }

            Default {
                Write-Verbose "Default" #-Verbose
                $Value = "'$($RawValue.ToString())'"
                break
            }
        }

        $Builder.Add("-$($_.Key) $Value") | Out-Null
    }

    $ArgString = $Builder -join ' '

    if (!$NoQoutes.IsPresent) {
        $ArgString = "`"$ArgString`"" 
    }

    Write-Verbose $ArgString #-Verbose

    $ArgString
}

function Get-Proxy {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TestUri
    )

    $Ret = $null
    $Uri = ""

    if (!([Uri]::TryCreate($TestUri, [UriKind]::Absolute, [ref] $Uri))) {
        throw "TestUri '$TestUri' is not a valid absolute uri."
    }

    $Proxy = ([System.Net.WebRequest]::GetSystemWebProxy().GetProxy($TestUri))

    if ($null -ne $Proxy -and $Proxy.OriginalString -ne $TestUri) {
        $Ret = $Proxy.OriginalString
    }

    $Ret
}
function Invoke-Pwsh {
    [CmdletBinding(DefaultParameterSetName = 'WithFile', SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName = 'WithFile', Mandatory, Position = 0)]
        [string]$FilePath,

        [Parameter(ParameterSetName = 'WithScriptBlock', Mandatory)]
        [ScriptBlock]$ScriptBlock,

        [Parameter(ParameterSetName = 'WithCommandText', Mandatory)]
        [string]$CommandText,

        [Parameter(ParameterSetName = 'WithFile')]
        [hashtable]$Arguments,

        [ValidateNotNullOrEmpty()]
        [string]$PwshFilePath
        # ,

        # [ValidateNotNullOrEmpty()]
        # [switch]$NoFallback

    )

    Write-Verbose "ParameterSetName: $($PSCmdlet.ParameterSetName)" -Verbose
    Write-Verbose "PSBoundParameters: $($PSBoundParameters.Keys -Join ',')" -Verbose

    if ($PSBoundParameters.ContainsKey('PwshFilePath')) {
        $PwshPath = $PwshFilePath

        if (!(Test-Path $PwshPath)) {
            throw "pwsh not found at at location specifed by param PwshFilePath - $PwshPath"
        }

        Write-Verbose "Using param PwshFilePath [$PwshFilePath]" -Verbose
    } elseif(![string]::IsNullOrEmpty($Env:PWSH_DEFAULT_PATH))  {
        $PwshPath = $Env:PWSH_DEFAULT_PATH

        if (!(Test-Path $PwshPath)) {
            throw "pwsh not found at at location specifed by `$env:PWSH_DEFAULT_PATH - $env:PWSH_DEFAULT_PATH"
        }

        Write-Verbose "Using $Env:PWSH_DEFAULT_PATH [$PwshFilePath]" -Verbose

    } else {
        $PwshPath = (gcm pwsh -ErrorAction 'Ignore') | select -exp Name

        if ([string]::IsNullOrEmpty($PwshPath)) {
            throw 'env var PWSH_DEFAULT_PATH not found and no pwsh found on PATH'
        }
        $FullPath = (gcm pwsh -ErrorAction 'Ignore') | select -exp Path
        Write-Verbose "Using pwsh found on PATH [$FullPath]" -Verbose
    }
    
    $Version = & $PwshPath '-V'
    Write-Verbose "PwshPath: $PwshPath : Version $Version" -Verbose

    switch ($PSCmdlet.ParameterSetName) {
        'WithScriptBlock' { 
            Write-Verbose "& $PwshPath -NoProfile -Command {$ScriptBlock}" -Verbose

            if ($PSCmdlet.ShouldProcess("scriptblock", "execute")) {
                & $PwshPath -NoProfile -Command $ScriptBlock
            } 
        }
        'WithCommandText' {
            Write-Verbose "& $PwshPath -NoProfile -Command $CommandText" -Verbose

            if ($PSCmdlet.ShouldProcess("CommandText", "execute")) {
                & $PwshPath -NoProfile -Command $CommandText
            } 
        }
        'WithFile' { 
            if ($null -eq $Arguments) {
                & $PwshPath -NoProfile -File $FilePath 
            }
            else {
                Write-Verbose "ParameterSetName: $($Arguments | ConvertTo-Json -Compress)"

                #& $PwshPath -NoProfile -Command $FilePath (GetArgsString $Arguments)
            }
        }
        Default {
            throw "Unknown parameter set: $($PSCmdlet.ParameterSetName)"
        }
    }
    
    if ($LASTEXITCODE -ne 0) {
        $ErrorMessage = "Running $(em $FilePath ) with $(em $PwshPath ) failed with exit code $(em $LASTEXITCODE)."
        Write-LogEntry $ErrorMessage -IgnoreActionLevel
        throw $ErrorMessage
    }

    Update-PathEnvVar 
}

function Update-PathEnvVar {
    [CmdletBinding(SupportsShouldProcess)]
    param(
    )
    <#
    .SYNOPSIS
    Updates the PATH env var from the latest MACHINE and USER settings
    
    .DESCRIPTION
    Long description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>

    if ($PSCmdlet.ShouldProcess("PATH", "refesh")) {
        $MachinePath = [System.Environment]::GetEnvironmentVariable($Script:ENV_VAR_PATH, [EnvironmentVariableTarget]::Machine)
        Write-verbose "machine path: $MachinePath"
        $UserPath = [System.Environment]::GetEnvironmentVariable($Script:ENV_VAR_PATH, [EnvironmentVariableTarget]::User)
        Write-verbose "user path: $UserPath"

        $Sep = if ($MachinePath[-1] -ne '; ') { '; ' }else { '' }
        $EffectivePath = $MachinePath + $Sep + $UserPath
        Write-verbose "new effective path: $EffectivePath"
        Set-Item -Path "env:\$Script:ENV_VAR_PATH" -Value $EffectivePath -force
    }
}                                                                                                                                                                                                                    

<#
    .SYNOPSIS
    Updates the specifed env var from the latest USER env settings
    
    .DESCRIPTION
    
    
    .EXAMPLE
    
    
    .NOTES
    
#>
function Update-UserEnvVar {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )
 
    if ($PSCmdlet.ShouldProcess("$Name", "refesh")) {
        $Value = [System.Environment]::GetEnvironmentVariable($Name, [EnvironmentVariableTarget]::User)
        Write-verbose "$Name : $Value"
        
        Set-Item -Path "env:\$Name" -Value $Value -force
    }
} 