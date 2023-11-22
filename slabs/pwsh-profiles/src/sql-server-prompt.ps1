#function Prompt {'🔥 '}

function prompt {
    
    if ($pwd.Provider.Name -eq 'SqlServer') {
        $PathBits = ($pwd.ProviderPath -split '\\')
        $PathBits = ($pwd.ProviderPath -split '\\')
        $Prompt1 = $PathBits[2..3] -join '\'
        $Prompt1 = $PathBits[4..$PathBits.Length-2] -join '\'
        $Prompt3 = $PathBits[$PathBits.Length -1] -join '\'        
        Write-host "$Prompt1 " -ForegroundColor 'Green' -NoNewline 
        Write-host "$Prompt2 " -ForegroundColor 'Cyan' -NoNewline
        Write-host $Prompt3  -ForegroundColor 'Yellow'; 
    }
    
    '$ '
}