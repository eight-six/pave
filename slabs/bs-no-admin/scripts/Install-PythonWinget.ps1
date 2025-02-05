#Requires -PSEdition Core
#Requires -Modules pave-logger

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Heading = 'python'
Write-LogHeader $Heading -Subheader:($null -ne $MyInvocation.PSCommandPath)
Push-LogAction "installing python versions: $(em $Env:PAVE_PY_VERSION)" -IncrementActionLevel

$Env:PAVE_PY_VERSION -split '\|' | % {
    Push-LogAction "Installing python $_"
    winget install "Python.Python.$_" --accept-source-agreements 
    Push-LogAction "Adding python $_"
    
    $PyVersion = $_ -replace '\.', ''
    $PyPath = "$Env:LOCALAPPDATA\Programs\Python\Python$PyVersion" 
    $PyScriptsPath = Join-Path $PyPath 'Scripts'

    Pop-LogAction "Adding $(em $PyPath) to Path"
    Add-UserPath $PyPath -AtStart -AddToCurrentSession
    Pop-LogAction

    Pop-LogAction "Adding $(em $PyScriptsPath) to Path" 
    Add-UserPath $PyScriptsPath -AtStart -AddToCurrentSession
    Pop-LogAction
}

# remove Windows App Store 'shims' for python
Push-LogAction 'Removing windows app shims for python'

$WindowsAppsRoot = "$Env:LOCALAPPDATA\Microsoft\WindowsApps"
$WindowsStorePythonPaths = "$WindowsAppsRoot\python.exe", "$WindowsAppsRoot\python3.exe"

$WindowsStorePythonPaths | ForEach-object {
    if (Test-Path $_){
        Push-LogAction "Removing shim $(em $_)"
        Remove-Item -path $_ -Force
        Pop-LogAction
    }
}

Pop-LogAction

if($null -eq $MyInvocation.PSCommandPath){
	$Heading += ' - completed'
	Write-LogHeader $Heading 
}