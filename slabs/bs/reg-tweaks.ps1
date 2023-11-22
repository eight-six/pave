
# windows themes settings
$Path = 'HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
sp -path $Path -Name 'AppsUseLightTheme' -Value 0
sp -path $Path -Name 'SystemUsesLightTheme' -Value 0

# explorer settings
$Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'


sp -path $Path -Name 'ShowTaskViewButton' -Value 0 -Type DWord
sp -path $Path -Name 'TaskbarDa' -Value 0 -Type DWord # widgets
sp -path $Path -Name 'TaskbarMn' -Value 0 -Type DWord # chat
sp -path $Path -Name 'TaskbarSi' -Value 2 -Type DWord # taskbar icon size

$Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\'
sp -path $Path -Name 'SearchboxTaskbarMode' -Value 0 -Type DWord

