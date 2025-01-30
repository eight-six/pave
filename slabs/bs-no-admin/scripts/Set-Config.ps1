param(
    [string]$Org,
    [string]$Repo,
    [string[]]$Configs,
    [string[]]$DotSourceConfigs,
    [switch]$Test

)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

if ($Env:Path[-1] -ne ';') {
    $Env:Path += ';'
}

$Header = 'applying configs'
Write-LogHeader $Header

if($Test.IsPresent){
    Write-LogEntry "Test Mode"
}

$GitCmd = 'git'

if ($null -eq (gcm $GitCmd -ea 'Ignore')) {
    $GitCmd = "$Env:LOCALAPPDATA\Programs\git\bin\git.exe"

    if (!(Test-Path $GitCmd)){
        throw "git not found on path or at $(em $GitCmd)"
    }
}

$Proxy = [System.Net.WebRequest]::GetSystemWebProxy().GetProxy('https://github.com')
$AddtionalArgs = if ($null -ne $Proxy) { "-c http.proxy=$($Proxy.OriginalString)" }else { $null }

$RepoLocal = "$($PWD.Path)\$Repo"

if(Test-Path $RepoLocal){
    Push-LogAction "deleting existing clone $(em $RepoLocal)"
    rm -Recurse -Force $RepoLocal
    Pop-LogAction
}

$Uri = "https://github.com/$Org/$Repo"
Push-LogAction "cloning $(em $uri) into $(em $RepoLocal)"
& $GitCmd clone $AddtionalArgs "$Uri"
Pop-LogAction

Push-LogAction "applying configs from $(em $RepoLocal )"

function apply{
    param(
        [string[]]$Configs,
        [string]$Comment,
        [string]$Comment2,
        [switch]$DotSource 
    )

    Push-LogAction $Comment

    $Configs | % {
        $Config = Join-Path $RepoLocal $_
        Push-LogAction "$Comment2 $(em $Config)"
    
        if($Test.IsPresent){
            Write-LogEntry "Test mode - file exists: $(Test-Path $Config )"
        } else {
            if($DotSource.IsPresent){
                . $Config
            } else {
                & $Config
            }
        }
    
        Pop-LogAction
    
    }

    Pop-LogAction

}

apply $Configs "applying configs" "calling"
apply $DotSourceConfigs "applying dot source configs" "dot sourcing" -DotSource

Pop-LogAction
Write-LogHeader "$Header - completed"