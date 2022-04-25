<#
.SYNOPSIS
    Converts an OBJ or STL file to VOX format (MagicaVoxel)

.PARAMETER Paths
    A list of file paths pointing to the files to be converted.

.PARAMETER Resolution
    The resolution of the final VOX file. Specify "All" to convert
    to 16, 32, 64, 128, 256, 512, 1024 automatically.

.EXAMPLE
    Convert-OBJ2VOX $OBJPaths -Resolution 'All'

.INPUTS
    String[]

.OUTPUTS
    Nothing. Saves all conversions in the same directory as the OBJ/STL file.

.NOTES
    Name: Convert-OBJ2VOX
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2022-01-10

.LINK
    https://github.com/visusys

.LINK
    Convert-SVGtoICO

.LINK
    Convert-ImageToPNG
    
#>
function Convert-OBJ2VOX {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [ValidateScript({
            if (!(Test-Path -LiteralPath $_)) {
                throw [System.ArgumentException] "File or Folder does not exist."
            }
            if (Test-Path -LiteralPath $_ -PathType Container) {
                throw [System.ArgumentException] "Folder passed when a file was expected."
            }
            if ($_ -notmatch "(\.obj|\.stl)") {
                throw [System.ArgumentException] "The file specified must be either of type OBJ or STL"
            }
            return $true
        })]
        [String[]]
        $Paths,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
        [ValidateScript( { $_ -eq 'All' -or ($_ -as [int] -and [int]$_ -le 2048) }, ErrorMessage = "Resolution must be a non-zero integer below 2048 or 'All'." )]
        [String[]]
        $Resolution
    )

    Process {

        if($Resolution -eq 'All') {
            $Resolution = @(16,32,64,128,256,512)
        }else{
            $Resolution = @($Resolution)
        }
        
        foreach ($Path in $Paths) {
            $Resolution | ForEach-Object -Parallel {
                $Path     = $Using:Path
                $InpObj   = $Path
                $Direct   = [System.IO.Path]::GetDirectoryName($Path)
                $FileName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
                $FileReso = $_
                $FileName = $FileName + "_$FileReso" + ".vox"
                $OutObj   = [System.IO.Path]::Combine($Direct, $FileName)

                Write-Host "`$InpObj:" $InpObj -ForegroundColor Green
                Write-Host "`$OutObj:" $OutObj -ForegroundColor Green


                obj2voxel-v1.3.4.exe `"$InpObj`" `"$OutObj`" -r $FileReso
            }
        }  
    }
}