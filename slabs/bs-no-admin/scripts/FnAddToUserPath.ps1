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