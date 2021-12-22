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
        [Parameter(Mandatory, Position=0)]
        [ValidateScript({
            if (!(Test-Path -LiteralPath $_)) {
                throw [System.ArgumentException] "File or Folder does not exist."
            }
            if (Test-Path -LiteralPath $_ -PathType Container) {
                throw [System.ArgumentException] "Folder passed when a file was expected."
            }
            if($_ -notmatch '(\.dll|\.ocx)'){
                throw "You must pass a .dll or .ocx file."
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

    process {
        if($Unregister){
            $Result = Invoke-GUIMessageBox "Unregister $File?" -Title "Unregister" -Buttons 'YesNoCancel' -Icon 'Question' -DefaultButton 'Button3'
            if($Result -ne 'Yes') { 
                Write-Verbose "User canceled the process."
                Exit
            }
            regsvr32.exe -u $File
        }else{
            if($Result -ne 'Yes') { 
                Write-Verbose "User canceled the process."
                Exit
            }
            $Result = Invoke-GUIMessageBox "Register $File?" -Title "Register" -Buttons 'YesNoCancel' -Icon 'Question' -DefaultButton 'Button3'
            regsvr32.exe $File
        }
    }
}