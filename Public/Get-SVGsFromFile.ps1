
<#
.SYNOPSIS
    Extracts individual SVGs from a single HTML document. 

.DESCRIPTION
    The function reads the full text of an HTML file, isolates <SVG> code blocks
    and then places these code blocks into a separate SVG file with a random filename.

.PARAMETER Source
    Source file containing any number of complete <SVG> tags and definitions.

.PARAMETER Destination
    A directory to output the newly created .SVG files. Doesn't have to exist.

.NOTES
    Name: Get-SVGsFromFile
    Author: Visusys
    Version: 1.0.0
    DateCreated: 2021-11-16

.EXAMPLE
    Get-SVGsFromFile -Source "C:\Users\username\Desktop\icons.html" -Destination 'C:\IconOutput' 
    
.LINK
    https://github.com/visusys
#>
function Get-SVGsFromFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({
                if (-Not ($_ | Test-Path) ) {
                    throw "File or folder does not exist" 
                }
                return $true
        })]
        [string]
        $Source,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
                Confirm-WindowsPathIsValid -Path $_ -Container
        })]
        [string]
        $Destination
    )

    if($Destination){
        $Destination = $Destination.TrimEnd('\')
        if(!(Test-Path -Path $Destination)){
            New-Item -Path $Destination -ItemType "directory"
        }
    }

    $regex = '<svg\b[^>]*?>[\s\S]*?<\/svg>'
    $outpt = select-string -Path $Source -Pattern $regex -AllMatches
    foreach ($match in $outpt.Matches) {
        $file = ((Get-RandomAlphanumericString -Length 14) + '.svg')
        if($Destination){
            $file = $Destination + '\' + $file
        }else{
            $srcd = ([System.IO.FileInfo]$Source).DirectoryName
            $file = $srcd + '\' + $file
        }
        Add-Content $file $match.Value -Encoding UTF8
    }
}

#Get-SVGsFromFile -Source "D:\Dev\Powershell\Modules\VSYSFileOps\Ignore\SVGPackage.txt" 