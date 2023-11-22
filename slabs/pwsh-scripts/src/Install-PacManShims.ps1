Write-Verbose $MyInvocation.InvocationName

if($MyInvocation.InvocationName -ne '.'){
    Write-Warning 'Script was not dot-sourced. Contained functions will not be added to session.'
}

function Install-Module {

    [CmdletBinding(DefaultParameterSetName = 'NameParameterSet', SupportsShouldProcess = $true, ConfirmImpact = 'Medium', HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=398573')]
    param(
        [Parameter(ParameterSetName = 'NameParameterSet', Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Name},

        [Parameter(ParameterSetName = 'InputObject', Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [psobject[]]
        ${InputObject},

        [Parameter(ParameterSetName = 'NameParameterSet', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        ${MinimumVersion},

        [Parameter(ParameterSetName = 'NameParameterSet', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        ${MaximumVersion},

        [Parameter(ParameterSetName = 'NameParameterSet', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        ${RequiredVersion},

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Repository},

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [uri]
        ${Proxy},

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${ProxyCredential},

        # [switch]
        # ${AllowClobber},

        # [switch]
        # ${SkipPublisherCheck},

        [switch]
        ${Force},

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [switch]
        ${AllowPrerelease},

        [switch]
        ${AcceptLicense} #,

        # [switch]
        # ${PassThru}
    )

    begin {
        Write-Warning "Install-Module proxied and forwarded to Save-Module." -WarningAction 'Continue'

        try {
            $PSBoundParameters.Path = '~/powershell/modules'
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Save-Module', [System.Management.Automation.CommandTypes]::Function)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline()
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }

    clean {
        if ($null -ne $steppablePipeline) {
            $steppablePipeline.Clean()
        }
    }
}

function Install-Script {
    [CmdletBinding(DefaultParameterSetName = 'NameParameterSet', SupportsShouldProcess = $true, ConfirmImpact = 'Medium', HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=619784')]
    param(
        [Parameter(ParameterSetName = 'NameParameterSet', Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Name},

        [Parameter(ParameterSetName = 'InputObject', Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [psobject[]]
        ${InputObject},

        [Parameter(ParameterSetName = 'NameParameterSet', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        ${MinimumVersion},

        [Parameter(ParameterSetName = 'NameParameterSet', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        ${MaximumVersion},

        [Parameter(ParameterSetName = 'NameParameterSet', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        ${RequiredVersion},

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Repository},

        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]
        ${Scope},

        [switch]
        ${NoPathUpdate},

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [uri]
        ${Proxy},

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${ProxyCredential},

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        # [switch]
        # ${Force},

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [switch]
        ${AllowPrerelease},

        [switch]
        ${AcceptLicense} #,

        # [switch]
        # ${PassThru}
    )

    begin {
        try {
            Write-Warning "Install-Script proxied and forwarded to Save-Script." -WarningAction 'Continue'
            
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $PSBoundParameters.Path = Join-path $HOME 'PowerShell' 'Scripts'
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Save-Script', [System.Management.Automation.CommandTypes]::Function)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline()
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }

    clean {
        if ($null -ne $steppablePipeline) {
            $steppablePipeline.Clean()
        }
    }

}