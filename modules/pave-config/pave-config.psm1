#Requires -Modules pave-logger
#Requires -Modules pave-utils

using namespace System.Collections
using namespace System.Management.Automation

$ErrorActionPreference = 'Stop'

function Set-ConfigGroup {

    param(
        $Configs,
        [switch]$UseExistingClone
    )
    
    Write-Verbose "$($MyInvocation.MyCommand): configs: $($Configs | ConvertTo-Json -Compress -depth 99)"

    
    $Configs.Repos | % {
        $Repo = $_
        Write-Verbose "$($MyInvocation.MyCommand) repo: $($Repo | ConvertTo-Json -Compress -depth 99)"
        
        $Repo.Groups | % {
            $UseExisting = $UseExistingClone.IsPresent

            $Group = $_
            Write-Verbose "$($MyInvocation.MyCommand): group: $($Group | ConvertTo-Json -Compress -Depth 99)"

            $SharedParams = @{
                Org  = $Configs.Org
                Repo = $Repo.Name
                Path = $Group.Path
            }
            if ($Group.DotSource.Length -gt 0) {
                Write-Verbose "$($MyInvocation.MyCommand): dot source: $($Configs | ConvertTo-Json -Compress -Depth 99) dot source: $($Group.DotSource -join ',')" 
                Set-Config -DotSource -Include $Group.DotSource @SharedParams -UseExistingClone
                $UseExisting = $true
            }
        
            if ($Group.Call.Length -gt 0) {
                Write-Verbose "$($MyInvocation.MyCommand): call: $($Configs | ConvertTo-Json -Compress -Depth 99) call: $($Group.Call -join ',')" 
                Set-Config -Include $Group.Call @SharedParams -UseExistingClone
                $UseExisting = $true
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
        
        [string]$Branch = 'main',

        [switch]$UseExistingClone
    )

    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $true

    Write-Verbose "$($MyInvocation.MyCommand): params: $($PSBoundParameters | ConvertTo-Json -Compress -Depth 99)"
    Write-Verbose "Include is null: $($null -eq $Include)"
    Write-Verbose "Exclude is null: $($null -eq $Exclude)"

    try {
        $Header = "applying configs from $Org/$Repo/$Path"
        Write-LogHeader $Header -Subheader:($null -ne $MyInvocation.PSCommandPath)

        if ($Test.IsPresent) {
            Write-LogEntry "Test Mode"
        }

        $RepoLocal = "$Env:PAVE_DOWNLOAD_CACHE\$Repo"
        $RepoLocalExists = Test-Path $RepoLocal

        #region clone config repo
        if (!($UseExistingClone.IsPresent -and $RepoLocalExists)) {
            $GitCmd = 'git'

            if ($null -eq (gcm $GitCmd -ea 'Ignore')) {
                $GitCmd = "$Env:LOCALAPPDATA\Programs\git\bin\git.exe"

                if (!(Test-Path $GitCmd)) {
                    throw "git not found on path or at $(em $GitCmd)"
                }
            }

            $Proxy = Get-Proxy 'https://github.com'
            $AdditionalArgs = if ($null -ne $Proxy) { "-c http.proxy=$($Proxy.OriginalString)" }else { $null }

            if (Test-Path $RepoLocal) {
                Push-LogAction "deleting existing clone $(em $RepoLocal)"
                rm -Recurse -Force $RepoLocal
                Pop-LogAction
            }

            $Uri = "https://github.com/$Org/$Repo"
            Push-LogAction "cloning $(em $uri) into $(em $RepoLocal)"

            if (!(Test-Path $RepoLocal)) {
                md $RepoLocal
            }

            $StackName = (new-guid).Guid.Substring(24, 12)
            pushd $RepoLocal -StackName $StackName
            
            & $GitCmd init  
            & $GitCmd remote add origin $Uri
            & $GitCmd $AdditionalArgs fetch
            & $GitCmd $AdditionalArgs checkout --detach origin/$Branch
            # & $GitCmd clone $AdditionalArgs "$Uri" | Out-Null

            popd -StackName $StackName

            Pop-LogAction
        }
        #endregion

        #region applying configs
        Push-LogAction "applying configs from $(em $RepoLocal)"
        
        $ConfigsRoot = "$RepoLocal\configs\$Path"
        Write-Verbose "looking for configs in $ConfigsRoot " 
        Write-Verbose "Including: $(if($Include){ $Include -join ','}else{'*'})" 
        Write-Verbose "Excluding: $(if($Exclude){$Exclude  -join ','}else{"[]"})" 
        
        $ConfigsToInclude = [ArrayList]::new()

        if ($Include.Length -eq 0) {
            $ConfigsToInclude.AddRange((ls $ConfigsRoot  -Directory -Name -Include $Include))
        }
        else {
            $Include | % {
                $ConfigPath = Join-Path $ConfigsRoot $_
                Write-Verbose "$_ - Path: $ConfigPath"

                if (Test-Path $ConfigPath) {
                    $ConfigsToInclude.Add($_) | Out-Null
                }
                else {
                    Write-Warning "Include $(em $_) not found - ignoring" -WarningAction 'Continue' 
                }
            }
        }

        $ExcludesToApply = [ArrayList]::new()

        if ($Exclude.Length -ne 0) {
            $Exclude | % {
                $ConfigPath = Join-Path $ConfigsRoot $_
                Write-Verbose "$_ - Path: $ConfigPath"

                if (Test-Path $ConfigPath) {
                    $ExcludesToApply.Add($_) | Out-Null
                }
                else {
                    Write-Warning "Exclude $(em $_) not found - ignoring" -WarningAction 'Continue' 
                }
            }
        }
        
        $ConfigsToApply = $ConfigsToInclude | ? { $_ -notin $ExcludesToApply }

        Write-LogEntry "Effective configs: $(if($ConfigsToApply){$ConfigsToApply  -join ','}else{"[]"})" 

        $RepoLocal = "$env:PAVE_DOWNLOAD_CACHE\$Repo"

        #region applying each config
        $Comment = if ($DotSource.IsPresent) { "dot sourcing configs" }else { "applying configs" }
        Push-LogAction $Comment

        $ConfigsToApply | % {
            #region apply config
            $ConfigScript = Join-Path $ConfigsRoot  (Join-Path $_ 'doit.ps1')
            Write-Verbose "ConfigScript: $(em $ConfigScript)"

            if (!(Test-Path $ConfigScript)) {
                Write-Warning "Config $(em $ConfigScript) not found. Skipping" -WarningAction 'Continue'
                log "WARNING: Config $(em $ConfigScript) not found. Skipping"
            }
            else {
                $Comment = if ($DotSource.IsPresent) { "dot sourcing" }else { "calling" }
                Push-LogAction "$Comment $(em $ConfigScript)"

                if ($Test.IsPresent) {
                    Write-LogEntry "Test mode - file exists: $(Test-Path $ConfigScript )"
                }
                else {
                    $ConfigScript = Resolve-Path $ConfigScript

                    if ($DotSource.IsPresent) {
                        Invoke-Pwsh -CommandText ". $ConfigScript"
                    }
                    else {
                        Invoke-Pwsh -File $ConfigScript
                    }
                }
                
                Pop-LogAction
            }
            #endregion


        }

        Pop-LogAction
        #endregion

        Pop-LogAction
        #endregion

        if (($null -ne $MyInvocation.PSCommandPath)) {
            Write-LogHeader "$Header - completed"   
        }
    }
    catch {
        if (![string]::IsNullOrWhiteSpace($StackName)) {
            while (Get-Location -StackName $StackName -ea ignore) {
                popd -StackName $StackName        
            }
        }

        throw
    }
}