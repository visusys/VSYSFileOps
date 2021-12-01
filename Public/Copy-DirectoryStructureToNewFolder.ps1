<#
.SYNOPSIS
    Copies the directory structure from one folder to another.

.DESCRIPTION
    Copies the directory structure from one folder to another. 
    Only folders will exist in the destination.

.PARAMETER SourcePath
    The target directory to copy folder structure from.

.PARAMETER NewFolderSuffix
    The suffix added to the newly created directory.

.PARAMETER Force
    Ignore prompts and duplicate folder warnings.

.EXAMPLE
    Copy-DirectoryStructureToNewFolder -SourcePath "C:\Test"
    > 'C:\Test Duplicate' will be created with a mirrored directory structure.

.INPUTS
    String (SourcePath)

.OUTPUTS
    By default, this function does not generate any output.

.NOTES
    Name: Copy-DirectoryStructureToNewFolder
    Author: Visusys
    Release: 1.0.1
    License: MIT License
    DateCreated: 2021-12-01

.LINK
    https://github.com/visusys

.LINK
    Move-SelectedFilesToNewFolder

.LINK
    Merge-FlattenDirectory
    
#>
Function Copy-DirectoryStructureToNewFolder{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateScript({
                if (!(Test-Path -LiteralPath $_)) {
                    throw [System.ArgumentException] "Path does not exist." 
                }
                if (!(Test-Path -LiteralPath $_ -PathType Container)) {
                    throw [System.ArgumentException] "Source parameter is not a valid path."
                }
                return $true
            })]
        [Alias("source", "path")]
        [string]
        $SourcePath,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [String]
        $NewFolderSuffix = "Duplicate",

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        Add-Type -AssemblyName PresentationCore, PresentationFramework
    }
    
    process {
        ##
        # $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        # 

        $DestParent = (Get-Item -LiteralPath $SourcePath).Parent
        $DestBaseName = (Get-Item -LiteralPath $SourcePath).BaseName + " " + $NewFolderSuffix
        $DestPath = [IO.Path]::Combine($DestParent, $DestBaseName)
    
        while(Test-Path -Path $DestPath -PathType Container){
            if($Force) {
                Break
            }
            $Message = "The destination path already exists. Continue anyway?"
            $Selection = [System.Windows.MessageBox]::Show($Message, 'Continue operation', 'YesNoCancel', 'Warning')
            if($Selection -eq 'Yes'){
                Break
            }else{
                Exit
            }
        }

        robocopy $SourcePath $DestPath /e /xf *.* /R:0 /W:0 /NFL /NDL /NC /NS /NP /MT:48 | Out-Null

        # $Stopwatch.Stop()
        # Write-Host "`$Stopwatch.Elapsed:            " $Stopwatch.Elapsed -ForegroundColor Green  
        # Write-Host "`$Stopwatch.ElapsedMilliseconds:" $Stopwatch.ElapsedMilliseconds -ForegroundColor Green
        # Write-Host "`$Stopwatch.ElapsedTicks:       " $Stopwatch.ElapsedTicks -ForegroundColor Green 
    }
}