

$ProfileDefaults = @'
function prompt {        
    $Role = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole($role)
    $Dollar = if ($IsAdmin ) { '>' } else { 'P$' }
    $Options = Get-PSReadLineOption
    $Color = if ($IsAdmin) { $Options.ErrorColor } else { $Options.DefaultTokenColor }
    
    $Line1 = @(
        $Options.CommentColor
        $Pwd.Path.Replace($HOME, '~')
        $PSStyle.Reset
        ) -join ''
        
    $Line2 = "$($Color)$Dollar $($PSStyle.Reset)"
    
    '', $Line1, $Line2 -join "`n"
}
'@

if(!(Test-Path $PROFILE )){
    $ProfilePath = Split-Path $PROFILE -Parent

    if(!(Test-Path $ProfilePath )){
        md $ProfilePath | Out-Null
    }

    $ProfileDefaults  | Out-File -Encoding 'utf8' $PROFILE 
}

$Modules = @(
    'az'
    'Microsoft.WinGet.Client'
    'powershell-yaml'
)

$Modules | % {
    Install-Module -Name $_  -Repository 'PSGallery' -Force -Scope 'CurrentUser'

}

