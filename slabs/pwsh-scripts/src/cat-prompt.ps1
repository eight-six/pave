function Prompt {
    Write-host "$([char]0x14DA)$([char]0x160F)$([char]0x15E2)" -ForegroundColor 'Yellow' -NoNewline; 
    '$ ' 
}