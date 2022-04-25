function Convert-PNGtoICO {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string[]]$InputPNGs
    )

    $InputPNGs | ForEach-Object -Parallel {

        [System.GC]::Collect()
        [System.GC]::GetTotalMemory('forcefullcollection') | out-null

        $TempDir     = New-TempDirectory
        $TempDirName = $TempDir.FullName
        
        $PNG = $_.Replace('`[', '[')
        $PNG = $PNG.Replace('`]', ']')
        
        $PNGObj = New-Object System.Drawing.Bitmap "$PNG"

        $IconTempName = Get-RandomAlphanumericString -Length 15

        if(($PNGObj.Height -le 16) -or ($PNGObj.Width -le 16)){
            if(($PNGObj.Height -eq 16) -and ($PNGObj.Width -eq 16)){
                Copy-Item -LiteralPath $PNG -Destination "$TempDirName\16.png"
            }else{
                magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$PNG`" `"$TempDirName\16.png`"
            }
            magick convert `"$TempDirName\16.png`" `"$TempDirName\$IconTempName.ico`"
        } elseif (($PNGObj.Height -le 20) -or ($PNGObj.Width -le 20)){
            if(($PNGObj.Height -eq 20) -and ($PNGObj.Width -eq 20)){
                Copy-Item -LiteralPath $PNG -Destination "$TempDirName\20.png"
            }else{
                magick convert -background none -resize 20x20 -gravity center -extent 20x20 `"$PNG`" `"$TempDirName\20.png`"
                magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$PNG`" `"$TempDirName\16.png`"
            }
            magick convert `"$TempDirName\20.png`" `"$TempDirName\16.png`" `"$TempDirName\$IconTempName.ico`"
        } elseif (($PNGObj.Height -le 24) -or ($PNGObj.Width -le 24)) {
            if(($PNGObj.Height -eq 24) -and ($PNGObj.Width -eq 24)){
                Copy-Item -LiteralPath $PNG -Destination "$TempDirName\24.png"
            }else{
                magick convert -background none -resize 24x24 -gravity center -extent 24x24 `"$PNG`" `"$TempDirName\24.png`"
                magick convert -background none -resize 20x20 -gravity center -extent 20x20 `"$PNG`" `"$TempDirName\20.png`"
                magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$PNG`" `"$TempDirName\16.png`"
            }
            magick convert `"$TempDirName\24.png`" `"$TempDirName\20.png`" `"$TempDirName\16.png`" `"$TempDirName\$IconTempName.ico`"
        } elseif (($PNGObj.Height -le 40) -or ($PNGObj.Width -le 40)) {
            if(($PNGObj.Height -eq 40) -and ($PNGObj.Width -eq 40)){
                Copy-Item -LiteralPath $PNG -Destination "$TempDirName\40.png"
            }else{
                magick convert -background none -resize 40x40 -gravity center -extent 40x40 `"$PNG`" `"$TempDirName\40.png`"
                magick convert -background none -resize 24x24 -gravity center -extent 24x24 `"$PNG`" `"$TempDirName\24.png`"
                magick convert -background none -resize 20x20 -gravity center -extent 20x20 `"$PNG`" `"$TempDirName\20.png`"
                magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$PNG`" `"$TempDirName\16.png`"
            }
            magick convert `"$TempDirName\40.png`" `"$TempDirName\24.png`" `"$TempDirName\20.png`" `"$TempDirName\16.png`" `"$TempDirName\$IconTempName.ico`"
        } elseif (($PNGObj.Height -le 48) -or ($PNGObj.Width -le 48)) {
            if(($PNGObj.Height -eq 48) -and ($PNGObj.Width -eq 48)){
                Copy-Item -LiteralPath $PNG -Destination "$TempDirName\48.png"
            }else{
                magick convert -background none -resize 48x48 -gravity center -extent 48x48 `"$PNG`" `"$TempDirName\48.png`"
                magick convert -background none -resize 40x40 -gravity center -extent 40x40 `"$PNG`" `"$TempDirName\40.png`"
                magick convert -background none -resize 24x24 -gravity center -extent 24x24 `"$PNG`" `"$TempDirName\24.png`"
                magick convert -background none -resize 20x20 -gravity center -extent 20x20 `"$PNG`" `"$TempDirName\20.png`"
                magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$PNG`" `"$TempDirName\16.png`"
            }
            magick convert `"$TempDirName\48.png`" `"$TempDirName\40.png`" `"$TempDirName\24.png`" `"$TempDirName\20.png`" `"$TempDirName\16.png`" `"$TempDirName\$IconTempName.ico`"
        } elseif (($PNGObj.Height -le 64) -or ($PNGObj.Width -le 64)) {
            if(($PNGObj.Height -eq 64) -and ($PNGObj.Width -eq 64)){
                Copy-Item -LiteralPath $PNG -Destination "$TempDirName\64.png"
            }else{
                magick convert -background none -resize 64x64 -gravity center -extent 64x64 `"$PNG`" `"$TempDirName\64.png`"
                magick convert -background none -resize 48x48 -gravity center -extent 48x48 `"$PNG`" `"$TempDirName\48.png`"
                magick convert -background none -resize 40x40 -gravity center -extent 40x40 `"$PNG`" `"$TempDirName\40.png`"
                magick convert -background none -resize 24x24 -gravity center -extent 24x24 `"$PNG`" `"$TempDirName\24.png`"
                magick convert -background none -resize 20x20 -gravity center -extent 20x20 `"$PNG`" `"$TempDirName\20.png`"
                magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$PNG`" `"$TempDirName\16.png`"
            }
            magick convert `"$TempDirName\64.png`" `"$TempDirName\48.png`" `"$TempDirName\40.png`" `"$TempDirName\24.png`" `"$TempDirName\20.png`" `"$TempDirName\16.png`" `"$TempDirName\$IconTempName.ico`"
        } elseif (($PNGObj.Height -le 96) -or ($PNGObj.Width -le 96)) {
            if(($PNGObj.Height -eq 96) -and ($PNGObj.Width -eq 96)){
                Copy-Item -LiteralPath $PNG -Destination "$TempDirName\96.png"
            }else{
                magick convert -background none -resize 96x96 -gravity center -extent 96x96 `"$PNG`" `"$TempDirName\96.png`"
                magick convert -background none -resize 64x64 -gravity center -extent 64x64 `"$PNG`" `"$TempDirName\64.png`"
                magick convert -background none -resize 48x48 -gravity center -extent 48x48 `"$PNG`" `"$TempDirName\48.png`"
                magick convert -background none -resize 40x40 -gravity center -extent 40x40 `"$PNG`" `"$TempDirName\40.png`"
                magick convert -background none -resize 24x24 -gravity center -extent 24x24 `"$PNG`" `"$TempDirName\24.png`"
                magick convert -background none -resize 20x20 -gravity center -extent 20x20 `"$PNG`" `"$TempDirName\20.png`"
                magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$PNG`" `"$TempDirName\16.png`"
            }
            magick convert `"$TempDirName\96.png`" `"$TempDirName\64.png`" `"$TempDirName\48.png`" `"$TempDirName\40.png`" `"$TempDirName\24.png`" `"$TempDirName\20.png`" `"$TempDirName\16.png`" `"$TempDirName\$IconTempName.ico`"
        } elseif (($PNGObj.Height -le 256) -or ($PNGObj.Width -le 256)) {
            if(($PNGObj.Height -eq 256) -and ($PNGObj.Width -eq 256)){
                Copy-Item -LiteralPath $PNG -Destination "$TempDirName\256.png"
            }else{
                magick convert -background none -resize 256x256 -gravity center -extent 256x256 `"$PNG`" `"$TempDirName\256.png`"
                magick convert -background none -resize 96x96 -gravity center -extent 96x96 `"$PNG`" `"$TempDirName\96.png`"
                magick convert -background none -resize 64x64 -gravity center -extent 64x64 `"$PNG`" `"$TempDirName\64.png`"
                magick convert -background none -resize 48x48 -gravity center -extent 48x48 `"$PNG`" `"$TempDirName\48.png`"
                magick convert -background none -resize 40x40 -gravity center -extent 40x40 `"$PNG`" `"$TempDirName\40.png`"
                magick convert -background none -resize 24x24 -gravity center -extent 24x24 `"$PNG`" `"$TempDirName\24.png`"
                magick convert -background none -resize 20x20 -gravity center -extent 20x20 `"$PNG`" `"$TempDirName\20.png`"
                magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$PNG`" `"$TempDirName\16.png`"
            }
            magick convert `"$TempDirName\256.png`" `"$TempDirName\96.png`" `"$TempDirName\64.png`" `"$TempDirName\48.png`" `"$TempDirName\40.png`" `"$TempDirName\24.png`" `"$TempDirName\20.png`" `"$TempDirName\16.png`" `"$TempDirName\$IconTempName.ico`"
        } elseif (($PNGObj.Height -gt 256) -or ($PNGObj.Width -gt 256)) {
            magick convert -background none -resize 256x256 -gravity center -extent 256x256 `"$PNG`" `"$TempDirName\256.png`"
            magick convert -background none -resize 96x96 -gravity center -extent 96x96 `"$PNG`" `"$TempDirName\96.png`"
            magick convert -background none -resize 64x64 -gravity center -extent 64x64 `"$PNG`" `"$TempDirName\64.png`"
            magick convert -background none -resize 48x48 -gravity center -extent 48x48 `"$PNG`" `"$TempDirName\48.png`"
            magick convert -background none -resize 40x40 -gravity center -extent 40x40 `"$PNG`" `"$TempDirName\40.png`"
            magick convert -background none -resize 24x24 -gravity center -extent 24x24 `"$PNG`" `"$TempDirName\24.png`"
            magick convert -background none -resize 20x20 -gravity center -extent 20x20 `"$PNG`" `"$TempDirName\20.png`"
            magick convert -background none -resize 16x16 -gravity center -extent 16x16 `"$PNG`" `"$TempDirName\16.png`"
            magick convert `"$TempDirName\256.png`" `"$TempDirName\96.png`" `"$TempDirName\64.png`" `"$TempDirName\48.png`" `"$TempDirName\40.png`" `"$TempDirName\24.png`" `"$TempDirName\20.png`" `"$TempDirName\16.png`" `"$TempDirName\$IconTempName.ico`"
        }

        $DestFile = [System.IO.Path]::GetFileNameWithoutExtension($_) + ".ico"
        $DestPath = [System.IO.Path]::GetDirectoryName($_)

        if (Test-Path -LiteralPath "$TempDirName\$IconTempName.ico" -PathType leaf) {
            Copy-Item $TempDirName\$IconTempName.ico -Destination $DestPath
            Rename-Item -LiteralPath "$DestPath\$IconTempName.ico" -NewName $DestFile
        }

        Remove-Item -LiteralPath $TempDirName -Force -Recurse

    } -ThrottleLimit 32

    [System.GC]::Collect()

    Invoke-VBMessageBox -Message "Conversion to ICO complete." -Title "Conversion Complete" -Icon Information -BoxType OKOnly -DefaultButton 1

}