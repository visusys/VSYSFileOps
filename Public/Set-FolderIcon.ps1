<#
.SYNOPSIS
    Changes the icon of a folder or multiple folders.

.PARAMETER Folder
    Path or an array of paths to change the icon of.

.PARAMETER Icon
    Path to the .ico file that will be applied to the folder or folders.

.PARAMETER Reset
    Resets the folder or folders to their default icons. 
    You must omit the Icon parameter for this to work.

.EXAMPLE
    Set-FolderIcon "C:\Dev\Powershell" -Icon "C:\icons\apps\PowershellIcon.ico"
    > Changes the icon of C:\Dev\Powershell to PowershellIcon.ico

.EXAMPLE
    Set-FolderIcon "C:\Dev\Powershell" -Reset
    > Resets the icon of C:\Dev\Powershell to default.

.EXAMPLE
    Set-FolderIcon $ArrayOfFolders -Icon "C:\icons\folders\CheckmarkFolder.ico"
    > Changes the icon for all folders in $ArrayOfFolders to CheckmarkFolder.ico

.EXAMPLE
    Set-FolderIcon $ArrayOfFolders -Reset
    > Resets the icon for all folders in $ArrayOfFolders to default.

.INPUTS
    String[] A folder or array of folders.

.OUTPUTS
    An object with references to all affected folders.

.NOTES
    Name: Set-FolderIcon
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-12-07

.LINK
    https://github.com/visusys

.LINK
    Convert-SVGtoICO
    
#>
function Set-FolderIcon {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "All", Position = 0)]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Icon", Position = 0)]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Reset", Position = 0)]
        [ValidateScript({
            if (!(Test-Path -LiteralPath $_)) {
                throw [System.ArgumentException] "File or Folder does not exist."
            }
            if (Test-Path -LiteralPath $_ -PathType Leaf) {
                throw [System.ArgumentException] "File passed when a folder was expected."
            }
            return $true
        })]
        [String[]]
        $Folder,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "Icon")]
        [ValidateScript({
            if (!(Test-Path -LiteralPath $_)) {
                throw [System.ArgumentException] "File or Folder does not exist."
            }
            if (Test-Path -LiteralPath $_ -PathType Container) {
                throw [System.ArgumentException] "Folder passed when a file was expected."
            }
            if ($_ -notmatch "(\.ico)") {
                throw [System.ArgumentException] "The file specified must be of type .ico"
            }
            return $true
        })]
        [String]
        $Icon,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = "Reset")]
        [Switch]
        $Reset
    )

    process {
        foreach ($FolderToChange in $Folder) {
            if(!($Reset)){

                # Create a temp directory to store our
                # desktop.ini file before moving it
                $TmpDir = (Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName()))
                mkdir $TmpDir -force >$null
                $TmpIniPath = "$TmpDir\desktop.ini"

                # Define desktop.ini content
                $INIContent = @(
                "[.ShellClassInfo]"
                "IconFile=$Icon"
                "IconIndex=0"
                "ConfirmFileOp=0"
                ""
                ) -join "`r`n"

                # Pipe desktop.ini content out into an actual file.
                $INIContent | Out-File $TmpIniPath -Force
                (Get-Item -LiteralPath $TmpIniPath).Attributes = 'Archive, System, Hidden'

                # Remove existing desktop.ini file if 
                # it exists in our target folder
                $IniFilePath = "$FolderToChange\desktop.ini"
                if(Test-Path -LiteralPath $IniFilePath -PathType Leaf){
                    Remove-Item -LiteralPath $IniFilePath -Force
                }

                # Desktop.ini must be updated using a Shell API method 
                # in order for the Shell/Explorer to be notified
                # This is the secret sauce for getting icons to display
                # and refresh immediately.
                # 
                # FOF_SILENT            0x0004 don't display progress UI
                # FOF_NOCONFIRMATION    0x0010 don't display confirmation UI, assume "yes" 
                # FOF_NOERRORUI         0x0400 don't put up error UI
                # 
                $shell = New-Object -com Shell.Application
                $shell.NameSpace($FolderToChange).MoveHere($TmpIniPath, 0x0004 + 0x0010 + 0x0400)

                # Clean up and remove our temp directory
                Remove-Item -LiteralPath $TmpDir -Recurse -Force

                # Set the ReadOnly attribute on our folder so
                # Explorer knows to use the desktop.ini file.
                $FolderObject = Get-Item -LiteralPath $FolderToChange
                $FolderObject.Attributes = 'ReadOnly,Directory'

            }else{

                # Reset code:
                # Remove desktop.ini and revert folder attributes
                if(Test-Path -LiteralPath "$FolderToChange\desktop.ini" -PathType Leaf){
                    Remove-Item -LiteralPath "$FolderToChange\desktop.ini" -Force
                }
                (Get-Item -LiteralPath $FolderToChange).Attributes = 'Directory'
            }
        }
    }

    end {
        # Refresh the icon cache just for good measure
        $cmd = 'ie4uinit.exe -show'
        Invoke-Expression $cmd
    }
}