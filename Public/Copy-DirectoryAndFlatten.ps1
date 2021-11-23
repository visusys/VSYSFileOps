<#
.SYNOPSIS
    Copies a folder and its contents to another location and flattens the directory.

.DESCRIPTION
    Copies a folder and its contents to another location and flattens the directory.
    The resulting directory will only contain files. Duplicates will be serialized.
    Safety checks are built in so that you don't accidentally flatten a system 
    directory. :)

.PARAMETER SourcePath
    The source directory you want to copy and flatten.

.PARAMETER DestinationPath
    The destination directory that will be flattened.

.EXAMPLE
    Copy-DirectoryAndFlatten -SourcePath "C:\Testing" -DestinationPath "C:\TestingFlat"

.INPUTS
    System.String (SourcePath and DestinationPath)

.OUTPUTS
    PSCustomObject with Source/Destination/ItemProperties values.

.NOTES
    Name: Copy-DirectoryAndFlatten
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-11-20

.LINK
    https://github.com/visusys

.LINK
    Copy-SelectedFilesToNewFolder

#>
function Copy-DirectoryAndFlatten {
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

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
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

    process {
        
        $SourcePath = $SourcePath.TrimEnd('\')
        $DestinationPath = $DestinationPath.TrimEnd('\')

        if($SourcePath -eq $DestinationPath){
            throw "Source and destination paths are identical. Aborting."
        }

        if(!(Test-Path -LiteralPath $DestinationPath -PathType Container)){
            New-Item -Path $DestinationPath -ItemType Container
        }

        $AllFiles = Get-ChildItem $SourcePath -Recurse | Where-Object { $_.PsIsContainer -eq $false }

        foreach ($File in $AllFiles) {
            $Source = $File.FullName
            $Dest = [IO.Path]::Combine($DestinationPath, $File.Name)

            # Handle duplicates
            if(Test-Path -LiteralPath $Dest -PathType Leaf){
                $i = 0
                while (Test-Path -LiteralPath $Dest -PathType Leaf) {
                    $i += 1
                    $x = $i + 1
                    $x = ([string]$x).PadLeft(2,'0')
                    $Dest = $DestinationPath + "\" + $File.basename + '_' + $x + $File.extension
                }
            }
            #TODO: Add Robocopy Support
            Copy-Item -LiteralPath $Source -Destination $Dest -Force

            $OperationResults = [PSCustomObject]@{
                Source          = $Source
                Destination		= $Dest
                ItemProperties	= Get-ItemProperty -Path $Dest
            }
            $OperationResults
        }
    }
}