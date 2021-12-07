<#
.SYNOPSIS
    Converts any image to PNG format.

.DESCRIPTION
    Converts any image to PNG format.
    Dependancy: Requires ImageMagick to be installed and available
    in the System PATH environment variable.

.PARAMETER SourceFiles
    Image or Images to convert to PNG.

.EXAMPLE
    Convert-ImageToPNG -SourceFiles $ABunchOfImages

.INPUTS
    String[]

.OUTPUTS
    Nothing.

.NOTES
    Name: Convert-ImageToPNG
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-12-06

.LINK
    https://github.com/visusys

.LINK
    Convert-SVGtoICO
    
#>
Function Convert-ImageToPNG {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({
                if (!(Test-Path -LiteralPath $_)) {
                    throw [System.ArgumentException] "File does not exist." 
                }
                if (!(Test-Path -LiteralPath $_ -PathType Leaf)) {
                    throw [System.ArgumentException] "A folder was passed when a file was expected." 
                }
                return $true
            })]
        [String[]]
        $SourceFiles
    )

    # Add PresentationCore / PresentationFramework to enable MessageBoxes
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $SourceFiles | ForEach-Object -Parallel {
        $MagickArgs = [System.Collections.ArrayList]@()
        $File       = $_
        $OrgFile    = [System.IO.Path]::GetFullPath($File)
        $NewFile    = [System.IO.Path]::ChangeExtension($File, "png")
        
        $MagickArgs.Add($OrgFile)  | Out-Null
        $MagickArgs.Add($NewFile)  | Out-Null

        magick @MagickArgs
    } -ThrottleLimit 20

    if($SourceFiles.Count -gt 1){
        $MBMessage			= "Conversion to PNG Complete."
        $MBTitle			= "Conversion Complete"
        $MBButtons		    = [System.Windows.Forms.MessageBoxButtons]::OK
        $MBIcon				= [System.Windows.Forms.MessageBoxIcon]::Information
        $MBDefaultButton	= [System.Windows.Forms.MessageBoxDefaultButton]::Button1
        [System.Windows.Forms.MessageBox]::Show($MBMessage, $MBTitle, $MBButtons, $MBIcon, $MBDefaultButton)
    }
}