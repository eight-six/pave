$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

$ToolsYaml = @'
- id: "Docker.DockerDesktop"                 
  version: latest
  scope: user
  skip: true
- id: "JGraph.Draw"                          
  version: latest
  scope: user
  skip: false
- id: "Git.Git"                              
  version: latest
  scope: user
  skip: false
- id: "GitHub.cli"                           
  version: latest
  scope: user
  skip: false

- id: "Hashicorp.Terraform"                  
  version: latest
  scope: user
  skip: false

- id: "Microsoft.DotNet.SDK.7"               
  version: latest
  scope: machine
  skip: false

- id: "Microsoft.AzureCLI"                   
  version: latest
  scope: user
  skip: false

- id: "Microsoft.AzureDataStudio"            
  version: latest
  scope: user
  skip: false

- id: "Microsoft.VisualStudioCode.Insiders"  
  version: latest
  scope: user
  skip: false

- id: "Neovim.Neovim"                        
  version: latest
  scope: user
  skip: false

- id: "JanDeDobbeleer.OhMyPosh"              
  version: latest
  scope: user
  skip: false

- id: "Perimeter81Ltd.Perimeter81Ltd"        
  version: latest
  scope: # Perimeter81 doesn't seen to have a user or machine scope
  skip: false

- id: "Microsoft.PowerShell"                 
  version: latest
  scope: user
  skip: false

- id: "Microsoft.PowerToys"                  
  version: latest
  scope: user
  skip: false

- id: "Python.Python.3.12"                   
  version: latest
  scope: user
  skip: false

- id: "Microsoft.WindowsTerminal"            
  version: latest
  scope: user
  skip: false

'@

$Tools = $ToolsYaml | ConvertFrom-Yaml

 
$Tools | ? id -EQ 'Perimeter81Ltd.Perimeter81Ltd' | % {
    if (! $_.skip) {
        $Op = "install"
        $HeaderWidth = 80
        $HeaderText = "$op $($_.id) ($($_.version))"
        $LPad = [Math]::Floor(($HeaderWidth - ($HeaderText.Length + 2))/2.0)
        $RPad = $HeaderWidth - ($HeaderText.Length + 2 + $LPad)
        Write-Information "`n`e[32m$('*' * $LPad)`e[0m `e[33m$HeaderText`e[0m `e[32m$('*' * $RPad)`e[0m"
        # winget search $_ --source winget
        $WingetArgs = $Op, "--id $($_.id)", "--exact"
        
        if($Op -eq 'install'){
            $WingetArgs += "--source winget"

            if(![string]::IsNullOrWhiteSpace($($_.scope))){
                $WingetArgs += "--scope $($_.scope)"
            }
        }

        if ($_.version -ne 'latest') {
            $WingetArgs += "--version $($_.version)"
        }
        Write-Verbose ($WingetArgs -join ' ') -Verbose
        start-Process winget -ArgumentList $WingetArgs -Wait -NoNewWindow
    }
}




                                                                                                                        
