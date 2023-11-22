function head {Write-Verbose -Message 'Use `Get-Content -Head n` in scripts'; Get-Content -Head 10 $args}
function tail {Write-Verbose -Message 'Use `Get-Content -Tail n` in scripts'; Get-Content -Tail 10 $args}
