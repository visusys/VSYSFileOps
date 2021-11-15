<#
.SYNOPSIS
    Registers or Unregisters a DLL or OCX

.PARAMETER File
    The DLL or OCX to register/unregister.

.PARAMETER Unregister
    If set, unregistration will be performed.

.NOTES
    Name: Register-DLLorOCX
    Author: Visusys
    Version: 1.0.0
    DateCreated: 2021-11-12

.EXAMPLE
    Register-DLLorOCX -File "C:\Test\Context.dll"

.EXAMPLE
    Register-DLLorOCX -File "C:\Test\Context.dll" -Unregister

.LINK
    https://github.com/visusys
#>
function Register-DLLorOCX {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position = 0)]
        [ValidateScript({
            if(!($_ | Test-Path)){
                throw "File doesn't exist."
            }
            if(!($_ | Test-Path -PathType Leaf)){
                throw "You must pass a file."
            }
            if($_ -notmatch '(\.dll|\.ocx)'){
                throw "You must pass a .dll or .ocx"
            }
            $true
        })]
        [string]
        $File,

        [Alias("u")]
        [Parameter(Mandatory = $false, Position = 1)]
        [switch]
        $Unregister
    )

    if($Unregister){
        regsvr32.exe -u $File
    }else{
        regsvr32.exe $File
    }
}