<#
.SYNOPSIS
    Flattens the directory structure of a folder. Duplicates are renamed.

.DESCRIPTION
    Flattens the directory structure of a folder. The function removes
    all directories recursively and copies all files to the root folder
    specified by the Directory parameter. 

.PARAMETER Path
    The path of the folder you want to flatten.

.EXAMPLE
    Copy-FlattenFolder -Path "C:\Test"

.INPUTS
    System.String - The directory to flatten.

.OUTPUTS
    Directory Info

.NOTES
    Name: Copy-FlattenFolder
    Author: Visusys
    Release: 1.0.1
    License: MIT License
    DateCreated: 2021-11-22

.LINK
    https://github.com/visusys

.LINK
    Copy-DirectoryAndFlatten

.LINK
    Copy-SelectedFilesToNewFolder
    
#>
function Copy-FlattenFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({
                if (!(Test-Path -LiteralPath $_)) {
                    throw[System.ArgumentException] "Directory doesn't exist." 
                }
                if (!(Test-Path -LiteralPath $_ -PathType Container)) {
                    throw[System.ArgumentException] "Passed value isn't a directory." 
                }
                return $true
            })]
        [string]
        [Alias("directory","folder","dir")]
        $Path
    )

    process {

        $ParentDir = (Get-Item $Path).Parent.ToString()
        $TempDirObject = New-TempDirectory
        $TempDirPath = $TempDirObject.FullName
        $TempDirName = $TempDirObject.Name
        $RelocatedTempDir = Join-Path $ParentDir $TempDirName
        
        try {
            Copy-DirectoryAndFlatten -SourcePath $Path -DestinationPath $TempDirPath | Out-Null
            Move-Item -LiteralPath $TempDirPath -Destination $ParentDir
        } catch {
            Write-Host "An error occurred:"
            Write-Host $_.ScriptStackTrace
            Exit
        }
        
        Remove-Item $Path -Recurse
        Rename-Item $RelocatedTempDir $Path

        Get-Item -LiteralPath $Path
    }
}