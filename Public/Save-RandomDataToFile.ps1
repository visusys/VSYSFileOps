<#
.SYNOPSIS
    Writes random data to a file.

.DESCRIPTION
    Writes random data to a file in the format specified. 

.PARAMETER OutputPath
    The directory where the file will be created.

.PARAMETER Filesize
    The target filesize of the created file. 

.PARAMETER Unit
    Specifies what unit of memory is being referred to by Filesize.
    For instance, if Filesize is 10 and Unit is 'MB', this will
    create a file that is exactly 10MB. Allowed values are:
    'Bytes','KB','MB','GB', or 'TB'

.PARAMETER FileExtension
    Specifies the file extension of the created file.

.PARAMETER FilenameLength
    Specifies the length of the filename for the created file (Excluding the extension).

.EXAMPLE
    Save-RandomDataToFile -OutputPath 'C:\Users\Username\Desktop\Random' -Filesize 50 -Unit 'MB'
    > This will create a random file exactly 50MB in 'C:\Users\Username\Desktop\Random'

.EXAMPLE
    Save-RandomDataToFile -OutputPath 'C:\Dev\Tools\Random' -Filesize 1 -Unit 'GB' -FileExtension 'exe' -FilenameLength 4
    > This will create a random file exactly 1GB in 'C:\Dev\Tools\Random' with a file extension of .exe, and a filename length of 4.
    
.INPUTS
    System.String   (OutputPath, Unit, FileExtension)
    Decimal         (Filesize)
    System.String   (OutputPath)
    Int16           (FilenameLength)

.OUTPUTS
    Nothing.

.NOTES
    Name: Save-RandomDataToFile
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-12-02

.LINK
    https://github.com/visusys

.LINK
    Save-RandomDataToFiles

#>
function Save-RandomDataToFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
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
        [Decimal]
        $Filesize,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('Bytes','KB','MB','GB','TB', IgnoreCase = $true)]
        [String]
        $Unit,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [String]
        $FileExtension = 'txt',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [Int32]
        $FilenameLength = 16
    )

    Process {

        # Gather parameters and rope them into useable values
        # Extension / Filename / Full Path
        $DestExtension = $FileExtension
        $DestFilename  = (Get-RandomAlphanumericString -Length $FilenameLength) + '.' + $DestExtension
        $DestFullPath  = [System.IO.Path]::Combine($OutputPath, $DestFilename)
        
        # We need to convert the input filesize from whatever units specified to bytes
        $IntendedFilesize = (Format-UnitsOfMemory $Filesize -From $Unit -To 'Bytes')
        
        # If we are creating a file less than ~2.1474GB, we can use a faster
        # method for writing random data. For some reason this technique is quicker
        # than the alternative of writing data in chunks to a temp file.
        if($IntendedFilesize -lt 2147483500) {

            # Create our file to match the target filesize and place it in destination.
            $Buffer = [System.Byte[]]::CreateInstance([System.Byte],$IntendedFilesize)
            (New-Object Random).NextBytes($Buffer)
            [IO.File]::WriteAllBytes($DestFullPath, $Buffer)

        } else {

            # This method is only used for files over ~2.1474GB. Arrays in .NET cannot exceed 
            # 2^31-1 items in length (2,147,483,647 Bytes). This is because the index value 
            # used for arrays is [int]. So we fall back to writing the file in 4KB chunks.
            
            # Create a new byte array instance, as well as our RNG provider.
            $Buffer = [System.Byte[]]::CreateInstance([System.Byte],4KB)
            $RNG = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
            
            # Create a temp file and open it for streaming.
            $TempFile = [System.IO.Path]::GetTempFileName() | Get-Item
            $FileStream = $TempFile.OpenWrite()

            do {
                # Write random data to our temp file in 4KB chunks.
                $RNG.GetBytes($Buffer)
                $FileStream.Write($Buffer, 0, $Buffer.Length)

            # We're finished when the filesize hits IntendedFilesize
            } while ($FileStream.Length -lt $IntendedFilesize)
            
            # Cleanup
            $FileStream.Dispose()
            $RNG.Dispose()
            
            # Move and Rename the temp file to match our function's parameters.
            Move-Item $TempFile.FullName -Destination $OutputPath
            $NewFullName = [System.IO.Path]::Combine($OutputPath, $TempFile.Name)
            Rename-Item -Path $NewFullName -NewName $DestFilename
        }
    }
}

# $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

<# 
$Rando = [PSCustomObject]@{
    OutputPath    = "C:\Users\futur\Desktop\Testing\Random"
    Filesize      = 50
    Unit          = 'KB'
    FileExtension = 'txt'
},
[PSCustomObject]@{
    OutputPath    = "C:\Users\futur\Desktop\Testing\Random"
    Filesize      = 200
    Unit          = 'MB'
    FileExtension = 'exe'
}

$Rando | Save-RandomDataToFile 
#>

# Save-RandomDataToFile -OutputPath 'C:\Users\futur\Desktop\Testing\Random' -Filesize 50 -Unit 'KB'

# $Stopwatch.Stop()
# Write-Host "`$Stopwatch.Elapsed:            " $Stopwatch.Elapsed -ForegroundColor Green  
# Write-Host "`$Stopwatch.ElapsedMilliseconds:" $Stopwatch.ElapsedMilliseconds -ForegroundColor Green
# Write-Host "`$Stopwatch.ElapsedTicks:       " $Stopwatch.ElapsedTicks -ForegroundColor Green 