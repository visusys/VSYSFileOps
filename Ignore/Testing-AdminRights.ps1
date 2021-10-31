Param(
    [Switch]$MySwitch,
    [String]$MyString1,
    [String]$MyString2,
    [String]$MyString3,
    [Int]$MyInteger
)

if (!(Test-IsAdmin)) {
    Request-AdminRights -Verbose -NoExit
    Exit
}

# Print the arguments received in diagnostic form.
Write-Verbose -Verbose '== Arguments received:'
[PSCustomObject] @{
    PSBoundParameters = $PSBoundParameters.GetEnumerator() | Select-Object Key, Value, @{ n = 'Type'; e = { $_.Value.GetType().Name } } | Out-String
    # Only applies to non-advanced scripts
    Args              = $args | ForEach-Object { [pscustomobject] @{ Value = $_; Type = $_.GetType().Name } } | Out-String
    CurrentLocation   = $PWD.ProviderPath
} | Format-List