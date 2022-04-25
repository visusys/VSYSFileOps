
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
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if (!(Test-Path -LiteralPath $_)) {
                throw [System.ArgumentException] "File or Folder does not exist."
            }
            if (Test-Path -LiteralPath $_ -PathType Container) {
                throw [System.ArgumentException] "Folder passed when a file was expected."
            }
            return $true
        })]
        [String]
        $Source,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if (Test-Path -LiteralPath $_ -PathType Leaf) {
                throw [System.ArgumentException] "File passed when a folder was expected."
            }
            return $true
        })]
        [string]
        $Destination
    )

    process {

        $Destination = $Destination.TrimEnd('\')

        Write-Host "INIT: Process Block."
        Write-Host "Destination: $Destination"

        if(!(Test-Path -LiteralPath $Destination)){
            New-Item -Path $Destination -ItemType "Directory" -Force
        }

        $regex = '<svg\b[^>]*?>[\s\S]*?<\/svg>'
        $SVGFiles = select-string -Path $Source -Pattern $regex -AllMatches

        $BaseName = ([IO.Path]::GetFileNameWithoutExtension($Source))

        foreach ($SVGFile in $SVGFiles.Matches) {

            $RND = Get-RandomAlphanumericString -Length 4
            $EXT = '.svg'
            $FileName  = $BaseName + "_" + $RND + $EXT

            $NewFile = [IO.Path]::Combine($Destination, $FileName)
            Write-Host "`$NewFile:" $NewFile -ForegroundColor Green
            Add-Content $NewFile $SVGFile.Value -Encoding UTF8
        }

        Invoke-GUIMessageBox -Message "Conversion complete." -Title "Conversion Complete" -Buttons OK -Icon Information
    }
}