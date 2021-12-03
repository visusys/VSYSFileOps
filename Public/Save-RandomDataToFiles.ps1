<#
.SYNOPSIS
    A brief description of the function or script.

.DESCRIPTION
    A detailed description of the function or script.

.PARAMETER OutputPath
    The path to save all generated random data.

.PARAMETER FilesizeMin
    The minimum filesize for each generated file.

.PARAMETER FilesizeMax
    The maximum filesize for each generated file.

.PARAMETER Unit
    The memory unit referenced by FilesizeMin / FilesizeMax
    Must be: 'Bytes','KB','MB','GB','TB'

.PARAMETER NumberOfFiles
    The number of random files to generate in the target directory.

.PARAMETER FilenameLengthMin
    The minimum filename length of each generated file excluding the extension.

.PARAMETER FilenameLengthMax
    The maximum filename length of each generated file excluding the extension.

.PARAMETER FileExtensions
    An array of possible file extensions to be used when generating files.
    Leave this as one string to restrict to a single extension.

.PARAMETER RandomFileExtensions
    When enabled, all resulting file extensions will be completely random.
    This overrides the FileExtensions parameter.

.EXAMPLE
    Save-RandomDataToFiles -OutputPath 'C:\Dev\Testing\Random' -FilesizeMin 20 -FilesizeMax 60 -Unit 'KB' -NumberOfFiles 20
    > This will generate 20 files between a filesize of 20-60KB in C:\Dev\Testing\Random

.EXAMPLE
    Save-RandomDataToFiles -OutputPath 'C:\Dev\Testing\Random' -FilesizeMin 1 -FilesizeMax 2 -Unit 'GB' -NumberOfFiles 5 -FileExtensions 'iso','bin'
    > This will generate 5 files between a filesize of 1-2GB in C:\Dev\Testing\Random with a file extension of either .iso or .bin.

.EXAMPLE
    Save-RandomDataToFiles -OutputPath 'C:\Dev\Testing\Random' -FilesizeMin 10 -FilesizeMax 20 -Unit 'MB' -NumberOfFiles 50 -RandomFileExtensions
    > This will generate 50 files between a filesize of 10-20MB in C:\Dev\Testing\Random with completely random file extensions.

.INPUTS
    String          (OutputPath, Unit)
    Decimal         (FilesizeMin, FilesizeMax)
    Int32           (NumberOfFiles, FilenameLengthMin, FilenameLengthMax)
    String Array    (FileExtensions)
    Switch          (RandomFileExtensions)

.OUTPUTS
    Nothing.

.NOTES
    Name: Save-RandomDataToFiles
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-12-02

.LINK
    https://github.com/visusys

.LINK
    Save-RandomDataToFile

#>
function Save-RandomDataToFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if (!(Test-Path -LiteralPath $_)) {
                throw [System.ArgumentException] "File or Folder does not exist."
            }
            if (Test-Path -LiteralPath $_ -PathType Leaf) {
                throw [System.ArgumentException] "File passed when a folder was expected."
            }
            return $true
        })]
        [String]
        $OutputPath,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [decimal]
        $FilesizeMin,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [decimal]
        $FilesizeMax,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('Bytes','KB','MB','GB','TB', IgnoreCase = $true)]
        [string]
        $Unit,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [Int32]
        $NumberOfFiles = 20,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [Int32]
        $FilenameLengthMin = 10,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [Int32]
        $FilenameLengthMax = 25,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [String[]]
        $FileExtensions = @('exe','jpg','png','dll','gif','ttf','doc','otf','txt'),

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Switch]
        $RandomFileExtensions
    )

    Begin {

    }

    Process {
        for ($i = 0; $i -lt $NumberOfFiles; $i++) {

            $CalculatedFilesize = Get-Random -Minimum $FilesizeMin -Maximum $FilesizeMax
            
            if(!$RandomFileExtensions){
                $Ext = Get-Random -Minimum 0 -Maximum $FileExtensions.Count
                $Extension = $FileExtensions[$Ext]
            }else{
                $Extension = Get-RandomAlphanumericString -Length 3
            }
            
            $FilenameLength = Get-Random -Minimum $FilenameLengthMin -Maximum $FilenameLengthMax

            $RandomHash = [PSCustomObject]@{
                OutputPath     = $OutputPath
                Filesize       = $CalculatedFilesize
                Unit           = $Unit
                FileExtension  = $Extension
                FilenameLength = $FilenameLength
            }

            $RandomHash | Save-RandomDataToFile
        }

    }

    End {

    }
}

# Save-RandomDataToFiles -OutputPath 'C:\Users\futur\Desktop\Testing\Random' -FilesizeMin 1 -FilesizeMax 2 -Unit 'GB' -NumberOfFiles 5 -FileExtensions 'iso','bin'
# Save-RandomDataToFiles -OutputPath 'C:\Users\futur\Desktop\Testing\Random' -FilesizeMin 20 -FilesizeMax 60 -Unit 'KB' -NumberOfFiles 20