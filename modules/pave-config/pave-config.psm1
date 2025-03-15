

function Set-Config {
    param(
        $Configs 
    )

    $ConfigFilePath = Join-Path $ScriptsPath 'Set-Config.ps1'
    
    $Configs.Repos | % {
        $Repo = $_
        
        $Repo.Groups | % {
            $Group = $_
            $SharedParams = "-Org '$($Configs.Org)' -Repo '$($Repo.Name)' -Path '$($Group.Path)'"  
            $CommandTextBase = "$ConfigFilePath $SharedParams"
            
            if ($Group.DotSource.Length -gt 0) {
                $DotSource = ($Group.DotSource | % { "'$_'" } ) -join ', '
                $CommandText = "`"$($CommandTextBase + " -DotSource -Include $DotSource")`""
                Write-Verbose "CommandText: $CommandText" 
                Invoke-Pwsh -CommandText $CommandText
            }
        
            if ($Group.Call.Length -gt 0) {
                $Call = ($Group.Call | % { "'$_'" } ) -join ', '
                $CommandText = "`"$($CommandTextBase + " -Include $Call")`""
                Write-Verbose "CommandText: $CommandText"
                Invoke-Pwsh -CommandText $CommandText
            }
        }
    }
}