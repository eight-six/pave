#Requires -version 5.1 # Windows Powershell
#Requires -modules PowershellGet
#Requires -modules pave-logger
#Requires -modules pave-utils

param ()

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$ScriptName = Split-Path -Path $PSCommandPath -Leaf
Write-LogHeader "$ScriptName" -Subheader:($null -ne $MyInvocation.PSCommandPath)

try {
    $PSRepo = Get-PSRepository | ? SourceLocation -eq 'https://www.powershellgallery.com/api/v2'

    if ($null -ne $PSRepo) {
        log "PS Gallery already registered: $($PSRepo | ConvertTo-Json -Compress)"
    }
    else {
        Push-LogAction  "Registering PS Gallery" -IncrementActionLevel
        $PSRepo = Register-PSRepository -Default -Force -
        Write-LogEntry "PS Repo registered: $($PSRepo | ConvertTo-Json -Compress)"
        Pop-LogAction
    }
    
}
catch {
    Clear-LogAction
    throw
}

Write-LogHeader "$ScriptName - done."

