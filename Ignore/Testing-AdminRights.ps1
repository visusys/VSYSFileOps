
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

# Print the arguments received
Get-AllArguments

# .\Testing-AdminRights.ps1 -MyString1 "Hello" -MyString2 "String 2" -MyString3 "String three." -MySwitch -MyInteger 3000 "unbound1" "unbound2"