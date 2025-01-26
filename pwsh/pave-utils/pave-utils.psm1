#Requires -version 5.1 # Windows Powershell

using namespace System

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

New-Variable -Name 'ENV_VAR_PATH' -Value 'PATH' -Option Constant -Scope 'Script'

function Add-UserEnvVar {
    param (
        [string]$Name,
        [string]$Value,
        [switch]$AddToCurrentSession
    )

    [System.Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::User)

    if ($AddToCurrentSession.IsPresent) {
        New-Item -Path env: -Name $name -Value $Name  | Out-Null 
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
    $EffectivePath = $MachinePath + $UserPath
    Write-verbose "new effective path: $EffectivePath"
    Set-Item -Path "env:\$Script:ENV_VAR_PATH" -Value $EffectivePath -force
}