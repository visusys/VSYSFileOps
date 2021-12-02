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
            if (!(Test-Path -LiteralPath $_ -PathType Container) ) {
                throw "Folder does not exist."
            }
            return $true
        })]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Confirm
    )

    # Add PresentationCore / PresentationFramework to enable MessageBoxes
    Add-Type -AssemblyName PresentationCore,PresentationFramework

    # This script must be run as admin since modifying system wide environment
    # variables requires elevated privileges. We auto-elevate at the wrapper level.
    if(!(Test-IsAdmin)){
        Read-Host -Prompt "This function requires admin privileges. Press any key to exit."
        Exit
    }

    # Get the system PATH environment variable and split by semicolon.
    # This will give us each path entry in the variable.
    # Where-Object here just removes empty lines.
    $RegKey = (Get-Item "HKLM:\System\CurrentControlSet\Control\Session Manager\Environment").GetValue("PATH", $null, "DoNotExpandEnvironmentNames")
    $PathList = $RegKey -split ';'
    $PathList = $PathList | Where-Object {$_}


    # Instantiate a new list to collect path entries.
    $NewPathList = [System.Collections.Generic.List[object]]@()

    # Ensure the path doesn't already exist in the system path. If it does,
    # spawn a MessageBox to alert the user of this information.
    foreach($PathEntry in $PathList) {
        if($PathEntry -eq $Path){
            $Message = "The path ($Path) was already in the system path."
            [System.Windows.MessageBox]::Show($Message, "Duplicate Entry", "Ok", "Error")
            Exit
        }else{
            # Populate the list with existing paths
            [void]$NewPathList.Add($PathEntry)
        }
    }
    # Finally add our new path to the bottom and join everything.
    [void]$NewPathList.Add($Path)
    $NewPath = $NewPathList -Join ';'

    if($Confirm){
        $Result = [System.Windows.MessageBox]::Show("Add $Path to System PATH?", "Confirmation", "YesNoCancel", "Warning")
        switch ($Result) {
            { @("Yes") -contains $_ } {
                Break
            }
            default {
                Exit
            }
        }
    }

    # Set the new environment variable
    [Environment]::SetEnvironmentVariable('path',$NewPath,'Machine')

    # Invoke a MessageBox to confirm the new addition.
    $msgBody = "$Path was successfully added to the system PATH."
    [System.Windows.MessageBox]::Show($msgBody, "Success", 0, "Information")
}

