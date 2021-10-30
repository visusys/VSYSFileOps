Param(
    [Switch]$MySwitch,
    [String]$MyString,
    [Switch]$NoExit,
    [Int]$MyInteger
)

$InvocationTest = [string]$MyInvocation.Line

if (!(Test-IsAdmin)) {
    Write-Host "MyString:" $MyString
    Request-AdminRights -CommandLine $InvocationTest
}

# '`TestingC&" v%$ :* 123'
# "`TestingC&`" v%$ :* 123"

Write-Host "MySwitch:" $MySwitch
Write-Host "MyString:" $MyString
Write-Host "MyInteger:" $MyInteger