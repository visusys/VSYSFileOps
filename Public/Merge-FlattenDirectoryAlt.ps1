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
    Merge-FlattenDirectoryAlt -SourcePath "C:\Testing" -DestinationPath "C:\Testing Flat"
    "C:\Testing Flat" will be created and populated with flattened files.

.EXAMPLE
    Merge-FlattenDirectoryAlt -SourcePath "C:\Logs"
    "C:\Logs" will be directly flattened. 

.INPUTS
    System.String (SourcePath and DestinationPath)

.OUTPUTS
    PSCustomObject with Source/Destination/ItemProperties values.

.NOTES
    Name: Merge-FlattenDirectoryAlt
    Author: Visusys
    Release: 1.0.2
    License: MIT License
    DateCreated: 2021-11-20

.LINK
    https://github.com/visusys

.LINK
    Copy-SelectedFilesToNewFolder

#>
function Merge-FlattenDirectoryAlt {
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
        $DestinationPath
    )

    begin {
        $SourcePath = $SourcePath.TrimEnd('\')
        if ($DestinationPath) {
            $DestinationPath = $DestinationPath.TrimEnd('\')
        }
        if(($SourcePath -eq $DestinationPath) -or ($SourcePath -and (!($DestinationPath)))){
            
            $FlattenItself = $true


            $ParentDir          = (Get-Item $SourcePath).Parent.FullName
            $TempDirObject      = New-TempDirectory
            $TempDirPath        = $TempDirObject.FullName
            $TempDirName        = $TempDirObject.Name
            $RelocatedTempDir   = Join-Path $ParentDir $TempDirName
            $DestinationPath    = $TempDirPath

            if((Test-IsSensitiveWindowsPath -Path $ParentDir -Strict).IsSensitive){
                throw [System.IO.IOException] "Path supplied is a protected OS directory."
            }
            if((Test-IsSensitiveWindowsPath -Path $TempDirPath -Strict).IsSensitive){
                throw [System.IO.IOException] "Path supplied is a protected OS directory."
            }
            
        }
        if(!(Test-Path -LiteralPath $DestinationPath -PathType Container)){
            New-Item -Path $DestinationPath -ItemType Container
        }

        $OperationResults = [System.Collections.Generic.List[object]]@()
    }

    process {

        $AllFiles = Get-ChildItem $SourcePath -Recurse | Where-Object { $_.PsIsContainer -eq $false }

        foreach ($File in $AllFiles) {
            $Source = $File.FullName
            $Filename = $File.Name
            $Dest = [IO.Path]::Combine($DestinationPath, $Filename)
            
            # Handle duplicates
            if(Test-Path -LiteralPath $Dest -PathType Leaf){
                $i = 0
                while (Test-Path -LiteralPath $Dest -PathType Leaf) {
                    $i += 1
                    $x = $i + 1
                    $x = ([string]$x).PadLeft(2,'0')
                    $Filename = $File.basename + '_' + $x + $File.extension
                    $Dest = [IO.Path]::Combine($DestinationPath, $Filename)
                }
            }

            Copy-Item -LiteralPath $Source -Destination $Dest -Force
            
            $OperationResultsObj = [PSCustomObject]@{
                Filename         = $Filename
                Source           = $Source
                Destination		 = $Dest
                ItemProperties	 = Get-ItemProperty -Path $Dest
            }

            $OperationResults.Add($OperationResultsObj)
        }

        if($FlattenItself){
            try {
                Move-Item -LiteralPath $TempDirPath -Destination $ParentDir
                Remove-Item $SourcePath -Recurse
                Rename-Item $RelocatedTempDir $SourcePath
            } catch {
                Write-Host "An error occurred:"
                Write-Host $_.ScriptStackTrace
                Exit
            }
            foreach ($ResultsObj in $OperationResults) {
                $ResultsObj.Destination = $SourcePath + '\' + $ResultsObj.Filename
                $ResultsObj.ItemProperties = Get-ItemProperty -Path $ResultsObj.Destination
            }
        }
    }
    end {
        foreach ($ResultsObj in $OperationResults) {
            $ResultsObj
        }
    }
}