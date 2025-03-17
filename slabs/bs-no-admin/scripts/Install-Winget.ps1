#Requires -version 5.1 # Windows Powershell
#Requires -modules PowershellGet
#Requires -modules pave-logger
#Requires -modules pave-utils

param ()
 
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$InformationPreference = 'Continue'

try {
    $Ret = @{
        Env   = @()
        Paths = @()
        Version = $null
    }
    
    $Heading = "$(u 'winget')"
    Write-LogHeader "$Heading" -Subheader:($null -ne $MyInvocation.PSCommandPath)

    $Winget = gcm 'winget' -ErrorAction ignore

    if ($null -ne $Winget) {
        $Version = winget --version
        $Ret.Version = $Version
        log "winget $Version already installed"
    }
    else {
        if ($PSCmdlet.ShouldProcess("winget", "install")) {
            Push-LogAction "Installing winget"
            Install-Module -Name 'Microsoft.WinGet.Client'  -Repository 'PSGallery' -Force -Scope 'CurrentUser'

            if ($PSCmdlet.ShouldProcess("Repair-WingetPackageManager", "call")) {
                Repair-WingetPackageManager
            }

            $Ret.Version = Get-WinGetVersion
            Pop-LogAction
        }
    }

    if ($null -eq $MyInvocation.PSCommandPath) {
        $Heading += ' - completed'
        Write-LogHeader $Heading 
    }
    
    Write-LogHeader "$ScriptName - done."
}
catch {
    Clear-LogAction
    throw
}


