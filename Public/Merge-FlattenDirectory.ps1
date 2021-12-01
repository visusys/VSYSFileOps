<#
.SYNOPSIS
    Flattens the directory structure of a folder and (optionally) places the results 
    in another directory. Duplicate files are renamed.

.DESCRIPTION
    Flattens the directory structure of a folder. The function removes all 
    directories recursively and copies all files to the root folder specified by the 
    SourcePath parameter. If a destination path is supplied, the results
    will be placed in the destination.

    The resulting directory will only contain files. Duplicates will be serialized.
    Safety checks are built in so that you don't accidentally flatten a system 
    directory. :)

.PARAMETER SourcePath
    The directory you want to flatten.

.PARAMETER DestinationPath
    An optional destination directory to place the flattened data.

.EXAMPLE
    Merge-FlattenDirectory -SourcePath "C:\Testing" -DestinationPath "C:\Testing Flat"
    "C:\Testing Flat" will be created and populated with flattened files.

.EXAMPLE
    Merge-FlattenDirectory -SourcePath "C:\Logs"
    "C:\Logs" will be directly flattened. 

.INPUTS
    System.String (SourcePath and DestinationPath)

.OUTPUTS
    System.IO.FileInfo

.NOTES
    Name: Merge-FlattenDirectory
    Author: Visusys
    Release: 2.0.0
    License: MIT License
    DateCreated: 2021-11-30

.LINK
    https://github.com/visusys

.LINK
    Copy-SelectedFilesToNewFolder

#>
function Merge-FlattenDirectory {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateScript({
                if (!(Test-Path -LiteralPath $_)) {
                    throw [System.ArgumentException] "Path does not exist." 
                }
                if ((Test-IsSensitiveWindowsPath -Path $_ -Strict).IsSensitive) {
                    throw [System.ArgumentException] "Path supplied is a protected OS directory."
                }
                return $true
            })]
        [Alias("source", "input", "i")]
        [string]
        $SourcePath,

        [Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias("destination", "dest", "output", "o")]
        [string]
        $DestinationPath = $null,

        [Parameter(Mandatory=$false)]
        [Switch]
        $Force,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [ValidateSet(1, 2, 3, 4, 5)]
        [int32]
        $DuplicatePadding = 2
    )

    begin {

        # Trim trailing backslashes and initialize a new temporary directory.
        $SourcePath         = $SourcePath.TrimEnd('\')
        $DestinationPath    = $DestinationPath.TrimEnd('\')
        $TempPath           = (New-TempDirectory).FullName

        New-Item -ItemType Directory -Force -Path $TempPath
        
        # Escape $SourcePath so we can use wildcards.
        $Source = [WildcardPattern]::Escape($SourcePath)

        # If there is no $DestinationPath supplied, we can assume the operation is to flatten 
        # only the SourcePath. Thus, we set the DestinationPath to be the same as the SourcePath.
        if (!$DestinationPath) {
            $DestinationPath = $SourcePath

            # Since there is no destination supplied, we move everything to a temporary 
            # directory for further processing.
            Move-Item -Path $Source'\*' -Destination $TempPath -Force

        }else{

            # We need to perform some parameter validation on DestinationPath:

            # Make sure the passed Destination is not a file
            if(Test-Path -LiteralPath $DestinationPath -PathType Leaf){
                throw [System.IO.IOException] "Please provide a valid directory, not a file."
            }

            # Make sure the passed Destination is a validly formed Windows path.
            if(!(Confirm-ValidWindowsPath -Path $DestinationPath -Container)){
                throw [System.IO.IOException] "Invalid Destination Path. Please provide a valid directory."
            }

            # Make sure the passed Destination is not in a protected or sensitive OS location.
            if((Test-IsSensitiveWindowsPath -Path $DestinationPath -Strict).IsSensitive){
                throw [System.IO.IOException] "The destination path is, or resides in a protected operating system directory."
            }

            # Since a destination was supplied, we copy everything to a new temp directory 
            # instead of moving everything. We want the source directory to remain untouched.

            # Robocopy seems to be the most performant here.
            # Robocopy on Large Dataset:  ~789ms - ~810ms
            # Copy-Item on Large Dataset: ~1203ms - ~1280ms
            #
            # Copy-Item -Path $Source'\*' -Destination $TempPath -Force -Recurse
            Robocopy $Source $TempPath /COPYALL /B /E /R:0 /W:0 /NFL /NDL /NC /NS /NP /MT:48

            # Create the destination directory now, ready for population in the process block.
            New-Item -ItemType Directory -Force -Path $DestinationPath

            # Write-Host "`$TempPath:" $TempPath -ForegroundColor Green
        }

        # Immediately grab all files as an Array of FileInfo Objects
        $AllFiles = [IO.DirectoryInfo]::new($TempPath).GetFiles('*', 'AllDirectories')
        
    }

    process {

        ##
        # $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        # 

        # Initialize array to store duplicate files
        $Duplicates = @{}
        
        # Iterate over all files
        foreach ($File in $AllFiles) {

            # If our $Duplicates array already contains the current filename, we have a duplicate.
            if ($Duplicates.Contains($File.Name)) {

                # Rename the duplicate file by appending a numerical index to the end of the file.
                $PathTemp = Get-ItemProperty -LiteralPath $File
                $RenamedFile = Rename-Item -LiteralPath $PathTemp.PSPath -PassThru -NewName ('{0}_{1}{2}' -f @(
                    $File.BaseName
                    $Duplicates[$File.Name].ToString().PadLeft($DuplicatePadding, '0')
                    $File.Extension
                ))

                # Increment the duplicate counter and pass $File down to be moved.
                $Duplicates[$File.Name]++
                $File = $RenamedFile

            } else {

                # No duplicates were detected. Add a value of 1 to the duplicates array to represent 
                # the current file. Pass $File down to be moved.
                $PathTemp = Get-ItemProperty -LiteralPath $File
                $Duplicates[$File.Name] = 1
                $File = $PathTemp
            }

            # If Force is specified, we don't have to worry about duplicate files,
            # as the operation will overwrite every file with a duplicate filename
            if($Force){

                # Move the file to its appropriate destination. (Force)
                Move-Item -LiteralPath $File -Destination $DestinationPath -Force
            }else{
                try {

                    # Move the file to its appropriate destination. (Non-Force)
                    Move-Item -LiteralPath $File -Destination $DestinationPath -ErrorAction Stop
                } catch {

                    # Warn the user that files were skipped because of duplicate filenames.
                    Write-Warning "$($File.Name) already exists in the destination folder. Skipping this file."
                }
            }

            # Return each file to the pipeline.
            # $File
        }

        # $Stopwatch.Stop()
        # Write-Host "`$Stopwatch.Elapsed:            " $Stopwatch.Elapsed -ForegroundColor Green  
        # Write-Host "`$Stopwatch.ElapsedMilliseconds:" $Stopwatch.ElapsedMilliseconds -ForegroundColor Green
        # Write-Host "`$Stopwatch.ElapsedTicks:       " $Stopwatch.ElapsedTicks -ForegroundColor Green 
    }

    end {
        
    }
}

# Merge-FlattenDirectory "C:\Users\futur\Desktop\Testing\Test" "C:\Users\futur\Desktop\Testing\TestFlat" -Force