

function AddToUserPath{
    param (
		[string]$PathToAdd,
		[switch]$AddToCurrentSession
	)
	
	$UserPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
	$UserPath += "$(if(-not $UserPath.EndsWith(';')){';'})$PathToAdd"
	[System.Environment]::SetEnvironmentVariable('PATH', $UserPath, 'User')
	
	if($AddToCurrentSession.IsPresent){
		$Env:Path += "$(if(-not $Env:Path.EndsWith(';')){';'})$PathToAdd"
	}
}

$DotNetInstallUri = 'https://dot.net/v1/dotnet-install.ps1'

Write-Information "installing dotnet latest LTS "
Start-BitsTransfer $DotNetInstallUri
.\dotnet-install.ps1 # LTS i.e. v6
$DotNetInstallPath = "$Env:LocalAppData\Microsoft\dotnet"
[System.Environment]::SetEnvironmentVariable('DOTNET_ROOT', $DotNetInstallPath, 'User')
$Env:DOTNET_ROOT =  $DotNetInstallPath
AddToUserPath -PathToAdd $DotNetInstallPath -AddToCurrentSession

Write-Information "installing dotnet latest LTS - done"