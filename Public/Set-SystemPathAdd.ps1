<#
.SYNOPSIS
    This script will add a directory to your system PATH variable.

.PARAMETER Path
    The directory you wish to add to your system PATH variable. 

.PARAMETER NoConfirm
    Surpresses messagebox confirmations throughout the process.

.EXAMPLE
    Set-SystemPathAdd -Path 'C:\Program Files\nodejs\' -NoConfirm

.EXAMPLE
    Set-SystemPathAdd -Path 'C:\Program Files\Git\cmd'

.INPUTS
    System.String: The path you wish to add to your system PATH environment variable.

.OUTPUTS
    Nothing.

.NOTES
    Name: Set-SystemPathAdd
    Author: Visusys
    Release: 1.1.0
    License: MIT License
    DateCreated: 2021-11-19

.LINK
    https://github.com/visusys
    
#>
Function Set-SystemPathAdd {
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

    # Ensure the path doesn't already exist in the system path. If it does,
    # spawn a MessageBox to alert the user of this information.
    $FoundPathEntry = $false
    $PathNoTrailingBackslash = $Path.TrimEnd('\')
    $PathWithTrailingBackslash = $PathNoTrailingBackslash + '\'
    foreach($PathEntry in $PathList) {
        if(($PathEntry -eq $PathNoTrailingBackslash) -or ($PathEntry -eq $PathWithTrailingBackslash)){
            $FoundPathEntry = $true
            Break
        }else{
            # Populate the list with existing paths
            [void]$NewPathList.Add($PathEntry)
        }
    }

    if($FoundPathEntry){
        if(!$NoConfirm){
            $MBMessage			= "The path $Path was already in your system path environment variable."
            $MBTitle			= "Path already exists"
            $MBButtons		    = [System.Windows.Forms.MessageBoxButtons]::OK
            $MBIcon				= [System.Windows.Forms.MessageBoxIcon]::Error
            $MBDefaultButton	= [System.Windows.Forms.MessageBoxDefaultButton]::Button1
            $MBResult			= [System.Windows.Forms.MessageBox]::Show($MBMessage, $MBTitle, $MBButtons, $MBIcon, $MBDefaultButton)
        }
        Exit
    }

    if(!$NoConfirm){

        $MBMessage			= "Add $Path to your System PATH environment variable?"
        $MBTitle			= "Confirm addition"
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

    # Add our new path to the bottom and join everything.
    [void]$NewPathList.Add($Path)
    $NewPath = $NewPathList -Join ';'

    # Set the new environment variable
    [Environment]::SetEnvironmentVariable('path',$NewPath,'Machine')

    # Invoke a MessageBox to confirm the new addition.
    # This supercedes the Confirm switch
    $MBMessage			= "$Path was successfully added to the system PATH environment variable."
    $MBTitle			= "Successful Addition"
    $MBButtons		    = [System.Windows.Forms.MessageBoxButtons]::OK
    $MBIcon				= [System.Windows.Forms.MessageBoxIcon]::Information
    $MBDefaultButton	= [System.Windows.Forms.MessageBoxDefaultButton]::Button1 
    $MBResult           = [System.Windows.MessageBox]::Show($MBMessage, $MBTitle, $MBButtons, $MBIcon, $MBDefaultButton)

}