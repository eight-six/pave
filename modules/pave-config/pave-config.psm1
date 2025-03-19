using namespace System.Management.Automation
#Requires -Modules pave-logger
#Requires -Modules pave-utils

$ErrorActionPreference = 'Stop'

function Set-ConfigGroup {
    param(
        $Configs 
    )
    
    $Configs.Repos | % {
        $Repo = $_
        
        $Repo.Groups | % {
            $Group = $_
            $SharedParams = @{
                Org  = $Configs.Org
                Repo = $Repo.Name
                Path = $Group.Path
            }
            
            if ($Group.DotSource.Length -gt 0) {
                Set-Config -DotSource -Include $Group.DotSource @SharedParams 
            }
        
            if ($Group.Call.Length -gt 0) {
                Set-Config -Include $Group.Call @SharedParams 
            }
        }
    }
}

function Set-Config {
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
        [switch]$Test,
        
        [string]$Branch = 'main'
    )

    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $true

    Write-Verbose "Include is null: $($null -eq $Include)"
    Write-Verbose "Exclude is null: $($null -eq $Exclude)"

    if ($Env:Path[-1] -ne ';') {
        $Env:Path += ';'
    }

    $Header = "applying configs from $Org $Repo $Path"
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

    $Proxy = Get-Proxy 'https://github.com'
    $AdditionalArgs = if ($null -ne $Proxy) { "-c http.proxy=$($Proxy.OriginalString)" }else { $null }
    $RepoLocal = "$($PWD.Path)\$Repo"

    if (Test-Path $RepoLocal) {
        Push-LogAction "deleting existing clone $(em $RepoLocal)"
        rm -Recurse -Force $RepoLocal
        Pop-LogAction
    }

    $Uri = "https://github.com/$Org/$Repo"
    Push-LogAction "cloning $(em $uri) into $(em $RepoLocal)"
    md $Repo
    $StackName = (new-guid).Guid.Substring(24,12)
    pushd $Repo -StackName $StackName
    & $GitCmd init  
    & $GitCmd remote add origin $Uri
    & $GitCmd $AdditionalArgs fetch
    & $GitCmd $AdditionalArgs checkout --detach origin/$Branch
    # & $GitCmd clone $AdditionalArgs "$Uri" | Out-Null

    Pop-LogAction
    #endregion

    #region applying configs
    Push-LogAction "applying configs from $(em $RepoLocal)"

    $ConfigsRoot = "$RepoLocal\configs\$Path"
    $ConfigsToApply = ls $ConfigsRoot  -Directory -Name -Include $Include -Exclude $Exclude
    Write-Verbose "looking for configs in $ConfigsRoot " #-verbose
    Write-Verbose "Including: $( $Include -join ',') " #-verbose
    Write-Verbose "Excluding: $( $Exclude -join ',') " #-verbose
    Write-Verbose "Applying: $($ConfigsToApply  -join ',') " #-verbose

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
                Invoke-Pwsh -CommandText ". $Config"
            }
            else {
                Invoke-Pwsh -File $Config
            }
        }

        Pop-LogAction
        #endregion
    }

    popd $StackName

    Pop-LogAction
    #endregion

    Pop-LogAction
    #endregion

    Write-LogHeader "$Header - completed"   
}