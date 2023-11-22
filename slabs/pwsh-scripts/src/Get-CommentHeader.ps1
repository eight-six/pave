


function Get-CommentHeader {
    param (
        [ValidateRange(80, 120)]
        [int]$Width = 80,
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [ValidateSet('*', '#', '-')]
        [string]$PadChar = '*'
    )

    begin {}

    process {

        if ($Value.Length -ge $Width) {
            $Value
        }

        $LeftPad = [math]::Ceiling($Width / 2 - (($Value.Length / 2) + 1))
        $RightPad = $Width - ($Value.Length + 2 + $LeftPad)

        "$($PadChar * $LeftPad) $Value $($PadChar * $RightPad)"
    }

    end {}

}

