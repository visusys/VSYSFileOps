<#
.SYNOPSIS
    A brief description of the function or script.

.DESCRIPTION
    A detailed description of the function or script.

.PARAMETER Path
    Short description of what this parameter is.

.PARAMETER Param2
    Short description of what this parameter is.

.EXAMPLE
    SomeFunction -Param1 "C:\Test"

.INPUTS
    The .NET types of objects that can be piped to the function or script. 
    You can also include a description of the input objects.

.OUTPUTS
    The .NET type of the objects that the cmdlet returns. 
    You can also include a description of the returned objects.

.NOTES
    Name: FunctionName
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-11-20

.LINK
    https://github.com/visusys

.LINK
    Get-AnotherCmdlet

.LINK
    Resolve-SomeTask
    
#>
function FunctionName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline,Position = 0)]
        [ValidateScript({
            if(!($_ | Test-Path -PathType leaf)){
                throw "File/Files don't exist." 
            }
            return $true
        })]
        [Alias('file','files')]
        [String[]]
        $Filepath,

        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if(!(Confirm-ValidWindowsPath -Path $_ -Absolute -Container)){
                throw [System.ArgumentException] "The supplied path is not valid. Please enter a fully qualified absolute path."
            }
            
            return $true
        })]
        [String]
        $Destination
        
    )
     
    
}