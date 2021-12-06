<#
.SYNOPSIS
    This script will remove a directory from your system PATH variable.

.PARAMETER Path
    The directory you wish to remove from your system PATH variable. 

.PARAMETER NoConfirm
    Surpresses messagebox confirmations throughout the process.

.EXAMPLE
    Set-SystemPathRemove -Path 'C:\Program Files\nodejs\' -NoConfirm

.EXAMPLE
    Set-SystemPathRemove -Path 'C:\Program Files\Git\cmd'

.INPUTS
    System.String (Path)
    The path you wish to remove from your system PATH environment variable.

.OUTPUTS
    Nothing.

.NOTES
    Name: Set-SystemPathRemove
    Author: Visusys
    Release: 1.1.0
    License: MIT License
    DateCreated: 2021-11-19

.LINK
    Add-ToSystemPath

.LINK
    https://github.com/visusys
    
#>
Function Set-SystemPathRemove {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$NoConfirm
    )

    # Add PresentationCore / PresentationFramework to enable MessageBoxes
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    [System.Windows.Forms.Application]::EnableVisualStyles()

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

    # Ensure the path exists in the system path. If it does,
    # Skip adding the entry and spawn a message box to alert
    # the user that the path was found and removed.
    $FoundPathEntry = $false
    $PathNoTrailingBackslash = $Path.TrimEnd('\')
    $PathWithTrailingBackslash = $PathNoTrailingBackslash + '\'
    foreach($PathEntry in $PathList) {
        if(($PathEntry -eq $PathWithTrailingBackslash) -or ($PathEntry -eq $PathNoTrailingBackslash)){
            $FoundPathEntry = $true
        }else{
            # Populate the list with existing paths
            [void]$NewPathList.Add($PathEntry)
        }
    }
    # Finally add our new path to the bottom and join everything.
    $NewPath = $NewPathList -Join ';'

    
    if($FoundPathEntry){
        if(!$NoConfirm){

            $MBMessage			= "Remove $Path from System PATH environment variable?"
            $MBTitle			= "Confirm remove"
            $MBButtons		    = [System.Windows.Forms.MessageBoxButtons]::YesNoCancel
            $MBIcon				= [System.Windows.Forms.MessageBoxIcon]::Warning
            $MBDefaultButton	= [System.Windows.Forms.MessageBoxDefaultButton]::Button1
            $MBResult			= [System.Windows.Forms.MessageBox]::Show($MBMessage, $MBTitle, $MBButtons, $MBIcon, $MBDefaultButton)

            switch ($MBResult) {
                { @("Yes") -contains $_ } {
                    Break
                }
                default {
                    Exit
                }
            }
        }
    } else {

        if(!$NoConfirm){

            $MBMessage			= "$Path was not found in your System PATH environment variable."
            $MBTitle			= "Path not found error"
            $MBButtons		    = [System.Windows.Forms.MessageBoxButtons]::OK
            $MBIcon				= [System.Windows.Forms.MessageBoxIcon]::Error
            $MBDefaultButton	= [System.Windows.Forms.MessageBoxDefaultButton]::Button1
            $MBResult			= [System.Windows.Forms.MessageBox]::Show($MBMessage, $MBTitle, $MBButtons, $MBIcon, $MBDefaultButton)
    
            Exit
        }
    }
    

    # Set the new environment variable
    [Environment]::SetEnvironmentVariable('path',$NewPath,'Machine')

    # Invoke a MessageBox to confirm the new removal.
    # This supercedes the NoConfirm switch
    $MBMessage			= "$Path was successfully removed from the system PATH environment variable."
    $MBTitle			= "Success"
    $MBButtons		    = [System.Windows.Forms.MessageBoxButtons]::OK
    $MBIcon				= [System.Windows.Forms.MessageBoxIcon]::Information
    $MBDefaultButton	= [System.Windows.Forms.MessageBoxDefaultButton]::Button1 
    $MBResult           = [System.Windows.MessageBox]::Show($MBMessage, $MBTitle, $MBButtons, $MBIcon, $MBDefaultButton)

}
