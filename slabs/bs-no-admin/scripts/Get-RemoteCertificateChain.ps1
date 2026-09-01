function Get-RemoteCertificateChain {
  [CmdletBinding()]
  param (
    [Parameter(
      Mandatory,
      ValueFromPipeline
    )]
    [ValidateNotNull()]
    [Uri]
    $Uri
  )
  process {
    try {
      $TcpClient = [System.Net.Sockets.TcpClient]::new($Uri.Host, $Uri.Port)
      try {
        $SslStream = [System.Net.Security.SslStream]::new($TcpClient.GetStream())
        $SslStream.AuthenticateAsClient($Uri.Host)
        $certificateChain = $sslStream.RemoteCertificate.ChainElements
foreach ($chainElement in $certificateChain) {
        $certificateChain = $sslStream.RemoteCertificate.ChainElements

        Write-Output "Certificate Subject: $($chainElement.Certificate.Subject)"
        Write-Output "Certificate Issuer: $($chainElement.Certificate.Issuer)"

 }
      } finally {
        $SslStream.Dispose()
      }
    } finally {
      $TcpClient.Dispose()
    }
  }
}