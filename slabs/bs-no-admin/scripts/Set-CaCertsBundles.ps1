function Set-CaCertsBundles {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(HelpMessage = 'Environment variable target')]
        [ValidateScript({ 
            $_ -ne [System.EnvironmentVariableTarget]::Machine -or 
            ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }, ErrorMessage = 'Cannot set machine environment variables without admin privileges')]
            [ArgumentCompleter({ [System.Enum]::GetNames([System.EnvironmentVariableTarget]) 
        })]
        [System.EnvironmentVariableTarget]
        $Target = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) ? 
                    [System.EnvironmentVariableTarget]::Machine : [System.EnvironmentVariableTarget]::Process,
        
        [Parameter(HelpMessage = 'Output file path')]
        [string]
        $CertOutPath = "$env:USERPROFILE\.certs\all.pem",
        
        [Parameter(HelpMessage = 'Create separate CRT file for the NodeJS package manager')]
        [switch]
        $WithSpecialNPM,
        
        [Parameter(HelpMessage = 'Create separate PEM files to import into Windows Subsystem for Linux (WSL)')]
        [switch]
        $Wsl,
        
        [Parameter(HelpMessage = 'Terminate on error')]
        [switch]
        $FailFast
    )
    #Requires -Version 6.0
    begin {
        if ($FailFast) {
            trap { Write-Error -Exception $_; return }  # Stop on error
        }
        $withOpenSSL = $false
        if (-not(Get-Command -Name openssl.exe -ErrorAction SilentlyContinue)) {
            if (Test-Path "$env:ProgramFiles\OpenSSL-Win64\bin" -PathType Container) {
                $env:PATH += [System.IO.Path]::PathSeparator + "$env:ProgramFiles\OpenSSL-Win64\bin"
                $withOpenSSL = $true
            }
        }
        else {
            $withOpenSSL = $true  # OpenSSL provides additional preamble on each PEM, which is nice for human-readability
        }
        # Collect the certs from the local machine
        $CertLocation = $Target -eq 'Machine' ? 'LocalMachine' : 'CurrentUser'
        $CertPath = "Cert:\${CertLocation}" 
        Write-Verbose -Message "Traversing $CertPath"
        $certs = ls -Path $CertPath -Exclude 'UserDS' | % {"$CertPath\$($_.Name)"} | Get-ChildItem  | Where-Object -FilterScript { $null -ne $_.Thumbprint }
        
        if ($null -eq $certs -or $certs.Count -eq 0) {
            Get-Error -Newest 1 | Set-Variable -Name LatestError
            if ($null -ne $LatestError -and $LatestError.Exception.ErrorCode -eq -2147467259) {
                Write-Error -Message "Unable to traverse Cert:\. Re-run as System with psexec -s -i pwsh $($MyInvocation.MyCommand) -Target $Target -CertOutPath `"$CertOutPath`" -Wsl:${Wsl} -FailFast:${FailFast}" -Exception $LatestError.Exception
                return
            }
            throw "No certificates found in 'Cert:\${CertLocation}'"
        }
        $certItem = (Test-Path -Path $CertOutPath -PathType Leaf) ? (Get-Item -Path $CertOutPath <# Get if exists #>) : (New-Item -Path $CertOutPath -ItemType File -Confirm:$ConfirmPreference -Force  <# Create if not exists #> ) 
        if ($null -eq $certItem -and $WhatIfPreference) {
            $certItem = [System.IO.FileInfo]::new($CertOutPath)  # For WhatIf, indicates hypothetical output file (not created)
        }
        # $envVars = 'GIT_SSL_CAINFO', 'AWS_CA_BUNDLE', 'CURL_CA_BUNDLE', 'NODE_EXTRA_CA_CERTS', 'REQUESTS_CA_BUNDLE', 'SSL_CERT_FILE'
        $envVars = , 'REQUESTS_CA_BUNDLE'
    }
    process {
        for ($i = 0; $i -lt $certs.Count; $i++) {
            Write-Progress -Activity 'Copying certificates' -PercentComplete (100 * $i / $certs.Count)
            if ($withOpenSSL) {
                $thumbprintCrt = Join-Path -Path $env:TEMP -ChildPath "$($certs[$i].Thumbprint).crt"
                $fs = [System.IO.FileStream]::new($thumbprintCrt, [System.IO.FileMode]::OpenOrCreate)
                try {
                    $fs.Write($certs[$i].RawData, 0, $certs[$i].RawData.Length)    
                }
                finally {
                    $fs.Dispose()
                }
        
                openssl x509 -inform DER -in $thumbprintCrt -text | Add-Content -Path $certItem
                if ($LASTEXITCODE -ne 0 -and $FailFast) {
                    Write-Error -Message 'Could not create last pem; stopping script to prevent further errors'
                    return
                }
                Remove-Item -Path $thumbprintCrt
            }
            else {
                @"
-----BEGIN CERTIFICATE-----
$([System.Convert]::ToBase64String($certs[$i].RawData) -replace '.{64}',"`$0`n")
-----END CERTIFICATE-----
"@ | Add-Content -Path $certItem

            }
        }
    }
    end {
        for ($i = 0; $i -lt $envVars.Count; $i++) {
            Write-Progress -Activity 'Setting environment variables' -Status $envVars[$i] -PercentComplete (100 * $i / $envVars.Count)
            if ($PSCmdlet.ShouldProcess($envVars[$i], "Set environment variable to '$certItem'" )) {
                [Environment]::SetEnvironmentVariable($envVars[$i], $certItem.FullName, $Target)
            }
        }
        if ($Wsl -and (Get-Command -Name wsl -ErrorAction SilentlyContinue) -and ($defaultDistro = Select-String -InputObject ((wsl --list *>&1) -join "`n") -Pattern '(.*)\([Default\u0000]+\)' | Select-Object -ExpandProperty Matches | ForEach-Object { ($_.Groups[1].Value -replace '\u0000').Trim() })) {
            Write-Verbose -Message "Copying certificates to WSL"
            
            Write-Verbose -Message 'Setting WSL environment variables'

        }
        if ($WithSpecialNPM -and $withOpenSSL) {
            #Requires -Modules Microsoft.PowerShell.Utility
            Write-Verbose -Message 'Collecting npm certificates'
            $WithSpecialNPMCertOutPath = Join-Path -Path (Split-Path -Path $CertOutPath -Parent) -ChildPath 'npmcerts.pem'
            Write-Verbose -Message "NPM certificate output path: '$WithSpecialNPMCertOutPath'"
            # Extract relevant URI's from the npm logs
            $uris = Select-String -Path "$env:LOCALAPPDATA\npm-cache\_logs\*.log" -Pattern 'https?://\S+' -AllMatches | Select-Object -ExpandProperty Matches | ForEach-Object { 
                $result = [uri]$null
                if ([uri]::TryCreate($_, [System.UriKind]::Absolute, [ref]$result)) {
                    $result
                }
            }
            $certs = [System.Collections.Concurrent.ConcurrentBag[string]]::new()  # For parallel processing
            $uniqueUris = $uris | Select-Object -Property Host, Port -Unique
            Write-Verbose -Message "Found $($uniqueUris.Count) unique URIs to collect certificates from"
            $uniqueUris | Select-Object -Property Host, Port -Unique | ForEach-Object -ThrottleLimit $env:NUMBER_OF_PROCESSORS -Parallel {
                $certs = $using:certs
                $uri = $_
                # This uses openssl to connect to the URI and get the complete certificate chain
                $certs.Add(
                        (Write-Output -InputObject '' | openssl s_client -showcerts -servername "$($uri.Host)" -connect "$($uri.Host):$($uri.Port)" 2>$null | Join-String -Separator "`r`n" | Select-String -Pattern "(?sm)-+BEGIN CERTIFICATE-+([^-]+[`r`n]+)+-+END CERTIFICATE-+" -AllMatches -CaseSensitive | Select-Object -ExpandProperty Matches | ForEach-Object { $_.Value })
                )
            }
            $certs.ToArray() | Set-Content -Path $WithSpecialNPMCertOutPath
            Get-Content -Path $CertOutPath -Raw | Select-String -Pattern "(?sm)-+BEGIN CERTIFICATE-+([^-]+[`r`n]+)+-+END CERTIFICATE-+" -AllMatches -CaseSensitive | Select-Object -ExpandProperty Matches | ForEach-Object { $_.Value } | Add-Content -Path $WithSpecialNPMCertOutPath
            if ($PSCmdlet.ShouldProcess("NODE_EXTRA_CA_CERTS", "Set environment variable to '$WithSpecialNPMCertOutPath" )) {
                [Environment]::SetEnvironmentVariable("NODE_EXTRA_CA_CERTS", $WithSpecialNPMCertOutPath, $Target)
            }
        }
    }
}