$ModuleName = 'pave-logger'
$Description =  'Provides logging functions for the pave module'

new-moduleManifest `
 -Path "modules\$ModuleName\$ModuleName.psd1" `
 -Author '@eight-six' `
 -Copyright "(c) Eight Six Consulting Limited $(Get-Date -Format 'yyyy')" `
 -CompanyName 'Eight Six Consulting Limited' `
 -RootModule "$ModuleName.psm1" `
 -Description $Description `
 -ModuleVersion '99.99.99' 
 #-Tags 