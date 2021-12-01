
<#
.SYNOPSIS
    Moves selected files to a new folder.

.DESCRIPTION
    Moves selected files to a new folder. This script is meant to
    be invoked through a context menu in Windows explorer. 
    The name of the new folder can be specified with NewFolderName.
    This function will fail if each passed file doesn't share the same
    parent directory. 

.PARAMETER SourceFiles
    An array of strings corresponding to files that should be moved.

.PARAMETER NewFolderName
    The name of the final folder that files will be moved to.

.EXAMPLE
    Move-SelectedFilesToNewFolder -SourceFiles $FileNames
    > Moves all files within $FileNames to a new folder.

.EXAMPLE
    Move-SelectedFilesToNewFolder -SourceFiles $FileNames -NewFolderName "Backup"
    > Moves all files within $FileNames to a new folder called "Backup".

.INPUTS
    Either a single string or an array of strings corresponding to files on 
    the filesystem to be moved.

.OUTPUTS
    By default, this function does not generate any output.

.NOTES
    Name: Move-SelectedFilesToNewFolder
    Author: Visusys
    Release: 1.1.0
    License: MIT License
    DateCreated: 2021-12-01

.LINK
    https://github.com/visusys

.LINK
    Copy-DirectoryStructure

.LINK
    Merge-FlattenDirectory
    
#>
Function Move-SelectedFilesToNewFolder {

    [CmdletBinding()]

    Param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [ValidateScript({
            if(!(Test-Path -LiteralPath $_)){
                throw "File or folder does not exist."
            }
            return $true
        })]
        [String[]]
        $SourceFiles,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [string]
        $NewFolderName = "New Folder"
    )

    process {

        ##
        # $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Initialize directory variable for comparison
        $Directory = ''
        foreach($File in $SourceFiles) {

            # Get a System.IO.FileInfo object to work with and test
            # to make sure all passed files share the same parent.
            $File = Get-ItemProperty -LiteralPath $File
            if(!$Directory){
                $Directory = $File.Directory.FullName
            }
            if($Directory -ne $File.Directory.FullName){
                throw "Not all files are in the same directory."
            }
        }

        # Resolve the final path to recieve files and create it. 
        $FinalPath = [IO.Path]::Combine($Directory, $NewFolderName)
        New-Item -Path $FinalPath -ItemType Directory -Force

        # Move all files passed in to SourceFile to the new directory.
        # Catch errors to notify end-user on soft fail.
        foreach ($File in $SourceFiles) {
            $File = Get-ItemProperty -LiteralPath $File
            $FinalFile = [IO.Path]::Combine($FinalPath, $File.Name)
            try {
                Move-Item -LiteralPath $File.FullName -Destination $FinalFile -ErrorAction Stop
            } catch {
                Write-Warning "Cannot create a file when that file already exists."
            }
        }
    }

    end {
        # $Stopwatch.Stop()
        # Write-Host "`$Stopwatch.Elapsed:            " $Stopwatch.Elapsed -ForegroundColor Green  
        # Write-Host "`$Stopwatch.ElapsedMilliseconds:" $Stopwatch.ElapsedMilliseconds -ForegroundColor Green
        # Write-Host "`$Stopwatch.ElapsedTicks:       " $Stopwatch.ElapsedTicks -ForegroundColor Green
    }
}

<# [string[]]$FilesToCopy = @(
    'C:\Users\futur\Desktop\Testing\Test Copy Selected\1088_p.jpg',
    'C:\Users\futur\Desktop\Testing\Test Copy Selected\04175_thecitythatneversleeps_2560x1440.jpg',
    'C:\Users\futur\Desktop\Testing\Test Copy Selected\04177_paradiseatbacarasantabarbara_2560x1440.jpg'
    'C:\Users\futur\Desktop\Testing\Test Copy Selected\04179_beachatpuntacana_2560x1440.jpg'
)

Move-SelectedFilesToNewFolder $FilesToCopy #>
