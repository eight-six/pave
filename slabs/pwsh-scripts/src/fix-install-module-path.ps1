<##
.DESCRIPTION
Adds the install location for PSGet to the PSModulePath if it is missing for the
current session and persists it as a user scope environment variable on windows.

On Windows, Install-Module installs into the user's Documents folder, which may be redirected

On Linux, Install-Module installs in ~/.local/share/
#>
[CmdletBinding()]
param(

)

$PathDelim = $IsWindows ? ';' : ':'
$ModulesRoot = $IsWindows ? 'PowerShell' : '.local/share/powershell'
$SpecialFolder = 'Personal' # aka'MyDocuments' on Windows
$InstalledModulesPath = Join-Path ([System.Environment]::GetFolderPath($SpecialFolder )) $ModulesRoot 'Modules'
$ModulePaths = $Env:PSModulePath -split $PathDelim 

if ($ModulePaths -contains $InstalledModulesPath) {
    Write-Verbose "``$InstalledModulesPath`` already on PSModulePath"
} else {
    $ModulePaths += $InstalledModulesPath
    $Env:PSModulePath = $ModulePaths -join $PathDelim 
    $LogScope = $Null

    if($IsWindows){,
        $UserModulePaths = [Environment]::GetEnvironmentVariable('PSModulePath', 'User') -split $PathDelim 
        $UserModulePaths += $InstalledModulesPath
        $UserModulePathsString = $UserModulePaths -join $PathDelim

        Write-Verbose "Adding ``$InstalledModulesPath``"
        [Environment]::SetEnvironmentVariable('PSModulePath', $UserModulePathsString, 'User')
        $LogScope = 'User'
    } else {
        [Environment]::SetEnvironmentVariable('PSModulePath',$Env:PSModulePath)
        Write-Verbose "Added ``$InstalledModulesPath`` to PSModulePath"

    }

    Write-Verbose "Added ``$InstalledModulesPath`` to $LogScope PSModulePath"
}

