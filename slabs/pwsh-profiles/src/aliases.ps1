

$Aliases = @{
    omp = 'oh-my-posh'
    less = 'more'
    tp = 'Test-Path'
}

$Aliases.Keys | % {
    $Alias = $_
    $Target = $Aliases[$_]

    if(gcm $Target){
	Write-Verbose "Target ``$Target`` found" -Verbose

        $Current = Get-Alias $Alias -ea 'SilentlyContinue' 

        if ($null -ne $Current){
	    if($Current.Definition -ne $Target){
                Write-Warning "Alias ``$($Current.Name)`` already exits with target ``$($Current.Definition)``"
            }
        } else {
	    Write-Verbose "Alias ``$Alias`` available" -Verbose
	    New-Alias $Alias $Target -Scope 'Global'
	}
    } else {
        Write-Warning "Target ``$Target`` not found.  Cannot set alias ``$_``"
    }
}

