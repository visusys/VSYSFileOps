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
    PSCustomObject with Source/Destination/ItemProperties values.

.NOTES
    Name: Merge-FlattenDirectory
    Author: Visusys
    Release: 1.0.2
    License: MIT License
    DateCreated: 2021-11-20

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
            if(!(Test-Path -LiteralPath $_)){
                throw [System.ArgumentException] "Path does not exist." 
            }
            if((Test-IsSensitiveWindowsPath -Path $_ -Strict).IsSensitive){
                throw [System.ArgumentException] "Path supplied is a protected OS directory."
            }
            return $true
        })]
        [Alias("source","input","i")]
        [string]
        $SourcePath,

        [Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if(!(Confirm-ValidWindowsPath $_ -Container -Absolute)){
                throw [System.ArgumentException] "Path is not valid."
            }
            if((Test-IsSensitiveWindowsPath -Path $_ -Strict).IsSensitive){
                throw [System.ArgumentException] "Path supplied is a protected OS directory."
            }
            return $true 
        })]
        [Alias("destination","dest","output","o")]
        [string]
        $DestinationPath,

        [Parameter(Mandatory=$false)]
        [ValidateSet(1, 2, 3, 4, 5, IgnoreCase = $true)]
        [Int32]
        $Padding = 3
    )

    begin {
        $SourcePath = $SourcePath.TrimEnd('\')
        if ($DestinationPath) {
            $DestinationPath = $DestinationPath.TrimEnd('\')
        }

        if($SourcePath -and (!($DestinationPath))){
            $DestinationPath = $SourcePath
        }

        $TempDirObject      = New-TempDirectory
        $TempDirPath        = $TempDirObject.FullName
        
        if(!(Test-Path -LiteralPath $TempDirPath -PathType Container)){
            New-Item -LiteralPath $TempDirPath -ItemType Container
        }
        
        Copy-Item -LiteralPath $SourcePath -Destination $TempDirPath -Force -Recurse

        $Hash = @{}
        $AllFiles = [IO.DirectoryInfo]::new($TempDirPath).GetFiles('*', 'AllDirectories')
        $FileList = [System.Collections.Generic.List[object]]@()

    }

    process {
        
        foreach ($File in $AllFiles) {
            $Key = $File.Name
            # Create Generic List to hold groups, store FileInfo objects in this list
            # Specialized generic lists are faster than ArrayList
            if ($Hash.ContainsKey($Key) -eq $false) {
                $Hash[$Key] = [Collections.Generic.List[System.IO.FileInfo]]::new()
            }
            $Hash[$Key].Add($File)
        }

        foreach ($pile in $Hash.Values) {
            if ($pile.Count -gt 1) {
                $i = 1
                foreach ($pileitem in $pile) {
                    # $pileitem # System.IO.FileSystemInfo
                    $fileobj = [PSCustomObject]@{
                        FilenameOld	   = $pileitem.Name
                        FilenameNew	   = $pileitem.Name
                        FileSystemInfo = $pileitem
                    }
                    if ($i -gt 1) {
                        $x = ([string]$i).PadLeft($Padding,'0')
                        $fileobj.FilenameNew = $pileitem.BaseName + '_' + $x + $pileitem.Extension
                        $FileList.Add($fileobj)
                    }else{
                        $FileList.Add($fileobj)
                    }
                    $i += 1
                }
            }else{
                $fileobj = [PSCustomObject]@{
                    FilenameOld	    = $pile[0].Name
                    FilenameNew	    = $pile[0].Name
                    FileSystemInfo  = $pile[0]
                }
                $FileList.Add($fileobj)
            }
        }

        if($SourcePath -eq $DestinationPath){
            Remove-Item $SourcePath -Recurse
        }

        if(!(Test-Path -LiteralPath $DestinationPath -PathType Container)){
            New-Item -Path $DestinationPath -ItemType Container
        }

        foreach ($Object in $FileList) {

            $ToRename =  [IO.Path]::Combine($Object.FileSystemInfo.DirectoryName, $Object.FilenameOld)
            $ToMove   =  [IO.Path]::Combine($Object.FileSystemInfo.DirectoryName, $Object.FilenameNew)

            Rename-Item -LiteralPath $ToRename -NewName $Object.FilenameNew
            Move-Item -LiteralPath $ToMove -Destination $DestinationPath
        }
    }
}

# Merge-FlattenDirectory "C:\Users\futur\Desktop\Testing\Test"
