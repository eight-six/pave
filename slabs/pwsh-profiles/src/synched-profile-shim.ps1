# This profile is synced accross devices by OneDrive

Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser' -Verbose

# uncomment/amend this to change emph chars in write-* messages
#$Env:PWSH_EMPH = $Env:PWSH_EMPH ?? '**'
$em = $Env:PWSH_EMPH ?? '``'

$ProfilePath = $env:PWSH_PROFILE_PATH ?? (Join-Path $HOME 'powershell' 'profile')
$DefaultProfileFilePath = Join-Path $ProfilePath 'basic-profile.ps1'
$ProfileFilePath = $env:BS_PROFILE ?? $DefaultProfileFilePath

if(!(Test-Path $ProfileFilePath)){
    Write-Warning "Profile $em$($ProfileFilePath)$em not found"
} else {
    Write-Verbose "Loading profile from $em$($ProfileFilePath)$em" -Verbose

    . $ProfileFilePath
}

# cleanup 
'em'| Get-Variable -ea Ignore | Remove-Variable
'ProfilePath' | Get-Variable -ea Ignore | Remove-Variable
'ProfilePath' | Get-Variable -ea Ignore | Remove-Variable
'DefaultProfileFilePath' | Get-Variable -ea Ignore | Remove-Variable
'ProfileFilePath' | Get-Variable -ea Ignore | Remove-Variable