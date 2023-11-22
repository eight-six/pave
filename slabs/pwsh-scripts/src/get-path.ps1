<#PSScriptInfo

.VERSION 3.0

.GUID a5ca41ce-02b2-4a23-b8a1-174c1e5fb594

.AUTHOR eight-six

.COMPANYNAME Eight Six Consulting Limited

.COPYRIGHT (c) Eight Six Consulting Limited

.TAGS utils path

.LICENSEURI

.PROJECTURI https://github.com/eight-six/sturdy-robot.git

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS  

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

.PRIVATEDATA
#>

<#
.SYNOPSIS
    Get the path as an array of strings

.DESCRIPTION
   Get the path as an array of strings, on windows provides a Scope param to specify
   what scope to check the PATH i.e. User, Machine, or Process

.PARAMETER PSModulePath 
   [Switch] Show PSModulePath rather than PATH

.PARAMETER Scope 
   [EnvironmentVariableTarget] The scope of the path  (Windows Only)

.EXAMPLE
    Get-Path 

.EXAMPLE
    Get-Path -Scope 'User'

.EXAMPLE
    Get-Path -Scope 'Machine'

.EXAMPLE
    Get-Path -Scope 'Process'

.EXAMPLE
    Get-Path -PSModulePath

.EXAMPLE
    Get-Path -PSModulePath -Scope 'User'

.INPUTS
    None

.OUTPUTS
    string[]

.NOTES
#>


[CmdletBinding()]
Param(
    [switch]$PSModulePath
)
dynamicparam {
    $ParamDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        
    if ($IsWindows) {
        $ParameterAttribute = [System.Management.Automation.ParameterAttribute]@{
            Mandatory = $false
        }

        $AttributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $AttributeCollection.Add($ParameterAttribute)
        $AttributeCollection.Add($ValidateSetAttribute)

        $ScopeParam = [System.Management.Automation.RuntimeDefinedParameter]::new(
            'Scope', [System.EnvironmentVariableTarget], $AttributeCollection
        )

        $ParamDictionary.Add('Scope', $ScopeParam)
    }
    
    return $ParamDictionary
}

process {
    $Target = $PSModulePath.IsPresent ? 'PSModulePath' : 'PATH'
    $Path = $null

    if ($PSBoundParameters.ContainsKey('Scope')) {
        $Scope = $($PSBoundParameters['Scope']) 
        Write-Verbose "Scope $Scope"
        Write-Verbose "Type $($Scope.GetType)"
        $Path = [System.Environment]::GetEnvironmentVariable($Target, $Scope)
    }
    else {
        $Path = [System.Environment]::GetEnvironmentVariable($Target)
    }

    return $Path -split ($IsWindows ? ';' : ':')
}
