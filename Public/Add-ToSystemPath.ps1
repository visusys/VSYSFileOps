<#
.SYNOPSIS
    This script will add a directory to your system PATH variable.

.PARAMETER Path
    The directory you wish to add to your system PATH variable. 

.PARAMETER Force
    Suppresses all confirmations and operates silently.

.EXAMPLE
    Add-ToSystemPath -Path 'D:\Software\SomeApplication\'

.EXAMPLE
    Add-ToSystemPath 'C:\Dev\Modules\Bin' -Force

.INPUTS
    System.String: The path you wish to add to your system PATH environment variable.

.OUTPUTS
    Nothing.

.NOTES
    Name: Add-ToSystemPath
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-11-19

.LINK
    https://github.com/visusys
    
#>
Function Add-ToSystemPath{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [ValidateScript({
            if (-Not (Test-Path $_ -PathType Container) ) {
                throw "Folder does not exist" 
            }
            return $true
        })]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if(!(Test-IsAdmin)){
        Read-Host -Prompt "This function requires admin privileges. Press any key to exit."
        Exit
    }

    $RegKey = (Get-Item "HKLM:\System\CurrentControlSet\Control\Session Manager\Environment").GetValue("PATH", $null, "DoNotExpandEnvironmentNames")
    $PathList = $RegKey -split ';'
    $PathList = $PathList | Where-Object {$_}

    $NewPathList = [System.Collections.Generic.List[object]]@()
    #Ensure the path doesn't already exist
    foreach($PathEntry in $PathList) {
        if($PathEntry -eq $Path){
            return "$Path already exists in PATH."
        }else{
            [void]$NewPathList.Add($PathEntry)
        }
    }
    # Add our new path to the bottom
    [void]$NewPathList.Add($Path)
    $NewPath = $NewPathList -Join ';'

    if(!$Force){
        Add-Type -AssemblyName PresentationCore,PresentationFramework
        $answer = [System.Windows.MessageBox]::Show("Add $Path to System PATH?", "Confirmation", "YesNoCancel", "Warning")
        switch ($answer) {
            { @("Yes") -contains $_ } {
                Break
            }
            default {Exit}
        }
    }

    # Set the new variable
    [Environment]::SetEnvironmentVariable('path',$NewPath,'Machine')
    if(!$Force){
        $msgBody = "$Path was successfully added to the system PATH."
        [System.Windows.MessageBox]::Show($msgBody, "Success", 0, "Information")
    }
}

