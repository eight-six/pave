

$Env:PAVE_PY_VERSION -split '\|' | % {
    winget install "Python.Python.$_" --accept-source-agreements 
    $PyVersion = $_ -replace '\.', ''
    $Env:Path = "$Env:LOCALAPPDATA\Programs\Python\Python$PyVersion;$Env:LOCALAPPDATA\Programs\Python\Python$PyVersion\Scripts;" + $Env:Path
}