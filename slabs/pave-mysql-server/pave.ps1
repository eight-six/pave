
param(
    [switch]$InitializeInsecure,
    [switch]$StartServer
)

begin {
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'
    $VerbosePreference = 'Continue'
    $WarningPreference = 'Continue'

    $Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $MySqlRoot = "C:\Program Files\MySQL\MySQL Server 8.0\bin"
}

process{
    $Info = "Installing MySQL with bs-winget"
    Write-Information "$Info..."
    & "$Root\bs-winget\bs.ps1" -FilePath "$Root\bs-winget\mysql-server.json"
    Write-Information "$Info - done."
    
    $Info = "Initializing MySQL Server"
    Write-Information "$Info..."
    
    $InitArgs = @("--console")
    
    if($InitializeInsecure.IsPresent){
        Write-Warning "Initializing MySQL Server insecurely. This is not recommended for production environments."
        $InitArgs += "--initialize-insecure"
    } else {
        $InitArgs += "--initialize"
    }

    & "$MySqlRoot\mysqld" $InitArgs

    Write-Information "$Info - done."

    if($StartServer.IsPresent){
        $StartArgs = @("--console")
        $Info = "Starting MySQL Server"
        Write-Information "$Info..."
        start "$MySqlRoot\mysqld" $StartArgs
        Write-Information "$Info - done."
    }
}