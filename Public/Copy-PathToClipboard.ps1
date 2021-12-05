<#
.SYNOPSIS
    Copies paths or filenames to the clipboard.

.DESCRIPTION
    This function will copy both file and folder paths, and optionally
    just filenames. This seems like a simple task, but there are
    a couple enhancements that have been added that set this implementation
    apart from the usual. 
    
    1. All copied paths will be sorted in a human friendly numerical order
    if they contain numbers or sequences of numbers.

    2. Both files and folders will be sorted alphabetically. If both folders 
    and files are passed in to copy, folders will always appear before files.
    No matter what, both will be sorted properly.
    
    3. This function is designed to be called from the right click context
    menu in Windows explorer. It performs much better than the included 
    "Copy as Path" function that ships with Windows.

.PARAMETER Path
    A single path or array of paths to copy.

.PARAMETER FilenamesOnly
    Limits the copy to file names and folder names only.

.PARAMETER SurroundQuotes
    Determines whether the copied text will be surrounded by double quotes.

.EXAMPLE
    Copy-PathToClipboard -Path $ArrayOfFilesAndFolders -SurroundQuotes

.INPUTS
    A single string or array of strings representing file/folder paths.

.OUTPUTS
    Nothing. The clipboard will be populated with data.

.NOTES
    Name: Copy-PathToClipboard
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-12-04

.LINK
    https://github.com/visusys
    
#>
function Copy-PathToClipboard {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [String[]]
        $Path,

        [Parameter(Mandatory=$false)]
        [Switch]
        $FilenamesOnly,

        [Parameter(Mandatory=$false)]
        [Switch]
        $NoQuotes
    )
    Process {

        Add-Type -AssemblyName System.Windows.Forms
        
        $FilenameList   = [System.Collections.ArrayList]@()
        $FoldernameList = [System.Collections.ArrayList]@()
        $CombinedList   = [System.Collections.ArrayList]@()

        if(!$FilenamesOnly){
            foreach ($P in $Path) {
                if(Test-Path -LiteralPath $P -PathType Container){
                    if(!$NoQuotes){
                        $FoldernameList.Add("`"$P`"")
                    }else{
                        $FoldernameList.Add($P)
                    }
                }else{
                    if(!$NoQuotes){
                        $FilenameList.Add("`"$P`"")
                    }else{
                        $FilenameList.Add($P)
                    }
                }
            }
        }else{
            foreach ($P in $Path) {
                if(Test-Path -LiteralPath $P -PathType Container){
                    $Name = [System.IO.Path]::GetFileName($P)
                    if(!$NoQuotes){
                        $FoldernameList.Add("`"$Name`"")
                    }else{
                        $FoldernameList.Add($Name)
                    }
                }else{
                    $Name = [System.IO.Path]::GetFileName($P)
                    if(!$NoQuotes){
                        $FilenameList.Add("`"$Name`"")
                    }else{
                        $FilenameList.Add($Name)
                    }
                }
            }
        }

        [System.Windows.Forms.Clipboard]::Clear()
        $FoldernameList = $FoldernameList | Format-SortNumerical
        $FilenameList   = $FilenameList | Format-SortNumerical 
        
        if($FoldernameList.Count -gt 0){
            if($FoldernameList.Count -eq 1){
                $CombinedList.Add($FoldernameList)
            }else{
                $CombinedList.AddRange($FoldernameList)
            }
        }

        if($FilenameList.Count -gt 0){
            if($FilenameList.Count -eq 1){
                $CombinedList.Add($FilenameList)
            }else{
                $CombinedList.AddRange($FilenameList)
            }
        }

        $CombinedList | Set-Clipboard
    }
}