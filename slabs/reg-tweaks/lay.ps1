
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$VerbosePreference = 'Continue'
$WarningPreference = 'Continue'

$SlabsRoot = (Resolve-Path(Join-Path $PSScriptRoot '..')).Path
. "$SlabsRoot/slab-utils/slab-utils.ps1"

# windows themes settings
$Path = 'HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
sp -path $Path -Name 'AppsUseLightTheme' -Value 0
sp -path $Path -Name 'SystemUsesLightTheme' -Value 0

# explorer settings
$Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

# taskbar settings
sp -path $Path -Name 'ShowTaskViewButton' -Value 0 -Type 'DWord'
sp -path $Path -Name 'TaskbarDa' -Value 0 -Type 'DWord' # widgets
sp -path $Path -Name 'TaskbarMn' -Value 0 -Type 'DWord' # chat
sp -path $Path -Name 'TaskbarSi' -Value 1 -Type 'DWord' # taskbar icon size: 0 smol, 1 Normal, 2 large

# taskbar search settings
$Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\'
sp -path $Path -Name 'SearchboxTaskbarMode' -Value 0 -Type 'DWord'

# input language switching - set all to none
$Path = 'HKCU:\Keyboard Layout\Toggle\'
sp -path $Path -Name 'Hotkey' -Value 3 -Type 'String' 
sp -path $Path -Name 'Language Hotkey' -Value 3 -Type 'String' 
sp -path $Path -Name 'Layout Hotkey' -Value 3 -Type 'String'


# Default Terminal Application  
# see https://support.microsoft.com/en-gb/windows/command-prompt-and-windows-powershell-for-windows-11-6453ce98-da91-476f-8651-5c14d5777c20
$Path = 'HKCU:\Console\%%Startup\'
sp -path $Path -Name 'DelegationConsole' -Value '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}' -Type 'String' 
sp -path $Path -Name 'DelegationTerminal' -Value '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}' -Type 'String' 

