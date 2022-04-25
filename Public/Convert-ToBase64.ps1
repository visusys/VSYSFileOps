function ConvertTo-Base64 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateScript( { Test-Path -LiteralPath $_ })]
        [String]$Path
    )
    [System.convert]::ToBase64String((Get-Content -LiteralPath $Path -AsByteStream))
}