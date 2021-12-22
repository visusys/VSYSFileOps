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
        [Parameter(Mandatory,Position = 0)]
        [ValidateScript({
            (Test-Path -Path $_ -PathType leaf) -and ((Get-Item $_).Extension -eq '.svg')
        },ErrorMessage = "The passed path, {0}, does not include a file, doesn't exist, or the file is not a SVG.")]
        [string]$InputFile,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if($_ -notmatch "(\.ico)"){
                throw "The output file must be .ico"
            }
            return $true
        })]
        [System.IO.FileInfo]$OutputFile
    )

    $TempDir = New-TempDirectory 
    $TempDirName = $TempDir.FullName
    
    $InputFileUnescaped = $InputFile.Replace('`[','[')
    $InputFileUnescaped = $InputFileUnescaped.Replace('`]',']')

    Write-Host "`$TempDir:" $TempDir -ForegroundColor Green
    Write-Host "`$InputFile:" $InputFile -ForegroundColor Green
    
    Start-Process -WindowStyle hidden -FilePath rsvg-convert -ArgumentList "-w 16 -h 16 -a -f png `"$InputFileUnescaped`" -o `"$TempDirName\16.png`""
    Start-Process -WindowStyle hidden -FilePath rsvg-convert -ArgumentList "-w 24 -h 24 -a -f png `"$InputFileUnescaped`" -o `"$TempDirName\24.png`""
    Start-Process -WindowStyle hidden -FilePath rsvg-convert -ArgumentList "-w 32 -h 32 -a -f png `"$InputFileUnescaped`" -o `"$TempDirName\32.png`""
    Start-Process -WindowStyle hidden -FilePath rsvg-convert -ArgumentList "-w 48 -h 48 -a -f png `"$InputFileUnescaped`" -o `"$TempDirName\48.png`""
    Start-Process -WindowStyle hidden -FilePath rsvg-convert -ArgumentList "-w 64 -h 64 -a -f png `"$InputFileUnescaped`" -o `"$TempDirName\64.png`""
    Start-Process -WindowStyle hidden -FilePath rsvg-convert -ArgumentList "-w 256 -h 256 -a -f png `"$InputFileUnescaped`" -o `"$TempDirName\256.png`"" -Wait
    
    Start-Process -WindowStyle hidden -FilePath "magick" -ArgumentList "convert -background none -resize 16x16 -gravity center -extent 16x16 `"$TempDirName\16.png`" `"$TempDirName\16.png`""
    Start-Process -WindowStyle hidden -FilePath "magick" -ArgumentList "convert -background none -resize 24x24 -gravity center -extent 24x24 `"$TempDirName\24.png`" `"$TempDirName\24.png`""
    Start-Process -WindowStyle hidden -FilePath "magick" -ArgumentList "convert -background none -resize 32x32 -gravity center -extent 32x32 `"$TempDirName\32.png`" `"$TempDirName\32.png`""
    Start-Process -WindowStyle hidden -FilePath "magick" -ArgumentList "convert -background none -resize 48x48 -gravity center -extent 48x48 `"$TempDirName\48.png`" `"$TempDirName\48.png`""
    Start-Process -WindowStyle hidden -FilePath "magick" -ArgumentList "convert -background none -resize 64x64 -gravity center -extent 64x64 `"$TempDirName\64.png`" `"$TempDirName\64.png`""
    Start-Process -WindowStyle hidden -FilePath "magick" -ArgumentList "convert -background none -resize 256x256 -gravity center -extent 256x256 `"$TempDirName\256.png`" `"$TempDirName\256.png`"" -Wait

    Start-Process -WindowStyle hidden -FilePath "magick" -ArgumentList "convert `"$TempDirName\16.png`" `"$TempDirName\24.png`" `"$TempDirName\32.png`" `"$TempDirName\48.png`" `"$TempDirName\64.png`" `"$TempDirName\256.png`" `"$TempDirName\icon.ico`"" -Wait

    if(!$OutputFile){
        $NewFileName = (Get-Item $InputFile).BaseName + ".ico"
        $OutputFile = (Split-Path -Path $InputFile) + "\" + $NewFileName
    }

    $DestPath = Split-Path -Path $OutputFile
    $DestFile = Split-Path -Path $OutputFile -Leaf

    if(!(Test-Path -Path $DestPath)){
        New-Item -Path $DestPath -ItemType "directory"
    }

    if(Test-Path -Path "$TempDirName\icon.ico" -PathType leaf){
        Copy-Item $TempDirName\icon.ico -Destination $DestPath
        Rename-Item -Path "$DestPath\icon.ico" -NewName $DestFile
    }

    Remove-Item -Path $TempDirName -Force -Recurse
    
}