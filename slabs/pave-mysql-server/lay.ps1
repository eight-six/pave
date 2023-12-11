
param(
    [switch]$InitializeInsecure,
    [switch]$StartServer
)

begin {
    $ErrorActionPreference = 'Stop'

    $ThisSlabName = Split-Path $PSScriptRoot -Leaf
    $SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
    . "$SlabsRoot/slab-utils/slab-utils.ps1"

    $MySqlRoot = "C:\Program Files\MySQL\MySQL Server 8.0\bin"
}

process{
    Deploy $ThisSlabName 'pave-mysql-server' @{PackageSet = 'mysql-server'}
    
    $Info = "Initializing MySQL Server"
    Write-Information "$Info$LogStart"
    
    $InitArgs = @("--console")
    
    if($InitializeInsecure.IsPresent){
        Write-Warning "Initializing MySQL Server insecurely. This is not recommended for production environments."
        $InitArgs += "--initialize-insecure"
    } else {
        $InitArgs += "--initialize"
    }

    Start-Process "$MySqlRoot\mysqld" $InitArgs -Wait
    Write-Information "$Info$LogDone"

    if($StartServer.IsPresent){
        $StartArgs = @("--console")
        $Info = "Starting MySQL Server"
        Write-Information "$Info$LogStart"
        Start-Process "$MySqlRoot\mysqld" $StartArgs
        Write-Information "$Info$LogDone"
    }
}