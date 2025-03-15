#Requires -version 5.1 # Windows Powershell
#Requires -Modules pave-logger

using namespace System

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'

New-Variable -Name 'ENV_VAR_PATH' -Value 'PATH' -Option Constant -Scope 'Script'

function Add-UserEnvVar {
    param (
        [string]$Name,
        [string]$Value,
        [switch]$AddToCurrentSession
    )

    [System.Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::User)

    if ($AddToCurrentSession.IsPresent) {
        Set-Item -Path "env:$name" -Value $Value  | Out-Null 
    }
}

function Add-UserPath {
    param (
        [string]$PathToAdd,
        [switch]$AtStart,
        [switch]$AddToCurrentSession
    )
	
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
        if(!(Test-Path $PathToAdd)){
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

function Get-Download {
    param (
        [string]$Uri,
        [string]$FilePath,
        [switch]$NoFallback
    )


    try {
        Start-BitsTransfer $Uri $FilePath
    }
    catch [Runtime.InteropServices.COMException] {
        Write-LogEntry "Download of $(emph $Uri) failed with $(emph 'Start-BitsTransfer') - error message: $(under $_.Exception.Message)"
    
        if ($_.Exception.Message -notmatch 'MUI Entry') {
            throw $_
        }
        else {
            Write-LogEntry "Start-BitsTransfer failed, trying $(emph Invoke-WebRequest)"
            iwr $Uri -OutFile $FilePath 
            Write-LogEntry "Download of $(emph $Uri) with $(emph Invoke-WebRequest) succeeded."
        }
    }
}

function Invoke-Pwsh {
    [CmdletBinding(DefaultParameterSetName='WithFile')]
    param(

        [Parameter(ParameterSetName = 'WithFile', Mandatory, Position=0)]
        [string]$FilePath,
        [Parameter(ParameterSetName = 'WithScriptBlock', Mandatory)]
        [ScriptBlock]$ScriptBlock,
        [Parameter(ParameterSetName = 'WithCommand', Mandatory)]
        [string]$CommandText
    )

    $PwshPath = "$Env:LocalAppData\powershell\$Env:PAVE_PWSH_VERSION\pwsh"

    if ($ScriptBlock.IsPresent) {
        & $PwshPath -NoProfile -Command $ScriptBlock 
    }
    if ($WithCommand.IsPresent) {
        & $PwshPath -NoProfile -Command $CommandText
    }
    else {
        & $PwshPath -NoProfile -File $FilePath 
    }
    
    if ($LASTEXITCODE -ne 0) {
        $ErrorMessage = "Running $(em $FilePath ) with $(em $PwshPath ) failed with exit code $(em $LASTEXITCODE)."
        Write-LogEntry $ErrorMessage -IgnoreActionLevel
        throw $ErrorMessage
    }

    Update-PathEnvVar 

}

function Update-PathEnvVar {
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
    $MachinePath = [System.Environment]::GetEnvironmentVariable($Script:ENV_VAR_PATH, [EnvironmentVariableTarget]::Machine)
    Write-verbose "machine path: $MachinePath"
    $UserPath = [System.Environment]::GetEnvironmentVariable($Script:ENV_VAR_PATH, [EnvironmentVariableTarget]::User)
    Write-verbose "user path: $UserPath"

    $Sep = if($MachinePath[-1] -ne ';'){';'}else{''}
    $EffectivePath = $MachinePath + $Sep + $UserPath
    Write-verbose "new effective path: $EffectivePath"
    Set-Item -Path "env:\$Script:ENV_VAR_PATH" -Value $EffectivePath -force
}                                                                                                                                                                                                                    