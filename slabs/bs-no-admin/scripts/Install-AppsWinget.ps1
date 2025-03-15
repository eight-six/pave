#Requires -version 7.4
#Requires -modules pave-logger
#Requires -modules pave-utils

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('az-cli',
        'azure-data-studio',
        'code-insiders',
        'code',
        'deno',
        'git',
        'node',
        'storage-explorer',
        'windows-terminal-preview',
        'windows-terminal')]
    [string[]]$Apps = @()
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$InformationPreference = 'Continue'

$AppLookup = @{
    'az-cli'                   = 'Microsoft.AzureCLI'
    'azure-data-studio'        = 'Microsoft.AzureDataStudio'
    'code-insiders'            = 'Microsoft.VisualStudioCode.Insiders'
    'code'                     = 'Microsoft.VisualStudioCode'
    'deno'                     = 'DenoLand.Deno'
    'git'                      = 'Git.Git'
    'node'                     = 'OpenJS.NodeJS'
    'storage-explorer'         = 'Microsoft.Azure.StorageExplorer'
    'windows-terminal-preview' = 'Microsoft.WindowsTerminal.Preview'
    'windows-terminal'         = 'Microsoft.WindowsTerminal'
}

try {
    $Heading = 'installing apps with winget'
    Write-LogHeader "$Heading" -Subheader:($null -ne $MyInvocation.PSCommandPath)
    
    $Apps | % {
        $Id = $AppLookup[$_]
        Push-LogAction "installing $(em $_) $Id (user scope) with winget"
        
        if ($PSCmdlet.ShouldProcess("winget install $Id", "call")) {
            winget install --exact --id "$Id" --scope user --accept-source-agreements
        }
        
        Pop-LogAction
    }

    if ($null -eq $MyInvocation.PSCommandPath) {
        $Heading += ' - completed'
        Write-LogHeader $Heading 
    }
}
catch {
    Clear-LogAction
    throw $_
}
