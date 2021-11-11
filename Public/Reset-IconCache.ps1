<#
.SYNOPSIS
    Resets the icon cache on Windows 10

.NOTES
    Name: Reset-IconCache
    Author: Visusys
    Version: 1.0.0
    DateCreated: 2021-11-08

.EXAMPLE
    Reset-IconCache

.LINK
    https://github.com/visusys
#>
function Reset-IconCache {
    [CmdletBinding()]
    param ()
    $cmd = 'ie4uinit.exe -show'
    Invoke-Expression $cmd
    'Icon cache has been refreshed.' | Out-Host
}