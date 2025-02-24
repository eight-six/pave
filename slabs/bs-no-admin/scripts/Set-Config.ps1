param(
    [Parameter(Mandatory)]
    [string]$Org,
    [Parameter(Mandatory)]
    [string]$Repo,
    [Parameter(Mandatory)]
    [string]$Path,
    [string[]]$Include,
    [string[]]$Exclude,
    [switch]$DotSource,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

Write-Verbose "Include is null: $($null -eq $Include)"slabs\bs-no-admin\scripts\Set-Config.ps1
Write-Verbose "Exclude is null: $($null -eq $Exclude)"

if ($Env:Path[-1] -ne ';') {
    $Env:Path += ';'
}

$Header = 'applying configs'
Write-LogHeader $Header

if ($Test.IsPresent) {
    Write-LogEntry "Test Mode"
}

#region clone config repo
$GitCmd = 'git'

if ($null -eq (gcm $GitCmd -ea 'Ignore')) {
    $GitCmd = "$Env:LOCALAPPDATA\Programs\git\bin\git.exe"

    if (!(Test-Path $GitCmd)) {
        throw "git not found on path or at $(em $GitCmd)"
    }
}

$Proxy = [System.Net.WebRequest]::GetSystemWebProxy().GetProxy('https://github.com')
$AdditionalArgs = if ($null -ne $Proxy) { "-c http.proxy=$($Proxy.OriginalString)" }else { $null }

$RepoLocal = "$($PWD.Path)\$Repo"

if (Test-Path $RepoLocal) {
    Push-LogAction "deleting existing clone $(em $RepoLocal)"
    rm -Recurse -Force $RepoLocal
    Pop-LogAction
}

$Uri = "https://github.com/$Org/$Repo"
Push-LogAction "cloning $(em $uri) into $(em $RepoLocal)"
& $GitCmd clone $AdditionalArgs "$Uri"
Pop-LogAction
#endregion

#region applying configs
Push-LogAction "applying configs from $(em $RepoLocal)"

$ConfigsRoot = "$RepoLocal\configs\$Path"
$ConfigsToApply = ls $ConfigsRoot  -Directory -Name -Include $Include -Exclude $Exclude
Write-Verbose "looking for configs in $ConfigsRoot" -Verbose
Write-Verbose "Including: $( $Include -join ',') " -Verbose
Write-Verbose "Excluding: $( $Exclude -join ',') " -Verbose
Write-Verbose "Applying: $($ConfigsToApply  -join ',') " -Verbose
#region applying each config
$Comment = if ($DotSource.IsPresent) { "dot sourcing configs" }else { "applying configs" }
Push-LogAction $Comment

$ConfigsToApply | % {
    $Config = Join-Path $ConfigsRoot  (Join-Path $_ 'doit.ps1')
    #region apply config
    $Comment = if ($DotSource.IsPresent) { "dot sourcing" }else { "calling" }
    Push-LogAction "$Comment $(em $Config)"

    if ($Test.IsPresent) {
        Write-LogEntry "Test mode - file exists: $(Test-Path $Config )"
    }
    else {
        if ($DotSource.IsPresent) {
            . $Config
        }
        else {
            & $Config
        }
    }

    Pop-LogAction
    #endregion
}

Pop-LogAction
#endregion

Pop-LogAction
#endregion

Write-LogHeader "$Header - completed"   