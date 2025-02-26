using namespace System
using namespace System.Net

function Get-Proxy {
    param(
        [Parameter(Mandatory)]
        $TestUri
    )

    $Ret = $null
    $Uri = ""

    if (!([Uri]::TryCreate($TestUri, [UriKind]::Absolute, [ref] $Uri))) {
        throw "TestUri '$TestUri' is not a valid absolute uri."
    }

    $Proxy = ([System.Net.WebRequest]::GetSystemWebProxy().GetProxy($TestUri))


    if ($null -ne $Proxy -and $Proxy.OriginalString -ne $TestUri) {
        $Ret = $Proxy.OriginalString
    }

    $Ret
}