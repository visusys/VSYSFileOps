function Convert-HEXToColorArray {
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
            if ($_ -notmatch "(\.txt|\.colorhex)") {
                throw [System.ArgumentException] "The file specified must have an extension of TXT or COLORHEX."
            }
            return $true
        })]
        [String]
        $HexListFile
    )

    Process {

        $HexContent = Get-Content -LiteralPath $HexListFile
        $HexContent = $HexContent.Split(' ')

        $HexListFilePath = [System.IO.Path]::GetDirectoryName($HexListFile)
        $HexListBaseName = [System.IO.Path]::GetFileNameWithoutExtension($HexListFile)
        $HexListExtension = [System.IO.Path]::GetExtension($HexListFile)

        $HexListNewName  = $HexListFilePath + "\" + $HexListBaseName + "_Formatted" + $HexListExtension

        Write-Host "`$HexListFile:   " $HexListFile -ForegroundColor Green
        Write-Host "`$HexListNewName:" $HexListNewName -ForegroundColor Green

        if(Test-Path -LiteralPath $HexListNewName -PathType Leaf){
            Remove-Item $HexListNewName -Recurse -Force
        }
        
        $NewHexFile = New-Item -Path $HexListNewName -ItemType File

        Add-Content -LiteralPath $HexListNewName -Value "var colorsArray = ["
        foreach ($HexValue in $HexContent) {
            Add-Content -LiteralPath $HexListNewName -Value "`t{`r`n`t`tcolor: `"$HexValue`",`r`n`t`tname: `"$HexValue`"`r`n`t},"
        }
        Add-Content -LiteralPath $HexListNewName -Value "];"

    }
}