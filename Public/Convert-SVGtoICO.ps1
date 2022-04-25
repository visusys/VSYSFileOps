<#
.SYNOPSIS
    Converts a SVG to ICO (Windows Icon)

.DESCRIPTION
    Output icon will contain 6 sizes: 16x16, 24x24, 32x32, 48x48, 64x64, 256x256
    Dependancy: ImageMagick must be installed and available in your system PATH environment variable.
    Dependancy: rsvg-convert must be installed and available in your system PATH environment variable. 
    (https://community.chocolatey.org/packages/rsvg-convert)

.PARAMETER InputFile
    A path to a valid .svg file that you want to convert.

.PARAMETER OutputFile
    A valid directory to save the generated ICO. Defaults to the same directory as the SVG.

.NOTES
    Name: Convert-SVGtoICO
    Author: Visusys
    Version: 1.0.0
    DateCreated: 2021-11-10

.EXAMPLE
    Convert-SVGtoICO -InputFile "C:\Icons\MyIcon.svg"

.EXAMPLE
    Convert-SVGtoICO -InputFile "C:\Icons\MyIcon.svg" -OutputFile "C:\Test\MyIconNew.ico"

.LINK
    https://github.com/visusys
#>
function Convert-SVGtoICO {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string[]]$InputSVGs
    )

    process {

        $InputSVGs | ForEach-Object -Parallel {

            $TempDir = New-TempDirectory
            $TempDirName = $TempDir.FullName
            
            $InputUnescaped = $_.Replace('`[', '[')
            $InputUnescaped = $InputUnescaped.Replace('`]', ']')
            
            rsvg-convert -w 16 -h 16 -a -f png `"$InputUnescaped`" -o `"$TempDirName\16.png`" 
            rsvg-convert -w 24 -h 24 -a -f png `"$InputUnescaped`" -o `"$TempDirName\24.png`"
            rsvg-convert -w 32 -h 32 -a -f png `"$InputUnescaped`" -o `"$TempDirName\32.png`"
            rsvg-convert -w 48 -h 48 -a -f png `"$InputUnescaped`" -o `"$TempDirName\48.png`"
            rsvg-convert -w 64 -h 64 -a -f png `"$InputUnescaped`" -o `"$TempDirName\64.png`"
            rsvg-convert -w 256 -h 256 -a -f png `"$InputUnescaped`" -o `"$TempDirName\256.png`"

            Write-Host "16.png Length: "(Get-Item -LiteralPath "$TempDirName\16.png").length

            If ((Get-Item -LiteralPath "$TempDirName\16.png").length -eq 0kb) {
                Remove-Item -LiteralPath $TempDirName -Force -Recurse
                Invoke-VBMessageBox "Error occured during SVG conversion ($_)." -Title "SVG Conversion Error" -Icon Critical -BoxType OKOnly -DefaultButton 1
                Break
            }

            magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$TempDirName\16.png`" `"$TempDirName\16.png`"
            magick convert -background none -resize 24x24 -gravity center -extent 24x24 `"$TempDirName\24.png`" `"$TempDirName\24.png`"
            magick convert -background none -resize 32x32 -gravity center -extent 32x32 `"$TempDirName\32.png`" `"$TempDirName\32.png`"
            magick convert -background none -resize 48x48 -gravity center -extent 48x48 `"$TempDirName\48.png`" `"$TempDirName\48.png`"
            magick convert -background none -resize 64x64 -gravity center -extent 64x64 `"$TempDirName\64.png`" `"$TempDirName\64.png`"
            magick convert -background none -resize 256x256 -gravity center -extent 256x256 `"$TempDirName\256.png`" `"$TempDirName\256.png`"
        
            $IconTempName = Get-RandomAlphanumericString -Length 15

            magick convert `"$TempDirName\16.png`" `"$TempDirName\24.png`" `"$TempDirName\32.png`" `"$TempDirName\48.png`" `"$TempDirName\64.png`" `"$TempDirName\256.png`" `"$TempDirName\$IconTempName.ico`"
            
            $DestFile = [System.IO.Path]::GetFileNameWithoutExtension($_) + ".ico"
            $DestPath = [System.IO.Path]::GetDirectoryName($_)

            if (Test-Path -LiteralPath "$TempDirName\$IconTempName.ico" -PathType leaf) {
                Copy-Item $TempDirName\$IconTempName.ico -Destination $DestPath
                Rename-Item -LiteralPath "$DestPath\$IconTempName.ico" -NewName $DestFile
            }
        
            Remove-Item -LiteralPath $TempDirName -Force -Recurse
            
        } -ThrottleLimit 32

        Invoke-VBMessageBox -Message "Conversion to ICO complete." -Title "Conversion Complete" -Icon Information -BoxType OKOnly -DefaultButton 1

    }
}