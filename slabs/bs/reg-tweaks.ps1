
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
sp -path $Path -Name 'TaskbarSi' -Value 2 -Type 'DWord' # taskbar icon size: 0 smol, 1 Normal, 2 large

# taskbar search settings
$Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\'
sp -path $Path -Name 'SearchboxTaskbarMode' -Value 0 -Type 'DWord'

# input language switching - set all to none
$Path = 'HKCU:\Keyboard Layout\Toggle\'
sp -path $Path -Name 'Hotkey' -Value 3 -Type 'String' 
sp -path $Path -Name 'Language Hotkey' -Value 3 -Type 'String' 
sp -path $Path -Name 'Layout Hotkey' -Value 3 -Type 'String' 

