Param(
    [Switch]$MySwitch,
    [String]$MyString1,
    [String]$MyString2,
    [String]$MyString3,
    [Int]$MyInteger
)

if (!(Test-IsAdmin)) {
    "Current location: $($PWD.ProviderPath)"
    Get-AdminRights -Verbose
}

# Print the arguments received in diagnostic form.
Write-Verbose -Verbose '== Arguments received:'
[PSCustomObject] @{
    PSBoundParameters = $PSBoundParameters.GetEnumerator() | Select-Object Key, Value, @{ n = 'Type'; e = { $_.Value.GetType().Name } } | Out-String
    # Only applies to non-advanced scripts
    Args              = $args | ForEach-Object { [pscustomobject] @{ Value = $_; Type = $_.GetType().Name } } | Out-String
    CurrentLocation   = $PWD.ProviderPath
} | Format-List


# .\Testing-AdminRights.ps1 -MyString1 'This is a string' -MyString3 "Lorem Ipsum" -MySwitch -MyString2 "Another string" -MyInteger 30000 "unbound1"
# .\Testing-AdminRights.ps1 -MyString1 'This "is a string' -MyString3 'Lorem "Ipsum"' -MySwitch -MyString2 "Anot'her`r`n string" -MyInteger 30000 "unbound1"
# .\Testing-AdminRights.ps1 -MyString1 "Anot'her`r`n string"
# .\Testing-AdminRights.ps1 -MyString1 'Anot''her`r`n string' 
# .\Testing-AdminRights.ps1 -MyString1 'Anot''""her`r`n string' 
# .\Testing-AdminRights.ps1 -MyString1 "Anot''""her string" 