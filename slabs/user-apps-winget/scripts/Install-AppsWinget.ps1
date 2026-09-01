#Requires -version 7.4
#Requires -modules pave-logger
#Requires -modules pave-utils

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet(
        'azure-data-studio',
        'code-insiders',
        'code',
        'deno',
        'git',
        'node',
        'storage-explorer',
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
    $Heading = "$(u 'install apps with winget')"
    Write-LogHeader "$Heading" -Subheader:($null -ne $MyInvocation.PSCommandPath)
    
    $Apps | % {
        $Id = $AppLookup[$_]
        Push-LogAction "installing $(em $_) [$Id] with winget (user scope)" -IncrementActionLevel
        
        if ($PSCmdlet.ShouldProcess("winget install $Id", "call")) {
            $Package =  Get-WinGetPackage -Id $Id

            if($null -eq $Package){
                #winget install --exact --id "$Id" --scope user -accept-source-agreements
                $Result = Install-WinGetPackage -Id $Id -Scope 'User' -Mode 'Silent' 
            } else {
                $Result = Update-WinGetPackage -Id $Id
            }
        }
        
        Pop-LogAction
    }

    if ($null -eq $MyInvocation.PSCommandPath) {
        $Heading += " - $(u completed)"
        Write-LogHeader $Heading 
    }

    $Result
}
catch {
    Clear-LogAction
    throw $_
}
 